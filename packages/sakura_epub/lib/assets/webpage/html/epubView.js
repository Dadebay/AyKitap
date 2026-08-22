var book = ePub();
var rendition;
var displayed;
var chapters = []
var clearSelectionOnPageChange = true; // Global flag for selection clearing behavior

// Font state
var _currentFontFamily = null;
var _currentFontBase64 = null;
var _currentFontMimeType = null;

function _injectFontCSS(contents, fontFamily, fontBase64, fontMimeType) {
  var old = contents.document.getElementById('sakura-font-style');
  if (old) old.remove();
  var style = contents.document.createElement('style');
  style.id = 'sakura-font-style';
  var css = '';
  if (fontBase64) {
    var fmt = (fontMimeType && fontMimeType.indexOf('opentype') !== -1) ? 'opentype' : 'truetype';
    css += "@font-face { font-family: '" + fontFamily + "'; src: url('data:" + fontMimeType + ";base64," + fontBase64 + "') format('" + fmt + "'); font-weight: normal; font-style: normal; }\n";
  }
  css += "body, p, span, div, li, td, th { font-family: '" + fontFamily + "', sans-serif !important; }";
  style.textContent = css;
  contents.document.head.appendChild(style);
}

// Calibre (and most FB2/EPUB converters) emit the cover as a percentage-sized
// SVG wrapper rather than a plain <img>:
//
//   <div><svg width="100%" height="100%" viewBox="0 0 737 1186">
//          <image width="737" height="1186" xlink:href="cover.jpg"/></svg></div>
//
// In paginated mode epub.js lays the section's <body> out as a flex row (its
// column layout), which leaves that plain <div> — a flex item with no
// intrinsic size — measuring 0x0. The <svg>'s width/height:100% then resolve
// against zero, so the whole cover collapses and the page renders blank even
// though the image itself loaded fine. Giving the wrapper chain a real size
// makes the percentages resolve again.
function _fixFullPageSvgImages(contents) {
  try {
    var doc = contents.document;
    var svgs = doc.querySelectorAll('svg');
    for (var i = 0; i < svgs.length; i++) {
      var svg = svgs[i];
      // Only full-page image covers. An inline diagram sized in px has an
      // intrinsic size already and lays out correctly, so leave it alone.
      if (!svg.querySelector('image')) continue;
      var w = svg.getAttribute('width') || '';
      var h = svg.getAttribute('height') || '';
      if (w.indexOf('%') === -1 && h.indexOf('%') === -1) continue;

      // Inline !important outranks the stylesheet rules epub.js's
      // adjustImages() installs, whose max-width/max-height would otherwise
      // cap the cover back down to ~95% of the column box.
      svg.style.setProperty('width', '100%', 'important');
      svg.style.setProperty('height', '100%', 'important');
      svg.style.setProperty('max-width', 'none', 'important');
      svg.style.setProperty('max-height', 'none', 'important');

      // Walk up to <body> — it's the collapsed ancestors (the flex items)
      // that zeroed the svg out, so each one needs the page box too.
      var el = svg.parentElement;
      while (el && el !== doc.body) {
        el.style.setProperty('width', '100%', 'important');
        el.style.setProperty('height', '100%', 'important');
        el = el.parentElement;
      }
    }
  } catch (e) {
    console.error('Error sizing full-page SVG image:', e);
  }
}

function setFontFamily(fontFamily, fontBase64, fontMimeType) {
  _currentFontFamily = fontFamily;
  _currentFontBase64 = fontBase64 || null;
  _currentFontMimeType = fontMimeType || 'font/truetype';
  if (!rendition) return;
  // A different typeface has different metrics, so it repaginates the book —
  // clear the frozen page-count divisor so it re-measures. (_resetPageMetrics
  // is a hoisted function declaration, safe to call from here.)
  _resetPageMetrics();
  try {
    rendition.getContents().forEach(function(contents) {
      _injectFontCSS(contents, _currentFontFamily, _currentFontBase64, _currentFontMimeType);
    });
  } catch(e) {
    console.error('Error applying font:', e);
  }
}
var selectAnnotationRange = false; // Global flag for programmatically selecting annotation ranges
var initialXPathProcessed = false; // Flag to prevent processing initialXPath multiple times
var xpathDisplayInProgress = false; // Flag to prevent multiple XPath displays
var initialPositionLoading = false; // Flag to track if initial position is being loaded
// Global selection state tracking (needed for blocking navigation when selection is active)
var isSelecting = false;
var lastCfiRange = null;
var selectionTimeout = null;
var hasSentSelection = false; // Track if we've actually sent a selection event to Flutter
var lastTapCoords = null; // Store the last tap coordinates for onTouchDown/onTouchUp callbacks
// ── Page-count metrics ─────────────────────────────────────────────────────
// The book's total "locations" (book.locations.length()) is a fixed number
// once generated, so the ONLY thing that made the reported total page count
// drift on every swipe was the divisor — the estimated number of locations one
// on-screen page holds — being recomputed live each page. We now measure that
// divisor over the first few genuine text screens, then FREEZE it: both the
// page number and the total are derived from the frozen divisor thereafter, so
// the total stays put. A genuine re-pagination (font size, line spacing, flow,
// font family) clears the freeze via _resetPageMetrics so it re-measures for
// the new layout. See pageInfoFor.
var _perPageSum = 0;        // sum of location-spans over sampled text screens
var _perPageSamples = 0;    // how many text screens have been folded in
var _perPageFrozen = 0;     // 0 = still warming up; else the locked divisor
// Freeze once this many genuine text screens have been sampled — a handful is
// enough to average out the screen-to-screen variance, then the total locks.
var _perPageFreezeAfter = 4;
// Direction of the most recent real page turn — 1 forward, -1 back, set by
// the rendition.next/prev wrapper in _installPageTransitions and consumed (and
// reset to 0) the next time pageInfoFor runs. 0 means the relocation was a
// jump instead (goToChapter, search, restoring position), not a swipe.
var _lastNavDirection = 0;
// The last page number pageInfoFor actually reported, so a run of image-only
// screens (see pageInfoFor) can still be counted forward one at a time.
var _lastComputedPage = 0;

// Clears the measured/frozen page-count divisor so the next few relocations
// re-measure it. Called on load and whenever the layout genuinely repaginates.
function _resetPageMetrics() {
  _perPageSum = 0;
  _perPageSamples = 0;
  _perPageFrozen = 0;
  _lastNavDirection = 0;
  _lastComputedPage = 0;
}

function loadBook(data, cfi, initialXPath, manager, flow, spread, snap, allowScriptedContent, direction, useCustomSwipe, backgroundColor, foregroundColor, fontSize, clearSelectionOnNav, selectAnnotationRangeParam, customCss, savedLocations) {
  // Reset flags for new book
  initialXPathProcessed = false;
  xpathDisplayInProgress = false;
  initialPositionLoading = false;
  _resetPageMetrics();
  // Store the clearSelectionOnPageChange setting
  clearSelectionOnPageChange = clearSelectionOnNav !== undefined ? clearSelectionOnNav : true;
  // Store the selectAnnotationRange setting
  selectAnnotationRange = selectAnnotationRangeParam !== undefined ? selectAnnotationRangeParam : false;
  var viewportHeight = window.innerHeight;
  document.getElementById('viewer').style.height = viewportHeight;
  var uint8Array;
  if (typeof data === 'string') {
    var binaryString = atob(data);
    uint8Array = new Uint8Array(binaryString.length);
    for (var i = 0; i < binaryString.length; i++) {
      uint8Array[i] = binaryString.charCodeAt(i);
    }
  } else {
    uint8Array = new Uint8Array(data);
  }
  book.open(uint8Array).catch(function (e) {
    console.error('Error opening book:', e);
    try {
      window.flutter_inappwebview.callHandler('displayError');
    } catch (err) {
      console.error('Error calling displayError callback:', err);
    }
  });
  rendition = book.renderTo("viewer", {
    manager: manager,
    flow: flow,
    spread: spread,
    // Lay the sections out left-to-right. Without this epub.js builds its
    // Stage with the container default — "vertical", i.e. display:block — and
    // only flips it to a flex row later, if and when a view's own load handler
    // gets round to calling setAxis. Until then the next section sits *below*
    // the current one, so a page turn slides up from the bottom edge no matter
    // which horizontal animation was chosen (see _transitionSpec).
    axis: "horizontal",
    width: "100vw",
    height: "100vh",
    snap: snap && !useCustomSwipe,
    allowScriptedContent: allowScriptedContent,
    defaultDirection: direction
  });

  // Route every page turn through the animation layer (TZ §12.2).
  _installPageTransitions(rendition);

  // Apply initial theme
  updateTheme(backgroundColor, foregroundColor, customCss);

  // Re-inject font CSS on every section render
  rendition.hooks.content.register(function(contents) {
    if (_currentFontFamily) {
      _injectFontCSS(contents, _currentFontFamily, _currentFontBase64, _currentFontMimeType);
    }
    _fixFullPageSvgImages(contents);
  });

  // Initial display - skip if we have XPath (we'll display after conversion)
  // If we have XPath, we'll display after converting it, so skip initial display
  if (initialXPath) {
    // Just display the default location, we'll navigate to XPath after conversion
    displayed = rendition.display()
    // XPath conversion will happen later in book.ready, callback will be fired there
  } else if (cfi) {
    // CFI display happens immediately, so fire callback now
    initialPositionLoading = true;
    try {
      window.flutter_inappwebview.callHandler('initialPositionLoading', { type: 'cfi' });
    } catch (e) {
      console.error('Error calling initialPositionLoading callback:', e);
    }
    displayed = rendition.display(cfi)
  } else {
    displayed = rendition.display()
  }

  // Setup blocking immediately after rendition is created
  // Use setTimeout to ensure rendition object is fully initialized
  setTimeout(function () {
    setupRenditionBlocking();
  }, 100);

  rendition.on("displayed", function (renderer) {
    window.flutter_inappwebview.callHandler('displayed');
    // If we were loading initial position, notify that it's complete
    if (initialPositionLoading) {
      initialPositionLoading = false;
      try {
        window.flutter_inappwebview.callHandler('initialPositionLoaded');
      } catch (e) {
        console.error('Error calling initialPositionLoaded callback:', e);
      }
    }
    // Setup blocking again to ensure it's active (in case it wasn't set up earlier)
    setupRenditionBlocking();
  });

  // Reset selection state tracking (use global variables)
  selectionTimeout = null;
  isSelecting = false;
  lastCfiRange = null;
  hasSentSelection = false;

  // Helper function to check and process selection
  function checkAndProcessSelection(contents) {
    try {
      // Try contents window first
      var selection = contents.window.getSelection();
      var range = null;
      var selectedText = '';

      if (selection && selection.rangeCount > 0) {
        try {
          range = selection.getRangeAt(0);
          selectedText = selection.toString();
        } catch (e) {
          // Ignore errors
        }
      }

      // If no selection in contents, try parent window (iPad sometimes puts it there)
      if ((!selectedText || !range || range.collapsed) && window.getSelection) {
        try {
          var parentSelection = window.getSelection();
          if (parentSelection && parentSelection.rangeCount > 0) {
            var parentRange = parentSelection.getRangeAt(0);
            var parentText = parentSelection.toString();
            // Check if parent selection is actually in the epub content
            if (parentText && !parentRange.collapsed) {
              // Try to find which iframe this selection is in
              var iframe = contents.document.defaultView.frameElement;
              if (iframe && parentRange.commonAncestorContainer) {
                // Check if the selection is within our iframe
                try {
                  if (iframe.contentDocument &&
                    (iframe.contentDocument === parentRange.commonAncestorContainer.ownerDocument ||
                      iframe.contentDocument.contains(parentRange.commonAncestorContainer))) {
                    selection = parentSelection;
                    range = parentRange;
                    selectedText = parentText;
                  }
                } catch (e) {
                  // Cross-origin or other error, try anyway
                  selection = parentSelection;
                  range = parentRange;
                  selectedText = parentText;
                }
              }
            }
          }
        } catch (e) {
          // Ignore errors
        }
      }

      if (!selection || !range || selection.rangeCount === 0) {
        return false;
      }

      if (!selectedText || range.collapsed) {
        return false;
      }

      // If we already have this selection, don't process again
      if (isSelecting && lastCfiRange) {
        return true;
      }

      // Try to get CFI from range using epub.js API
      try {
        if (typeof contents.cfiFromRange === 'function') {
          var cfiRange = contents.cfiFromRange(range);
          if (cfiRange) {
            lastCfiRange = cfiRange;
            isSelecting = true;
            // Clear any existing timeout
            if (selectionTimeout) {
              clearTimeout(selectionTimeout);
            }
            // Debounce to allow selection to stabilize
            selectionTimeout = setTimeout(function () {
              // Verify selection still exists before sending
              var stillHasSelection = false;
              try {
                var currentSelection = contents.window.getSelection();
                if (currentSelection && currentSelection.rangeCount > 0) {
                  var currentRange = currentSelection.getRangeAt(0);
                  var currentText = currentSelection.toString();
                  if (currentText && currentRange && !currentRange.collapsed) {
                    stillHasSelection = true;
                  }
                }
              } catch (e) {
                // Ignore errors
              }

              if (stillHasSelection && lastCfiRange === cfiRange) {
                sendSelectionData(cfiRange, contents);
              } else {
                // Selection was cleared before timeout fired, clear flags
                if (lastCfiRange === cfiRange) {
                  isSelecting = false;
                  lastCfiRange = null;
                  hasSentSelection = false;
                }
              }
            }, 200);
            return true;
          }
        }
      } catch (e) {
        // Ignore errors
      }
    } catch (e) {
      // Ignore errors
    }
    return false;
  }

  // Continuous polling for iPad (as last resort when events don't fire)
  var pollIntervals = []; // Store intervals for each content frame
  var lastPolledSelections = new Map(); // Track last selection per contents

  function startPolling(contents) {
    // Check if we're already polling this contents
    var contentsId = contents.document ? contents.document.URL : 'unknown';
    if (lastPolledSelections.has(contentsId)) {
      return;
    }

    lastPolledSelections.set(contentsId, null);

    var pollCount = 0;
    var noSelectionCount = 0;
    var interval = setInterval(function () {
      try {
        pollCount++;

        // Stop polling if no selection found for 5 seconds (50 polls * 100ms)
        // This optimizes performance - only poll when there might be a selection
        if (pollCount > 50 && noSelectionCount > 40) {
          clearInterval(interval);
          lastPolledSelections.delete(contentsId);
          return;
        }

        // Check if window/selection API is available
        if (!contents.window || !contents.window.getSelection) {
          return;
        }

        var selection = contents.window.getSelection();
        if (!selection) {
          noSelectionCount++;
          return;
        }

        // Check selection properties even if toString() is empty
        var rangeCount = selection.rangeCount || 0;
        var selectedText = selection.toString() || '';
        var hasRanges = rangeCount > 0;

        // Even if toString() is empty, check if there are ranges (iPad quirk)
        var currentSelection = selectedText || (hasRanges ? 'HAS_RANGE_BUT_NO_TEXT' : null);
        var lastSelection = lastPolledSelections.get(contentsId);

        // Only process if selection changed
        if (currentSelection !== lastSelection) {
          lastPolledSelections.set(contentsId, currentSelection);
          noSelectionCount = 0; // Reset counter when selection found

          if (!selectedText && !hasRanges) {
            // Clear flags if they're set (even if we haven't sent a selection yet)
            if (isSelecting || lastCfiRange) {
              // Only fire selectionCleared if we've actually sent a selection
              if (hasSentSelection) {
                window.flutter_inappwebview.callHandler('selectionCleared');
              }
              // Always clear the flags when there's no selection
              isSelecting = false;
              lastCfiRange = null;
              hasSentSelection = false;
              if (selectionTimeout) {
                clearTimeout(selectionTimeout);
                selectionTimeout = null;
              }
            }
          } else {
            // Selection exists - try to process it
            if (!isSelecting) {
              checkAndProcessSelection(contents);
            }
          }
        } else if (!currentSelection) {
          noSelectionCount++;
        }
      } catch (e) {
        // Ignore errors
      }
    }, 200); // Check every 200ms

    pollIntervals.push({ contentsId: contentsId, interval: interval });
  }

  function stopPolling() {
    pollIntervals.forEach(function (item) {
      clearInterval(item.interval);
    });
    pollIntervals = [];
    lastPolledSelections.clear();
  }

  // Handle selection clearing and changes
  rendition.hooks.content.register(function (contents) {
    // Listen on document
    contents.window.document.addEventListener('selectionchange', function () {
      var selection = contents.window.getSelection();
      var selectedText = selection.toString();

      // Check if there's actually a range, not just text (more reliable)
      var hasRange = selection && selection.rangeCount > 0;
      var hasNonCollapsedRange = false;
      if (hasRange) {
        try {
          var range = selection.getRangeAt(0);
          hasNonCollapsedRange = range && !range.collapsed;
        } catch (e) {
          // Ignore errors
        }
      }

      // Only clear selection if there's truly no range AND no text
      // This prevents clearing when toString() is temporarily empty but range exists
      if (!hasNonCollapsedRange && !selectedText) {
        // Double-check across all content frames before clearing
        var stillHasSelection = false;
        try {
          var allContents = rendition.getContents();
          for (var i = 0; i < allContents.length; i++) {
            try {
              var cont = allContents[i];
              if (cont.window && cont.window.getSelection) {
                var contSel = cont.window.getSelection();
                if (contSel && contSel.rangeCount > 0) {
                  var contRange = contSel.getRangeAt(0);
                  var contText = contSel.toString();
                  if (contText || (contRange && !contRange.collapsed)) {
                    stillHasSelection = true;
                    break;
                  }
                }
              }
            } catch (e) {
              // Ignore errors
            }
          }
          // Also check parent window
          if (!stillHasSelection && window.getSelection) {
            var parentSel = window.getSelection();
            if (parentSel && parentSel.rangeCount > 0) {
              var parentRange = parentSel.getRangeAt(0);
              var parentText = parentSel.toString();
              if (parentText || (parentRange && !parentRange.collapsed)) {
                stillHasSelection = true;
              }
            }
          }
        } catch (e) {
          // Ignore errors
        }

        if (!stillHasSelection) {
          // Clear flags if they're set (even if we haven't sent a selection yet)
          // This handles the case where checkAndProcessSelection set flags but selection was cleared before timeout
          if (isSelecting || lastCfiRange) {
            // Only fire selectionCleared if we've actually sent a selection
            if (hasSentSelection) {
              window.flutter_inappwebview.callHandler('selectionCleared');
            }
            // Always clear the flags when there's no selection
            isSelecting = false;
            lastCfiRange = null;
            hasSentSelection = false;
            if (selectionTimeout) {
              clearTimeout(selectionTimeout);
              selectionTimeout = null;
            }
          }
        }
      } else if (isSelecting) {
        // Selection is being modified (dragging handles)
        // Notify Flutter to hide the widget
        window.flutter_inappwebview.callHandler('selectionChanging');

        // Find the contents object that actually contains the current selection
        // The passed contents might be from a different page after navigation
        var actualContents = contents;
        try {
          var allContents = rendition.getContents();
          for (var i = 0; i < allContents.length; i++) {
            var cont = allContents[i];
            try {
              if (cont.window && cont.window.getSelection) {
                var sel = cont.window.getSelection();
                if (sel && sel.rangeCount > 0) {
                  var range = sel.getRangeAt(0);
                  if (range && !range.collapsed) {
                    // This contents has an active selection, use it
                    actualContents = cont;
                    break;
                  }
                }
              }
            } catch (e) {
              // Ignore errors, continue checking other contents
            }
          }
        } catch (e) {
          // If we can't find the right contents, use the passed one
          actualContents = contents;
        }

        // Get the current CFI from the current selection range (not the stale lastCfiRange)
        // This ensures we use the correct CFI for the current page after navigation
        try {
          var currentSelection = actualContents.window.getSelection();
          if (currentSelection && currentSelection.rangeCount > 0) {
            var currentRange = currentSelection.getRangeAt(0);
            if (currentRange && !currentRange.collapsed) {
              // Get the current CFI from the current selection
              if (typeof actualContents.cfiFromRange === 'function') {
                var currentCfi = actualContents.cfiFromRange(currentRange);
                if (currentCfi) {
                  // Update lastCfiRange with the current CFI
                  lastCfiRange = currentCfi;
                }
              }
            }
          }
        } catch (e) {
          // If we can't get the current CFI, we'll use lastCfiRange as fallback
          // but this might cause issues if it's from a different page
        }

        // Clear existing timeout
        if (selectionTimeout) {
          clearTimeout(selectionTimeout);
        }

        // Set timeout to detect when dragging stops
        selectionTimeout = setTimeout(function () {
          // Selection has stabilized, send the final selection
          // Find the correct contents again in case it changed
          var finalContents = actualContents;
          try {
            var allContents = rendition.getContents();
            for (var i = 0; i < allContents.length; i++) {
              var cont = allContents[i];
              try {
                if (cont.window && cont.window.getSelection) {
                  var sel = cont.window.getSelection();
                  if (sel && sel.rangeCount > 0) {
                    var range = sel.getRangeAt(0);
                    if (range && !range.collapsed) {
                      finalContents = cont;
                      break;
                    }
                  }
                }
              } catch (e) {
                // Ignore errors
              }
            }
          } catch (e) {
            // Use actualContents as fallback
            finalContents = actualContents;
          }

          // Get the current CFI again in case it changed during dragging
          var finalCfi = lastCfiRange;
          try {
            var finalSelection = finalContents.window.getSelection();
            if (finalSelection && finalSelection.rangeCount > 0) {
              var finalRange = finalSelection.getRangeAt(0);
              if (finalRange && !finalRange.collapsed) {
                if (typeof finalContents.cfiFromRange === 'function') {
                  var updatedCfi = finalContents.cfiFromRange(finalRange);
                  if (updatedCfi) {
                    finalCfi = updatedCfi;
                    lastCfiRange = updatedCfi;
                  }
                }
              }
            }
          } catch (e) {
            // Use lastCfiRange as fallback
          }

          if (finalCfi) {
            sendSelectionData(finalCfi, finalContents);
          }
          // Set isSelecting = false, but keep lastCfiRange so hasActiveSelection() still returns true
          // This allows navigation to remain blocked while selection is active
          isSelecting = false;
        }, 300); // 300ms debounce
      } else {
        // Fallback for iPad/iOS: Detect initial selection when epub.js "selected" event doesn't fire
        checkAndProcessSelection(contents);
      }
    });

    // Also listen on window (some browsers fire it there)
    if (contents.window.addEventListener) {
      contents.window.addEventListener('selectionchange', function () {
        var selection = contents.window.getSelection();
        var selectedText = selection.toString();
        if (selectedText && !isSelecting) {
          checkAndProcessSelection(contents);
        }
      });
    }

    // Start polling for this content frame (optimized - stops if no selection found)
    try {
      startPolling(contents);
    } catch (e) {
      // Ignore errors
    }

    // Also try to get all contents and poll them (important for spread layout with 2 pages)
    try {
      var allContents = rendition.getContents();
      allContents.forEach(function (cont, index) {
        var frameId = cont.document ? cont.document.URL : ('frame' + index);
        if (cont.window && !lastPolledSelections.has(frameId)) {
          startPolling(cont);
        }
      });

      // Set up a periodic check to ensure all frames are being polled
      // (in case frames are added/removed dynamically)
      setInterval(function () {
        try {
          var currentContents = rendition.getContents();
          currentContents.forEach(function (cont, index) {
            var frameId = cont.document ? cont.document.URL : ('frame' + index);
            if (cont.window && !lastPolledSelections.has(frameId)) {
              startPolling(cont);
            }
          });
        } catch (e) {
          // Ignore errors in periodic check
        }
      }, 2000); // Check every 2 seconds for new frames
    } catch (e) {
      // Ignore errors
    }

    // Also poll parent window selection (iPad often puts selection there)
    if (!lastPolledSelections.has('parent')) {
      lastPolledSelections.set('parent', null);
      var parentNoSelectionCount = 0;
      var parentInterval = setInterval(function () {
        try {
          if (!window.getSelection) return;
          var parentSelection = window.getSelection();
          var parentText = parentSelection ? parentSelection.toString() : '';
          var currentParentSelection = parentText || null;
          var lastParentSelection = lastPolledSelections.get('parent');

          if (currentParentSelection !== lastParentSelection) {
            lastPolledSelections.set('parent', currentParentSelection);
            parentNoSelectionCount = 0;

            if (parentText && parentSelection.rangeCount > 0) {
              // Try to process with each content frame (important for spread with 2 pages)
              try {
                var allContents = rendition.getContents();
                allContents.forEach(function (cont, index) {
                  if (!isSelecting) {
                    checkAndProcessSelection(cont);
                  }
                });
              } catch (e) {
                // Ignore errors
              }
            } else {
              parentNoSelectionCount++;
            }
          } else if (!currentParentSelection) {
            parentNoSelectionCount++;
          }

          // Stop polling if no selection found for 5 seconds
          if (parentNoSelectionCount > 25) {
            clearInterval(parentInterval);
            lastPolledSelections.delete('parent');
          }
        } catch (e) {
          // Ignore errors
        }
      }, 200);
      pollIntervals.push({ contentsId: 'parent', interval: parentInterval });
    }
  });

  book.loaded.navigation.then(function (toc) {
    chapters = parseChapters(toc)
    window.flutter_inappwebview.callHandler('chapters');
  })

  rendition.on("rendered", function () {
    _installScrollLogging();
    window.flutter_inappwebview.callHandler('rendered');
  })

  // Function to calculate and send selection data
  // Make it globally accessible for native callbacks (needed for iPad support)
  function sendSelectionData(cfiRange, contents) {
    // Find the contents object that actually contains the current selection
    // This is important after navigation - the passed contents might be from a different page
    var actualContents = contents;
    var selection = null;
    var selRange = null;
    var selectedText = '';

    try {
      var allContents = rendition.getContents();
      for (var i = 0; i < allContents.length; i++) {
        var cont = allContents[i];
        try {
          if (cont.window && cont.window.getSelection) {
            var sel = cont.window.getSelection();
            if (sel && sel.rangeCount > 0) {
              var range = sel.getRangeAt(0);
              if (range && !range.collapsed) {
                // This contents has an active selection, use it
                actualContents = cont;
                selection = sel;
                selRange = range;
                // Get text directly from the selection range to avoid calling book.getRange()
                // which can cause navigation if the CFI is from a different page
                selectedText = sel.toString() || range.toString();
                break;
              }
            }
          }
        } catch (e) {
          // Ignore errors, continue checking other contents
        }
      }

      // If we didn't find a selection in any contents, try the passed contents
      if (!selection && contents && contents.window && contents.window.getSelection) {
        selection = contents.window.getSelection();
        if (selection && selection.rangeCount > 0) {
          selRange = selection.getRangeAt(0);
          if (selRange && !selRange.collapsed) {
            selectedText = selection.toString() || selRange.toString();
            actualContents = contents;
          }
        }
      }
    } catch (e) {
      // If we can't find the right contents, use the passed one
      actualContents = contents;
      try {
        if (contents && contents.window && contents.window.getSelection) {
          selection = contents.window.getSelection();
          if (selection && selection.rangeCount > 0) {
            selRange = selection.getRangeAt(0);
            if (selRange && !selRange.collapsed) {
              selectedText = selection.toString() || selRange.toString();
            }
          }
        }
      } catch (e2) {
        // Ignore
      }
    }

    // Convert CFI to XPath (this doesn't cause navigation)
    cfiRangeToXPath(cfiRange.toString()).then(function (selectionXpath) {
      try {
        // Get selection coordinates from the actual contents that has the selection
        var rect = null;

        if (selection && selRange) {
          // Get the range and its client rect (relative to iframe viewport)
          var clientRect = selRange.getBoundingClientRect();

          // Get the WebView dimensions (parent window)
          var webViewWidth = window.innerWidth;
          var webViewHeight = window.innerHeight;

          // Get the iframe element in the parent document
          var iframe = actualContents.document.defaultView.frameElement;
          var iframeRect = iframe.getBoundingClientRect();

          // Calculate absolute position in WebView (iframe offset + selection position)
          var absoluteLeft = iframeRect.left + clientRect.left;
          var absoluteTop = iframeRect.top + clientRect.top;

          // Normalize to 0-1 range relative to WebView dimensions
          rect = {
            left: absoluteLeft / webViewWidth,
            top: absoluteTop / webViewHeight,
            width: clientRect.width / webViewWidth,
            height: clientRect.height / webViewHeight,
            contentHeight: webViewHeight
          };
        }

        var args = [cfiRange.toString(), selectedText, rect, selectionXpath];
        window.flutter_inappwebview.callHandler('selection', ...args);
        hasSentSelection = true; // Mark that we've sent a selection
      } catch (e) {
        // Still send the selection without coordinates if there's an error
        var args = [cfiRange.toString(), selectedText, null, selectionXpath];
        window.flutter_inappwebview.callHandler('selection', ...args);
        hasSentSelection = true; // Mark that we've sent a selection
      }
    }).catch(function (e) {
      // If XPath conversion fails, still send CFI
      try {
        var rect = null;
        if (selection && selRange) {
          var clientRect = selRange.getBoundingClientRect();
          var webViewWidth = window.innerWidth;
          var webViewHeight = window.innerHeight;
          var iframe = actualContents.document.defaultView.frameElement;
          var iframeRect = iframe.getBoundingClientRect();
          var absoluteLeft = iframeRect.left + clientRect.left;
          var absoluteTop = iframeRect.top + clientRect.top;
          rect = {
            left: absoluteLeft / webViewWidth,
            top: absoluteTop / webViewHeight,
            width: clientRect.width / webViewWidth,
            height: clientRect.height / webViewHeight,
            contentHeight: webViewHeight
          };
        }
        var args = [cfiRange.toString(), selectedText, rect, null];
        window.flutter_inappwebview.callHandler('selection', ...args);
        hasSentSelection = true; // Mark that we've sent a selection
      } catch (e2) {
        var args = [cfiRange.toString(), selectedText, null, null];
        window.flutter_inappwebview.callHandler('selection', ...args);
        hasSentSelection = true; // Mark that we've sent a selection
      }
    });
  }

  // Make sendSelectionData globally accessible for iPad native callbacks
  window.sendSelectionData = sendSelectionData;

  ///text selection callback
  rendition.on("selected", function (cfiRange, contents) {
    lastCfiRange = cfiRange;

    if (!isSelecting) {
      // Initial selection - send immediately
      isSelecting = true;
      sendSelectionData(cfiRange, contents);
    }
    // If already selecting, the selectionchange handler will debounce it
  });

  //book location changes callback
  rendition.on("relocated", function (location) {
    // BLOCK navigation if there's an active selection
    // This is a final safeguard - if something bypassed our other blocks, prevent the navigation
    // BUT: Don't block if the user is actively dragging selection handles (isSelecting is true)
    // because that would cause the page to snap back when dragging handles after navigation
    if (hasActiveSelection() && !isSelecting) {
      console.log('Blocked relocated event - selection active, attempting to revert');
      // Try to revert to previous location
      // Store the previous location before blocking
      if (rendition.location && rendition.location.start) {
        try {
          // Get the current location before this navigation
          var currentCfi = rendition.location.start.cfi;
          // If we have a stored previous location, go back to it
          // BUT: Only revert if the current location is different from lastValidLocation
          // and we're not in the middle of a selection operation
          // AND: Don't revert if lastValidLocation is null or undefined (initial state)
          if (window.lastValidLocation &&
            window.lastValidLocation !== currentCfi &&
            !isSelecting &&
            window.lastValidLocation !== null &&
            window.lastValidLocation !== undefined) {
            console.log('Reverting to last valid location:', window.lastValidLocation);
            setTimeout(function () {
              // Double-check that selection is still active and we're not selecting
              if (!hasActiveSelection() || isSelecting) {
                return; // Don't revert if selection was cleared or user is actively selecting
              }
              if (originalDisplay && !hasActiveSelection()) {
                originalDisplay(window.lastValidLocation);
              } else if (rendition.display && !hasActiveSelection()) {
                rendition.display(window.lastValidLocation);
              }
            }, 10);
          }
        } catch (e) {
          console.error('Error reverting location:', e);
        }
      }
      // Don't process the relocation - return early (don't update lastValidLocation)
      return;
    }

    // Only store valid location for potential revert if navigation succeeded
    // (i.e., we didn't block it above)
    if (location && location.start && location.start.cfi) {
      window.lastValidLocation = location.start.cfi;
    }

    // Clear selection when navigating to a new page (if enabled)
    if (clearSelectionOnPageChange && hasSentSelection && (isSelecting || lastCfiRange)) {
      isSelecting = false;
      lastCfiRange = null;
      hasSentSelection = false;
      if (selectionTimeout) {
        clearTimeout(selectionTimeout);
        selectionTimeout = null;
      }

      // Clear the actual browser selection across all iframe contents
      rendition.getContents().forEach(function (contents) {
        try {
          if (contents.window.getSelection) {
            contents.window.getSelection().removeAllRanges();
          }
        } catch (e) {
          // Ignore errors if iframe is not accessible
        }
      });

      // Notify Flutter that selection was cleared
      window.flutter_inappwebview.callHandler('selectionCleared');
    }

    sendRelocated(location);
  });

// Builds and ships the location payload. Split out of the "relocated" handler
// so it can be re-sent once book.locations.generate() finishes: the first
// relocations of a book race that generation and would otherwise report page 0
// forever, since no further relocated event fires until the reader turns a page.
function sendRelocated(location) {
    var percent = location.start.percentage;
    var pages = pageInfoFor(location.start.cfi, location.end && location.end.cfi);

    // Convert CFIs to XPath
    Promise.all([
      cfiToXPath(location.start.cfi),
      cfiToXPath(location.end.cfi)
    ]).then(function (xpaths) {
      var locationData = {
        startCfi: location.start.cfi,
        endCfi: location.end.cfi,
        startXpath: xpaths[0],
        endXpath: xpaths[1],
        // Spine href of the current page — names the file, not the chapter.
        href: location.start.href,
        // The actual chapter, anchor and all. See resolveTocHref.
        tocHref: resolveTocHref(location),
        progress: percent,
        page: pages.page,
        totalPages: pages.totalPages
      }
      var args = [locationData]
      window.flutter_inappwebview.callHandler('relocated', ...args);
    }).catch(function (e) {
      // If XPath conversion fails, still send CFI
      var locationData = {
        startCfi: location.start.cfi,
        endCfi: location.end.cfi,
        startXpath: null,
        endXpath: null,
        href: location.start.href,
        tocHref: resolveTocHref(location),
        progress: percent,
        page: pages.page,
        totalPages: pages.totalPages
      }
      var args = [locationData]
      window.flutter_inappwebview.callHandler('relocated', ...args);
    });
  }

  rendition.on('displayError', function (e) {
    window.flutter_inappwebview.callHandler('displayError');
  })

  rendition.on('markClicked', function (cfiRange) {
    // Only programmatically select if enabled
    if (selectAnnotationRange) {
      // Programmatically select the annotation range to trigger the selection event
      // The selection event will provide the correct rect automatically
      try {
        var allContents = rendition.getContents();
        var contents = null;
        var range = null;

        // Try to get the range from each contents frame
        for (var i = 0; i < allContents.length; i++) {
          try {
            var testContents = allContents[i];
            if (typeof testContents.range === 'function') {
              var testRange = testContents.range(cfiRange);
              if (testRange && testRange.startContainer && testRange.endContainer) {
                if (testContents.document.contains(testRange.startContainer) ||
                  testContents.document.contains(testRange.endContainer)) {
                  contents = testContents;
                  range = testRange;
                  break;
                }
              }
            }
          } catch (e) {
            // Continue to next contents
          }
        }

        // If we didn't find it in contents, fall back to book.getRange()
        if (!range || !contents) {
          book.getRange(cfiRange).then(function (bookRange) {
            var allContents2 = rendition.getContents();
            var contents2 = null;

            if (bookRange && bookRange.startContainer) {
              var rangeDoc = bookRange.startContainer.ownerDocument;
              for (var j = 0; j < allContents2.length; j++) {
                try {
                  if (allContents2[j].document === rangeDoc) {
                    contents2 = allContents2[j];
                    break;
                  }
                } catch (e) {
                  // Continue
                }
              }
            }

            if (!contents2 && allContents2.length > 0) {
              contents2 = allContents2[0];
            }

            if (contents2 && bookRange) {
              selectAnnotationRangeHelper(contents2, bookRange);
            }
          }).catch(function (e) {
            console.error('Error getting range for annotation:', e);
          });
          return;
        }

        // We found the range, select it
        selectAnnotationRangeHelper(contents, range);

      } catch (e) {
        console.error('Error in markClicked handler:', e);
      }
    }

    // Helper function to programmatically select the range
    // This will trigger the selection event with the correct rect
    function selectAnnotationRangeHelper(contents, range) {
      try {
        var selection = contents.window.getSelection();
        if (selection && range) {
          // Clear existing selection
          selection.removeAllRanges();
          // Select the annotation range - this will trigger the selection event
          selection.addRange(range);
        }
      } catch (e) {
        console.error('Error selecting annotation range:', e);
      }
    }
  })

  // Sends the just-generated locations up to Flutter so they can be cached
  // (see ReaderProvider.onLocationsGenerated) and handed back in as
  // savedLocations on the next open of this book, skipping this scan.
  function sendGeneratedLocations() {
    try {
      var json = book.locations.save();
      window.flutter_inappwebview.callHandler('locationsGenerated', json);
    } catch (e) {
      console.error('Error saving/sending locations:', e);
    }
  }

  book.ready.then(function () {
    // Runs once locations exist, however they got there — either loaded from
    // cache below or freshly generated. Was inlined in generate(1600)'s own
    // .then() before; pulled out so both paths can share it.
    function afterLocationsReady() {
      // The page count only exists from here on, and the relocations that got
      // the reader to this point all reported page 0 — re-send the current one
      // now that it can be numbered.
      try {
        if (rendition && rendition.location && rendition.location.start) {
          sendRelocated(rendition.location);
        }
      } catch (e) {
        console.error('Error re-sending location after generate:', e);
      }

      // Handle initial position after locations are generated
      // XPath takes precedence over CFI
      if (initialXPath && !initialXPathProcessed) {
        initialXPathProcessed = true; // Mark as processed to prevent multiple calls
        initialPositionLoading = true; // Mark that we're loading initial position
        // Notify parent app that initial position loading has started
        try {
          window.flutter_inappwebview.callHandler('initialPositionLoading', { type: 'xpath' });
        } catch (e) {
          console.error('Error calling initialPositionLoading callback:', e);
        }
        xpathToCfi(initialXPath).then(function (convertedCfi) {
          if (convertedCfi && !xpathDisplayInProgress) {
            xpathDisplayInProgress = true; // Mark as in progress
            // Wait for the initial display to complete, then navigate to the XPath location
            // Use the displayed promise if available, or wait a bit
            var displayPromise = displayed;
            if (displayPromise && typeof displayPromise.then === 'function') {
              displayPromise.then(function () {
                setTimeout(function () {
                  if (xpathDisplayInProgress) { // Double-check flag
                    try {
                      rendition.display(convertedCfi);
                      xpathDisplayInProgress = false; // Mark as complete
                    } catch (e) {
                      console.error('Error displaying converted CFI:', e);
                      xpathDisplayInProgress = false; // Reset on error
                    }
                  }
                }, 50);
              }).catch(function (e) {
                console.error('Error waiting for initial display:', e);
                // Try anyway after a delay
                setTimeout(function () {
                  if (xpathDisplayInProgress) { // Double-check flag
                    try {
                      rendition.display(convertedCfi);
                      xpathDisplayInProgress = false; // Mark as complete
                    } catch (e2) {
                      console.error('Error displaying converted CFI after delay:', e2);
                      xpathDisplayInProgress = false; // Reset on error
                    }
                  }
                }, 200);
              });
            } else {
              // No promise, just wait a bit
              setTimeout(function () {
                if (xpathDisplayInProgress) { // Double-check flag
                  try {
                    rendition.display(convertedCfi);
                    xpathDisplayInProgress = false; // Mark as complete
                  } catch (e) {
                    console.error('Error displaying converted CFI:', e);
                    xpathDisplayInProgress = false; // Reset on error
                  }
                }
              }, 200);
            }
          } else {
            console.warn('Failed to convert XPath to CFI, falling back to CFI or default');
            if (cfi) {
              rendition.display(cfi);
              // initialPositionLoading flag will be cleared when "displayed" event fires
            } else {
              // No CFI fallback, clear the loading flag immediately
              initialPositionLoading = false;
              window.flutter_inappwebview.callHandler('initialPositionLoaded');
            }
          }
          window.flutter_inappwebview.callHandler('locationLoaded');
        }).catch(function (e) {
          console.error('Error converting XPath to CFI in ready:', e);
          if (cfi) {
            rendition.display(cfi);
            // initialPositionLoading flag will be cleared when "displayed" event fires
          } else {
            // No CFI fallback, clear the loading flag immediately
            initialPositionLoading = false;
            window.flutter_inappwebview.callHandler('initialPositionLoaded');
          }
          window.flutter_inappwebview.callHandler('locationLoaded');
        });
      } else if (cfi) {
        // CFI callback was already fired when we did the initial display above
        // Just ensure locationLoaded is called
        window.flutter_inappwebview.callHandler('locationLoaded');
      } else {
        window.flutter_inappwebview.callHandler('locationLoaded');
      }
    }

    // A cached locations JSON (see the savedLocations param and
    // ReaderProvider.savedLocationsJson) skips the multi-second
    // book.locations.generate() scan below entirely — that scan is what used
    // to leave the page count and progress bar at 0 for the first few seconds
    // of *every* open of the same book, not just the first. Falls back to a
    // fresh generate() if the cached JSON is missing or fails to parse (e.g.
    // it's from an incompatible epub.js version).
    if (savedLocations) {
      try {
        book.locations.load(savedLocations);
        afterLocationsReady();
      } catch (e) {
        console.error('Error loading saved locations, regenerating:', e);
        book.locations.generate(1600).then(function () {
          afterLocationsReady();
          sendGeneratedLocations();
        });
      }
    } else {
      book.locations.generate(1600).then(function () {
        afterLocationsReady();
        sendGeneratedLocations();
      });
    }
  })

  rendition.hooks.content.register((contents) => {
    var doc = contents.document;
    if (!doc) return;

    // Track touch positions to detect horizontal swipes
    var touchStartX = null;
    var touchStartY = null;
    var currentTouchX = null;
    var currentTouchY = null;
    var hasMoved = false; // Track if touch has moved significantly (swipe vs tap)
    var touchStartTime = null; // Track when touch started

    // Helper function to calculate normalized touch coordinates (0-1 range)
    // Uses the same logic as selection coordinate calculation
    function getNormalizedTouchCoordinates(touchEvent) {
      try {
        if (!touchEvent.touches || touchEvent.touches.length === 0) {
          return null;
        }

        var touch = touchEvent.touches[0];
        // Touch coordinates are relative to the iframe viewport (same as selection clientRect)
        var clientX = touch.clientX;
        var clientY = touch.clientY;

        // Get the WebView dimensions (parent window)
        var webViewWidth = window.innerWidth;
        var webViewHeight = window.innerHeight;

        // Get the iframe element in the parent document
        var iframe = contents.document.defaultView.frameElement;
        if (!iframe) {
          // Fallback: use clientX/Y directly if no iframe
          return {
            x: clientX / webViewWidth,
            y: clientY / webViewHeight
          };
        }

        var iframeRect = iframe.getBoundingClientRect();

        // Calculate absolute position in WebView (iframe offset + touch position)
        // Same logic as selection: absoluteLeft = iframeRect.left + clientRect.left
        var absoluteX = iframeRect.left + clientX;
        var absoluteY = iframeRect.top + clientY;

        // Normalize to 0-1 range relative to WebView dimensions
        return {
          x: absoluteX / webViewWidth,
          y: absoluteY / webViewHeight
        };
      } catch (e) {
        console.error('Error calculating touch coordinates:', e);
        return null;
      }
    }

    // Helper function to get normalized coordinates from changedTouches (for touchend)
    // Uses the same logic as selection coordinate calculation
    function getNormalizedTouchCoordinatesFromChanged(touchEvent) {
      try {
        if (!touchEvent.changedTouches || touchEvent.changedTouches.length === 0) {
          return null;
        }

        var touch = touchEvent.changedTouches[0];
        // Touch coordinates are relative to the iframe viewport (same as selection clientRect)
        var clientX = touch.clientX;
        var clientY = touch.clientY;

        // Get the WebView dimensions (parent window)
        var webViewWidth = window.innerWidth;
        var webViewHeight = window.innerHeight;

        // Get the iframe element in the parent document
        var iframe = contents.document.defaultView.frameElement;
        if (!iframe) {
          // Fallback: use clientX/Y directly if no iframe
          return {
            x: clientX / webViewWidth,
            y: clientY / webViewHeight
          };
        }

        var iframeRect = iframe.getBoundingClientRect();

        // Calculate absolute position in WebView (iframe offset + touch position)
        // Same logic as selection: absoluteLeft = iframeRect.left + clientRect.left
        var absoluteX = iframeRect.left + clientX;
        var absoluteY = iframeRect.top + clientY;

        // Normalize to 0-1 range relative to WebView dimensions
        return {
          x: absoluteX / webViewWidth,
          y: absoluteY / webViewHeight
        };
      } catch (e) {
        console.error('Error calculating touch coordinates:', e);
        return null;
      }
    }

    // Helper function to safely call flutter_inappwebview handler
    // On iOS, window.flutter_inappwebview might not be available in iframe context
    // Try parent window as fallback
    function callFlutterHandler(handlerName, ...args) {
      try {
        if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
          window.flutter_inappwebview.callHandler(handlerName, ...args);
          return true;
        }
      } catch (err) {
        // Try parent window as fallback (for iOS iframe context)
        try {
          if (window.parent && window.parent !== window && window.parent.flutter_inappwebview && window.parent.flutter_inappwebview.callHandler) {
            window.parent.flutter_inappwebview.callHandler(handlerName, ...args);
            return true;
          }
        } catch (parentErr) {
          // Ignore parent window errors
        }
      }
      return false;
    }

    // Helper function to get normalized coordinates from parent window perspective (for iOS fallback)
    // When called from parent window event, touch.clientX/Y are already relative to parent window
    function getNormalizedTouchCoordinatesFromParent(touchEvent) {
      try {
        var touch = null;
        if (touchEvent.touches && touchEvent.touches.length > 0) {
          touch = touchEvent.touches[0];
        } else if (touchEvent.changedTouches && touchEvent.changedTouches.length > 0) {
          touch = touchEvent.changedTouches[0];
        }
        if (!touch) return null;

        // Get parent window dimensions
        var parentWindow = window.parent && window.parent !== window ? window.parent : window;
        var webViewWidth = parentWindow.innerWidth;
        var webViewHeight = parentWindow.innerHeight;

        // When called from parent window event listener, touch.clientX/Y are already in parent window coordinates
        // So we can normalize directly
        return {
          x: touch.clientX / webViewWidth,
          y: touch.clientY / webViewHeight
        };
      } catch (e) {
        console.error('Error calculating touch coordinates from parent: ', e);
        return null;
      }
    }

    // Block horizontal swipe gestures when there's a selection
    // This must be done at the document level in capture phase to intercept early
    // Use { passive: false } to allow preventDefault() to work
    var touchStartHandler = function (e) {
      console.log('[TOUCH] doc touchstart, hasActiveSelection=' + hasActiveSelection() + ' useCustomSwipe=' + useCustomSwipe);
      // Fire onTouchDown callback with normalized coordinates FIRST (before any preventDefault)
      var touchCoords = null;
      try {
        var coords = getNormalizedTouchCoordinates(e);
        if (coords) {
          touchCoords = coords;
          // Store tap coordinates for later checking in selectionchange
          lastTapCoords = coords;
          callFlutterHandler('onTouchDown', coords.x, coords.y);
        }
      } catch (err) {
        // Ignore errors in callback
      }

      if (hasActiveSelection()) {
        // Store initial touch position and time to detect if this is a tap or swipe
        if (e.touches && e.touches.length > 0) {
          touchStartX = e.touches[0].clientX;
          touchStartY = e.touches[0].clientY;
          currentTouchX = touchStartX;
          currentTouchY = touchStartY;
          touchStartTime = Date.now();
          hasMoved = false; // Reset movement flag
        }
        // Don't preventDefault yet - wait to see if it's a tap or swipe
      } else {
        // Track for normal swipe detection
        if (e.touches && e.touches.length > 0) {
          touchStartX = e.touches[0].clientX;
          touchStartY = e.touches[0].clientY;
          currentTouchX = touchStartX;
          currentTouchY = touchStartY;
          touchStartTime = Date.now();
          hasMoved = false;
        }
      }
    };

    // Attach to iframe document
    doc.addEventListener('touchstart', touchStartHandler, { capture: true, passive: false });

    // Also attach to parent window as fallback for iOS
    // On iOS, touch events in iframes may not fire, so we also listen on the parent window
    try {
      if (window.parent && window.parent !== window && window.parent.document) {
        // Get iframe element from parent document
        var iframe = contents.document.defaultView.frameElement;
        if (iframe) {
          window.parent.document.addEventListener('touchstart', function (e) {
            // Only handle if touch is within iframe bounds
            try {
              var iframeRect = iframe.getBoundingClientRect();
              var touch = e.touches && e.touches.length > 0 ? e.touches[0] : null;
              if (touch) {
                var touchX = touch.clientX;
                var touchY = touch.clientY;
                // Check if touch is within iframe bounds
                if (touchX >= iframeRect.left && touchX <= iframeRect.right &&
                  touchY >= iframeRect.top && touchY <= iframeRect.bottom) {
                  // Calculate normalized coordinates (touch is already in parent window coordinates)
                  var coords = getNormalizedTouchCoordinatesFromParent(e);
                  if (coords) {
                    lastTapCoords = coords;
                    callFlutterHandler('onTouchDown', coords.x, coords.y);
                  }
                }
              }
            } catch (err) {
              // Ignore errors in event handler
            }
          }, { capture: true, passive: false });
        }
      }
    } catch (err) {
      // Ignore errors when accessing parent window (cross-origin restrictions)
    }

    doc.addEventListener('touchmove', function (e) {
      if (hasActiveSelection()) {
        // Update position
        if (e.touches && e.touches.length > 0 && touchStartX !== null) {
          currentTouchX = e.touches[0].clientX;
          currentTouchY = e.touches[0].clientY;

          var deltaX = Math.abs(currentTouchX - touchStartX);
          var deltaY = Math.abs(currentTouchY - touchStartY);

          // If there's significant movement (more than 10px), it's a swipe - block it
          if (deltaX > 10 || deltaY > 10) {
            hasMoved = true;
            // Block horizontal swipes completely
            if (deltaX > 30 && deltaX > deltaY * 1.5) {
              e.preventDefault();
              e.stopPropagation();
              e.stopImmediatePropagation();
              return false;
            }
            // Also block if it's a significant horizontal movement (even if not strictly horizontal)
            if (deltaX > 50) {
              e.preventDefault();
              e.stopPropagation();
              e.stopImmediatePropagation();
              return false;
            }
          }
        }
      } else {
        // Update current position for normal swipe detection
        if (e.touches && e.touches.length > 0) {
          currentTouchX = e.touches[0].clientX;
          currentTouchY = e.touches[0].clientY;
        }
      }
    }, { capture: true, passive: false }); // Use options object with passive: false

    var touchEndHandler = function (e) {
      // Fire onTouchUp callback with normalized coordinates
      var tapCoords = null;
      try {
        var coords = getNormalizedTouchCoordinatesFromChanged(e);
        if (coords) {
          tapCoords = coords;
          callFlutterHandler('onTouchUp', coords.x, coords.y);
        }
      } catch (err) {
        // Ignore errors in callback
      }

      if (hasActiveSelection()) {
        // Check if this was a tap (no significant movement) or a swipe
        if (touchStartX !== null && currentTouchX !== null && touchStartTime !== null) {
          var deltaX = Math.abs(currentTouchX - touchStartX);
          var deltaY = Math.abs(currentTouchY - touchStartY);
          var touchDuration = Date.now() - touchStartTime;

          // If there was minimal movement (< 10px) and short duration (< 300ms), it's a tap
          if (!hasMoved && deltaX < 10 && deltaY < 10 && touchDuration < 300) {
            // Simple tap - allow normal behavior
          } else if (deltaX > 30 && deltaX > deltaY * 1.5) {
            // It was a horizontal swipe - block it
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
            return false;
          } else if (deltaX > 50) {
            // Significant horizontal movement - block it
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
            return false;
          }
        }
      }
      // Reset tracking
      touchStartX = null;
      touchStartY = null;
      currentTouchX = null;
      currentTouchY = null;
      hasMoved = false;
      touchStartTime = null;
      // Keep lastTapCoords for longer to allow click handler and selectionchange to check it
      // Clear after a longer delay to handle quick taps
      setTimeout(function () {
        lastTapCoords = null;
      }, 500);
    };

    // Attach to iframe document
    doc.addEventListener('touchend', touchEndHandler, { capture: true, passive: false });

    // Also attach to parent window as fallback for iOS
    // On iOS, touch events in iframes may not fire, so we also listen on the parent window
    try {
      if (window.parent && window.parent !== window && window.parent.document) {
        // Get iframe element from parent document (same as touchstart)
        var iframe = contents.document.defaultView.frameElement;
        if (iframe) {
          window.parent.document.addEventListener('touchend', function (e) {
            // Only handle if touch is within iframe bounds
            try {
              var iframeRect = iframe.getBoundingClientRect();
              var touch = e.changedTouches && e.changedTouches.length > 0 ? e.changedTouches[0] : null;
              if (touch) {
                var touchX = touch.clientX;
                var touchY = touch.clientY;
                // Check if touch is within iframe bounds
                if (touchX >= iframeRect.left && touchX <= iframeRect.right &&
                  touchY >= iframeRect.top && touchY <= iframeRect.bottom) {
                  // Calculate normalized coordinates (touch is already in parent window coordinates)
                  var coords = getNormalizedTouchCoordinatesFromParent(e);
                  if (coords) {
                    callFlutterHandler('onTouchUp', coords.x, coords.y);
                  }
                }
              }
            } catch (err) {
              // Ignore errors in event handler
            }
          }, { capture: true, passive: false });
        }
      }
    } catch (err) {
      // Ignore errors when accessing parent window (cross-origin restrictions)
    }

    if (useCustomSwipe) {
      const el = contents.document.documentElement;

      if (el) {
        detectSwipe(el, function (el, direction) {
          // Block swipes if there's an active selection
          if (hasActiveSelection()) {
            console.log('Blocked swipe - selection active, direction:', direction);
            return;
          }

          if (_pageTransition === 'scroll') {
            // Sections here render one screen at a time (no free-scrolling
            // *within* one), so — same as every other transition — moving to
            // the next/previous one is still a discrete swipe, just on the
            // vertical axis a continuous-scroll layout reads naturally on:
            // swipe up advances, swipe down goes back. A left/right swipe
            // reaching here is incidental (a mostly-vertical drag can read as
            // horizontal too) and must NOT also turn a page, or scrolling
            // occasionally double-jumps a section.
            if (direction == 'u') {
              rendition.next();
            } else if (direction == 'd') {
              rendition.prev();
            }
            return;
          }

          if (direction == 'l') {
            rendition.next();
          }
          if (direction == 'r') {
            rendition.prev();
          }
        });
      }
    }

    // Block epub.js built-in click/tap navigation when there's a selection
    // epub.js typically handles clicks on the left/right sides of the page
    try {
      if (doc) {
        // Helper function to check if event is in navigation zone and should be blocked
        function shouldBlockNavigation(e) {
          if (!hasActiveSelection()) {
            return false;
          }

          // Don't block if clicking on links or interactive elements
          var target = e.target;
          if (target && target.tagName &&
            target.tagName.toLowerCase() !== 'a' &&
            target.tagName.toLowerCase() !== 'button' &&
            !target.closest('a') &&
            !target.closest('button')) {
            // Get click/touch position
            var clickX = null;
            if (e.clientX !== undefined) {
              clickX = e.clientX;
            } else if (e.touches && e.touches.length > 0) {
              clickX = e.touches[0].clientX;
            } else if (e.changedTouches && e.changedTouches.length > 0) {
              clickX = e.changedTouches[0].clientX;
            }

            if (clickX !== null) {
              var pageWidth = doc.documentElement.clientWidth || window.innerWidth;
              var leftThird = pageWidth / 3;
              var rightThird = pageWidth * 2 / 3;

              // Block navigation clicks/taps in left/right thirds when selection is active
              if (clickX < leftThird || clickX > rightThird) {
                return true;
              }
            }
          }
          return false;
        }

        // Intercept click events to prevent navigation when selection is active
        doc.addEventListener('click', function (e) {
          // Block navigation clicks if needed
          if (shouldBlockNavigation(e)) {
            e.preventDefault();
            e.stopPropagation();
            return false;
          }
        }, { capture: true, passive: false }); // Use options object with passive: false

        // Also intercept touch events for mobile devices (backup)
        // But only block if it's in navigation zone AND not a simple tap
        doc.addEventListener('touchend', function (e) {
          // Check if this was a simple tap
          var wasSimpleTap = false;
          if (touchStartX !== null && currentTouchX !== null && touchStartTime !== null) {
            var deltaX = Math.abs(currentTouchX - touchStartX);
            var deltaY = Math.abs(currentTouchY - touchStartY);
            var touchDuration = Date.now() - touchStartTime;
            wasSimpleTap = (!hasMoved && deltaX < 10 && deltaY < 10 && touchDuration < 300);
          }

          // Only block navigation if it's NOT a simple tap
          if (!wasSimpleTap && shouldBlockNavigation(e)) {
            e.preventDefault();
            e.stopPropagation();
            return false;
          }
        }, { capture: true, passive: false }); // Use options object with passive: false
      }
    } catch (e) {
      // Ignore errors
    }
  });
  rendition.themes.fontSize(fontSize + "px");
  //set background and foreground color
  updateTheme(backgroundColor, foregroundColor);
}

window.addEventListener("flutterInAppWebViewPlatformReady", function (event) {
  window.flutter_inappwebview.callHandler('readyToLoad');
});

// Global touch event handlers for iOS compatibility
// On iOS, touch events in iframes may not fire, so we also listen on the main document
(function () {
  // Helper function to safely call flutter_inappwebview handler
  function callFlutterHandlerGlobal(handlerName, ...args) {
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler(handlerName, ...args);
        return true;
      } else {
        // Debug: log if flutter_inappwebview is not available
        if (typeof console !== 'undefined' && console.log) {
          console.log('flutter_inappwebview not available when calling:', handlerName);
        }
      }
    } catch (err) {
      if (typeof console !== 'undefined' && console.error) {
        console.error('Error calling flutter handler:', err);
      }
    }
    return false;
  }

  // Helper function to get normalized coordinates from main window
  function getNormalizedCoordinatesFromMainWindow(touchEvent, isTouchEnd) {
    try {
      var touch = null;
      if (isTouchEnd) {
        touch = touchEvent.changedTouches && touchEvent.changedTouches.length > 0 ? touchEvent.changedTouches[0] : null;
      } else {
        touch = touchEvent.touches && touchEvent.touches.length > 0 ? touchEvent.touches[0] : null;
      }
      if (!touch) return null;

      var webViewWidth = window.innerWidth;
      var webViewHeight = window.innerHeight;

      // Get viewer element to check if touch is within bounds
      var viewer = document.getElementById('viewer');
      if (!viewer) {
        // If no viewer element, normalize directly to WebView
        return {
          x: touch.clientX / webViewWidth,
          y: touch.clientY / webViewHeight
        };
      }

      var viewerRect = viewer.getBoundingClientRect();

      // Check if touch is within viewer bounds (with small tolerance for edge cases)
      var touchX = touch.clientX;
      var touchY = touch.clientY;
      var tolerance = 5; // 5px tolerance
      if (touchX < viewerRect.left - tolerance || touchX > viewerRect.right + tolerance ||
        touchY < viewerRect.top - tolerance || touchY > viewerRect.bottom + tolerance) {
        return null; // Touch is outside viewer
      }

      // Clamp coordinates to viewer bounds
      var clampedX = Math.max(viewerRect.left, Math.min(viewerRect.right, touchX));
      var clampedY = Math.max(viewerRect.top, Math.min(viewerRect.bottom, touchY));

      // Calculate position relative to viewer
      var relativeX = clampedX - viewerRect.left;
      var relativeY = clampedY - viewerRect.top;

      // Normalize to 0-1 range relative to viewer dimensions
      // This matches the coordinate system used by the iframe-based handlers
      var normalizedX = relativeX / viewerRect.width;
      var normalizedY = relativeY / viewerRect.height;

      // However, we need to account for the viewer's position in the WebView
      // If the viewer doesn't fill the entire WebView, we need to adjust
      // For now, let's assume the viewer fills most of the WebView and use viewer-relative coordinates
      // But actually, the iframe handlers normalize to WebView, so we should too
      // Let's calculate absolute position in WebView
      var absoluteX = clampedX / webViewWidth;
      var absoluteY = clampedY / webViewHeight;

      return {
        x: absoluteX,
        y: absoluteY
      };
    } catch (e) {
      if (typeof console !== 'undefined' && console.error) {
        console.error('Error calculating coordinates from main window:', e);
      }
      return null;
    }
  }

  // Track if we've already fired touch events to avoid duplicates
  var lastTouchDownTime = 0;
  var lastTouchUpTime = 0;
  var TOUCH_DEBOUNCE_MS = 50; // Prevent duplicate events within 50ms

  // Touch event handler function
  function handleTouchStart(e) {
    try {
      if (typeof console !== 'undefined' && console.log) {
        console.log('TOUCHSTART FIRED on', e.target, 'touches:', e.touches ? e.touches.length : 0);
      }
      var coords = getNormalizedCoordinatesFromMainWindow(e, false);
      if (coords) {
        var now = Date.now();
        // Only fire if enough time has passed since last event (debounce)
        if (now - lastTouchDownTime > TOUCH_DEBOUNCE_MS) {
          lastTouchDownTime = now;
          // Debug log for iOS
          if (typeof console !== 'undefined' && console.log) {
            console.log('Global touchstart - calling onTouchDown:', coords.x, coords.y);
          }
          callFlutterHandlerGlobal('onTouchDown', coords.x, coords.y);
        }
      } else {
        if (typeof console !== 'undefined' && console.log) {
          console.log('Touchstart: coords calculation returned null');
        }
      }
    } catch (err) {
      // Debug log errors
      if (typeof console !== 'undefined' && console.error) {
        console.error('Error in global touchstart handler:', err);
      }
    }
  }

  function handleTouchEnd(e) {
    try {
      if (typeof console !== 'undefined' && console.log) {
        console.log('TOUCHEND FIRED on', e.target, 'changedTouches:', e.changedTouches ? e.changedTouches.length : 0);
      }
      var coords = getNormalizedCoordinatesFromMainWindow(e, true);
      if (coords) {
        var now = Date.now();
        // Only fire if enough time has passed since last event (debounce)
        if (now - lastTouchUpTime > TOUCH_DEBOUNCE_MS) {
          lastTouchUpTime = now;
          // Debug log for iOS
          if (typeof console !== 'undefined' && console.log) {
            console.log('Global touchend - calling onTouchUp:', coords.x, coords.y);
          }
          callFlutterHandlerGlobal('onTouchUp', coords.x, coords.y);
        }
      } else {
        if (typeof console !== 'undefined' && console.log) {
          console.log('Touchend: coords calculation returned null');
        }
      }
    } catch (err) {
      // Debug log errors
      if (typeof console !== 'undefined' && console.error) {
        console.error('Error in global touchend handler:', err);
      }
    }
  }

  // Try multiple attachment points for maximum compatibility
  // 1. Document (capture phase)
  document.addEventListener('touchstart', handleTouchStart, { capture: true, passive: true });
  document.addEventListener('touchend', handleTouchEnd, { capture: true, passive: true });

  // 2. Document (bubble phase)
  document.addEventListener('touchstart', handleTouchStart, { capture: false, passive: true });
  document.addEventListener('touchend', handleTouchEnd, { capture: false, passive: true });

  // 3. Window
  window.addEventListener('touchstart', handleTouchStart, { capture: true, passive: true });
  window.addEventListener('touchend', handleTouchEnd, { capture: true, passive: true });

  // 4. Body element (when available)
  if (document.body) {
    document.body.addEventListener('touchstart', handleTouchStart, { capture: true, passive: true });
    document.body.addEventListener('touchend', handleTouchEnd, { capture: true, passive: true });
  } else {
    // Wait for body to be available
    document.addEventListener('DOMContentLoaded', function () {
      if (document.body) {
        document.body.addEventListener('touchstart', handleTouchStart, { capture: true, passive: true });
        document.body.addEventListener('touchend', handleTouchEnd, { capture: true, passive: true });
      }
    });
  }

  // 5. Also try pointer events as fallback (iOS 13+)
  function handlePointerDown(e) {
    try {
      if (typeof console !== 'undefined' && console.log) {
        console.log('POINTERDOWN FIRED:', e.pointerType, e.clientX, e.clientY);
      }
      if (e.pointerType === 'touch' || e.pointerType === '') {
        var webViewWidth = window.innerWidth;
        var webViewHeight = window.innerHeight;
        var coords = {
          x: e.clientX / webViewWidth,
          y: e.clientY / webViewHeight
        };
        var now = Date.now();
        if (now - lastTouchDownTime > TOUCH_DEBOUNCE_MS) {
          lastTouchDownTime = now;
          if (typeof console !== 'undefined' && console.log) {
            console.log('PointerDown - calling onTouchDown:', coords.x, coords.y);
          }
          callFlutterHandlerGlobal('onTouchDown', coords.x, coords.y);
        }
      }
    } catch (err) {
      if (typeof console !== 'undefined' && console.error) {
        console.error('Error in pointerdown handler:', err);
      }
    }
  }

  function handlePointerUp(e) {
    try {
      if (typeof console !== 'undefined' && console.log) {
        console.log('POINTERUP FIRED:', e.pointerType, e.clientX, e.clientY);
      }
      if (e.pointerType === 'touch' || e.pointerType === '') {
        var webViewWidth = window.innerWidth;
        var webViewHeight = window.innerHeight;
        var coords = {
          x: e.clientX / webViewWidth,
          y: e.clientY / webViewHeight
        };
        var now = Date.now();
        if (now - lastTouchUpTime > TOUCH_DEBOUNCE_MS) {
          lastTouchUpTime = now;
          if (typeof console !== 'undefined' && console.log) {
            console.log('PointerUp - calling onTouchUp:', coords.x, coords.y);
          }
          callFlutterHandlerGlobal('onTouchUp', coords.x, coords.y);
        }
      }
    } catch (err) {
      if (typeof console !== 'undefined' && console.error) {
        console.error('Error in pointerup handler:', err);
      }
    }
  }

  document.addEventListener('pointerdown', handlePointerDown, { capture: true, passive: true });
  document.addEventListener('pointerup', handlePointerUp, { capture: true, passive: true });
  window.addEventListener('pointerdown', handlePointerDown, { capture: true, passive: true });
  window.addEventListener('pointerup', handlePointerUp, { capture: true, passive: true });

  // Debug: Log that listeners are attached
  if (typeof console !== 'undefined' && console.log) {
    console.log('Global touch/pointer event listeners attached');
    console.log('window.flutter_inappwebview available:', !!(window.flutter_inappwebview && window.flutter_inappwebview.callHandler));
  }
})();

// Helper function to check if there's an active text selection (global version)
function hasActiveSelection() {
  // Check our tracking variables first
  if (isSelecting || lastCfiRange) {
    return true;
  }

  // Also check actual DOM selection across all content frames
  try {
    if (typeof rendition !== 'undefined' && rendition) {
      var allContents = rendition.getContents();
      for (var i = 0; i < allContents.length; i++) {
        try {
          var contents = allContents[i];
          if (contents.window && contents.window.getSelection) {
            var selection = contents.window.getSelection();
            if (selection && selection.rangeCount > 0) {
              var range = selection.getRangeAt(0);
              var selectedText = selection.toString();
              if (selectedText && range && !range.collapsed) {
                return true;
              }
            }
          }
        } catch (e) {
          // Ignore errors for this content frame
        }
      }

      // Also check parent window selection
      if (window.getSelection) {
        var parentSelection = window.getSelection();
        if (parentSelection && parentSelection.rangeCount > 0) {
          var parentRange = parentSelection.getRangeAt(0);
          var parentText = parentSelection.toString();
          if (parentText && parentRange && !parentRange.collapsed) {
            return true;
          }
        }
      }
    }
  } catch (e) {
    // Ignore errors
  }

  return false;
}

// Store original rendition methods to override them
var originalNext = null;
var originalPrev = null;
var originalDisplay = null;

// Override rendition methods to block when selection exists
function setupRenditionBlocking() {
  if (typeof rendition !== 'undefined' && rendition && !originalNext) {
    // Store original methods
    originalNext = rendition.next.bind(rendition);
    originalPrev = rendition.prev.bind(rendition);
    originalDisplay = rendition.display.bind(rendition);

    // Override next()
    rendition.next = function () {
      if (hasActiveSelection()) {
        console.log('Blocked next() - selection active');
        return Promise.resolve(rendition.location);
      }
      return originalNext();
    };

    // Override prev()
    rendition.prev = function () {
      if (hasActiveSelection()) {
        console.log('Blocked prev() - selection active');
        return Promise.resolve(rendition.location);
      }
      return originalPrev();
    };

    // Override display() - this is what actually changes the page
    rendition.display = function (cfi) {
      if (hasActiveSelection()) {
        console.log('Blocked display() - selection active, cfi:', cfi);
        return Promise.resolve(rendition.location);
      }
      return originalDisplay(cfi);
    };
  }
}

//move to next page
// ── Page-change animations (TZ §12.2) ────────────────────────────────────
// epub.js has no transition API of its own — `flow` only chooses paginated
// vs scrolled — so the styles are animated here, on the #viewer element that
// epub.js renders into. The page swap itself is still epub.js's; we just play
// an "out" tween, let it commit, then play an "in" tween.
// slide | curl | overlay | scroll | shift | none. 'scroll' (Prokrutka) is the
// default here to match ReaderProvider's, which is what a reader who has never
// touched the setting gets — the two have to agree, or the first turns of a
// freshly-opened book animate as 'slide' until Flutter pushes the real mode
// through setPageTransition on the 'displayed' event.
var _pageTransition = 'scroll';
var _turnAnimating = false;

function setPageTransition(mode) {
  _pageTransition = mode || 'scroll';
}

// dir: 1 = forward, -1 = backward.
// Every spec may carry `outOrigin`/`inOrigin` (transform-origin for each half
// of the turn) and `shadow` (a box-shadow played while the page is in flight).
// Both default to "nothing special" in _animatedTurn, so only the modes that
// need a hinge or a lift have to name them.
function _transitionSpec(mode, dir) {
  var ease = 'cubic-bezier(0.4, 0.0, 0.2, 1)';
  switch (mode) {
    // Сдвиг — the page shifts right off to one side.
    case 'shift':
      return { out: 'translateX(' + (-100 * dir) + '%)', outOpacity: 1,
               inFrom: 'translateX(' + (100 * dir) + '%)', inOpacity: 1,
               outMs: 190, inMs: 210, ease: ease };
    // Наложение — the new page rises over the old one.
    case 'overlay':
      return { out: 'scale(0.97)', outOpacity: 0,
               inFrom: 'scale(1.04)', inOpacity: 0,
               outMs: 140, inMs: 210, ease: ease };
    // Снятие — a true page curl needs canvas/WebGL. This used to fake it with
    // perspective()+rotateY(), a 3-D transform — but #viewer holds epub.js's
    // iframe, and asking mobile WebViews to composite a 3-D-rotated iframe
    // means rasterizing its whole content into a texture every turn, which is
    // exactly the kind of work that reads as the reader "freezing" on a
    // mid-range phone (reported in release builds too, so not a debug-mode
    // slowdown). scale()+skewY() reads as a similar peel/lift but is a plain
    // 2-D transform — cheap for any WebView to composite.
    case 'curl':
      return { out: 'scale(0.92) skewY(' + (-5 * dir) + 'deg) translateX(' + (-55 * dir) + '%)', outOpacity: 0,
               inFrom: 'scale(0.95) skewY(' + (3 * dir) + 'deg) translateX(' + (28 * dir) + '%)', inOpacity: 0.15,
               outMs: 200, inMs: 220, ease: ease };
    // Прокрутка — the only *vertical* mode. Going forward the new page rises up
    // from the bottom edge into place (never sideways) while the old one lifts
    // slightly and fades out the top; going back it mirrors, so the page you
    // are returning to comes back down from the top. The swipe that drives it
    // is vertical too (see the detectSwipe callback), with a slower entrance
    // than exit so the travel itself is what reads on screen.
    //
    // Both offsets are multiplied by `dir` for that mirroring — exactly as the
    // horizontal modes above do. They used to be hardcoded to the forward pose,
    // which meant a backwards turn still played "new page arrives from the
    // bottom": the page changed correctly but appeared to travel the wrong way.
    case 'scroll':
      return { out: 'translateY(' + (-10 * dir) + '%)', outOpacity: 0,
               inFrom: 'translateY(' + (72 * dir) + '%)', inOpacity: 0,
               outMs: 150, inMs: 280, ease: ease };
    // Листание — the plain horizontal page slide every reader does: the page
    // travels the full width sideways, so it leaves and arrives edge-to-edge
    // rather than fading in place. No squeeze, skew or fade — an earlier fold
    // effect here read as the page distorting, not sliding. The soft shadow is
    // the only ornament: it gives the travelling page an edge to read against
    // the one behind it. ('shift' is the same motion without the shadow and a
    // touch snappier — the two are deliberately close.)
    case 'slide':
    default:
      return { out: 'translateX(' + (-100 * dir) + '%)', outOpacity: 1,
               inFrom: 'translateX(' + (100 * dir) + '%)', inOpacity: 1,
               shadow: '0 0 26px rgba(0,0,0,0.38)',
               outMs: 200, inMs: 230, ease: ease };
  }
}

function _animatedTurn(dir, commit) {
  var el = document.getElementById('viewer');
  // 'none' is meant to be instant. Bailing while one tween is in flight keeps
  // fast swipes from stacking. ('scroll' used to bail here too, back when it
  // ran on epub.js's continuous scrolled flow; it's now a vertical *paginated*
  // mode with its own bottom-to-top tween — see _transitionSpec's 'scroll'
  // case — so it animates like every other paginated turn.)
  if (!el || !_pageTransition || _pageTransition === 'none' || _turnAnimating) {
    return commit();
  }

  var s = _transitionSpec(_pageTransition, dir);
  _turnAnimating = true;

  var released = false;
  // The "out" tween leaves the viewer transparent and pushed off to one side,
  // so *every* exit from here has to put it back — if one doesn't, the reader is
  // left staring at a blank page with no way to recover, because _turnAnimating
  // also stays stuck and sends every later turn down the un-animated path.
  //
  // That is not hypothetical: the restore used to hang off commit()'s promise,
  // and rendition.prev() does not always settle — epub.js queues the turn behind
  // loading the previous section, and a queue that stalls never rejects either,
  // so neither .then nor .catch would run. Hence a watchdog rather than trust.
  var release = function () {
    if (released) return;
    released = true;
    clearTimeout(watchdog);
    el.style.transition = '';
    el.style.transform = '';
    el.style.opacity = '';
    el.style.willChange = '';
    el.style.transformOrigin = '';
    el.style.boxShadow = '';
    _turnAnimating = false;
  };

  // Long enough that it never pre-empts a page turn that is merely slow, short
  // enough that a stalled one doesn't read as a broken app.
  var watchdog = setTimeout(function () {
    console.log('page transition watchdog fired — restoring viewer');
    release();
  }, s.outMs + s.inMs + 2000);

  el.style.willChange = 'transform, opacity';
  el.style.transformOrigin = s.outOrigin || 'center center';
  if (s.shadow) el.style.boxShadow = s.shadow;
  el.style.transition = 'transform ' + s.outMs + 'ms ' + s.ease + ', opacity ' + s.outMs + 'ms ' + s.ease;
  el.style.transform = s.out;
  el.style.opacity = s.outOpacity;

  setTimeout(function () {
    var proceeded = false;
    // Play the "in" tween: snap to the incoming pose with no transition, then
    // let it settle back to rest. Guarded so the promise and the fallback
    // timer below can't both run it.
    var proceed = function () {
      if (proceeded || released) return;
      proceeded = true;
      el.style.transition = 'none';
      // The arriving half hinges on the opposite edge, so the origin flips
      // between the two tweens — set it in the same un-transitioned frame as
      // the incoming pose, or the switch itself animates and the fold jumps.
      el.style.transformOrigin = s.inOrigin || s.outOrigin || 'center center';
      el.style.transform = s.inFrom;
      el.style.opacity = s.inOpacity;
      requestAnimationFrame(function () {
        requestAnimationFrame(function () {
          if (released) return;
          el.style.transition = 'transform ' + s.inMs + 'ms ' + s.ease + ', opacity ' + s.inMs + 'ms ' + s.ease +
                                (s.shadow ? ', box-shadow ' + s.inMs + 'ms ' + s.ease : '');
          el.style.transform = 'none';
          el.style.opacity = 1;
          // Fade the fold's shadow out with the motion; release() clears it
          // outright, which would otherwise pop once the page is already flat.
          if (s.shadow) el.style.boxShadow = 'none';
          setTimeout(release, s.inMs + 20);
        });
      });
    };

    // Ask epub.js to actually turn the page, then animate the new one in as
    // soon as EITHER that settles OR a short fallback elapses — whichever comes
    // first. On Android rendition.next()/prev() resolves quickly, so the tween
    // stays perfectly in step with the real turn. On iOS (WKWebView) that
    // promise frequently never settles, which used to leave the viewer pushed
    // off-screen until the 2s watchdog fired — the visible lag. The new page
    // has been requested and renders within a frame or two regardless, so the
    // fallback drives the "in" tween without waiting on a promise that won't come.
    Promise.resolve().then(commit).then(proceed).catch(function (e) {
      console.log('page transition commit failed: ' + e);
      proceed();
    });
    setTimeout(proceed, 120);
  }, s.outMs);
}

// Wrapping rendition.next/prev rather than each caller means swipes, the
// arrow buttons and Flutter-driven turns all animate from one place.
function _installPageTransitions(r) {
  if (!r || r.__transitionsInstalled) return;
  var origNext = r.next.bind(r);
  var origPrev = r.prev.bind(r);
  // Every page turn — a swipe (Android's custom detectSwipe, or the browser's
  // own gesture handling elsewhere) and epub.js's own paginated-mode swipe
  // alike — reaches the reader through exactly one of these two calls, since
  // nothing else in this file calls rendition.next()/prev(). One log here is a
  // log of every real page turn, without duplicating it at each gesture source.
  r.next = function () { console.log('👉 SWIPE: next page (mode=' + _pageTransition + ')'); _lastNavDirection = 1; return _animatedTurn(1, origNext); };
  r.prev = function () { console.log('👈 SWIPE: previous page (mode=' + _pageTransition + ')'); _lastNavDirection = -1; return _animatedTurn(-1, origPrev); };
  r.__transitionsInstalled = true;
}

// ── Scroll logging ────────────────────────────────────────────────────────
// In scroll/manga mode (EpubFlow.scrolled) reading moves by the browser's own
// native scroll, not by next()/prev() — so it needs a separate hook. sakura_epub
// only ever uses the 'continuous' manager (see EpubManager), which keeps one
// scroller for the whole session regardless of flow, so this only needs to
// attach once; it's called from 'rendered', which fires often, hence the flag.
var _scrollLoggingAttached = false;
function _installScrollLogging() {
  try {
    if (_scrollLoggingAttached) return;
    var scroller = rendition && rendition.manager && rendition.manager.scroller;
    if (!scroller || !scroller.addEventListener) return;
    _scrollLoggingAttached = true;
    var lastLog = 0;
    scroller.addEventListener('scroll', function () {
      // One continuous drag fires dozens of scroll events; log the gesture,
      // not every pixel of it.
      var now = Date.now();
      if (now - lastLog < 400) return;
      lastLog = now;
      console.log('📜 SCROLL (mode=' + _pageTransition + ')');
    }, { passive: true });
  } catch (e) {
    console.error('Error installing scroll logging:', e);
  }
}

function next() {
  // Block navigation if there's an active selection
  if (hasActiveSelection()) {
    console.log('Blocked next() - selection active');
    return;
  }
  if (rendition) {
    rendition.next();
  }
}

//move to previous page
function previous() {
  // Block navigation if there's an active selection
  if (hasActiveSelection()) {
    console.log('Blocked previous() - selection active');
    return;
  }
  if (rendition) {
    rendition.prev();
  }
}

//move to given cfi location or xpath
function toCfi(cfiOrXPath) {
  // Check if it looks like an XPath (starts with /)
  if (cfiOrXPath && cfiOrXPath.startsWith('/')) {
    xpathToCfi(cfiOrXPath).then(function (convertedCfi) {
      if (convertedCfi) {
        rendition.display(convertedCfi);
      } else {
        console.error('Failed to convert XPath to CFI:', cfiOrXPath);
      }
    }).catch(function (e) {
      console.error('Error converting XPath to CFI:', e);
    });
  } else {
    // Treat as CFI
    rendition.display(cfiOrXPath);
  }
}

//get all chapters
function getChapters() {
  return chapters;
}

async function getBookInfo() {
  const metadata = book.package.metadata;
  metadata['coverImage'] = book.cover;
  return metadata;
}

function getCurrentLocation(requestId) {
  var percent = rendition.location.start.percentage;
  percent = parseFloat(percent);

  // Convert CFIs to XPath
  return Promise.all([
    cfiToXPath(rendition.location.start.cfi),
    cfiToXPath(rendition.location.end.cfi)
  ]).then(function (xpaths) {
    const args = {
      startCfi: rendition.location.start.cfi,
      endCfi: rendition.location.end.cfi,
      startXpath: xpaths[0],
      endXpath: xpaths[1],
      progress: percent
    };
    window.flutter_inappwebview.callHandler("currentLocation", {
      requestId: requestId,
      location: args
    });
  }).catch(function (e) {
    // If XPath conversion fails, still return CFI
    const args = {
      startCfi: rendition.location.start.cfi,
      endCfi: rendition.location.end.cfi,
      startXpath: null,
      endXpath: null,
      progress: percent
    };
    window.flutter_inappwebview.callHandler("currentLocation", {
      requestId: requestId,
      location: args
    });
  });
}

// ── Page numbers ─────────────────────────────────────────────────────────
// epub.js has no notion of a page: reflowable text has no fixed pagination, so
// the only stable unit it offers is a "location" — a fixed-length slice of the
// book's text produced by book.locations.generate(N). We number *screens*
// rather than raw locations: one on-screen page holds several locations, so
// numbering locations directly makes the counter jump by 3–5 on every swipe.
//
// The number of locations a screen holds is measured live from the start→end
// span of the current view (font-adaptive: a bigger font fits fewer locations
// per screen, giving more, shorter pages) and smoothed with an EMA so the
// derived total doesn't wobble as slightly different amounts of text land on
// each screen. Dividing the location index/length by that gives a page that
// advances by ~1 per swipe and a total that reads like a real page count.
//
// locations.generate() is async (see book.ready below) and takes a while on a
// long book, so both values are 0 until it finishes — callers must treat 0 as
// "not counted yet" rather than as page zero.
function pageInfoFor(startCfi, endCfi) {
  var info = { page: 0, totalPages: 0 };
  try {
    if (!book.locations || !book.locations.length()) return info;
    var totalLocations = book.locations.length();

    // locationFromCfi is 0-based.
    var startIdx = book.locations.locationFromCfi(startCfi);
    if (typeof startIdx !== 'number' || startIdx < 0) startIdx = 0;
    var endIdx = endCfi ? book.locations.locationFromCfi(endCfi) : startIdx;
    if (typeof endIdx !== 'number' || endIdx < startIdx) endIdx = startIdx;

    // Locations visible on this one screen (at least 1). endIdx is inclusive.
    var locationsThisPage = (endIdx - startIdx) + 1;
    if (locationsThisPage < 1) locationsThisPage = 1;

    // Warm-up: average the location-span of the first few genuine text screens,
    // then freeze that average as the divisor (see _perPageFrozen). Image-only
    // screens (covers, front-matter illustrations) carry no text, so epub.js
    // collapses them onto the same location marker as their neighbours —
    // reporting a span of 1, same as a real single-location text page would.
    // Sampling those would skew the divisor, so only multi-location (text)
    // screens are folded in.
    if (_perPageFrozen === 0 && locationsThisPage > 1) {
      _perPageSum += locationsThisPage;
      _perPageSamples += 1;
      if (_perPageSamples >= _perPageFreezeAfter) {
        _perPageFrozen = _perPageSum / _perPageSamples;
      }
    }

    // The divisor: the frozen value once we have it; otherwise the running
    // average so far; otherwise 1 until the first text screen is measured.
    var perPage = _perPageFrozen > 0
      ? _perPageFrozen
      : (_perPageSamples > 0 ? _perPageSum / _perPageSamples : 1);

    info.totalPages = Math.max(1, Math.round(totalLocations / perPage));
    // +1 so readers count from 1.
    info.page = Math.floor(startIdx / perPage) + 1;

    // Image-only screens collapse onto one location marker, so a run of them
    // all resolve to the same startIdx — the math above would then report the
    // same page for several real swipes in a row. A genuine next()/prev() (as
    // opposed to a jump — goToChapter, search, restoring position, all of
    // which go through rendition.display() instead) always moves exactly one
    // page, so enforce that when the location math didn't agree with the
    // direction the reader actually swiped.
    if (_lastNavDirection === 1 && info.page <= _lastComputedPage) {
      info.page = _lastComputedPage + 1;
    } else if (_lastNavDirection === -1 && info.page >= _lastComputedPage && _lastComputedPage > 1) {
      info.page = _lastComputedPage - 1;
    }
    // Clamp the page to the (now-frozen) total rather than growing the total to
    // fit the page — the whole point is that the total stays put. At the very
    // end of the book this means the last couple of image screens read as
    // "N / N" instead of nudging the total upward.
    if (info.page > info.totalPages) info.page = info.totalPages;
    info.page = Math.max(1, info.page);

    _lastComputedPage = info.page;
    _lastNavDirection = 0;
  } catch (e) {
    console.error('Error computing page info:', e);
  }
  return info;
}

// TOC and spine hrefs disagree on anchors, query strings and directory
// prefixes (`OEBPS/text/ch1.xhtml` vs `ch1.xhtml`), so files are compared on
// the bare name.
function hrefFileName(href) {
  var h = (href || '').split('#')[0].split('?')[0];
  var slash = h.lastIndexOf('/');
  return slash === -1 ? h : h.substring(slash + 1);
}

// Every anchored TOC entry living in the spine file [file], flattened out of
// the TOC tree. Entries without an anchor are skipped: they refer to the file
// as a whole and are what resolveTocHref falls back to.
function anchoredTocEntriesIn(file) {
  var out = [];
  var target = hrefFileName(file);
  (function walk(list) {
    if (!list) return;
    list.forEach(function (item) {
      var href = item.href || '';
      var anchor = href.split('#')[1];
      if (anchor && hrefFileName(href) === target) {
        out.push({ href: href, anchor: anchor });
      }
      walk(item.subitems);
    });
  })(book.navigation && book.navigation.toc);
  return out;
}

// One spine file routinely holds many chapters — Calibre splits a book into
// index_split_NNN.xhtml and separates the chapters inside each file with
// #anchors. epub.js reports only the file in location.start.href, so from the
// outside every chapter in that file looks identical and the reader appears to
// be stuck on the first one.
//
// Find the anchored TOC entry nearest at-or-before the current position and
// report that instead. Uses the already-rendered document, so nothing is
// loaded or parsed here.
function cfiToRangeIn(cfiString, doc) {
  try {
    return new ePub.CFI(cfiString).toRange(doc);
  } catch (e) {
    return null;
  }
}

function resolveTocHref(location) {
  var fallback = location.start.href;
  try {
    var entries = anchoredTocEntriesIn(fallback);
    if (!entries.length) return fallback;

    var all = rendition.getContents();
    var contents = all.filter(function (c) {
      return c.sectionIndex === location.start.index;
    })[0] || all[0];
    var doc = contents && contents.document;
    if (!doc) return fallback;

    // Measured from the END of the visible page, not its start.
    //
    // rendition.display('file.xhtml#anchor') pages to the column that
    // *contains* the anchor; it does not begin the page at it. So the page
    // opens on the tail of the previous chapter with the requested heading
    // part-way down it. Measuring from location.start therefore answers with
    // the previous chapter — tap "Глава 5", get "Глава 4". The last heading
    // appearing anywhere on the page is the one the reader has arrived at.
    var marker = null;
    if (location.end && location.end.cfi && location.end.index === location.start.index) {
      var endRange = cfiToRangeIn(location.end.cfi, doc);
      if (endRange) marker = endRange.endContainer;
    }
    if (!marker) {
      var startRange = cfiToRangeIn(location.start.cfi, doc);
      if (!startRange) return fallback;
      marker = startRange.startContainer;
    }

    // Node.DOCUMENT_POSITION_* bits, spelled out rather than read off Node
    // because these nodes belong to the rendered iframe's document.
    var FOLLOWING = 4;
    var CONTAINED_BY = 16;

    // Nearest preceding-or-equal entry wins. Compared pairwise by document
    // position rather than trusting the TOC to be in document order.
    var best = null, bestEl = null;
    for (var i = 0; i < entries.length; i++) {
      var el = doc.getElementById(entries[i].anchor);
      if (!el) continue;

      // el is at-or-before the marker when the marker IS el, follows it, or
      // sits inside it (the page ends within the heading itself).
      var pos = el.compareDocumentPosition(marker);
      if (!(marker === el || (pos & FOLLOWING) || (pos & CONTAINED_BY))) continue;

      if (!bestEl || (bestEl.compareDocumentPosition(el) & FOLLOWING)) {
        best = entries[i].href;
        bestEl = el;
      }
    }
    // No anchor on or before this page means we're in the file's lead-in,
    // above its first anchored chapter — the file-level entry is the honest
    // answer.
    return best || fallback;
  } catch (e) {
    return fallback;
  }
}

///parsing chapters and subitems recursively
var parseChapters = function (toc) {
  var chapters = []
  toc.forEach(function (chapter) {
    chapters.push({
      // NCX <text> nodes carry the source file's own line breaks and
      // indentation, so labels arrive as "\n        Глава 2\n      ".
      // Normalise here rather than leaving every consumer to trim.
      title: (chapter.label || '').replace(/\s+/g, ' ').trim(),
      href: chapter.href,
      id: chapter.id,
      subitems: parseChapters(chapter.subitems)
    })
  })
  return chapters;
}

// The Dart side parks a Completer on every call, so this must post exactly one
// 'search' message for `requestId` on every path — including failure, or the
// caller waits forever.
function searchInBook(query, requestId, includeXPath) {
  function send(results) {
    window.flutter_inappwebview.callHandler('search', {
      requestId: requestId,
      results: results
    });
  }

  search(query).then(function (data) {
    if (!includeXPath) return send(data);

    // XPath conversion reloads each hit's spine item, so it runs one at a time
    // and only when the caller asked for it.
    var withXPath = [];
    return data.reduce(function (chain, result) {
      return chain.then(function () {
        return cfiToXPath(result.cfi).catch(function () { return null; });
      }).then(function (xpath) {
        withXPath.push({
          cfi: result.cfi,
          excerpt: result.excerpt,
          href: result.href,
          xpath: xpath
        });
      });
    }, Promise.resolve()).then(function () {
      send(withXPath);
    }).catch(function () {
      send(data);
    });
  }).catch(function (e) {
    send([]);
  });
}


// Re-measures every annotation overlay and re-lays the marks drawn on it.
//
// marks-pane draws a highlight at (rangeRect - paneOrigin), where paneOrigin is
// whatever Pane.render() measured last. Pane.render() runs on construction and
// on epub.js's resize — but Pane.addMark() deliberately does NOT re-run it, so
// any layout change since the pane was built leaves that origin stale and every
// mark added afterwards lands offset from its own text, typically by a couple of
// paragraphs. The everyday trigger is adding a note: the note sheet's keyboard
// resizes the WebView and reflows the page while the sheet is open, and the
// highlight is only painted once it closes.
function _refreshAnnotationPanes() {
  // Two frames, so the measurement happens after the layout that follows the
  // mark being inserted has actually been committed.
  requestAnimationFrame(function () {
    requestAnimationFrame(function () {
      try {
        rendition.views().forEach(function (view) {
          if (view && view.pane) view.pane.render();
        });
      } catch (e) {
        console.error('Error refreshing annotation panes:', e);
      }
    });
  });
}

// adds highlight with given color
function addHighlight(cfiRange, color, opacity) {
  rendition.annotations.highlight(cfiRange, {}, (e) => {
    // Highlight clicked handler (can be extended if needed)
  }, "hl", { "fill": color, "fill-opacity": '0.3', "mix-blend-mode": "multiply" });
  _refreshAnnotationPanes();
}

function addUnderLine(cfiString) {
  rendition.annotations.underline(cfiString)
  _refreshAnnotationPanes();
}

function addMark(cfiString) {
  rendition.annotations.mark(cfiString)
  _refreshAnnotationPanes();
}

function removeHighlight(cfiString) {
  rendition.annotations.remove(cfiString, "highlight");
}

function removeUnderLine(cfiString) {
  rendition.annotations.remove(cfiString, "underline");
}

function removeMark(cfiString) {
  rendition.annotations.remove(cfiString, "mark");
}

function clearSelection() {
  try {
    if (typeof rendition !== 'undefined' && rendition) {
      // Clear selection in all content frames (iframes)
      rendition.getContents().forEach(function (contents) {
        try {
          if (contents.window.getSelection) {
            contents.window.getSelection().removeAllRanges();
          }
        } catch (e) {
          // Ignore errors if iframe is not accessible
        }
      });

      // Also clear selection in parent window as fallback
      if (window.getSelection) {
        window.getSelection().removeAllRanges();
      }

      // Notify Flutter that selection was cleared - only if we've actually sent a selection
      if (hasSentSelection && (isSelecting || lastCfiRange) && window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        isSelecting = false;
        lastCfiRange = null;
        hasSentSelection = false;
        if (selectionTimeout) {
          clearTimeout(selectionTimeout);
          selectionTimeout = null;
        }
        window.flutter_inappwebview.callHandler('selectionCleared');
      }
    } else {
      // Fallback if rendition is not available
      if (window.getSelection) {
        window.getSelection().removeAllRanges();
      }
    }
  } catch (e) {
    console.error('Error clearing selection:', e);
  }
}

// Explicitly attach to window for global access
window.clearSelection = clearSelection;

function toProgress(progress) {
  // book.locations.generate() is async and may not have finished yet (large
  // books can take longer than callers are willing to wait) — cfiFromPercentage
  // would throw on an empty location list and silently kill the navigation.
  if (!book.locations || !book.locations.length()) return;
  var cfi = book.locations.cfiFromPercentage(progress);
  rendition.display(cfi);
}


// A hit cap and batch size for search(). epub.js's stock implementation maps
// over the whole spine inside one Promise.all, so every chapter of the book is
// parsed into a live document at the same moment — on a large epub that alone
// is enough to OOM the WebView renderer, which takes the host app down with it.
var SEARCH_MAX_RESULTS = 200;
var SEARCH_BATCH_SIZE = 4;

// Walks the spine in small batches, unloading each item as soon as it has been
// scanned, and stops early once SEARCH_MAX_RESULTS hits are collected. Peak
// memory stays proportional to SEARCH_BATCH_SIZE instead of the book's length.
// A chapter that fails to load contributes no hits rather than rejecting the
// whole search.
function search(q) {
  var items = book.spine.spineItems.slice();
  var out = [];
  var next = 0;

  function scan(item) {
    return Promise.resolve()
      .then(function () { return item.load(book.load.bind(book)); })
      .then(function () {
        // Section.search walks the document with a TreeWalker over runs of text
        // nodes, so it still matches a phrase broken up by inline markup
        // (<em>, <b>, a stray <span>) and centres the excerpt on the hit.
        // Section.find only ever looks at one text node at a time and misses
        // those. Fall back to it if this epub.js build lacks search.
        return typeof item.search === 'function' ? item.search(q) : item.find(q);
      })
      .catch(function () { return []; })
      .then(function (hits) {
        try { item.unload(); } catch (e) { /* never loaded */ }
        // Tag each hit with the chapter it came from so the caller can group
        // results; href survives the unload above.
        return (hits || []).map(function (h) {
          return { cfi: h.cfi, excerpt: h.excerpt, href: item.href };
        });
      });
  }

  function nextBatch() {
    if (next >= items.length || out.length >= SEARCH_MAX_RESULTS) {
      return Promise.resolve(out.slice(0, SEARCH_MAX_RESULTS));
    }
    var batch = items.slice(next, next + SEARCH_BATCH_SIZE);
    next += batch.length;
    return Promise.all(batch.map(scan)).then(function (results) {
      out = out.concat.apply(out, results);
      return nextBatch();
    });
  }

  return nextBatch();
};

function setSpread(spread) {
  rendition.spread(spread);
}

function setFlow(flow) {
  // Paginated vs. scrolled is a wholesale layout change — re-measure the page
  // divisor for it.
  _resetPageMetrics();
  rendition.flow(flow);
}

function setManager(manager) {
  rendition.manager(manager);
}

function setFontSize(fontSize) {
  // Bigger/smaller text repaginates the book, so the frozen page-count divisor
  // no longer holds — clear it before reportLocation triggers a fresh measure.
  _resetPageMetrics();
  rendition.themes.fontSize(`${fontSize}px`);
  rendition.reportLocation();
}

//get current page text
function getCurrentPageText() {
  var startCfi = rendition.location.start.cfi
  var endCfi = rendition.location.end.cfi
  var cfiRange = makeRangeCfi(startCfi, endCfi)
  book.getRange(cfiRange).then(function (range) {
    var text = range.toString();
    // Convert CFI range to XPath
    cfiRangeToXPath(cfiRange).then(function (xpathRange) {
      var args = [text, cfiRange, xpathRange]
      window.flutter_inappwebview.callHandler('epubText', ...args);
    }).catch(function (e) {
      // If XPath conversion fails, still send CFI
      var args = [text, cfiRange, null]
      window.flutter_inappwebview.callHandler('epubText', ...args);
    });
  })
}

//get text from a range
function getTextFromCfi(startCfi, endCfi) {
  var cfiRange = makeRangeCfi(startCfi, endCfi)
  book.getRange(cfiRange).then(function (range) {
    var text = range.toString();
    // Convert CFI range to XPath
    cfiRangeToXPath(cfiRange).then(function (xpathRange) {
      var args = [text, cfiRange, xpathRange]
      window.flutter_inappwebview.callHandler('epubText', ...args);
    }).catch(function (e) {
      // If XPath conversion fails, still send CFI
      var args = [text, cfiRange, null]
      window.flutter_inappwebview.callHandler('epubText', ...args);
    });
  })
}

///update theme
function updateTheme(backgroundColor, foregroundColor, customCss) {
  // Line spacing reaches the rendition through customCss here, and changing it
  // repaginates the book — so re-measure the page-count divisor. A pure colour
  // change (theme swatch) doesn't repaginate, but it also routes through here;
  // re-measuring in that case is harmless (a few pages re-lock to the same
  // total), and telling the two apart isn't worth the complexity.
  _resetPageMetrics();

  var rules = {};
  var themeObj = {};

  // Build theme object with available colors
  // Only include properties that are provided and not empty
  if (backgroundColor && backgroundColor !== "" && backgroundColor !== "null") {
    themeObj["background"] = backgroundColor;
  }
  if (foregroundColor && foregroundColor !== "" && foregroundColor !== "null") {
    themeObj["color"] = foregroundColor;
  }

  if (Object.keys(themeObj).length > 0) {
    rules["body"] = themeObj;
  }

  // Merge custom CSS
  if (customCss && customCss !== "null" && typeof customCss === 'object') {
    Object.keys(customCss).forEach(function(selector) {
      if (rules[selector] && typeof rules[selector] === 'object' && typeof customCss[selector] === 'object') {
        // Deep merge properties for existing selectors (like 'body')
        Object.assign(rules[selector], customCss[selector]);
      } else {
        // Just add or overwrite non-object properties or new selectors
        rules[selector] = customCss[selector];
      }
    });
  }

  // Update theme if there are rules
  if (Object.keys(rules).length > 0) {
    rendition.themes.register("user-theme", rules);
    rendition.themes.select("user-theme");
  }
}

const makeRangeCfi = (a, b) => {
  const CFI = new ePub.CFI()
  const start = CFI.parse(a), end = CFI.parse(b)
  const cfi = {
    range: true,
    base: start.base,
    path: {
      steps: [],
      terminal: null
    },
    start: start.path,
    end: end.path
  }
  const len = cfi.start.steps.length
  for (let i = 0; i < len; i++) {
    if (CFI.equalStep(cfi.start.steps[i], cfi.end.steps[i])) {
      if (i == len - 1) {
        // Last step is equal, check terminals
        if (cfi.start.terminal === cfi.end.terminal) {
          // CFI's are equal
          cfi.path.steps.push(cfi.start.steps[i])
          // Not a range
          cfi.range = false
        }
      } else cfi.path.steps.push(cfi.start.steps[i])
    } else break
  }
  cfi.start.steps = cfi.start.steps.slice(cfi.path.steps.length)
  cfi.end.steps = cfi.end.steps.slice(cfi.path.steps.length)

  return 'epubcfi(' + CFI.segmentString(cfi.base)
    + '!' + CFI.segmentString(cfi.path)
    + ',' + CFI.segmentString(cfi.start)
    + ',' + CFI.segmentString(cfi.end)
    + ')'
}

// Convert a DOM node to XPath
function getXPath(node) {
  if (node.nodeType === Node.DOCUMENT_NODE) {
    return '/';
  }

  if (node.nodeType === Node.TEXT_NODE) {
    var parent = node.parentNode;
    var xpath = getXPath(parent);
    var index = 1;
    var sibling = node.previousSibling;
    while (sibling) {
      if (sibling.nodeType === Node.TEXT_NODE && sibling.nodeName === node.nodeName) {
        index++;
      }
      sibling = sibling.previousSibling;
    }
    return xpath + '/text()[' + index + ']';
  }

  if (node.nodeType === Node.ELEMENT_NODE) {
    var parts = [];
    var current = node;

    while (current && current.nodeType === Node.ELEMENT_NODE) {
      var index = 1;
      var sibling = current.previousSibling;
      while (sibling) {
        if (sibling.nodeType === Node.ELEMENT_NODE && sibling.nodeName === current.nodeName) {
          index++;
        }
        sibling = sibling.previousSibling;
      }

      var tagName = current.nodeName.toLowerCase();
      var xpathSegment = tagName + '[' + index + ']';

      // Add ID if available for more precise targeting
      if (current.id) {
        xpathSegment = tagName + '[@id="' + current.id + '"]';
      }

      parts.unshift(xpathSegment);
      current = current.parentNode;
    }

    return '/' + parts.join('/');
  }

  return '';
}

// Convert CFI to XPath/XPointer
// Returns a promise that resolves to an XPointer string or null if conversion fails
function cfiToXPath(cfiString) {
  if (!cfiString) {
    return Promise.resolve(null);
  }

  try {
    var cfi = new ePub.CFI(cfiString);
    var spineIndex = cfi.spinePos;

    // Get the spine item
    var spineItem = book.spine.get(spineIndex);
    if (!spineItem) {
      return Promise.resolve(null);
    }

    // Load the item and convert CFI to Range
    return spineItem.load(book.load.bind(book)).then(function () {
      try {
        var range = cfi.toRange(spineItem.document);
        if (!range) {
          return null;
        }

        // Build XPath from the range
        var startXPath = getXPath(range.startContainer);
        var endXPath = getXPath(range.endContainer);

        // Convert to KoReader format: /body/DocFragment[N]/body/...
        // Extract the path after /html[N]/body[N] and prepend /body/DocFragment[N]/body
        function convertToKoReaderFormat(xpath, offset) {
          // Match /html[N]/body[N] and extract the rest
          var match = xpath.match(/^\/html\[\d+\]\/body\[\d+\](.*)$/);
          if (match) {
            var elementPath = match[1] || '';
            // Convert /text()[1] to /text() for KoReader format
            elementPath = elementPath.replace(/\/text\(\)\[\d+\]$/, '/text()');
            // DocFragment index is spineIndex + 1 (1-based)
            var docFragmentIndex = spineIndex + 1;
            // Build KoReader format: /body/DocFragment[N]/body/...
            var koreaderPath = '/body/DocFragment[' + docFragmentIndex + ']/body' + elementPath;
            // Add offset for text nodes
            if (offset !== undefined && offset !== null) {
              koreaderPath += '.' + offset;
            }
            return koreaderPath;
          }
          // If format doesn't match, return original with offset
          if (offset !== undefined && offset !== null) {
            return xpath + '.' + offset;
          }
          return xpath;
        }

        // Add offset for text nodes and convert to KoReader format
        var startOffset = null;
        var endOffset = null;
        if (range.startContainer.nodeType === Node.TEXT_NODE) {
          startOffset = range.startOffset;
        }
        if (range.endContainer.nodeType === Node.TEXT_NODE) {
          endOffset = range.endOffset;
        }

        var startXPathKoReader = convertToKoReaderFormat(startXPath, startOffset);
        var endXPathKoReader = convertToKoReaderFormat(endXPath, endOffset);

        // Format as XPointer: /body/DocFragment[1]/body/div[2]/p[3]/text().123
        // For ranges, we return start and end separated by comma
        if (startXPathKoReader === endXPathKoReader && startOffset === endOffset) {
          return startXPathKoReader;
        } else {
          return startXPathKoReader + ',' + endXPathKoReader;
        }
      } catch (e) {
        console.error('Error converting CFI to XPath:', e);
        return null;
      }
    }).catch(function (e) {
      console.error('Error loading spine item for CFI conversion:', e);
      return null;
    });
  } catch (e) {
    console.error('Error parsing CFI:', e);
    return Promise.resolve(null);
  }
}

// Helper to convert CFI range to XPath range
function cfiRangeToXPath(cfiRangeString) {
  if (!cfiRangeString) {
    return Promise.resolve(null);
  }

  try {
    // Parse the CFI range to extract start and end CFIs
    var cfi = new ePub.CFI(cfiRangeString);
    var spineIndex = cfi.spinePos;

    var spineItem = book.spine.get(spineIndex);
    if (!spineItem) {
      return Promise.resolve(null);
    }

    return spineItem.load(book.load.bind(book)).then(function () {
      try {
        var range = cfi.toRange(spineItem.document);
        if (!range) {
          return null;
        }

        var startXPath = getXPath(range.startContainer);
        var endXPath = getXPath(range.endContainer);

        // Convert to KoReader format: /body/DocFragment[N]/body/...
        function convertToKoReaderFormat(xpath, offset) {
          // Match /html[N]/body[N] and extract the rest
          var match = xpath.match(/^\/html\[\d+\]\/body\[\d+\](.*)$/);
          if (match) {
            var elementPath = match[1] || '';
            // Convert /text()[1] to /text() for KoReader format
            elementPath = elementPath.replace(/\/text\(\)\[\d+\]$/, '/text()');
            // DocFragment index is spineIndex + 1 (1-based)
            var docFragmentIndex = spineIndex + 1;
            // Build KoReader format: /body/DocFragment[N]/body/...
            var koreaderPath = '/body/DocFragment[' + docFragmentIndex + ']/body' + elementPath;
            // Add offset for text nodes
            if (offset !== undefined && offset !== null) {
              koreaderPath += '.' + offset;
            }
            return koreaderPath;
          }
          // If format doesn't match, return original with offset
          if (offset !== undefined && offset !== null) {
            return xpath + '.' + offset;
          }
          return xpath;
        }

        // Add offset for text nodes and convert to KoReader format
        var startOffset = null;
        var endOffset = null;
        if (range.startContainer.nodeType === Node.TEXT_NODE) {
          startOffset = range.startOffset;
        }
        if (range.endContainer.nodeType === Node.TEXT_NODE) {
          endOffset = range.endOffset;
        }

        var startXPathKoReader = convertToKoReaderFormat(startXPath, startOffset);
        var endXPathKoReader = convertToKoReaderFormat(endXPath, endOffset);

        if (startXPathKoReader === endXPathKoReader && startOffset === endOffset) {
          return startXPathKoReader;
        } else {
          return startXPathKoReader + ',' + endXPathKoReader;
        }
      } catch (e) {
        console.error('Error converting CFI range to XPath:', e);
        return null;
      }
    }).catch(function (e) {
      console.error('Error loading spine item for CFI range conversion:', e);
      return null;
    });
  } catch (e) {
    console.error('Error parsing CFI range:', e);
    return Promise.resolve(null);
  }
}

// Convert XPath/XPointer to CFI
// Returns a promise that resolves to a CFI string or null if conversion fails
function xpathToCfi(xpathString) {
  if (!xpathString) {
    return Promise.resolve(null);
  }

  try {
    // Parse XPath - handle ranges (comma-separated) and offsets
    var parts = xpathString.split(',');
    var startXPath = parts[0].trim();
    var endXPath = parts.length > 1 ? parts[1].trim() : startXPath;

    // Extract offset from XPath if present (e.g., /path/to/text().123)
    var startOffset = 0;
    var endOffset = 0;
    var startXPathWithoutOffset = startXPath;
    var endXPathWithoutOffset = endXPath;

    var startOffsetMatch = startXPath.match(/\.(\d+)$/);
    if (startOffsetMatch) {
      startOffset = parseInt(startOffsetMatch[1]);
      startXPathWithoutOffset = startXPath.replace(/\.\d+$/, '');
    }

    var endOffsetMatch = endXPath.match(/\.(\d+)$/);
    if (endOffsetMatch) {
      endOffset = parseInt(endOffsetMatch[1]);
      endXPathWithoutOffset = endXPath.replace(/\.\d+$/, '');
    }

    // Extract DocFragment index if present (KoReader format: /body/DocFragment[9]/body/...)
    var docFragmentIndex = null;
    var docFragmentMatch = startXPathWithoutOffset.match(/\/DocFragment\[(\d+)\]/);
    if (docFragmentMatch) {
      docFragmentIndex = parseInt(docFragmentMatch[1]) - 1; // Convert to 0-based index
      // Remove /body/DocFragment[N]/ part, leaving /body/... or just the content path
      startXPathWithoutOffset = startXPathWithoutOffset.replace(/^\/body\/DocFragment\[\d+\]/, '');
    }

    // Try to find the node in each spine item (or just the specific one if DocFragment index was found)
    // Optimize: check sequentially and stop on first match to avoid loading all spine items
    var spineItemsToCheck = docFragmentIndex !== null
      ? [book.spine.spineItems[docFragmentIndex]].filter(function (item) { return item != null; })
      : book.spine.spineItems;

    // Optimize: if no DocFragment index, try to check currently displayed spine item first
    // Create a mapping to track original indices when reordering
    var indexMap = [];
    for (var mapIdx = 0; mapIdx < spineItemsToCheck.length; mapIdx++) {
      indexMap.push(mapIdx);
    }

    if (docFragmentIndex === null && rendition && rendition.location) {
      try {
        var currentLocation = rendition.location;
        if (currentLocation && currentLocation.start && currentLocation.start.index !== undefined) {
          var currentSpineIndex = currentLocation.start.index;
          if (currentSpineIndex >= 0 && currentSpineIndex < spineItemsToCheck.length) {
            // Check current spine item first by moving it to the front
            var currentItem = spineItemsToCheck[currentSpineIndex];
            var currentIndexInMap = indexMap[currentSpineIndex];
            spineItemsToCheck = [currentItem].concat(
              spineItemsToCheck.slice(0, currentSpineIndex),
              spineItemsToCheck.slice(currentSpineIndex + 1)
            );
            indexMap = [currentIndexInMap].concat(
              indexMap.slice(0, currentSpineIndex),
              indexMap.slice(currentSpineIndex + 1)
            );
          }
        }
      } catch (e) {
        // Silently fail - optimization is optional
      }
    }

    // Sequential check function that stops on first match
    function checkSpineItemSequentially(itemIndex) {
      if (itemIndex >= spineItemsToCheck.length) {
        // All items checked, no match found
        return Promise.resolve(null);
      }

      var item = spineItemsToCheck[itemIndex];
      // Use the mapped index to get the correct original spine index for CFI creation
      var index = docFragmentIndex !== null ? docFragmentIndex : indexMap[itemIndex];

      // Check if document is already loaded to avoid unnecessary loading
      var doc = item.document;
      var loadPromise = doc ? Promise.resolve() : item.load(book.load.bind(book));

      return loadPromise.then(function () {
        try {
          doc = item.document;
          if (!doc) {
            return null;
          }

          var startNode = null;
          var endNode = null;

          // Parse and resolve XPath manually (following Readest's approach)
          // This is more reliable than XPath evaluation in epub.js context
          function resolveXPointerPath(path) {
            var elementPath = '';
            var current = doc.body || doc.documentElement;

            if (!current) {
              return null;
            }

            // Handle empty path - return body element
            if (!path || path === '') {
              return current;
            }

            // Handle KoReader format: /body/DocFragment[N]/body/p[5]/text()
            var koreaderMatch = path.match(/^\/body\/DocFragment\[\d+\]\/body(.*)$/);
            if (koreaderMatch) {
              elementPath = koreaderMatch[1] || '';
            } else {
              // Handle our library's format: /html[1]/body[1]/p[1]/text()[1]
              var ourFormatMatch = path.match(/^\/html\[\d+\]\/body\[\d+\](.*)$/);
              if (ourFormatMatch) {
                elementPath = ourFormatMatch[1] || '';
              } else {
                // Try /body format
                var bodyMatch = path.match(/^\/body(.*)$/);
                if (bodyMatch) {
                  elementPath = bodyMatch[1] || '';
                } else {
                  // Try /html format
                  var htmlMatch = path.match(/^\/html\[\d+\](.*)$/);
                  if (htmlMatch) {
                    elementPath = htmlMatch[1] || '';
                  } else {
                    return null;
                  }
                }
              }
            }

            if (!elementPath || elementPath === '') {
              return current;
            }

            // Parse path segments (e.g., /p[5]/text() or /p[1]/text()[1] -> ['p[5]'] or ['p[1]', 'text()[1]'])
            var segments = elementPath.split('/').filter(function (s) { return s.length > 0; });

            for (var s = 0; s < segments.length; s++) {
              var segment = segments[s];

              // Handle text() or text()[1] - we'll handle this separately
              if (segment === 'text()' || segment.match(/^text\(\)\[\d+\]$/)) {
                break; // Stop here, current is the element containing the text
              }

              // Match tag[index] or just tag
              var segmentWithIndexMatch = segment.match(/^(\w+)\[(\d+)\]$/);
              var segmentWithoutIndexMatch = segment.match(/^(\w+)$/);

              var tagName = null;
              var index = 0;

              if (segmentWithIndexMatch) {
                tagName = segmentWithIndexMatch[1].toLowerCase();
                index = parseInt(segmentWithIndexMatch[2], 10) - 1; // Convert to 0-based
              } else if (segmentWithoutIndexMatch) {
                tagName = segmentWithoutIndexMatch[1].toLowerCase();
                index = 0;
              } else {
                return null;
              }

              // Find children with matching tag name
              var children = Array.from(current.children || []).filter(function (child) {
                return child.nodeType === Node.ELEMENT_NODE &&
                  child.tagName.toLowerCase() === tagName;
              });

              if (index >= children.length) {
                return null;
              }

              current = children[index];
            }

            return current;
          }

          // Resolve the start element
          var startElement = resolveXPointerPath(startXPathWithoutOffset);
          var startOffsetInNode = startOffset; // Default to original offset

          if (startElement) {
            // Handle text offset if present
            // If we have an offset (including 0) or explicit /text() in path, treat it as text node offset
            // Empty path with offset means we're targeting text nodes within the resolved element
            var hasTextOffset = startXPathWithoutOffset.includes('/text()') ||
              (startOffset >= 0 && (startXPathWithoutOffset === '' || startXPathWithoutOffset === '/body'));

            if (hasTextOffset) {
              // Find text node at the specified offset
              var textNodes = [];
              var walker = doc.createTreeWalker(startElement, NodeFilter.SHOW_TEXT, null, false);
              var textNode;
              while (textNode = walker.nextNode()) {
                if (textNode.textContent && textNode.textContent.length > 0) {
                  textNodes.push(textNode);
                }
              }

              if (textNodes.length > 0) {
                // If offset is 0, use the first text node
                if (startOffset === 0) {
                  startNode = textNodes[0];
                  startOffsetInNode = 0;
                } else {
                  // Calculate cumulative offset to find the right text node
                  var currentOffset = 0;
                  var targetTextNode = null;
                  var offsetInNode = 0;

                  for (var t = 0; t < textNodes.length; t++) {
                    var tn = textNodes[t];
                    var nodeLength = tn.textContent ? tn.textContent.length : 0;

                    // If offset is within this text node's range
                    if (currentOffset + nodeLength > startOffset) {
                      targetTextNode = tn;
                      offsetInNode = startOffset - currentOffset;
                      break;
                    }

                    currentOffset += nodeLength;
                  }

                  if (targetTextNode) {
                    startNode = targetTextNode;
                    startOffsetInNode = offsetInNode;
                  } else {
                    // Offset beyond all text, use last text node
                    var lastNode = textNodes[textNodes.length - 1];
                    startNode = lastNode;
                    var lastLength = lastNode.textContent ? lastNode.textContent.length : 0;
                    startOffsetInNode = lastLength;
                  }
                }
              } else {
                // No text nodes found, use the element itself
                startNode = startElement;
                startOffsetInNode = 0;
              }
            } else {
              // No text offset, use the element itself
              startNode = startElement;
              startOffsetInNode = 0;
            }
          }

          // If manual resolution failed, try XPath evaluation as fallback
          if (!startNode) {
            // Build XPath variations to try
            var xpathVariations = [startXPathWithoutOffset];

            if (startXPathWithoutOffset.startsWith('/body/')) {
              xpathVariations.push('/html' + startXPathWithoutOffset);
              xpathVariations.push(startXPathWithoutOffset.replace(/^\/body\//, '/'));
            }

            try {
              for (var v = 0; v < xpathVariations.length && !startNode; v++) {
                var xpathToTry = xpathVariations[v];
                try {
                  var startResult = doc.evaluate(xpathToTry, doc, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
                  startNode = startResult.singleNodeValue;
                  if (startNode) {
                    break;
                  }
                } catch (e) {
                  // Try next variation
                }
              }
            } catch (e) {
              // XPath evaluation failed, continue
            }
          }

          // Resolve end node (same approach as start node)
          var endOffsetInNode = endOffset; // Default to original offset
          if (parts.length > 1) {
            var endElement = resolveXPointerPath(endXPathWithoutOffset);
            if (endElement) {
              // Handle text offset if present (same logic as start node)
              var hasEndTextOffset = endXPathWithoutOffset.includes('/text()') ||
                (endOffset >= 0 && (endXPathWithoutOffset === '' || endXPathWithoutOffset === '/body'));

              if (hasEndTextOffset) {
                var endTextNodes = [];
                var endWalker = doc.createTreeWalker(endElement, NodeFilter.SHOW_TEXT, null, false);
                var endTextNode;
                while (endTextNode = endWalker.nextNode()) {
                  if (endTextNode.textContent && endTextNode.textContent.length > 0) {
                    endTextNodes.push(endTextNode);
                  }
                }

                if (endTextNodes.length > 0) {
                  var endCurrentOffset = 0;
                  var endTargetTextNode = null;
                  var endOffsetInNodeCalc = 0;

                  for (var t = 0; t < endTextNodes.length; t++) {
                    var tn = endTextNodes[t];
                    var nodeLength = tn.textContent ? tn.textContent.length : 0;

                    if (endCurrentOffset + nodeLength >= endOffset) {
                      endTargetTextNode = tn;
                      endOffsetInNodeCalc = endOffset - endCurrentOffset;
                      break;
                    }

                    endCurrentOffset += nodeLength;
                  }

                  if (endTargetTextNode) {
                    endNode = endTargetTextNode;
                    endOffsetInNode = endOffsetInNodeCalc;
                  } else if (endTextNodes.length > 0) {
                    var lastEndNode = endTextNodes[endTextNodes.length - 1];
                    endNode = lastEndNode;
                    endOffsetInNode = lastEndNode.textContent ? lastEndNode.textContent.length : 0;
                  } else {
                    endNode = endElement;
                    endOffsetInNode = 0;
                  }
                } else {
                  endNode = endElement;
                  endOffsetInNode = 0;
                }
              } else {
                endNode = endElement;
                endOffsetInNode = 0;
              }
            }

            // Fallback to startNode if endNode not found
            if (!endNode && startNode) {
              endNode = startNode;
              endOffsetInNode = startOffsetInNode;
            }
          } else {
            endNode = startNode;
            endOffsetInNode = startOffsetInNode;
          }

          if (!startNode || !endNode) {
            console.error('Missing startNode or endNode. startNode:', startNode, 'endNode:', endNode);
            return null;
          }

          // Create a Range from the nodes
          try {
            var range = doc.createRange();

            if (startNode.nodeType === Node.TEXT_NODE) {
              var startTextLength = startNode.textContent ? startNode.textContent.length : 0;
              range.setStart(startNode, Math.min(startOffsetInNode, startTextLength));
            } else {
              range.setStart(startNode, 0);
            }

            if (endNode.nodeType === Node.TEXT_NODE) {
              var endTextLength = endNode.textContent ? endNode.textContent.length : 0;
              range.setEnd(endNode, Math.min(endOffsetInNode, endTextLength));
            } else {
              var endChildNodesLength = (endNode.childNodes && endNode.childNodes.length) || 0;
              range.setEnd(endNode, endChildNodesLength);
            }
          } catch (e) {
            console.error('Error creating range:', e);
            return null;
          }

          // Create CFI from the range
          var spineItem = book.spine.get(index);
          var cfiString = null;

          try {
            // Create CFI from range
            // epub.js CFI constructor needs the document to be in the book context
            var packageIndices = [6, 4];
            var created = false;

            // Check if range is valid
            if (!range || !range.startContainer || !range.endContainer) {
              console.error('Invalid range - missing containers');
              return null;
            }

            // Try creating CFI with base string directly (epub.js needs base)
            // The base format is /{packageIndex}/{spineIndex} where spineIndex is 1-based
            for (var p = 0; p < packageIndices.length && !created; p++) {
              try {
                var packageIndex = packageIndices[p];
                // epub.js uses even numbers for spine indices: 2, 4, 6, 8...
                // So spine index 8 (0-based) = 18 (2 * (8 + 1))
                var spineIndexCfi = (index + 1) * 2;
                var baseString = "/" + packageIndex + "/" + spineIndexCfi;

                var cfi = new ePub.CFI(range, baseString);
                var cfiStringWithoutBase = cfi.toString();

                // Parse it to verify
                var parsedCfi = new ePub.CFI(cfiStringWithoutBase);

                // If spinePos matches, use it
                if (parsedCfi.spinePos === index) {
                  cfiString = cfiStringWithoutBase;
                  created = true;
                  break;
                } else {
                  cfiString = null;
                }
              } catch (e) {
                cfiString = null;
              }
            }

            if (created && cfiString) {
              return cfiString;
            } else {
              console.error('Failed to create valid CFI with any package index');
              return null;
            }
          } catch (e) {
            console.error('Error creating CFI:', e);
            return null;
          }
        } catch (e) {
          console.error('Error creating CFI for spine item', index, ':', e);
          return null;
        }
      }).catch(function (e) {
        console.error('Error loading spine item', index, ':', e);
        return null;
      }).then(function (result) {
        // If we found a match, return it immediately
        if (result) {
          return result;
        }
        // Otherwise, check the next spine item
        return checkSpineItemSequentially(itemIndex + 1);
      });
    }

    // Start sequential checking from the first item
    return checkSpineItemSequentially(0).then(function (result) {
      if (!result) {
        console.warn('No CFI found for XPath:', xpathString);
      }
      return result;
    }).catch(function (e) {
      console.error('Error converting XPath to CFI:', e);
      return null;
    });
  } catch (e) {
    console.error('Error parsing XPath:', e);
    return Promise.resolve(null);
  }
}

// Block or unblock gestures using CSS touch-action when selection is active
function blockGesturesWhenSelected(block) {
  try {
    var styleId = 'epub-selection-block-style';
    var existingStyle = document.getElementById(styleId);

    if (block) {
      // Block horizontal panning/swiping when selection exists
      // Use 'pan-y' to allow vertical scrolling but block horizontal swipes
      // Also add 'manipulation' to prevent double-tap zoom which can interfere
      if (!existingStyle) {
        var style = document.createElement('style');
        style.id = styleId;
        style.textContent = `
          body, html, #viewer {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
            -webkit-touch-callout: none !important;
            user-select: text !important;
          }
          body *, html *, #viewer * {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
            user-select: text !important;
          }
          iframe {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
            pointer-events: auto !important;
          }
          /* Block all horizontal gestures on iframes */
          iframe[src], iframe[srcdoc] {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
          }
        `;
        document.head.appendChild(style);
      }

      // Function to apply touch-action to iframes
      function applyTouchActionToIframes() {
        try {
          var allIframes = document.querySelectorAll('iframe');
          allIframes.forEach(function (iframe) {
            iframe.style.touchAction = 'pan-y manipulation';
            iframe.style.setProperty('-ms-touch-action', 'pan-y manipulation', 'important');
            iframe.style.setProperty('touch-action', 'pan-y manipulation', 'important');
          });
        } catch (e) {
          console.error('Error setting iframe touch-action:', e);
        }

        // Also try to get iframes from epub.js rendition
        if (typeof rendition !== 'undefined' && rendition) {
          try {
            var allContents = rendition.getContents();
            allContents.forEach(function (contents) {
              try {
                // Get the iframe element from the parent document
                var iframe = contents.document.defaultView.frameElement;
                if (iframe && iframe.style) {
                  iframe.style.touchAction = 'pan-y manipulation';
                  iframe.style.setProperty('-ms-touch-action', 'pan-y manipulation', 'important');
                  iframe.style.setProperty('touch-action', 'pan-y manipulation', 'important');
                }
              } catch (e) {
                // Ignore errors - iframe might be sandboxed
              }
            });
          } catch (e) {
            // Ignore errors
          }
        }
      }

      // Apply immediately
      applyTouchActionToIframes();

      // Watch for new iframes being added (epub.js creates them dynamically)
      if (!window.epubIframeObserver) {
        window.epubIframeObserver = new MutationObserver(function (mutations) {
          applyTouchActionToIframes();
        });
        window.epubIframeObserver.observe(document.body || document.documentElement, {
          childList: true,
          subtree: true
        });
      }
    } else {
      // Remove blocking when selection is cleared
      if (existingStyle) {
        existingStyle.remove();
      }

      // Stop observing if observer exists
      if (window.epubIframeObserver) {
        window.epubIframeObserver.disconnect();
        window.epubIframeObserver = null;
      }

      // Reset iframe styles
      try {
        var allIframes = document.querySelectorAll('iframe');
        allIframes.forEach(function (iframe) {
          iframe.style.touchAction = '';
          iframe.style.removeProperty('-ms-touch-action');
          iframe.style.removeProperty('touch-action');
        });
      } catch (e) {
        // Ignore errors
      }

      // Reset epub.js iframe styles
      if (typeof rendition !== 'undefined' && rendition) {
        try {
          var allContents = rendition.getContents();
          allContents.forEach(function (contents) {
            try {
              var iframe = contents.document.defaultView.frameElement;
              if (iframe && iframe.style) {
                iframe.style.touchAction = '';
                iframe.style.removeProperty('-ms-touch-action');
                iframe.style.removeProperty('touch-action');
              }
            } catch (e) {
              // Ignore errors
            }
          });
        } catch (e) {
          // Ignore errors
        }
      }
    }
  } catch (e) {
    console.error('Error blocking gestures:', e);
  }
}

// Check selection after long press (for iPad support)
function checkSelectionAfterLongPress() {
  try {
    // Check all content frames
    if (typeof rendition !== 'undefined' && rendition) {
      var allContents = rendition.getContents();
      allContents.forEach(function (contents, idx) {
        try {
          var selection = contents.window.getSelection();
          if (selection && selection.rangeCount > 0) {
            var range = selection.getRangeAt(0);
            var text = selection.toString();
            if (text && range && !range.collapsed) {
              // Try to get CFI
              if (typeof contents.cfiFromRange === 'function') {
                try {
                  var cfiRange = contents.cfiFromRange(range);
                  if (cfiRange) {
                    // Store this CFI to track changes
                    window.lastProcessedCfi = cfiRange.toString();

                    // Call sendSelectionData if it exists (it should be globally available)
                    if (typeof window.sendSelectionData === 'function') {
                      try {
                        window.sendSelectionData(cfiRange, contents);
                      } catch (e) {
                        // Fallback to direct handler call with manual rect calculation
                        try {
                          var rect = null;
                          if (range) {
                            var clientRect = range.getBoundingClientRect();
                            var webViewWidth = window.innerWidth;
                            var webViewHeight = window.innerHeight;
                            var iframe = contents.document.defaultView.frameElement;
                            if (iframe) {
                              var iframeRect = iframe.getBoundingClientRect();
                              var absoluteLeft = iframeRect.left + clientRect.left;
                              var absoluteTop = iframeRect.top + clientRect.top;
                              rect = {
                                left: absoluteLeft / webViewWidth,
                                top: absoluteTop / webViewHeight,
                                width: clientRect.width / webViewWidth,
                                height: clientRect.height / webViewHeight,
                                contentHeight: webViewHeight
                              };
                            }
                          }
                          window.flutter_inappwebview.callHandler('selection', cfiRange.toString(), text, rect, null);
                        } catch (e2) {
                          window.flutter_inappwebview.callHandler('selection', cfiRange.toString(), text, null, null);
                        }
                      }
                    } else {
                      // Try to get rect manually as fallback
                      try {
                        var rect = null;
                        if (range) {
                          var clientRect = range.getBoundingClientRect();
                          var webViewWidth = window.innerWidth;
                          var webViewHeight = window.innerHeight;
                          var iframe = contents.document.defaultView.frameElement;
                          if (iframe) {
                            var iframeRect = iframe.getBoundingClientRect();
                            var absoluteLeft = iframeRect.left + clientRect.left;
                            var absoluteTop = iframeRect.top + clientRect.top;
                            rect = {
                              left: absoluteLeft / webViewWidth,
                              top: absoluteTop / webViewHeight,
                              width: clientRect.width / webViewWidth,
                              height: clientRect.height / webViewHeight,
                              contentHeight: webViewHeight
                            };
                          }
                        }
                        window.flutter_inappwebview.callHandler('selection', cfiRange.toString(), text, rect, null);
                      } catch (e) {
                        window.flutter_inappwebview.callHandler('selection', cfiRange.toString(), text, null, null);
                      }
                    }
                  }
                } catch (e) {
                  // Ignore errors
                }
              }
            }
          }
        } catch (e) {
          // Ignore errors
        }
      });

      // Also check parent window
      try {
        var parentSel = window.getSelection();
        if (parentSel && parentSel.rangeCount > 0) {
          var parentText = parentSel.toString();
          if (parentText) {
            // Try to match to a content frame
            allContents.forEach(function (contents, idx) {
              try {
                var range = parentSel.getRangeAt(0);
                if (range && !range.collapsed && typeof contents.cfiFromRange === 'function') {
                  var cfiRange = contents.cfiFromRange(range);
                  if (cfiRange) {
                    if (typeof window.sendSelectionData === 'function') {
                      window.sendSelectionData(cfiRange, contents);
                    } else {
                      window.flutter_inappwebview.callHandler('selection', cfiRange.toString(), parentText, null, null);
                    }
                  }
                }
              } catch (e) {
                // Try next frame
              }
            });
          }
        }
      } catch (e) {
        // Ignore errors
      }
    }
  } catch (e) {
    // Ignore errors
  }
}

// Check selection periodically (for tracking selection changes when handles are dragged)
function checkSelectionPeriodically() {
  try {
    if (typeof rendition !== 'undefined' && rendition) {
      var allContents = rendition.getContents();
      var foundSelection = false;
      allContents.forEach(function (contents, idx) {
        try {
          var selection = contents.window.getSelection();
          if (selection && selection.rangeCount > 0) {
            var range = selection.getRangeAt(0);
            var text = selection.toString();
            if (text && range && !range.collapsed) {
              foundSelection = true;
              // Check if this is a new/different selection
              if (typeof contents.cfiFromRange === 'function') {
                try {
                  var cfiRange = contents.cfiFromRange(range);
                  if (cfiRange) {
                    var cfiString = cfiRange.toString();
                    // Only process if CFI changed (selection was modified)
                    if (cfiString !== window.lastProcessedCfi) {
                      window.lastProcessedCfi = cfiString;
                      if (typeof window.sendSelectionData === 'function') {
                        window.sendSelectionData(cfiRange, contents);
                      }
                    }
                  }
                } catch (e) {
                  // Ignore errors
                }
              }
            }
          }
        } catch (e) {
          // Ignore errors
        }
      });

      // Also check parent window
      try {
        var parentSel = window.getSelection();
        if (parentSel && parentSel.rangeCount > 0) {
          var parentText = parentSel.toString();
          if (parentText) {
            foundSelection = true;
            var allContents = rendition.getContents();
            allContents.forEach(function (contents, idx) {
              try {
                var range = parentSel.getRangeAt(0);
                if (range && !range.collapsed && typeof contents.cfiFromRange === 'function') {
                  var cfiRange = contents.cfiFromRange(range);
                  if (cfiRange) {
                    var cfiString = cfiRange.toString();
                    if (cfiString !== window.lastProcessedCfi) {
                      window.lastProcessedCfi = cfiString;
                      if (typeof window.sendSelectionData === 'function') {
                        window.sendSelectionData(cfiRange, contents);
                      }
                    }
                  }
                }
              } catch (e) {
                // Try next frame
              }
            });
          }
        }
      } catch (e) {
        // Ignore
      }
    }
  } catch (e) {
    // Ignore errors
  }
}

// Check if selection still exists and re-apply blocking if needed
function checkSelectionAndReapplyBlocking() {
  try {
    // Check if selection still exists
    var hasSelection = false;

    if (typeof rendition !== 'undefined' && rendition) {
      var allContents = rendition.getContents();
      for (var i = 0; i < allContents.length; i++) {
        try {
          var contents = allContents[i];
          if (contents.window && contents.window.getSelection) {
            var selection = contents.window.getSelection();
            if (selection && selection.rangeCount > 0) {
              var range = selection.getRangeAt(0);
              var text = selection.toString();
              if ((text && text.length > 0) || (range && !range.collapsed)) {
                hasSelection = true;
                break;
              }
            }
          }
        } catch (e) {
          // Ignore errors
        }
      }
    }

    // Also check parent window
    if (!hasSelection && window.getSelection) {
      var parentSel = window.getSelection();
      if (parentSel && parentSel.rangeCount > 0) {
        var parentRange = parentSel.getRangeAt(0);
        var parentText = parentSel.toString();
        if ((parentText && parentText.length > 0) || (parentRange && !parentRange.collapsed)) {
          hasSelection = true;
        }
      }
    }

    // If selection exists, ensure blocking is still active
    if (hasSelection) {
      var styleId = 'epub-selection-block-style';
      var existingStyle = document.getElementById(styleId);

      if (!existingStyle) {
        // Re-apply blocking if it was removed - use 'pan-y manipulation' to block horizontal swipes
        var style = document.createElement('style');
        style.id = styleId;
        style.textContent = `
          body, html, #viewer {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
            -webkit-touch-callout: none !important;
            user-select: text !important;
          }
          body *, html *, #viewer * {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
            user-select: text !important;
          }
          iframe {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
            pointer-events: auto !important;
          }
          iframe[src], iframe[srcdoc] {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
          }
        `;
        document.head.appendChild(style);
      }

      // Re-apply to iframes
      try {
        var allIframes = document.querySelectorAll('iframe');
        allIframes.forEach(function (iframe) {
          iframe.style.touchAction = 'pan-y manipulation';
          iframe.style.setProperty('-ms-touch-action', 'pan-y manipulation', 'important');
          iframe.style.setProperty('touch-action', 'pan-y manipulation', 'important');
        });
      } catch (e) {
        // Ignore errors
      }
    } else {
      // No selection, stop monitoring
      return 'no-selection';
    }
  } catch (e) {
    console.error('Error checking selection:', e);
  }
}

function detectSwipe(el, func) {
  // Called once per section as it renders, so this runs many times per book —
  // and a page turn is itself what renders the next section.
  //
  // Every bit of state below must therefore be per-call. `swipe_det` and `ele`
  // used to be declared without `var`, which made them implicit globals: each
  // new section reset the one shared object to zeroes while every section's
  // listeners kept reading from it. A section rendering in the middle of a
  // gesture would zero sX after touchstart, and touchend then compared the
  // finger's real end point against 0 — so the swipe either registered no
  // direction at all (the page simply didn't turn, and you swiped again), or
  // came out as `eX - min_x > sX` and turned the page *backwards*.
  var swipe_det = {
    sX: 0,
    sY: 0,
    eX: 0,
    eY: 0,
    blocked: false,      // Whether this swipe should be blocked
    hasMoved: false,     // Whether the touch has moved
    touchStartTime: null // When the touch started
  };
  var min_x = 50;  //min x swipe for horizontal swipe
  var max_x = 40;  //max x difference for vertical swipe
  var min_y = 40;  //min y swipe for vertical swipe
  var max_y = 50;  //max y difference for horizontal swipe
  var direc = "";
  // Re-registering on a document we already wired up would double every turn.
  if (!el || el.__sakuraSwipeInstalled) return;
  el.__sakuraSwipeInstalled = true;
  var ele = el;
  ele.addEventListener('touchstart', function (e) {
    // Check if selection exists at start of gesture
    if (hasActiveSelection()) {
      // Store position and time to detect if it's a tap or swipe
      swipe_det.blocked = false; // Don't block yet - wait to see if it's a tap
      swipe_det.hasMoved = false;
      swipe_det.touchStartTime = Date.now();
      if (e.touches && e.touches.length > 0) {
        var t = e.touches[0];
        swipe_det.sX = t.screenX;
        swipe_det.sY = t.screenY;
        swipe_det.eX = swipe_det.sX;
        swipe_det.eY = swipe_det.sY;
      }
      // Don't preventDefault yet - allow taps to deselect
    } else {
      swipe_det.blocked = false;
      swipe_det.hasMoved = false;
      swipe_det.touchStartTime = Date.now();
      var t = e.touches[0];
      swipe_det.sX = t.screenX;
      swipe_det.sY = t.screenY;
      swipe_det.eX = swipe_det.sX;
      swipe_det.eY = swipe_det.sY;
    }
  }, { capture: true, passive: false }); // Use options object with passive: false
  ele.addEventListener('touchmove', function (e) {
    // If selection exists, check if it's a swipe
    if (hasActiveSelection()) {
      var t = e.touches[0];
      swipe_det.eX = t.screenX;
      swipe_det.eY = t.screenY;

      var deltaX = Math.abs(swipe_det.eX - swipe_det.sX);
      var deltaY = Math.abs(swipe_det.eY - swipe_det.sY);

      // If there's significant movement, it's a swipe - block it
      if (deltaX > 10 || deltaY > 10) {
        swipe_det.hasMoved = true;
        // Block horizontal swipes
        if (deltaX > 30 && deltaX > deltaY * 1.5) {
          swipe_det.blocked = true;
          e.preventDefault();
          e.stopPropagation();
          return false;
        }
        // Block significant horizontal movement
        if (deltaX > 50) {
          swipe_det.blocked = true;
          e.preventDefault();
          e.stopPropagation();
          return false;
        }
      }
    } else {
      // Only prevent default if we're actually tracking a swipe
      e.preventDefault();
      var t = e.touches[0];
      swipe_det.eX = t.screenX;
      swipe_det.eY = t.screenY;
    }
  }, { capture: true, passive: false }); // Use options object with passive: false
  ele.addEventListener('touchend', function (e) {
    // If selection exists, check if it was a tap or swipe
    if (hasActiveSelection()) {
      if (swipe_det.touchStartTime !== null) {
        var deltaX = Math.abs(swipe_det.eX - swipe_det.sX);
        var deltaY = Math.abs(swipe_det.eY - swipe_det.sY);
        var touchDuration = Date.now() - swipe_det.touchStartTime;

        // If minimal movement and short duration, it's a tap - allow it to deselect
        if (!swipe_det.hasMoved && deltaX < 10 && deltaY < 10 && touchDuration < 300) {
          // Don't preventDefault - allow tap to deselect
        } else if (deltaX > 30 && deltaX > deltaY * 1.5) {
          // It was a horizontal swipe - block it
          swipe_det.blocked = true;
          e.preventDefault();
          e.stopPropagation();
          return false;
        } else if (deltaX > 50) {
          // Significant horizontal movement - block it
          swipe_det.blocked = true;
          e.preventDefault();
          e.stopPropagation();
          return false;
        }
      }
      // If it was a tap, don't preventDefault
      swipe_det.blocked = false;
      return;
    }

    // Don't process swipe if it was blocked
    if (swipe_det.blocked) {
      swipe_det.blocked = false;
      swipe_det.hasMoved = false;
      swipe_det.touchStartTime = null;
      return;
    }

    //horizontal detection
    if ((((swipe_det.eX - min_x > swipe_det.sX) || (swipe_det.eX + min_x < swipe_det.sX)) && ((swipe_det.eY < swipe_det.sY + max_y) && (swipe_det.sY > swipe_det.eY - max_y)))) {
      if (swipe_det.eX > swipe_det.sX) direc = "r";
      else direc = "l";
    }
    //vertical detection
    if ((((swipe_det.eY - min_y > swipe_det.sY) || (swipe_det.eY + min_y < swipe_det.sY)) && ((swipe_det.eX < swipe_det.sX + max_x) && (swipe_det.sX > swipe_det.eX - max_x)))) {
      if (swipe_det.eY > swipe_det.sY) direc = "d";
      else direc = "u";
    }

    if (direc != "") {
      if (typeof func == 'function') func(el, direc);
    }
    direc = "";
    swipe_det.blocked = false;
    swipe_det.hasMoved = false;
    swipe_det.touchStartTime = null;
  }, { capture: true, passive: false }); // Use options object with passive: false
}

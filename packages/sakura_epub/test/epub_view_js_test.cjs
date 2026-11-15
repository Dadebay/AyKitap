const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(
  path.join(__dirname, '../lib/assets/webpage/html/epubView.js'), 'utf8');

// Run the actual reader functions with a minimal WebView environment.
const selectionCode = source.slice(
  source.indexOf('  var pollIntervals = [];'),
  source.indexOf('  // Handle selection clearing and changes'));
let nextTimer = 0;
const activeIntervals = new Set();
const selectionContext = {
  Map,
  window: {},
  setInterval() {
    const id = ++nextTimer;
    activeIntervals.add(id);
    return id;
  },
  clearInterval(id) { activeIntervals.delete(id); },
};
vm.createContext(selectionContext);
vm.runInContext(selectionCode, selectionContext);
const firstDocument = { URL: 'chapter.xhtml' };
const secondDocument = { URL: 'chapter.xhtml' };
selectionContext.startPolling({ document: firstDocument });
selectionContext.startPolling({ document: firstDocument });
assert.equal(activeIntervals.size, 1, 'same frame must have one poller');
selectionContext.startPolling({ document: secondDocument });
assert.equal(activeIntervals.size, 2, 'new frame with same URL needs its own poller');
selectionContext.stopPolling();
assert.equal(activeIntervals.size, 0, 'closing a book clears all pollers');

const turnCode = source.slice(
  source.indexOf('function _animatedTurn('),
  source.indexOf('// Wrapping rendition.next/prev'));
let scheduled = [];
let commits = 0;
const viewer = { style: {} };
const turnContext = {
  Promise,
  console,
  document: { getElementById: () => viewer },
  _pageTransition: 'slide',
  _turnAnimating: false,
  _lastNavDirection: 0,
  _transitionSpec: () => ({
    outMs: 200, inMs: 230, out: 'translateX(-100%)',
    inFrom: 'translateX(100%)', outOpacity: 1, inOpacity: 1, ease: 'ease',
  }),
  setTimeout(callback) { scheduled.push(callback); return scheduled.length; },
  clearTimeout() {},
  requestAnimationFrame(callback) { callback(); },
};
vm.createContext(turnContext);
vm.runInContext(turnCode, turnContext);
turnContext._animatedTurn(1, () => { commits++; return Promise.resolve(); });
const timerCount = scheduled.length;
turnContext._animatedTurn(1, () => { commits++; return Promise.resolve(); });
assert.equal(commits, 0, 'a second turn must not commit during animation');
assert.equal(scheduled.length, timerCount, 'a second turn must not add animations');
assert.equal(turnContext._lastNavDirection, 1);

console.log('EPUB selection polling and rapid-turn checks passed');

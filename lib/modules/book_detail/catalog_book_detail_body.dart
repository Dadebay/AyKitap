part of 'catalog_book_detail_screen.dart';

/// The screen's widget tree: loading/error state, the blurred-cover header,
/// the scrolling content sheet (composed from the widgets in
/// widgets/catalog_detail_*.dart) and the floating back/favorite/share
/// controls on top.
extension _CatalogBookDetailBody on _CatalogBookDetailScreenState {
  Widget _buildBody() {
    if (_loading) {
      final initialCoverUrl = widget.initialCoverUrl;
      if (initialCoverUrl != null && initialCoverUrl.isNotEmpty) {
        // [SizedBox.expand] is load-bearing: every child below is
        // `Positioned` except the back button, and a `StackFit.loose` Stack
        // sizes itself to its largest *non-positioned* child — so without
        // this the Stack collapsed to the back button's 50px, `left: 0,
        // right: 0` resolved to 50px, and the cover's Hero landed flush
        // left. It only snapped to center once the loaded branch's
        // full-width ListView took over, which read as the cover flying
        // left and then sliding back.
        return SizedBox.expand(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _CatalogBookDetailScreenState._headerHeight,
                child: CatalogDetailHeaderArt(
                  imageUrl: initialCoverUrl,
                  heroTag: _heroTag,
                ),
              ),
              Positioned(
                top: _CatalogBookDetailScreenState._headerHeight + 24,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.2,
                    ),
                  ),
                ),
              ),
              _buildBackButton(context),
            ],
          ),
        );
      }
      return Stack(
        children: [
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
          _buildBackButton(context),
        ],
      );
    }
    if (_error != null) {
      return Stack(
        children: [
          NetworkErrorState(onRetry: _load),
          _buildBackButton(context),
        ],
      );
    }
    final book = _book!;
    final image = book.image;
    final imageUrl = image != null && image.isNotEmpty
        ? ApiConfig.resolveImageUrl(image)
        : null;
    return Stack(
      children: [
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _CatalogBookDetailScreenState._headerHeight,
            child: CatalogDetailHeaderArt(
              imageUrl: imageUrl,
              heroTag: _heroTag,
            )),
        ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
                height: _CatalogBookDetailScreenState._headerHeight -
                    _CatalogBookDetailScreenState._sheetOverlap),
            _buildContentSheet(book),
          ],
        ),
        DetailHeaderControls(
          isFinished: _isFinished,
          isFavorite: _isFavorite,
          onBack: () => Navigator.pop(context),
          onToggleFinished: _toggleFinished,
          onToggleFavorite: _toggleFavorite,
          onShare: () => _onShare(book),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8, left: 12),
      child: IconCircleButton(
        icon: HugeIcons.strokeRoundedArrowLeft01,
        onTap: () => Navigator.pop(context),
        size: 38,
        iconSize: 18,
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        iconColor: Colors.white,
      ),
    );
  }

  Widget _buildContentSheet(BookDetail book) {
    final headerSteps = CatalogDetailHeaderInfo.stepCount(book);
    final descriptionSteps = CatalogDetailDescription.stepCount(book);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(38), topRight: Radius.circular(38)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(38), topRight: Radius.circular(38)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -6))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          // Each block below (title, stats, pills, genres, synopsis)
          // fades/slides in on its own beat rather than as one lump — see
          // [CatalogDetailHeaderInfo]'s doc comment. `headerSteps` keeps
          // the description's and the secondary section's stagger index
          // contiguous with the header's without either widget hardcoding
          // the other's internal block count.
          child: Column(
            children: [
              CatalogDetailHeaderInfo(
                  book: book,
                  onTapAuthor: () => _openAuthor(book.authors.first)),
              CatalogDetailDescription(
                book: book,
                expanded: _descriptionExpanded,
                onToggleExpanded: () => _setState(
                    () => _descriptionExpanded = !_descriptionExpanded),
                onTapGenre: _openGenre,
                startIndex: headerSteps,
              ),
              // Related rows load separately and render nothing until they
              // arrive. The primary CTA now stays fixed below this scroll.
              ...buildDetailRelatedSections(book),
              StaggerFadeIn(
                index: headerSteps + descriptionSteps,
                child: CatalogDetailCtaSection(
                  book: book,
                  canRemoveFromPurchased: widget.canRemoveFromPurchased,
                  removingFromPurchased: _removingFromPurchased,
                  onRemoveFromPurchased: () => _removeFromPurchased(book),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

part of 'catalog_book_detail_screen.dart';

/// The screen's widget tree: loading/error state, the blurred-cover header,
/// the scrolling content sheet (composed from the widgets in
/// widgets/catalog_detail_*.dart) and the floating back/favorite/share
/// controls on top.
extension _CatalogBookDetailBody on _CatalogBookDetailScreenState {
  Widget _buildBody() {
    if (_loading || _error != null) {
      return Stack(
        children: [
          if (_loading)
            Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
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
              heroTag: AppHeroTags.catalogBookCover(book.id),
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
              ),
              CatalogDetailCtaSection(
                book: book,
                access: _access,
                canRemoveFromPurchased: widget.canRemoveFromPurchased,
                removingFromPurchased: _removingFromPurchased,
                onRemoveFromPurchased: () => _removeFromPurchased(book),
                onRead: _onRead,
                onBuy: _onBuy,
                onCancelDownload: _cancelDownload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

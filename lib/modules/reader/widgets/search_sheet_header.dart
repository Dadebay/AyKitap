part of 'search_sheet.dart';

/// [SearchSheet]'s header (title, hit count, close) and the search text
/// field — the parts of the sheet that don't depend on the results list.
extension _SearchSheetHeader on _SearchSheetState {
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ReaderSearchStrings.searchTitle,
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
            ),
          ),
          if (_hitCount > 0 && !_searching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ReaderSearchStrings.searchResultCount(_hitCount),
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 30,
              height: 30,
              decoration:
                  BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
              child: Icon(Icons.close, color: AppColors.grey2, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, color: AppColors.grey2, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _submit,
              style: TextStyle(color: AppColors.white, fontSize: 15),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: ReaderSearchStrings.searchHint,
                hintStyle: TextStyle(color: AppColors.grey2, fontSize: 14),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (_searching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            )
          else if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: _controller.clear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child:
                    Icon(Icons.close_rounded, color: AppColors.grey2, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

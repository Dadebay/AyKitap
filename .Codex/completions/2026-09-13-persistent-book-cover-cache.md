# Persistent book cover cache

## Problem

Book covers appeared to download again after the app was closed and reopened.
The shared image widget used `cached_network_image`, but its default manager
kept only 200 files and stored them in the OS temporary directory. Once the
process memory cache disappeared, catalogue-sized usage could therefore miss
the disk cache on the next launch.

## Change

- Added one process-wide `CoverImageCacheManager` for catalogue imagery.
- Mobile and desktop cache files now live under application support storage.
- Increased the LRU capacity to 1000 objects and the unused-file lifetime to
  180 days.
- Timestamp-versioned public media URLs remain fresh for at least 30 days.
- Routed `NetworkCoverImage`, the ranked collection banner, and cover sharing
  through the same cache manager.
- Added regression coverage proving the shared widget uses the configured
  singleton and catalogue-sized limits.

## Verification

- `flutter test test/core/widgets/network_cover_image_test.dart test/modules/home/widgets/catalog_rank_shelf_card_test.dart`
- Targeted `flutter analyze` for all changed Dart files and related tests
- `git diff --check`

All passed.

# iPad Home banner and sizing

- Replaced the fixed 300-point tablet carousel height with a width-based aspect ratio and capped the banner card at 800 points. Tablet cards use the website artwork when supplied.
- Removed the visible black surround of the first uploaded banner with a small clipped overscan. The source image itself contains a black frame.
- Increased Home book covers, ranked shelves, section headings, welcome row, and the wheel navigation controls for windows at least 600 points wide. Compact windows keep the phone layout.
- Updated Home's bottom scroll clearance to follow the wheel navigation height.

Verification: `flutter analyze lib/core/widgets/section_header.dart lib/modules/home lib/modules/main_nav` and `flutter test test/modules/home/widgets/catalog_rank_shelf_card_test.dart test/modules/home/widgets/catalog_numbered_book_section_test.dart` passed. Visually checked both banners and the larger Home layout on the iPad Air 13-inch (M4) simulator, iPadOS 27. The iPad Air 11-inch simulator currently opens this app in a narrow iPadOS window, which exercises the compact layout.

import 'package:flutter/material.dart';
import '../../models/book.dart';

/// What's left of the pre-backend mock catalogue, now that Home / Search /
/// Filter / Library / Book Detail / Author all read the real API: just
/// [generateBooks], a pure `(seed, index) -> Book` mapping still used by
/// [ReadingNote.book] to reconstruct a `book_<seed>_<index>` id's source
/// book without a network round-trip. The rest of this class (fixed
/// collections, series, search-chip pools, ~100 lines) was dead — nothing
/// outside this file read it — and was deleted rather than split when this
/// file was trimmed under the 200-line limit; see git history to resurrect
/// it.
class MockData {
  MockData._();

  static const _coverColors = [
    Color(0xFF3B4A6B),
    Color(0xFF4A3B6B),
    Color(0xFF6B3B3B),
    Color(0xFF3B6B4A),
    Color(0xFF6B5B3B),
    Color(0xFF3B5B6B),
    Color(0xFF5B3B6B),
    Color(0xFF6B3B5B),
  ];

  static final authors = List.generate(25, (i) {
    return Author(
      id: 'author_$i',
      name: _authorNames[i % _authorNames.length],
      color: _coverColors[i % _coverColors.length],
      bio:
          'Türkmen we dünýä edebiýatynda tanalýan ýazyjy. Onlarça eseri dürli dillere terjime edildi we millionlarça okyjyny özüne çekdi.',
    );
  });

  static const _authorNames = [
    'Osman Ödäýew',
    'Gurbannazar Ezizow',
    'Kerim Gurbannepesow',
    'Agageldi Allanazarow',
    'Bäşim Ataýew',
    'Nurmuhammet Andalyp',
    'Amanmyrat Bugaýew',
    'Rahim Esenow',
    'Hydyr Deryaýew',
    'Berdi Kerbabaýew',
  ];

  static const _titles = [
    'Ýitgi we tapyş',
    'Gije gelen myhman',
    'Söýginiň soňy ýok',
    'Çölüň sesi',
    'Asman ýyldyzlary',
    'Ykbal ýollary',
    'Garaşan gije',
    'Ýalňyz ýürek',
    'Umyt guşy',
    'Wagt akymy',
    'Gizlin dünýä',
    'Soňky söz',
    'Ýaşlyk ýyllary',
    'Düýşdäki söýgi',
    'Uzak ýoluň ahyry',
    'Gara garga',
    'Bagt syry',
    'Öý — mukaddes',
    'Ykbal çyzgysy',
    'Ýürekdäki ot',
    'Söýgi hatlary',
    'Dagyň aňyrsynda',
    'Ýaz gelende',
    'Ynam köprüsi',
    'Ata Watan',
    'Ene dilim',
    'Çaga ýyllary',
    'Iki dünýäniň arasynda',
    'Ýurduň nury',
    'Gyş ertekisi',
    'Bahar şemaly',
    'Deňziň aňyrsy',
    'Ýoluň soňy',
    'Görlüp-eşidilmedik',
    'Gujagyňda gizlener',
    'Dostluk ýoly',
    'Aýralyk agysy',
    'Gara gije, ak daň',
    'Söýgi we ölüm',
    'Wysal güni',
    'Çyn ýürekden',
    'Gadymy syrlar',
    'Ýitirilen wagt',
    'Ykbal oýny',
    'Ýaşaýşyň manysy',
    'Ýat illerde',
    'Öwrülişik',
    'Täleýiň ýazgysy',
    'Şugla',
    'Gizlin arzuw',
  ];

  static final genrePool = [
    'Romantika',
    'Fantasy',
    'Detektif',
    'Triller',
    'Taryh',
    'Klassika',
    'Ylmy-Fantastika',
    'Psihologiýa',
    'Biografiýa',
    'Gorkunç',
  ];

  // 16 real cover photos (assets/images/covers) cycled across however many
  // mock books get generated — there just aren't 50 distinct cover images.
  static const _coverImages = [
    'assets/images/covers/cover_01.jpg',
    'assets/images/covers/cover_02.jpg',
    'assets/images/covers/cover_03.jpg',
    'assets/images/covers/cover_04.jpg',
    'assets/images/covers/cover_05.jpg',
    'assets/images/covers/cover_06.jpg',
    'assets/images/covers/cover_07.jpg',
    'assets/images/covers/cover_08.jpg',
    'assets/images/covers/cover_09.jpg',
    'assets/images/covers/cover_10.jpg',
    'assets/images/covers/cover_11.jpg',
    'assets/images/covers/cover_12.jpg',
    'assets/images/covers/cover_13.jpg',
    'assets/images/covers/cover_14.jpg',
    'assets/images/covers/cover_15.jpg',
    'assets/images/covers/cover_16.jpg',
  ];

  static List<Book> generateBooks(int count, {int seed = 0}) {
    return List.generate(count, (i) {
      final idx = (i + seed) % _titles.length;
      final authorIdx = (i + seed) % authors.length;
      return Book(
        id: 'book_${seed}_$i',
        title: _titles[idx],
        author: authors[authorIdx],
        coverColor: _coverColors[(i + seed) % _coverColors.length],
        coverImage: _coverImages[(i + seed) % _coverImages.length],
        format: BookFormat.values[(i + seed) % BookFormat.values.length],
        genres: [
          genrePool[(i + seed) % genrePool.length],
          genrePool[(i + seed + 3) % genrePool.length]
        ],
        publisher: 'Türkmen Neşirýat',
        pages: 180 + ((i + seed) * 37) % 320,
        readCount: 1200 + ((i + seed) * 913) % 58000,
        purchaseCount: 80 + ((i + seed) * 57) % 4000,
        priceManat: 10 + ((i + seed) * 5) % 40,
        isFree: (i + seed) % 9 == 0,
        synopsis:
            'Bu kitap okyjyny çuňňur duýgulara we pikirlenmelere iterýän, wakalary ýatda galjak gahrymanlar bilen suratlandyrýan täsirli bir eser. Awtoryň öňki eserlerinden tapawutlylykda, bu gezek has çuňňur temalar gozgalýar.',
      );
    });
  }
}

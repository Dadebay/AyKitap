/// A user-imported EPUB/PDF file, kept separate from the mock catalogue
/// [Book] model since it has no author/genre/price — just a file on disk.
enum OwnBookFormat { epub, pdf }

class OwnBook {
  final String id;
  final String title;
  final String filePath;
  final OwnBookFormat format;
  final DateTime addedAt;

  const OwnBook({
    required this.id,
    required this.title,
    required this.filePath,
    required this.format,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'filePath': filePath,
    'format': format.name,
    'addedAt': addedAt.toIso8601String(),
  };

  factory OwnBook.fromJson(Map<String, dynamic> json) => OwnBook(
    id: json['id'] as String,
    title: json['title'] as String,
    filePath: json['filePath'] as String,
    format: OwnBookFormat.values.byName(json['format'] as String),
    addedAt: DateTime.parse(json['addedAt'] as String),
  );
}

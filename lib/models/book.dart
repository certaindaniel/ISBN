class Book {
  final int? id;
  final String isbn;
  final String title;
  final String author;
  final String publisher;
  final String? coverUrl;
  final String? description;
  final double purchasePrice;
  final double? salePrice;
  final DateTime purchaseDate;
  final DateTime? saleDate;
  final int quantity;
  final String status; // 'owned', 'sold', 'available'

  Book({
    this.id,
    required this.isbn,
    required this.title,
    required this.author,
    required this.publisher,
    this.coverUrl,
    this.description,
    required this.purchasePrice,
    this.salePrice,
    required this.purchaseDate,
    this.saleDate,
    this.quantity = 1,
    this.status = 'owned',
  });

  double? get profit => salePrice != null ? salePrice! - purchasePrice : null;

  Map<String, dynamic> toJson() => {
        'isbn': isbn,
        'title': title,
        'author': author,
        'publisher': publisher,
        'coverUrl': coverUrl,
        'description': description,
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
        'purchaseDate': purchaseDate.toIso8601String(),
        'saleDate': saleDate?.toIso8601String(),
        'quantity': quantity,
        'status': status,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        isbn: json['isbn'],
        title: json['title'],
        author: json['author'],
        publisher: json['publisher'],
        coverUrl: json['coverUrl'],
        description: json['description'],
        purchasePrice: json['purchasePrice'],
        salePrice: json['salePrice'],
        purchaseDate: DateTime.parse(json['purchaseDate']),
        saleDate:
            json['saleDate'] != null ? DateTime.parse(json['saleDate']) : null,
        quantity: json['quantity'] ?? 1,
        status: json['status'] ?? 'owned',
      );

  Map<String, dynamic> toMap() => {
        'isbn': isbn,
        'title': title,
        'author': author,
        'publisher': publisher,
        'coverUrl': coverUrl,
        'description': description,
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
        'purchaseDate': purchaseDate.toIso8601String(),
        'saleDate': saleDate?.toIso8601String(),
        'quantity': quantity,
        'status': status,
      };

  factory Book.fromMap(Map<String, dynamic> map) => Book(
        id: map['id'],
        isbn: map['isbn'],
        title: map['title'],
        author: map['author'],
        publisher: map['publisher'],
        coverUrl: map['coverUrl'],
        description: map['description'],
        purchasePrice: map['purchasePrice'],
        salePrice: map['salePrice'],
        purchaseDate: DateTime.parse(map['purchaseDate']),
        saleDate:
            map['saleDate'] != null ? DateTime.parse(map['saleDate']) : null,
        quantity: map['quantity'] ?? 1,
        status: map['status'] ?? 'owned',
      );

  Book copyWith({
    int? id,
    String? isbn,
    String? title,
    String? author,
    String? publisher,
    String? coverUrl,
    String? description,
    double? purchasePrice,
    double? salePrice,
    DateTime? purchaseDate,
    DateTime? saleDate,
    int? quantity,
    String? status,
  }) =>
      Book(
        id: id ?? this.id,
        isbn: isbn ?? this.isbn,
        title: title ?? this.title,
        author: author ?? this.author,
        publisher: publisher ?? this.publisher,
        coverUrl: coverUrl ?? this.coverUrl,
        description: description ?? this.description,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        salePrice: salePrice ?? this.salePrice,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        saleDate: saleDate ?? this.saleDate,
        quantity: quantity ?? this.quantity,
        status: status ?? this.status,
      );
}

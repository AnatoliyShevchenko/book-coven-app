import 'package:flutter/painting.dart';

class Book {
  const Book({required this.title, required this.author, required this.cover});

  final String title;
  final String author;
  final BookCover cover;
}

/// Цвет обложки на лицевой стороне карты: фон и цвет текста.
class BookCover {
  const BookCover(this.bg, this.ink);

  final Color bg;
  final Color ink;
}

/// Пары цветов обложек из макета. Книге достаётся пара по её номеру в таблице.
const bookCovers = <BookCover>[
  BookCover(Color(0xFF2B2D5C), Color(0xFFE9D9A6)),
  BookCover(Color(0xFF7A3B2E), Color(0xFFF3E2C4)),
  BookCover(Color(0xFF1F3A34), Color(0xFFE6DDC6)),
  BookCover(Color(0xFF4E5C3E), Color(0xFFF4EBD8)),
  BookCover(Color(0xFFC7863A), Color(0xFF2A1A10)),
  BookCover(Color(0xFF3D1F2B), Color(0xFFE8C9B0)),
  BookCover(Color(0xFF3E4A3D), Color(0xFFD9E0C8)),
  BookCover(Color(0xFF6B1420), Color(0xFFF0DCC8)),
  BookCover(Color(0xFFD8CFC0), Color(0xFF2A2522)),
  BookCover(Color(0xFF161616), Color(0xFFE4E0DA)),
  BookCover(Color(0xFF4A2F24), Color(0xFFE7D3AE)),
  BookCover(Color(0xFF26303F), Color(0xFFD5DCE6)),
  BookCover(Color(0xFF8A8F3A), Color(0xFF1E1F10)),
  BookCover(Color(0xFF9E6F86), Color(0xFF23141C)),
  BookCover(Color(0xFF2F3F6B), Color(0xFFF0D98A)),
  BookCover(Color(0xFFC9B48A), Color(0xFF2C2417)),
  BookCover(Color(0xFF54606B), Color(0xFFEDE6DA)),
  BookCover(Color(0xFF3B6B5E), Color(0xFFF2E6C9)),
  BookCover(Color(0xFF1E2A2A), Color(0xFFCFE0D8)),
  BookCover(Color(0xFF2A2A2E), Color(0xFFD8B26A)),
  BookCover(Color(0xFF5A4632), Color(0xFFEFE3CC)),
  BookCover(Color(0xFFB5602A), Color(0xFF1F130B)),
  BookCover(Color(0xFF402A52), Color(0xFFEAD7F0)),
  BookCover(Color(0xFF7D2F45), Color(0xFFF4DCC8)),
];

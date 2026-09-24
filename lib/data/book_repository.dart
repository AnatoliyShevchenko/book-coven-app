import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'book.dart';

/// Публичная таблица со списком книг, открытая «всем по ссылке» на чтение.
const _sheetId = '1SYZCdkQhV02JvKaCdWHfXz1aO2o3q-NgBhhpXkzi9W4';
final _csvUrl = Uri.parse('https://docs.google.com/spreadsheets/d/$_sheetId/export?format=csv');

const _cacheKey = 'books_csv';
const _timeout = Duration(seconds: 10);

class BookRepository {
  BookRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Загружает книги из таблицы. Без сети отдаёт последний сохранённый список.
  /// Бросает исключение, только если нет ни сети, ни кэша.
  Future<List<Book>> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final res = await _client.get(_csvUrl).timeout(_timeout);
      if (res.statusCode != 200) {
        throw http.ClientException('HTTP ${res.statusCode}', _csvUrl);
      }
      final body = utf8.decode(res.bodyBytes);
      final books = parseBooks(body);
      await prefs.setString(_cacheKey, body);
      return books;
    } catch (_) {
      final cached = prefs.getString(_cacheKey);
      if (cached == null) rethrow;
      return parseBooks(cached);
    }
  }
}

/// Разбирает CSV с колонками `Title`, `Author`, `Read`.
/// Книги с непустой колонкой `Read` уже прочитаны и в расклад не попадают.
List<Book> parseBooks(String body) {
  final rows = csv.decode(body);
  if (rows.isEmpty) return const [];

  final header = rows.first.map((c) => c.toString().trim().toLowerCase()).toList();
  final titleCol = header.indexOf('title');
  final authorCol = header.indexOf('author');
  final readCol = header.indexOf('read');
  if (titleCol < 0 || authorCol < 0) {
    throw const FormatException('В таблице нет колонок Title и Author');
  }

  String cell(List<dynamic> row, int col) =>
      col >= 0 && col < row.length ? row[col].toString().trim() : '';

  final books = <Book>[];
  for (final row in rows.skip(1)) {
    final title = _unquote(cell(row, titleCol));
    if (title.isEmpty || cell(row, readCol).isNotEmpty) continue;
    books.add(Book(
      title: title,
      author: cell(row, authorCol),
      cover: bookCovers[books.length % bookCovers.length],
    ));
  }
  return books;
}

/// Названия в таблице записаны в кавычках: `"Самайнтаун"` или `«Самайнтаун»`.
String _unquote(String s) {
  const pairs = {'"': '"', '«': '»', '“': '”', '„': '“'};
  final close = pairs[s.isEmpty ? '' : s[0]];
  if (close != null && s.length >= 2 && s.endsWith(close)) {
    return s.substring(1, s.length - 1).trim();
  }
  return s;
}

import 'package:book_coven/data/book_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseBooks', () {
    test('берёт название и автора, снимает кавычки с названия', () {
      const csv = 'Title,Author,Cover,Read\n'
          '"""Самайнтаун""",Анастасия Гор,https://example.com/a.jpg,\n'
          '«Лед и пепел»,Мила Дуглас,,';
      final books = parseBooks(csv);
      expect(books.map((b) => b.title), ['Самайнтаун', 'Лед и пепел']);
      expect(books.map((b) => b.author), ['Анастасия Гор', 'Мила Дуглас']);
    });

    test('пропускает прочитанные книги и пустые строки', () {
      const csv = 'Title,Author,Read\nА,Автор А,да\nБ,Автор Б,\n,,\nВ,Автор В,';
      expect(parseBooks(csv).map((b) => b.title), ['Б', 'В']);
    });

    test('колонки ищет по заголовку, без учёта регистра и порядка', () {
      const csv = 'read,AUTHOR,title\n,Автор,Книга';
      final book = parseBooks(csv).single;
      expect((book.title, book.author), ('Книга', 'Автор'));
    });

    test('без колонки Title бросает FormatException', () {
      expect(() => parseBooks('Name,Author\nА,Б'), throwsFormatException);
    });

    test('обложки разных книг разные', () {
      const csv = 'Title,Author\nА,x\nБ,y';
      final books = parseBooks(csv);
      expect(books[0].cover, isNot(same(books[1].cover)));
    });
  });
}

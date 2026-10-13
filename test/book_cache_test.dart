import 'dart:convert';

import 'package:book_coven/data/book_repository.dart';
import 'package:book_coven/widgets/cache_notice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _csv = 'Title,Author,Read\nА,Автор А,\nБ,Автор Б,';

/// Google отдаёт CSV в UTF-8.
http.Response _ok() => http.Response.bytes(utf8.encode(_csv), 200);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('с сетью отдаёт свежий список и сохраняет его', () async {
    final repo = BookRepository(client: MockClient((_) async => _ok()));
    final list = await repo.load();
    expect(list.fromCache, isFalse);
    expect(list.books.map((b) => b.title), ['А', 'Б']);
    expect(list.savedAt, isNotNull);
  });

  test('без сети отдаёт сохранённый список с датой обновления', () async {
    await BookRepository(client: MockClient((_) async => _ok())).load();
    final offline = BookRepository(client: MockClient((_) async => throw http.ClientException('нет сети')));
    final list = await offline.load();
    expect(list.fromCache, isTrue);
    expect(list.books.map((b) => b.title), ['А', 'Б']);
    expect(list.savedAt, isNotNull);
  });

  test('ошибка сервера тоже уводит в кэш', () async {
    await BookRepository(client: MockClient((_) async => _ok())).load();
    final broken = BookRepository(client: MockClient((_) async => http.Response('', 500)));
    expect((await broken.load()).fromCache, isTrue);
  });

  test('без сети и без кэша бросает ошибку', () async {
    final offline = BookRepository(client: MockClient((_) async => throw http.ClientException('нет сети')));
    expect(offline.load(), throwsA(isA<http.ClientException>()));
  });

  test('дата обновления в формате «24 сент., 09:05»', () {
    expect(formatSavedAt(DateTime(2026, 9, 24, 9, 5)), '24 сент., 09:05');
    expect(formatSavedAt(DateTime(2026, 5, 1, 21, 30)), '1 мая, 21:30');
  });
}

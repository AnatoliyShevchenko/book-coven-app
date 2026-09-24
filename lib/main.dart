import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/book.dart';
import 'data/book_repository.dart';
import 'screens/splash_screen.dart';
import 'screens/spread_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const CovenApp());
}

class CovenApp extends StatelessWidget {
  const CovenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Книжный ковен',
      debugShowCheckedModeBanner: false,
      theme: buildCovenTheme(),
      home: const _Boot(),
    );
  }
}

/// Показывает сплэш, пока грузятся книги, но не меньше, чем длится появление.
class _Boot extends StatefulWidget {
  const _Boot();

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  final _repository = BookRepository();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    List<Book> books = const [];
    Object? error;
    await Future.wait([
      Future<void>.delayed(splashMinDuration),
      _repository.load().then((b) => books = b, onError: (Object e) => error = e),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, _, _) => SpreadScreen(repository: _repository, books: books, loadError: error),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}

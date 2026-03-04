//book_provider.dart
// ============================================================================
// Book Provider
//
// FIXES:
//  1. The books getter previously called _bookBox.values.toList() on every
//     single access, allocating a new List on every widget build. It is now
//     replaced with a cached _cachedBooks list that is only rebuilt when a
//     mutation actually occurs.
//  2. Books are sorted newest-first by createdAt so the list stays in a
//     sensible order as the user's library grows.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';

class BookProvider extends ChangeNotifier {

  late final Box<Book> _bookBox;

  // FIX 1: cached list — not rebuilt on every getter call
  List<Book> _cachedBooks = [];

  BookProvider() {
    _bookBox = Hive.box<Book>('books');
    _rebuildCache();
  }

  // FIX 1 + 2: single place where the list is built and sorted
  void _rebuildCache() {
    _cachedBooks = _bookBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Returns the cached, sorted list — no allocation on access
  List<Book> get books => _cachedBooks;

  Book? findById(String id) {
    return _bookBox.get(id);
  }

  Future<void> addBook(Book book) async {
    await _bookBox.put(book.id, book);
    _rebuildCache();
    notifyListeners();
  }

  Future<void> updateBook(Book updatedBook) async {
    await _bookBox.put(updatedBook.id, updatedBook);
    _rebuildCache();
    notifyListeners();
  }

  Future<void> deleteBook(String id) async {
    await _bookBox.delete(id);
    _rebuildCache();
    notifyListeners();
  }
}
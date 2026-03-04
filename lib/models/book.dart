//book.dart

import 'package:hive_flutter/hive_flutter.dart';

part 'book.g.dart';

// =========================================================
// 1. BOOK MODEL (Type ID 0)
// =========================================================
@HiveType(typeId: 0)
class Book extends HiveObject
{
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late DateTime createdAt;

  @HiveField(3)
  late String prompt; // The user's original idea/description

  @HiveField(4)
  late String stylePrompt; // The prompt used for image generation style

  @HiveField(5)
  late List<BookPage> pages; // List of pages

  @HiveField(6)
  late String coverImagePath; // Path/Base64 of the first page image

  @HiveField(7)
  late String author;

  @HiveField(8)
  late String artStyle;

  Book(
  {
    required this.id,
    required this.title,
    required this.createdAt,
    required this.prompt,
    required this.stylePrompt,
    required this.pages,
    required this.coverImagePath,
    required this.author,
    this.artStyle = 'Watercolor',
  });
}

// =========================================================
// 2. BOOK PAGE MODEL (Type ID 1)
// =========================================================
@HiveType(typeId: 1)
class BookPage extends HiveObject
{
  @HiveField(0)
  late int pageNumber;

  @HiveField(1)
  late String textContent; // The generated story text for this page

  @HiveField(2)
  late String imagePath; // Base64 string or local file path

  @HiveField(3)
  late bool isImageGenerated; // Flag to track background completion

  BookPage(
  {
    required this.pageNumber,
    required this.textContent,
    required this.imagePath,
    required this.isImageGenerated,
  });
}
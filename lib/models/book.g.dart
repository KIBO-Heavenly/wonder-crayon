//book.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 0;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      prompt: fields[3] as String,
      stylePrompt: fields[4] as String,
      pages: (fields[5] as List).cast<BookPage>(),
      coverImagePath: fields[6] as String,
      author: fields[7] == null ? "Unknown" : fields[7] as String,
      artStyle: fields[8] == null ? "Watercolor" : fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.prompt)
      ..writeByte(4)
      ..write(obj.stylePrompt)
      ..writeByte(5)
      ..write(obj.pages)
      ..writeByte(6)
      ..write(obj.coverImagePath)
      ..writeByte(7)
      ..write(obj.author)
      ..writeByte(8)
      ..write(obj.artStyle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BookAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}


class BookPageAdapter extends TypeAdapter<BookPage> {
  @override
  final int typeId = 1;

  @override
  BookPage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookPage(
      pageNumber: fields[0] as int,
      textContent: fields[1] as String,
      imagePath: fields[2] as String,
      isImageGenerated: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BookPage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.pageNumber)
      ..writeByte(1)
      ..write(obj.textContent)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.isImageGenerated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookPageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

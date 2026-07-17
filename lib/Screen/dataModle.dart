import 'package:flutter/material.dart';

/// Core data model for a single note.
class NoteModel {
  final String id;
  String title;
  String note;
  Color color;
  bool isFavourite;
  bool isPinned;
  bool isArchived;
  bool isLocked;
  String? pin;
  String? imagePath;
  String category;
  DateTime createdAt;
  DateTime? reminderTime;

  /// Store formatted HTML content from Quill editor
  String? formattedNote;

  NoteModel({
    String? id,
    required this.title,
    required this.note,
    required this.color,
    this.isFavourite = false,
    this.isPinned = false,
    this.isArchived = false,
    this.isLocked = false,
    this.pin,
    this.imagePath,
    this.category = "All",
    DateTime? createdAt,
    this.reminderTime,
    this.formattedNote,
  })  : createdAt = createdAt ?? DateTime.now(),
        id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  int get wordCount {
    if (note.trim().isEmpty) return 0;
    return note.trim().split(RegExp(r'\s+')).length;
  }

  int get charCount => note.length;

  String get preview {
    if (note.isEmpty) return "No content added.";
    return note.length > 120 ? "${note.substring(0, 120)}..." : note;
  }

  bool get isReminderExpired {
    if (reminderTime == null) return false;
    return reminderTime!.isBefore(DateTime.now());
  }

  bool get hasActiveReminder {
    if (reminderTime == null) return false;
    return !isReminderExpired;
  }

  int get notificationId => id.hashCode.abs() % 2147483647;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "note": note,
      "color": color.toARGB32(),
      "isFavourite": isFavourite,
      "isPinned": isPinned,
      "isArchived": isArchived,
      "isLocked": isLocked,
      "pin": pin,
      "imagePath": imagePath,
      "category": category,
      "createdAt": createdAt.toIso8601String(),
      "reminderTime": reminderTime?.toIso8601String(),
      "formattedNote": formattedNote,
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    DateTime safeDate(dynamic value) {
      try {
        if (value == null) return DateTime.now();
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    DateTime? safeNullableDate(dynamic value) {
      try {
        if (value == null) return null;
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final createdDate = safeDate(json["createdAt"]);

    return NoteModel(
      id: json["id"] ?? createdDate.microsecondsSinceEpoch.toString(),
      title: json["title"] ?? "",
      note: json["note"] ?? "",
      color: Color(json["color"] ?? 0xffF6E58D),
      isFavourite: json["isFavourite"] ?? false,
      isPinned: json["isPinned"] ?? false,
      isArchived: json["isArchived"] ?? false,
      isLocked: json["isLocked"] ?? false,
      pin: json["pin"],
      imagePath: json["imagePath"],
      category: json["category"] ?? "All",
      createdAt: createdDate,
      reminderTime: safeNullableDate(json["reminderTime"]),
      formattedNote: json["formattedNote"],
    );
  }

  NoteModel copyWith({
    String? title,
    String? note,
    Color? color,
    bool? isFavourite,
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
    String? pin,
    String? imagePath,
    String? category,
    DateTime? createdAt,
    DateTime? reminderTime,
    String? formattedNote,
    bool clearReminder = false,
    bool clearImage = false,
    bool clearPin = false,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      color: color ?? this.color,
      isFavourite: isFavourite ?? this.isFavourite,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isLocked: isLocked ?? this.isLocked,
      pin: clearPin ? null : (pin ?? this.pin),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      reminderTime: clearReminder ? null : (reminderTime ?? this.reminderTime),
      formattedNote: formattedNote ?? this.formattedNote,
    );
  }

  NoteModel resetForTemplate({
    String? newTitle,
    String? newNote,
    Color? newColor,
    String? newCategory,
  }) {
    return NoteModel(
      id: id,
      title: newTitle ?? title,
      note: newNote ?? note,
      color: newColor ?? color,
      category: newCategory ?? category,
      isFavourite: false,
      isPinned: false,
      isArchived: false,
      isLocked: false,
      pin: null,
      imagePath: null,
      createdAt: DateTime.now(),
      reminderTime: null,
      formattedNote: null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteModel) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NoteModel(id: $id, title: $title, category: $category, isLocked: $isLocked)';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  String get formattedDateTime {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  bool get hasContent => title.isNotEmpty || note.isNotEmpty;

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  bool get hasPin => pin != null && pin!.isNotEmpty;

  String get shareText {
    final shareTitle = title.isEmpty ? "Untitled Note" : title;
    final shareContent = note.isEmpty ? "No content" : note;
    return "📝 $shareTitle\n\n$shareContent\n\n— Shared from VibeNote";
  }

  String get categoryEmoji {
    switch (category.toLowerCase()) {
      case "study":
        return "📚";
      case "work":
        return "💼";
      case "personal":
        return "👤";
      case "important":
        return "⭐";
      default:
        return "📝";
    }
  }

  bool get isEmptyNote => title.isEmpty && note.isEmpty && imagePath == null;

  NoteModel duplicate() {
    return NoteModel(
      title: title,
      note: note,
      color: color,
      category: category,
      isFavourite: false,
      isPinned: false,
      isArchived: false,
      isLocked: false,
      pin: null,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      reminderTime: null,
      formattedNote: formattedNote,
    );
  }

  NoteModel toggleFavourite() {
    return copyWith(isFavourite: !isFavourite);
  }

  NoteModel togglePinned() {
    return copyWith(isPinned: !isPinned);
  }

  NoteModel toggleArchived() {
    return copyWith(isArchived: !isArchived);
  }

  NoteModel toggleLocked({String? newPin}) {
    if (isLocked) {
      return copyWith(isLocked: false, pin: null);
    } else {
      return copyWith(isLocked: true, pin: newPin);
    }
  }

  bool verifyPin(String pinToCheck) {
    if (pin == null) return false;
    return pin == pinToCheck;
  }
}
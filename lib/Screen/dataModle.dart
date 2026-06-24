import 'package:flutter/material.dart';

class NoteModel {
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

   final String id;

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
  })  : createdAt = createdAt ?? DateTime.now(),
        id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  // ✅ word count helper
  int get wordCount {
    if (note.trim().isEmpty) return 0;
    return note.trim().split(RegExp(r'\s+')).length;
  }

  // ✅ character count helper
  int get charCount => note.length;

  // ✅ short preview of note
  String get preview {
    if (note.isEmpty) return "No content added.";
    return note.length > 120 ? "${note.substring(0, 120)}..." : note;
  }

  // ✅ check if reminder is expired
  bool get isReminderExpired {
    if (reminderTime == null) return false;
    return reminderTime!.isBefore(DateTime.now());
  }

  // ✅ check if reminder is active (set and not expired)
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
      "color": color.value,
      "isFavourite": isFavourite,
      "isPinned": isPinned,
      "isArchived": isArchived,
      "isLocked": isLocked,
      "pin": pin,
      "imagePath": imagePath,
      "category": category,
      "createdAt": createdAt.toIso8601String(),
      "reminderTime": reminderTime?.toIso8601String(),
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      // ✅ backward compatible: old notes without id get one from createdAt
      id: json["id"] ??
          (json["createdAt"] != null
              ? DateTime.parse(json["createdAt"])
              .microsecondsSinceEpoch
              .toString()
              : DateTime.now().microsecondsSinceEpoch.toString()),
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
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : DateTime.now(),
      reminderTime: json["reminderTime"] != null
          ? DateTime.parse(json["reminderTime"])
          : null,
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
    );
  }
}
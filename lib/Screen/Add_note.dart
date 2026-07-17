import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rainbow_edge_lighting/rainbow_edge_lighting.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dataModle.dart';
import 'notification_service.dart';

class AddNoteScreen extends StatefulWidget {
  final NoteModel? editNote;
  final int? editIndex;
  final dynamic template;

  const AddNoteScreen({
    super.key,
    this.editNote,
    this.editIndex,
    this.template,
  });

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // ============================================================
  // CORE VARIABLES
  // ============================================================

  int selectedIndex = 0;
  DateTime? reminderTime;
  String selectedCategory = "Study";

  late final stt.SpeechToText speech;
  bool isListening = false;
  bool isSaving = false;
  String oldSpeechText = "";

  final List<String> categories = ["Study", "Work", "Personal", "Important"];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  final FocusNode titleFocusNode = FocusNode();
  final FocusNode noteFocusNode = FocusNode();
  bool isTitleFocused = false;
  bool isNoteFocused = false;

  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  // Word and char count
  int wordCount = 0;
  int charCount = 0;

  final List<Color> noteColors = [
    const Color(0xffF6E58D),
    const Color(0xffA5D6A7),
    const Color(0xff90CAF9),
    const Color(0xffF48FB1),
    const Color(0xffFFCC80),
    const Color(0xffBDBDBD),
    const Color(0xff5E35B1),
    const Color(0xff009688),
    const Color(0xff607D8B),
    const Color(0xffFF7043),
  ];

  // Full Screen Mode
  bool isFullScreen = false;

  // ============================================================
  // TEXT FORMATTING VARIABLES (Manual)
  // ============================================================

  double fontSize = 16.0;
  Color? textColor;
  TextAlign textAlign = TextAlign.start;

  // ============================================================
  // ANIMATION CONTROLLERS
  // ============================================================

  late final AnimationController _saveButtonController;
  late final Animation<double> _saveButtonScale;
  late final AnimationController _micPulseController;
  late final Animation<double> _micPulseAnimation;
  late final AnimationController _contentFadeController;
  late final Animation<double> _contentFadeAnimation;
  late final AnimationController _fullScreenController;
  late final Animation<double> _fullScreenAnimation;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();

    WidgetsBinding.instance.addObserver(this);

    titleFocusNode.addListener(() {
      if (!mounted) return;
      setState(() => isTitleFocused = titleFocusNode.hasFocus);
    });

    noteFocusNode.addListener(() {
      if (!mounted) return;
      setState(() => isNoteFocused = noteFocusNode.hasFocus);
    });

    noteController.addListener(_updateCount);

    // Initialize animations
    _saveButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _saveButtonScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _saveButtonController,
        curve: Curves.easeInOut,
      ),
    );

    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _micPulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _micPulseController,
        curve: Curves.easeInOut,
      ),
    );

    _contentFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _contentFadeAnimation = CurvedAnimation(
      parent: _contentFadeController,
      curve: Curves.easeOut,
    );

    _fullScreenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fullScreenAnimation = CurvedAnimation(
      parent: _fullScreenController,
      curve: Curves.easeInOut,
    );

    final editNote = widget.editNote;
    if (editNote != null) {
      titleController.text = editNote.title;
      noteController.text = editNote.note;
      selectedCategory = editNote.category;
      reminderTime = editNote.reminderTime;

      if (editNote.imagePath != null && editNote.imagePath!.isNotEmpty) {
        selectedImage = File(editNote.imagePath!);
      }

      final hasCategory = categories.any(
        (e) => e.toLowerCase() == selectedCategory.toLowerCase(),
      );
      if (!hasCategory) categories.add(selectedCategory);

      final colorIndex = noteColors.indexWhere(
        (color) => color.value == editNote.color.value,
      );

      if (colorIndex == -1) {
        noteColors.add(editNote.color);
        selectedIndex = noteColors.length - 1;
      } else {
        selectedIndex = colorIndex;
      }
    } else if (widget.template != null) {
      titleController.text = widget.template.title;
      noteController.text = widget.template.content;
      selectedCategory = widget.template.category;

      final colorIndex = noteColors.indexWhere(
        (c) => c.value == widget.template.color.value,
      );

      if (colorIndex != -1) {
        selectedIndex = colorIndex;
      }
    }
  }

  // ============================================================
  // UPDATE COUNT
  // ============================================================

  void _setListening(bool value) {
    if (!mounted) return;
    setState(() => isListening = value);
    if (value) {
      _micPulseController.repeat(reverse: true);
    } else {
      _micPulseController.stop();
      _micPulseController.value = 0;
    }
  }

  void _updateCount() {
    if (!mounted) return;
    final text = noteController.text;
    setState(() {
      charCount = text.length;
      wordCount =
          text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    });
  }

  void _showTextSizeDialog() {
    double tempSize = fontSize;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff151225) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          "Text Size",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text("A", style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: tempSize,
                        min: 10,
                        max: 36,
                        divisions: 26,
                        label: "${tempSize.round()}px",
                        activeColor: const Color(0xff7F5AF0),
                        onChanged: (value) {
                          setState(() => tempSize = value);
                        },
                      ),
                    ),
                    Text("A", style: TextStyle(fontSize: 36)),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    setState(() => fontSize = tempSize);
                    Navigator.pop(context);
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _showTextColorPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color selectedColor = textColor ?? (isDark ? Colors.white : Colors.black);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff151225) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          "Text Color",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.black,
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.pink,
                    Colors.brown,
                    Colors.teal,
                    Colors.indigo,
                    Colors.amber,
                    Colors.cyan,
                  ].map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedColor = color);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xff7F5AF0)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() => textColor = selectedColor);
                    Navigator.pop(context);
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _showAlignmentDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff151225) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          "Text Alignment",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAlignmentOption(
                TextAlign.left, Icons.format_align_left_rounded),
            _buildAlignmentOption(
                TextAlign.center, Icons.format_align_center_rounded),
            _buildAlignmentOption(
                TextAlign.right, Icons.format_align_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildAlignmentOption(TextAlign align, IconData icon) {
    final isSelected = textAlign == align;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() => textAlign = align);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xff7F5AF0).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xff7F5AF0) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? const Color(0xff7F5AF0)
              : (isDark ? Colors.white70 : Colors.black54),
          size: 28,
        ),
      ),
    );
  }

  // ============================================================
  // LIFECYCLE METHODS
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && isListening) {
      stopListening();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    speech.stop();
    noteController.removeListener(_updateCount);
    titleController.dispose();
    noteController.dispose();
    titleFocusNode.dispose();
    noteFocusNode.dispose();
    _saveButtonController.dispose();
    _micPulseController.dispose();
    _contentFadeController.dispose();
    _fullScreenController.dispose();
    super.dispose();
  }

  // ============================================================
  // UI HELPER METHODS
  // ============================================================

  void showPremiumSnackBar({
    required String message,
    IconData icon = Icons.info_rounded,
    Color color = const Color(0xff7F5AF0),
  }) {
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        duration: const Duration(milliseconds: 1800),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.82),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.18),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VOICE TO NOTE
  // ============================================================

  Future<void> startListening() async {
    HapticFeedback.lightImpact();

    final micStatus = await Permission.microphone.request();
    if (!mounted) return;

    if (!micStatus.isGranted) {
      showPremiumSnackBar(
        message: "Please allow microphone permission for Voice to Note.",
        icon: Icons.mic_off_rounded,
        color: Colors.redAccent,
      );
      return;
    }

    try {
      final available = await speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == "done" || status == "notListening") {
            _setListening(false);
          }
        },
        onError: (error) {
          if (!mounted) return;
          _setListening(false);
          showPremiumSnackBar(
            message: "Voice typing stopped. Please try again.",
            icon: Icons.mic_off_rounded,
            color: Colors.redAccent,
          );
        },
      );

      if (!available) {
        if (!mounted) return;
        showPremiumSnackBar(
          message: "Voice typing not available. Enable Google Voice Typing.",
          icon: Icons.mic_off_rounded,
          color: Colors.orangeAccent,
        );
        return;
      }

      oldSpeechText = noteController.text.trim();

      if (!mounted) return;
      _setListening(true);

      showPremiumSnackBar(
        message: "Listening... speak your note now.",
        icon: Icons.graphic_eq_rounded,
        color: const Color(0xff2CB67D),
      );

      await speech.listen(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        onResult: (result) {
          if (!mounted) return;
          final spoken = result.recognizedWords.trim();
          final newText = oldSpeechText.isEmpty
              ? spoken
              : spoken.isEmpty
                  ? oldSpeechText
                  : "$oldSpeechText $spoken";

          noteController.text = newText;
          noteController.selection = TextSelection.fromPosition(
            TextPosition(offset: noteController.text.length),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      _setListening(false);
      showPremiumSnackBar(
        message: "Voice typing could not start. Please try again.",
        icon: Icons.mic_off_rounded,
        color: Colors.redAccent,
      );
    }
  }

  Future<void> stopListening() async {
    await speech.stop();
    if (!mounted) return;
    _setListening(false);
    showPremiumSnackBar(
      message: "Voice to Note stopped.",
      icon: Icons.check_circle_rounded,
      color: const Color(0xff2CB67D),
    );
  }

  // ============================================================
  // REMINDER METHODS
  // ============================================================

  Future<void> pickReminder() async {
    HapticFeedback.lightImpact();
    final currentTheme = Theme.of(context);

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: reminderTime ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: currentTheme.copyWith(
            colorScheme: currentTheme.colorScheme.copyWith(
              primary: const Color(0xff7F5AF0),
              secondary: const Color(0xffFF6B9A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: reminderTime == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(reminderTime!),
      builder: (context, child) {
        return Theme(
          data: currentTheme.copyWith(
            colorScheme: currentTheme.colorScheme.copyWith(
              primary: const Color(0xff7F5AF0),
              secondary: const Color(0xffFF6B9A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null || !mounted) return;

    final selectedReminder = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (selectedReminder.isBefore(DateTime.now())) {
      showPremiumSnackBar(
        message: "Please choose a future reminder time.",
        icon: Icons.schedule_rounded,
        color: Colors.orangeAccent,
      );
      return;
    }

    setState(() => reminderTime = selectedReminder);

    showPremiumSnackBar(
      message:
          "Reminder set for ${selectedReminder.day}/${selectedReminder.month}/${selectedReminder.year} at ${selectedReminder.hour}:${selectedReminder.minute.toString().padLeft(2, '0')}",
      icon: Icons.notifications_active_rounded,
      color: const Color(0xff2CB67D),
    );
  }

  void clearReminder() {
    setState(() => reminderTime = null);
    showPremiumSnackBar(
      message: "Reminder cleared.",
      icon: Icons.alarm_off_rounded,
      color: Colors.orangeAccent,
    );
  }

  // ============================================================
  // COLOR PICKER
  // ============================================================

  Future<void> pickCustomColor() async {
    Color tempColor = noteColors[selectedIndex];
    final hexController = TextEditingController();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selected = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void applyHexColor(String value) {
              String hex = value.trim().replaceAll("#", "");
              if (hex.length == 6) hex = "FF$hex";
              if (hex.length == 8) {
                final colorValue = int.tryParse(hex, radix: 16);
                if (colorValue != null) {
                  setDialogState(() => tempColor = Color(colorValue));
                }
              }
            }

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xff151522) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                "Pick Custom Color",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: hexController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: "Enter HEX e.g. #FF5733",
                        prefixIcon: const Icon(Icons.tag_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onChanged: applyHexColor,
                    ),
                    const SizedBox(height: 16),
                    ColorPicker(
                      pickerColor: tempColor,
                      onColorChanged: (color) {
                        setDialogState(() => tempColor = color);
                      },
                      pickerAreaHeightPercent: 0.75,
                      displayThumbColor: true,
                      enableAlpha: true,
                      paletteType: PaletteType.hsvWithHue,
                      labelTypes: const [
                        ColorLabelType.rgb,
                        ColorLabelType.hsv,
                        ColorLabelType.hsl,
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(dialogContext).pop(tempColor);
                  },
                  child: const Text("Select"),
                ),
              ],
            );
          },
        );
      },
    );

    hexController.dispose();
    if (!mounted || selected == null) return;

    setState(() {
      final index = noteColors.indexWhere((c) => c.value == selected.value);
      if (index == -1) {
        noteColors.add(selected);
        selectedIndex = noteColors.length - 1;
      } else {
        selectedIndex = index;
      }
    });
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> pickImage() async {
    HapticFeedback.lightImpact();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff151225) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          "Select Image Source",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Color(0xff7F5AF0),
              ),
              title: const Text("Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xffFF6B9A),
              ),
              title: const Text("Camera"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null && mounted) {
        setState(() => selectedImage = File(image.path));
        showPremiumSnackBar(
          message: "Image added to your note.",
          icon: Icons.image_rounded,
          color: const Color(0xff2CB67D),
        );
      }
    } catch (_) {
      if (!mounted) return;
      showPremiumSnackBar(
        message: "Image could not be selected. Please try again.",
        icon: Icons.broken_image_rounded,
        color: Colors.redAccent,
      );
    }
  }

  String reminderLabel() {
    if (reminderTime == null) return "Set Reminder";
    return "${reminderTime!.day}/${reminderTime!.month}/${reminderTime!.year}  ${reminderTime!.hour}:${reminderTime!.minute.toString().padLeft(2, '0')}";
  }

  // ============================================================
  // SAVE NOTE
  // ============================================================

  Future<void> saveNote() async {
    HapticFeedback.mediumImpact();

    final title = titleController.text.trim();
    final note = noteController.text.trim();

    if (title.isEmpty && note.isEmpty) {
      showPremiumSnackBar(
        message: "Add a title and note before saving.",
        icon: Icons.edit_note_rounded,
        color: Colors.orangeAccent,
      );
      return;
    }

    if (title.isEmpty) {
      showPremiumSnackBar(
        message: "Title is required.",
        icon: Icons.title_rounded,
        color: Colors.orangeAccent,
      );
      return;
    }

    if (note.isEmpty) {
      showPremiumSnackBar(
        message: "Note description is required.",
        icon: Icons.notes_rounded,
        color: Colors.orangeAccent,
      );
      return;
    }

    if (reminderTime != null && reminderTime!.isBefore(DateTime.now())) {
      showPremiumSnackBar(
        message: "Reminder time must be in the future.",
        icon: Icons.schedule_rounded,
        color: Colors.orangeAccent,
      );
      return;
    }

    setState(() => isSaving = true);

    final String noteId =
        widget.editNote?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

    final int targetNoteId =
        widget.editNote?.notificationId ?? noteId.hashCode.abs() % 2147483647;

    if (reminderTime != null) {
      try {
        await NotificationService.cancelNotification(targetNoteId);
        final noteText = noteController.text.trim();

        String categoryEmoji(String category) {
          switch (category.toLowerCase()) {
            case "study":
              return "🟦";
            case "work":
              return "🟩";
            case "personal":
              return "🟨";
            case "important":
              return "🟥";
            default:
              return "📝";
          }
        }

        final preview = noteText.length > 120
            ? "${noteText.substring(0, 120)}..."
            : noteText;

        final notificationTitle = "📝 VibeNote • Reminder";

        final notificationBody = "${categoryEmoji(selectedCategory)} $title\n"
            "────────────────\n"
            "$preview\n\n"
            "Tap to open your note";

        await NotificationService.scheduleNotification(
          noteId: noteId,
          id: targetNoteId,
          title: notificationTitle,
          body: notificationBody,
          scheduledTime: reminderTime!,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => isSaving = false);
        showPremiumSnackBar(
          message:
              "Reminder could not be scheduled. Please allow notification permission.",
          icon: Icons.notifications_off_rounded,
          color: Colors.redAccent,
        );
        return;
      }
    } else {
      await NotificationService.cancelNotification(targetNoteId);
    }

    if (!mounted) return;

    Navigator.pop(
      context,
      NoteModel(
        id: noteId,
        title: title,
        note: note,
        color: noteColors[selectedIndex],
        imagePath: selectedImage?.path,
        isFavourite: widget.editNote?.isFavourite ?? false,
        isPinned: widget.editNote?.isPinned ?? false,
        isArchived: widget.editNote?.isArchived ?? false,
        isLocked: widget.editNote?.isLocked ?? false,
        pin: widget.editNote?.pin,
        createdAt: widget.editNote?.createdAt ?? DateTime.now(),
        reminderTime: reminderTime,
        category: selectedCategory,
      ),
    );
  }

  // ============================================================
  // FULL SCREEN MODE
  // ============================================================

  void _toggleFullScreen() {
    setState(() {
      isFullScreen = !isFullScreen;
    });
    if (isFullScreen) {
      _fullScreenController.forward();
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      _fullScreenController.reverse();
    }
    HapticFeedback.mediumImpact();
  }

  Widget _buildFullScreenButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _toggleFullScreen,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.50),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isFullScreen
              ? Icons.fullscreen_exit_rounded
              : Icons.fullscreen_rounded,
          color: isDark ? Colors.white : const Color(0xff151225),
          size: 24,
        ),
      ),
    );
  }

  // ============================================================
  // ANIMATED WIDGETS
  // ============================================================

  Widget _buildAnimatedMicButton() {
    return AnimatedBuilder(
      animation: _micPulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _micPulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isListening
                    ? [Colors.redAccent, Colors.red.shade700]
                    : [const Color(0xff7F5AF0), const Color(0xffFF6B9A)],
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isListening ? Colors.redAccent : const Color(0xff7F5AF0))
                          .withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: isListening ? 10 : 5,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () async {
                  if (!isListening) {
                    await startListening();
                  } else {
                    await stopListening();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSaveButton() {
    return AnimatedBuilder(
      animation: _saveButtonScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _saveButtonScale.value,
          child: _SaveButton(
            isSaving: isSaving,
            text: widget.editNote == null ? "Save Note" : "Update Note",
            onTap: isSaving ? () {} : saveNote,
          ),
        );
      },
    );
  }

  // ============================================================
  // CATEGORY POPUP (Glass UI)
  // ============================================================

  Widget _buildCategoryDropdown(bool isDark) {
    return GestureDetector(
      onTap: () {
        _showGlassCategoryPicker(isDark);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.62),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _categoryColor(selectedCategory).withOpacity(0.16),
              ),
              child: Icon(
                _categoryIcon(selectedCategory),
                color: _categoryColor(selectedCategory),
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedCategory,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xff151225),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white : const Color(0xff151225),
            ),
          ],
        ),
      ),
    );
  }

  void _showGlassCategoryPicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xff151225).withOpacity(0.96)
                    : Colors.white.withOpacity(0.96),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.20)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text(
                    "Select Category",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...categories.map((category) {
                    final isSelected = selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => selectedCategory = category);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xff7F5AF0).withOpacity(0.16)
                                : (isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.black.withOpacity(0.03)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xff7F5AF0).withOpacity(0.45)
                                  : Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 34,
                                width: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _categoryColor(category)
                                      .withOpacity(0.16),
                                ),
                                child: Icon(
                                  _categoryIcon(category),
                                  color: _categoryColor(category),
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xff151225),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xff7F5AF0),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // LISTENING INDICATOR
  // ============================================================

  Widget _buildListeningIndicator(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withOpacity(0.28)),
      ),
      child: const Row(
        children: [
          Icon(Icons.mic_rounded, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Voice to Note is ON — speak now...",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = noteColors[selectedIndex];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
          isDark ? const Color(0xff090A12) : const Color(0xffF8F5FF),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xff090A12),
                    selectedColor.withOpacity(0.25),
                    const Color(0xff17122B),
                  ]
                : [
                    const Color(0xffFFF9FD),
                    selectedColor.withOpacity(0.45),
                    const Color(0xffF3ECFF),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: isFullScreen
              ? _buildFullScreenContent(isDark, selectedColor)
              : _buildNormalContent(isDark, selectedColor),
        ),
      ),
    );
  }

  // ============================================================
  // NORMAL CONTENT
  // ============================================================

  Widget _buildNormalContent(bool isDark, Color selectedColor) {
    return Stack(
      children: [
        Positioned(
          top: -70,
          right: -50,
          child: _GlowBlob(
            color: const Color(0xff7F5AF0).withOpacity(0.35),
            size: 210,
          ),
        ),
        Positioned(
          bottom: 80,
          left: -70,
          child: _GlowBlob(
            color: const Color(0xffFF6B9A).withOpacity(0.25),
            size: 230,
          ),
        ),
        Column(
          children: [
            _PremiumHeader(
              title: widget.editNote == null ? "Create Note" : "Edit Note",
              subtitle: widget.editNote == null
                  ? "Capture your ideas in VibeNote"
                  : "Update your note",
              isDark: isDark,
              onBack: () {
                if (isFullScreen) {
                  setState(() => isFullScreen = false);
                } else {
                  Navigator.pop(context);
                }
              },
              fullScreenButton: _buildFullScreenButton(),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 10,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: FadeTransition(
                  opacity: _contentFadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      RainbowEdgeLighting(
                        enabled: isTitleFocused,
                        radius: 24,
                        child: _GlassField(
                          isDark: isDark,
                          child: TextField(
                            focusNode: titleFocusNode,
                            controller: titleController,
                            autofocus: widget.editNote == null,
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xff151225),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                            decoration: InputDecoration(
                              hintText: "Note title",
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontWeight: FontWeight.w800,
                              ),
                              prefixIcon: Icon(
                                Icons.title_rounded,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xff7F5AF0),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Note field with formatting
                      RainbowEdgeLighting(
                        enabled: isNoteFocused,
                        radius: 28,
                        child: _GlassField(
                          isDark: isDark,
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 240,
                                child: TextField(
                                  focusNode: noteFocusNode,
                                  controller: noteController,
                                  maxLines: null,
                                  expands: true,
                                  keyboardType: TextInputType.multiline,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: TextStyle(
                                    color: textColor ??
                                        (isDark ? Colors.white : Colors.black),
                                    fontSize: fontSize,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Write your note...",
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                      fontSize: fontSize,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  textAlign: textAlign,
                                ),
                              ),
                              // Word and char count row
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 6,
                                  bottom: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      Icons.text_fields_rounded,
                                      size: 13,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$wordCount words · $charCount chars",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Category
                      _SectionTitle(
                        title: "Category",
                        icon: Icons.category_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildCategoryDropdown(isDark),
                      const SizedBox(height: 18),

                      // Media
                      _SectionTitle(
                        title: "Media",
                        icon: Icons.image_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _ActionButton(
                        text: selectedImage == null
                            ? "Add Image"
                            : "Change Image",
                        icon: Icons.image_rounded,
                        gradient: const [
                          Color(0xff7F5AF0),
                          Color(0xffFF6B9A),
                        ],
                        onTap: pickImage,
                      ),
                      if (selectedImage != null) ...[
                        const SizedBox(height: 14),
                        _buildImagePreview(),
                      ],
                      const SizedBox(height: 18),

                      // Color picker
                      _SectionTitle(
                        title: "Pick Color",
                        icon: Icons.palette_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildColorPicker(isDark),
                      const SizedBox(height: 20),

                      const SizedBox(height: 12),

                      // Reminder button
                      _ActionButton(
                        text: reminderTime == null
                            ? "Set Reminder"
                            : "📅 ${reminderLabel()}",
                        icon: Icons.notifications_active_rounded,
                        gradient: const [
                          Color(0xff7F5AF0),
                          Color(0xff00C2FF),
                        ],
                        onTap: pickReminder,
                      ),

                      if (reminderTime != null) ...[
                        const SizedBox(height: 10),
                        _ActionButton(
                          text: "Clear Reminder",
                          icon: Icons.alarm_off_rounded,
                          gradient: const [
                            Color(0xffFF6B9A),
                            Color(0xffFF4B2B),
                          ],
                          onTap: clearReminder,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Save button
                      _buildAnimatedSaveButton(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // FULL SCREEN CONTENT
  // ============================================================

  Widget _buildFullScreenContent(bool isDark, Color selectedColor) {
    return AnimatedBuilder(
      animation: _fullScreenAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fullScreenAnimation.value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * _fullScreenAnimation.value),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xff090A12),
                          selectedColor.withOpacity(0.25),
                          const Color(0xff17122B),
                        ]
                      : [
                          const Color(0xffFFF9FD),
                          selectedColor.withOpacity(0.45),
                          const Color(0xffF3ECFF),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  _PremiumHeader(
                    title: "Full Screen",
                    subtitle: "Write without distractions",
                    isDark: isDark,
                    onBack: _toggleFullScreen,
                    fullScreenButton: _buildFullScreenButton(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Full screen note editor
                          Expanded(
                            child: RainbowEdgeLighting(
                              enabled: isNoteFocused,
                              radius: 28,
                              child: _GlassField(
                                isDark: isDark,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        focusNode: noteFocusNode,
                                        controller: noteController,
                                        maxLines: null,
                                        expands: true,
                                        keyboardType: TextInputType.multiline,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        textAlignVertical:
                                            TextAlignVertical.top,
                                        style: TextStyle(
                                          color: textColor ??
                                              (isDark
                                                  ? Colors.white
                                                  : Colors.black),
                                          fontSize: fontSize + 4,
                                          height: 1.6,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "Write your note...",
                                          hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black38,
                                            fontSize: fontSize + 4,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        textAlign: textAlign,
                                      ),
                                    ),
                                    // Stats with Voice Button
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "$wordCount words · $charCount chars",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          _buildAnimatedMicButton(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Save button
                          _buildAnimatedSaveButton(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD HELPER WIDGETS
  // ============================================================

  Widget _buildColorPicker(bool isDark) {
    return SizedBox(
      height: 58,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: noteColors.length + 1,
        itemBuilder: (context, index) {
          if (index == noteColors.length) {
            return _ColorPickerAddButton(
              onTap: pickCustomColor,
            );
          }
          final isSelected = selectedIndex == index;
          return _ColorCircle(
            color: noteColors[index],
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => selectedIndex = index);
            },
          );
        },
      ),
    );
  }

  Widget _buildImagePreview() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.file(
                        selectedImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
              child: Image.file(
                selectedImage!,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => selectedImage = null);
                  showPremiumSnackBar(
                    message: "Image removed.",
                    icon: Icons.delete_outline_rounded,
                    color: Colors.orangeAccent,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.zoom_in_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Tap to zoom",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HELPER WIDGETS (From Original Code)
// ============================================================

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case "study":
      return Icons.school_rounded;
    case "work":
      return Icons.business_center_rounded;
    case "personal":
      return Icons.person_sharp;
    case "important":
      return Icons.priority_high_rounded;
    default:
      return Icons.folder_rounded;
  }
}

Color _categoryColor(String category) {
  switch (category.toLowerCase()) {
    case "study":
      return const Color(0xff4F8CFF);
    case "work":
      return const Color(0xff7F5AF0);
    case "personal":
      return const Color(0xff2CB67D);
    case "important":
      return const Color(0xffFF6B9A);
    default:
      return const Color(0xff7F5AF0);
  }
}

class _PremiumHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onBack;
  final Widget? fullScreenButton;

  const _PremiumHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onBack,
    this.fullScreenButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: _GlassCircleIcon(
              icon: Icons.arrow_back_ios_new_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xff151225),
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (fullScreenButton != null) ...[
            fullScreenButton!,
            const SizedBox(width: 8),
          ],
          _GlassCircleIcon(icon: Icons.auto_awesome_rounded, isDark: isDark),       ],
      ),
    );
  }
}

class _GlassCircleIcon extends StatelessWidget {
  final IconData icon;
  final bool isDark;

  const _GlassCircleIcon({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.58),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white : const Color(0xff151225),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  const _GlassField({
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xff7F5AF0)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xff151225),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final String text;
  final VoidCallback onTap;

  const _SaveButton({
    required this.isSaving,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: isSaving ? null : onTap,
        child: Ink(
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSaving
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : const [Color(0xff7F5AF0), Color(0xffFF6B9A)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xff7F5AF0).withOpacity(isSaving ? 0.10 : 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 54.0 : 48.0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(4),
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isSelected ? 0.70 : 0.22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(isSelected ? 0.75 : 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.32)
                  : Colors.black.withOpacity(0.03),
              blurRadius: isSelected ? 14 : 4,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: isSelected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
              : null,
        ),
      ),
    );
  }
}

class _ColorPickerAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ColorPickerAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.purple,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

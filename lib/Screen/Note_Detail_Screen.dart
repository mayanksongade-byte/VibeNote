import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dataModle.dart';

class NoteDetailScreen extends StatefulWidget {
  final NoteModel note;
  final VoidCallback onEdit;
  final VoidCallback onBack;

  const NoteDetailScreen({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onBack,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  // ✅ track if content is expanded
  bool isExpanded = false;

  String formatDate(DateTime date) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  String formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return "${formatDate(date)} at $hour:$min";
  }

  void openImage(BuildContext context) {
    if (widget.note.imagePath == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            // ✅ download/share image from viewer
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: () {
                  Share.shareXFiles([XFile(widget.note.imagePath!)]);
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(widget.note.imagePath!),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text(
                    "Image not found",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void copyNote(BuildContext context) {
    Clipboard.setData(
      ClipboardData(
        text:
        "${widget.note.title}\n\n${widget.note.note}",
      ),
    );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text("Note copied to clipboard"),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xff2CB67D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  void shareNote() {
    final text =
        "📝 ${widget.note.title}\n\n${widget.note.note}\n\n— Shared from VibeNote";
    Share.share(text);
  }

  // ✅ share note as text + image together
  void shareNoteWithImage() {
    if (widget.note.imagePath != null) {
      Share.shareXFiles(
        [XFile(widget.note.imagePath!)],
        text:
        "📝 ${widget.note.title}\n\n${widget.note.note}\n\n— Shared from VibeNote",
      );
    } else {
      shareNote();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final note = widget.note;

    return Scaffold(
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xff7F5AF0), Color(0xffFF6B9A)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff7F5AF0).withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: "editNoteDetail",
          elevation: 0,
          backgroundColor: Colors.transparent,
          onPressed: widget.onEdit,
          child:
          const Icon(Icons.edit_rounded, color: Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
              Color(0xff090A12),
              Color(0xff17122B),
              Color(0xff261A3D),
            ]
                : const [
              Color(0xffF8F5FF),
              Color(0xffFFEAF3),
              Color(0xffEEF7FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -70,
              child: _glowCircle(
                const Color(0xff7F5AF0).withOpacity(0.30),
                220,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: _glowCircle(
                const Color(0xffFF6B9A).withOpacity(0.24),
                240,
              ),
            ),
            SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.fromLTRB(18, 12, 18, 100),
                children: [
                  _topBar(context, isDark),
                  const SizedBox(height: 18),

                  // ✅ Main note card
                  _glassCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          note.title.isEmpty
                              ? "Untitled Note"
                              : note.title,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xff151225),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Chips row
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip(
                              Icons.category_rounded,
                              note.category,
                              isDark,
                            ),
                            _chip(
                              Icons.calendar_month_rounded,
                              formatDate(note.createdAt),
                              isDark,
                            ),
                            if (note.isPinned)
                              _chip(
                                Icons.push_pin_rounded,
                                "Pinned",
                                isDark,
                                color: const Color(0xff7F5AF0),
                              ),
                            if (note.isFavourite)
                              _chip(
                                Icons.favorite_rounded,
                                "Favourite",
                                isDark,
                                color: Colors.redAccent,
                              ),
                            if (note.isLocked)
                              _chip(
                                Icons.lock_rounded,
                                "Locked",
                                isDark,
                                color: Colors.orangeAccent,
                              ),
                            if (note.reminderTime != null)
                              _chip(
                                note.isReminderExpired
                                    ? Icons.alarm_off_rounded
                                    : Icons.alarm_rounded,
                                note.isReminderExpired
                                    ? "Reminder Passed"
                                    : "Reminder Set",
                                isDark,
                                color: note.isReminderExpired
                                    ? Colors.redAccent
                                    : const Color(0xff2CB67D),
                              ),
                          ],
                        ),

                        // ✅ reminder time display
                        if (note.reminderTime != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: (note.isReminderExpired
                                  ? Colors.redAccent
                                  : const Color(0xff7F5AF0))
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (note.isReminderExpired
                                    ? Colors.redAccent
                                    : const Color(0xff7F5AF0))
                                    .withOpacity(0.30),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  note.isReminderExpired
                                      ? Icons.alarm_off_rounded
                                      : Icons.alarm_rounded,
                                  size: 18,
                                  color: note.isReminderExpired
                                      ? Colors.redAccent
                                      : const Color(0xff7F5AF0),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Reminder: ${formatDateTime(note.reminderTime!)}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Image
                        if (note.imagePath != null) ...[
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => openImage(context),
                            child: ClipRRect(
                              borderRadius:
                              BorderRadius.circular(26),
                              child: Stack(
                                children: [
                                  Image.file(
                                    File(note.imagePath!),
                                    height: 240,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return Container(
                                        height: 180,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withOpacity(0.12),
                                          borderRadius:
                                          BorderRadius.circular(
                                              26),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .broken_image_rounded,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                              size: 38,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Image not found",
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    right: 12,
                                    bottom: 12,
                                    child: Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withOpacity(0.45),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.fullscreen_rounded,
                                            color: Colors.white,
                                            size: 15,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            "Tap to preview",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight:
                                              FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Divider
                        Container(
                          height: 1,
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06),
                        ),
                        const SizedBox(height: 20),

                        // Note content
                        Text(
                          note.note.isEmpty
                              ? "No content added."
                              : note.note,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : Colors.black87,
                            fontSize: 16,
                            height: 1.7,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ✅ word & char count footer
                        if (note.note.isNotEmpty) ...[
                          Container(
                            height: 1,
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.05),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.text_fields_rounded,
                                size: 14,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${note.wordCount} words  ·  ${note.charCount} characters",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, bool isDark) {
    return Row(
      children: [
        _glassIcon(
          isDark: isDark,
          icon: Icons.arrow_back_rounded,
          onTap: widget.onBack,
        ),
        const Spacer(),

        // ✅ copy button
        _glassIcon(
          isDark: isDark,
          icon: Icons.copy_rounded,
          onTap: () => copyNote(context),
        ),
        const SizedBox(width: 10),

        // ✅ share with image support
        _glassIcon(
          isDark: isDark,
          icon: Icons.share_rounded,
          onTap: shareNoteWithImage,
        ),

        // ✅ more options
        const SizedBox(width: 10),
        _glassIcon(
          isDark: isDark,
          icon: Icons.more_vert_rounded,
          onTap: () => _showMoreOptions(context, isDark),
        ),
      ],
    );
  }

  // ✅ more options bottom sheet
  void _showMoreOptions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ClipRRect(
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xff151225).withOpacity(0.96)
                    : Colors.white.withOpacity(0.96),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color:
                      isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Note info
                  Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.note.color.withOpacity(0.3),
                        ),
                        child: Icon(
                          Icons.sticky_note_2_rounded,
                          color: isDark
                              ? Colors.white
                              : const Color(0xff151225),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.note.title.isEmpty
                                  ? "Untitled Note"
                                  : widget.note.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xff151225),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Created ${formatDate(widget.note.createdAt)}",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _optionTile(
                    isDark: isDark,
                    icon: Icons.copy_rounded,
                    color: const Color(0xff7F5AF0),
                    label: "Copy Note",
                    onTap: () {
                      Navigator.pop(context);
                      copyNote(context);
                    },
                  ),
                  _optionTile(
                    isDark: isDark,
                    icon: Icons.share_rounded,
                    color: const Color(0xff2CB67D),
                    label: "Share Note",
                    onTap: () {
                      Navigator.pop(context);
                      shareNote();
                    },
                  ),
                  if (widget.note.imagePath != null)
                    _optionTile(
                      isDark: isDark,
                      icon: Icons.image_rounded,
                      color: Colors.blueAccent,
                      label: "Share with Image",
                      onTap: () {
                        Navigator.pop(context);
                        shareNoteWithImage();
                      },
                    ),
                  _optionTile(
                    isDark: isDark,
                    icon: Icons.edit_rounded,
                    color: Colors.orangeAccent,
                    label: "Edit Note",
                    onTap: () {
                      Navigator.pop(context);
                      widget.onEdit();
                    },
                  ),

                  // ✅ note stats
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                      children: [
                        _statChip(
                          isDark,
                          Icons.text_fields_rounded,
                          "${widget.note.wordCount}",
                          "Words",
                        ),
                        _statChip(
                          isDark,
                          Icons.abc_rounded,
                          "${widget.note.charCount}",
                          "Chars",
                        ),
                        _statChip(
                          isDark,
                          Icons.category_rounded,
                          widget.note.category,
                          "Category",
                        ),
                      ],
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

  Widget _statChip(
      bool isDark, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon,
            size: 18,
            color: isDark
                ? Colors.white60
                : const Color(0xff7F5AF0)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xff151225),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.black45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _optionTile({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.14),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xff151225),
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: isDark ? Colors.white38 : Colors.black26,
      ),
    );
  }

  Widget _glassIcon({
    required bool isDark,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.60),
              borderRadius: BorderRadius.circular(18),
              border:
              Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Icon(
              icon,
              color: isDark
                  ? Colors.white
                  : const Color(0xff151225),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassCard({
    required bool isDark,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: widget.note.color
                .withOpacity(isDark ? 0.28 : 0.45),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: Colors.white.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(isDark ? 0.30 : 0.10),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _chip(
      IconData icon,
      String text,
      bool isDark, {
        Color? color,
      }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: (color ?? Colors.white)
            .withOpacity(isDark ? 0.12 : 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? const Color(0xff7F5AF0),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color:
              isDark ? Colors.white70 : Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
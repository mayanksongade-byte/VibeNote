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

class _NoteDetailScreenState extends State<NoteDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _statsController;
  late final Animation<double> _statsAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutCubic,
      ),
    );

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _statsAnimation = CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
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
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
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
      ),
    );
  }

  void copyNote(BuildContext context) {
    Clipboard.setData(
      ClipboardData(
        text: "${widget.note.title}\n\n${widget.note.note}",
      ),
    );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Note copied to clipboard ✅",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xff2CB67D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 2000),
        elevation: 4,
      ),
    );
  }

  void shareNote() {
    final text =
        "📝 ${widget.note.title}\n\n${widget.note.note}\n\n— Shared from VibeNote";
    Share.share(text);
  }

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

  Widget _buildPremiumSnackBar({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SnackBar(
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.black.withOpacity(0.82),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.18),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      duration: const Duration(milliseconds: 2000),
    );
  }

  Widget _buildNoteContent(bool isDark, NoteModel note) {
    return Text(
      note.note.isEmpty ? "No content added." : note.note,
      style: TextStyle(
        color: isDark ? Colors.white70 : Colors.black87,
        fontSize: 16,
        height: 1.7,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final note = widget.note;

    return Scaffold(
      floatingActionButton: _buildAnimatedFAB(isDark),
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
              child: _buildGlowCircle(
                const Color(0xff7F5AF0).withOpacity(0.30),
                220,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: _buildGlowCircle(
                const Color(0xffFF6B9A).withOpacity(0.24),
                240,
              ),
            ),
            Positioned(
              top: 200,
              left: -50,
              child: _buildGlowCircle(
                const Color(0xff00C2FF).withOpacity(0.12),
                180,
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                    children: [
                      _buildTopBar(context, isDark),
                      const SizedBox(height: 18),
                      _buildNoteCard(isDark, note),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Row(
      children: [
        _buildGlassIcon(
          isDark: isDark,
          icon: Icons.arrow_back_rounded,
          onTap: widget.onBack,
        ),
        const Spacer(),
        _buildGlassIcon(
          isDark: isDark,
          icon: Icons.copy_rounded,
          onTap: () => copyNote(context),
        ),
        const SizedBox(width: 10),
        _buildGlassIcon(
          isDark: isDark,
          icon: Icons.share_rounded,
          onTap: shareNoteWithImage,
        ),
        const SizedBox(width: 10),
        _buildGlassIcon(
          isDark: isDark,
          icon: Icons.more_vert_rounded,
          onTap: () => _showPremiumOptions(context, isDark),
        ),
      ],
    );
  }

  Widget _buildGlassIcon({
    required bool isDark,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.1),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
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
                border: Border.all(color: Colors.white.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : const Color(0xff151225),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(bool isDark, NoteModel note) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                note.color.withOpacity(isDark ? 0.28 : 0.45),
                note.color.withOpacity(isDark ? 0.12 : 0.25),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.15 : 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.30 : 0.10),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: note.color.withOpacity(isDark ? 0.10 : 0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isEmpty ? "Untitled Note" : note.title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xff151225),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              _buildChipsRow(isDark, note),
              const SizedBox(height: 16),
              if (note.reminderTime != null) _buildReminderCard(isDark, note),
              if (note.reminderTime != null) const SizedBox(height: 16),
              if (note.imagePath != null) _buildImageCard(isDark, note),
              if (note.imagePath != null) const SizedBox(height: 20),
              Container(
                height: 1,
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
              const SizedBox(height: 18),
              _buildNoteContent(isDark, note),
              const SizedBox(height: 18),
              Container(
                height: 1,
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.05),
              ),
              const SizedBox(height: 14),
              _buildStatsFooter(isDark, note),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipsRow(bool isDark, NoteModel note) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildGlassChip(
          icon: Icons.category_rounded,
          text: note.category,
          isDark: isDark,
          color: const Color(0xff7F5AF0),
        ),
        _buildGlassChip(
          icon: Icons.calendar_month_rounded,
          text: formatDate(note.createdAt),
          isDark: isDark,
          color: Colors.blueAccent,
        ),
        if (note.isPinned)
          _buildGlassChip(
            icon: Icons.push_pin_rounded,
            text: "Pinned",
            isDark: isDark,
            color: const Color(0xff7F5AF0),
          ),
        if (note.isFavourite)
          _buildGlassChip(
            icon: Icons.favorite_rounded,
            text: "Favourite",
            isDark: isDark,
            color: Colors.redAccent,
          ),
        if (note.isLocked)
          _buildGlassChip(
            icon: Icons.lock_rounded,
            text: "Locked",
            isDark: isDark,
            color: Colors.orangeAccent,
          ),
        if (note.reminderTime != null)
          _buildGlassChip(
            icon: note.isReminderExpired
                ? Icons.alarm_off_rounded
                : Icons.alarm_rounded,
            text: note.isReminderExpired ? "Reminder Passed" : "Reminder Set",
            isDark: isDark,
            color: note.isReminderExpired
                ? Colors.redAccent
                : const Color(0xff2CB67D),
          ),
      ],
    );
  }

  Widget _buildGlassChip({
    required IconData icon,
    required String text,
    required bool isDark,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.30 : 0.40),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(bool isDark, NoteModel note) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (note.isReminderExpired
            ? Colors.redAccent
            : const Color(0xff7F5AF0))
            .withOpacity(0.10),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (note.isReminderExpired
                  ? Colors.redAccent
                  : const Color(0xff7F5AF0))
                  .withOpacity(0.15),
            ),
            child: Icon(
              note.isReminderExpired
                  ? Icons.alarm_off_rounded
                  : Icons.alarm_rounded,
              size: 18,
              color: note.isReminderExpired
                  ? Colors.redAccent
                  : const Color(0xff7F5AF0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.isReminderExpired ? "Reminder Passed" : "Reminder Set",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Text(
                  formatDateTime(note.reminderTime!),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(bool isDark, NoteModel note) {
    return GestureDetector(
      onTap: () => openImage(context),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Image.file(
                File(note.imagePath!),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 180,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size: 38,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Image not found",
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.50),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.20),
                    ),
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.image_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Image",
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
      ),
    );
  }

  Widget _buildStatsFooter(bool isDark, NoteModel note) {
    return FadeTransition(
      opacity: _statsAnimation,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.text_fields_rounded,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 6),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: note.wordCount),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Text(
                      "$value words",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Container(
                  height: 14,
                  width: 1,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.abc_rounded,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 6),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: note.charCount),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Text(
                      "$value chars",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 6),
                Text(
                  note.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumOptions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  _buildMenuHeader(isDark),
                  const SizedBox(height: 16),
                  _buildMenuOption(
                    isDark: isDark,
                    icon: Icons.copy_rounded,
                    color: const Color(0xff7F5AF0),
                    label: "Copy Note",
                    onTap: () {
                      Navigator.pop(context);
                      copyNote(context);
                    },
                  ),
                  _buildMenuOption(
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
                    _buildMenuOption(
                      isDark: isDark,
                      icon: Icons.image_rounded,
                      color: Colors.blueAccent,
                      label: "Share with Image",
                      onTap: () {
                        Navigator.pop(context);
                        shareNoteWithImage();
                      },
                    ),
                  _buildMenuOption(
                    isDark: isDark,
                    icon: Icons.edit_rounded,
                    color: Colors.orangeAccent,
                    label: "Edit Note",
                    onTap: () {
                      Navigator.pop(context);
                      widget.onEdit();
                    },
                  ),
                  _buildMenuOption(
                    isDark: isDark,
                    icon: Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    label: "Delete Note",
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(isDark);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuStats(isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuHeader(bool isDark) {
    final note = widget.note;
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                note.color.withOpacity(0.4),
                note.color.withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.20),
            ),
          ),
          child: Icon(
            Icons.sticky_note_2_rounded,
            color: isDark ? Colors.white : const Color(0xff151225),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isEmpty ? "Untitled Note" : note.title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xff151225),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "Created ${formatDate(note.createdAt)}",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.14),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xff151225),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuStats(bool isDark) {
    final note = widget.note;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              isDark, Icons.text_fields_rounded, "${note.wordCount}", "Words"),
          _buildStatItem(
              isDark, Icons.abc_rounded, "${note.charCount}", "Chars"),
          _buildStatItem(
              isDark, Icons.category_rounded, note.category, "Category"),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      bool isDark, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white60 : const Color(0xff7F5AF0),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xff151225),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isDark ? Colors.white54 : Colors.black45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff151225) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          "Delete Note?",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          "This note will be deleted permanently. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onBack();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFAB(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
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
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.3,
              spreadRadius: size * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}
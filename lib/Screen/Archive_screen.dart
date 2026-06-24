import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dataModle.dart';
import 'Note_Detail_Screen.dart';
import 'Add_note.dart';

class ArchiveScreen extends StatefulWidget {
  final List<NoteModel> notes;
  final Function(NoteModel) onRestore;
  final Function(NoteModel) onDelete;

  const ArchiveScreen({
    super.key,
    required this.notes,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  // ✅ search inside archive
  final TextEditingController searchController =
  TextEditingController();
  bool isSearching = false;
  String searchQuery = "";

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  // ✅ mounted check added
  void showMessage(String message, {bool danger = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
        danger ? Colors.redAccent : const Color(0xff7F5AF0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<bool> confirmDelete(bool isDark) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDark ? const Color(0xff151225) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          "Delete Note?",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          "This note will be permanently deleted. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ✅ confirm delete all archived notes
  Future<void> deleteAllArchived(bool isDark) async {
    final archivedNotes =
    widget.notes.where((n) => n.isArchived).toList();
    if (archivedNotes.isEmpty) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? const Color(0xff151225) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          "Delete All Archived?",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          "This will permanently delete all ${archivedNotes.length} archived notes. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete All"),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      for (final note in archivedNotes) {
        widget.onDelete(note);
      }
      if (mounted) setState(() {});
      showMessage(
        "All archived notes deleted",
        danger: true,
      );
    }
  }

  List<NoteModel> get archivedNotes {
    final archived =
    widget.notes.where((e) => e.isArchived).toList();
    if (searchQuery.trim().isEmpty) return archived;
    final q = searchQuery.toLowerCase().trim();
    return archived.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.note.toLowerCase().contains(q) ||
          n.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final archived = archivedNotes;

    return Scaffold(
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
              Color(0xffFFF3E8),
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
                Colors.orange.withOpacity(0.30),
                230,
              ),
            ),
            Positioned(
              bottom: -90,
              left: -80,
              child: _glowCircle(
                const Color(0xff7F5AF0).withOpacity(0.30),
                240,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _topBar(isDark),
                  _headerCard(isDark, archived.length),
                  const SizedBox(height: 8),

                  // ✅ search bar
                  _searchBar(isDark),
                  const SizedBox(height: 8),

                  Expanded(
                    child: archived.isEmpty
                        ? _emptyState(isDark)
                        : GridView.builder(
                      physics:
                      const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          16, 0, 16, 22),
                      itemCount: archived.length,
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                        MediaQuery.of(context)
                            .size
                            .width >
                            600
                            ? 3
                            : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemBuilder: (context, index) {
                        final note = archived[index];
                        return TweenAnimationBuilder<
                            double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(
                            milliseconds:
                            280 + (index * 50),
                          ),
                          curve: Curves.easeOutCubic,
                          builder:
                              (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale:
                                0.94 + (value * 0.06),
                                child: child,
                              ),
                            );
                          },
                          child:
                          _archiveCard(note, isDark),
                        );
                      },
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

  Widget _topBar(bool isDark) {
    final hasArchived =
    widget.notes.any((n) => n.isArchived);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          _glassIconButton(
            icon: Icons.arrow_back_rounded,
            isDark: isDark,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Archived Notes",
              style: TextStyle(
                color: isDark
                    ? Colors.white
                    : const Color(0xff151225),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          // ✅ search toggle
          _glassIconButton(
            icon: isSearching
                ? Icons.search_off_rounded
                : Icons.search_rounded,
            isDark: isDark,
            color: const Color(0xff7F5AF0),
            onTap: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                  searchQuery = "";
                }
              });
            },
          ),
          const SizedBox(width: 8),

          // ✅ delete all archived button
          if (hasArchived) ...[
            _glassIconButton(
              icon: Icons.delete_sweep_rounded,
              isDark: isDark,
              color: Colors.redAccent,
              onTap: () => deleteAllArchived(isDark),
            ),
            const SizedBox(width: 8),
          ],

          _glassIconButton(
            icon: Icons.inventory_2_rounded,
            isDark: isDark,
            color: Colors.orange,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _searchBar(bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isSearching
          ? Padding(
        key: const ValueKey("search"),
        padding:
        const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter:
            ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: TextField(
              controller: searchController,
              autofocus: true,
              onChanged: (v) =>
                  setState(() => searchQuery = v),
              style: TextStyle(
                color: isDark
                    ? Colors.white
                    : const Color(0xff151225),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: "Search archived notes...",
                hintStyle: TextStyle(
                  color: isDark
                      ? Colors.white54
                      : Colors.black45,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.orange,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? Colors.white54
                        : Colors.black45,
                  ),
                  onPressed: () {
                    searchController.clear();
                    setState(
                            () => searchQuery = "");
                  },
                )
                    : null,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.72),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
              ),
            ),
          ),
        ),
      )
          : const SizedBox(
          key: ValueKey("no-search"), height: 0),
    );
  }

  Widget _headerCard(bool isDark, int count) {
    return _glassBox(
      isDark: isDark,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xffFF9800),
                  Color(0xffFF6B9A),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.archive_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$count Archived",
                  style: TextStyle(
                    color: isDark
                        ? Colors.white
                        : const Color(0xff151225),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Restore or permanently delete old notes",
                  style: TextStyle(
                    color: isDark
                        ? Colors.white60
                        : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    final isSearchEmpty = searchQuery.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _glassBox(
          isDark: isDark,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withOpacity(0.14),
                ),
                child: Icon(
                  isSearchEmpty
                      ? Icons.search_off_rounded
                      : Icons.inventory_2_outlined,
                  color: isSearchEmpty
                      ? Colors.redAccent
                      : Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isSearchEmpty
                    ? "Nothing matched"
                    : "No archived notes",
                style: TextStyle(
                  color: isDark
                      ? Colors.white
                      : const Color(0xff151225),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearchEmpty
                    ? "Try a different keyword."
                    : "Swipe a note left on home screen to archive it.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? Colors.white60
                      : Colors.black54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _archiveCard(NoteModel note, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        // ✅ tap to open note detail
        if (!note.isLocked) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteDetailScreen(
                note: note,
                onBack: () => Navigator.pop(context),
                onEdit: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddNoteScreen(editNote: note),
                    ),
                  ).then((updated) {
                    if (updated != null && mounted) {
                      final idx =
                      widget.notes.indexOf(note);
                      if (idx != -1) {
                        setState(() {
                          widget.notes[idx] = updated;
                        });
                      }
                    }
                  });
                },
              ),
            ),
          );
        }
      },
      child: _glassBox(
        isDark: isDark,
        padding: const EdgeInsets.all(13),
        child: note.isLocked
            ? _lockedCard(note, isDark)
            : _normalCard(note, isDark),
      ),
    );
  }

  Widget _lockedCard(NoteModel note, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xff7F5AF0),
                Color(0xffFF6B9A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff7F5AF0)
                    .withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Locked Note",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: isDark
                ? Colors.white
                : const Color(0xff151225),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "Private archive",
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 11,
          ),
        ),
        const Spacer(),
        _actionRow(note, isDark),
      ],
    );
  }

  Widget _normalCard(NoteModel note, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                note.title.isEmpty
                    ? "Untitled"
                    : note.title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: isDark
                      ? Colors.white
                      : const Color(0xff151225),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const Icon(
              Icons.archive_rounded,
              color: Colors.orange,
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 12,
              color: isDark
                  ? Colors.white60
                  : Colors.black45,
            ),
            const SizedBox(width: 4),
            Text(
              formatDate(note.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? Colors.white60
                    : Colors.black45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Text(
            note.note.isEmpty
                ? "No content"
                : note.note,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: isDark
                  ? Colors.white70
                  : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _categoryChip(note.category, isDark),
            const Spacer(),
            // ✅ word count
            Text(
              "${note.wordCount}w",
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? Colors.white38
                    : Colors.black38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _actionRow(note, isDark),
      ],
    );
  }

  Widget _categoryChip(String category, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark
              ? Colors.white70
              : const Color(0xff151225),
        ),
      ),
    );
  }

  Widget _actionRow(NoteModel note, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _smallButton(
            icon: Icons.restore_rounded,
            label: "Restore",
            color: Colors.green,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onRestore(note);
              if (mounted) setState(() {});
              showMessage("Note restored ✅");
            },
          ),
        ),
        const SizedBox(width: 8),
        // ✅ locked note delete also needs confirmation
        _roundIcon(
          icon: Icons.delete_forever_rounded,
          color: Colors.redAccent,
          onTap: () async {
            final isDark =
                Theme.of(context).brightness ==
                    Brightness.dark;
            final ok = await confirmDelete(isDark);
            if (!ok || !mounted) return;
            widget.onDelete(note);
            if (mounted) setState(() {});
            showMessage(
              "Note deleted permanently",
              danger: true,
            );
          },
        ),
      ],
    );
  }

  Widget _smallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _glassBox({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.56),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(isDark ? 0.30 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.50),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
            ),
            child: Icon(
              icon,
              color: color ??
                  (isDark
                      ? Colors.white
                      : const Color(0xff151225)),
              size: 22,
            ),
          ),
        ),
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
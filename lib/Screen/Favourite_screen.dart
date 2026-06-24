import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dataModle.dart';
import 'Note_Detail_Screen.dart';
import 'Add_note.dart';



class FavouriteScreen extends StatefulWidget {
  final List<NoteModel> notes;
  final VoidCallback onChanged;

  const FavouriteScreen({
    super.key,
    required this.notes,
    required this.onChanged,
  });

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  // ✅ search inside favourites
  final TextEditingController searchController = TextEditingController();
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
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  void removeFavourite(NoteModel note) {
    if (!mounted) return;
    setState(() {
      note.isFavourite = false;
    });
    widget.onChanged();
    showMessage("Removed from favourites");
  }

  List<NoteModel> get favouriteNotes {
    final favs =
    widget.notes.where((e) => e.isFavourite).toList();
    if (searchQuery.trim().isEmpty) return favs;
    final q = searchQuery.toLowerCase().trim();
    return favs.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.note.toLowerCase().contains(q) ||
          n.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favNotes = favouriteNotes;

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
                const Color(0xffFF4F8B).withOpacity(0.35),
                220,
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
                  _headerCard(isDark, favNotes.length),
                  const SizedBox(height: 8),

                  // ✅ search bar
                  _searchBar(isDark),
                  const SizedBox(height: 8),

                  Expanded(
                    child: favNotes.isEmpty
                        ? _emptyState(isDark)
                        : ListView.builder(
                      physics:
                      const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          16, 0, 16, 20),
                      itemCount: favNotes.length,
                      itemBuilder: (context, index) {
                        final note = favNotes[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(
                            milliseconds: 300 + (index * 60),
                          ),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(
                                    0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child:
                          _favouriteCard(note, isDark),
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
              "Favourite Notes",
              style: TextStyle(
                color: isDark
                    ? Colors.white
                    : const Color(0xff151225),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // ✅ toggle search
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
          _glassIconButton(
            icon: Icons.favorite_rounded,
            isDark: isDark,
            color: Colors.red,
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
                hintText: "Search favourites...",
                hintStyle: TextStyle(
                  color: isDark
                      ? Colors.white54
                      : Colors.black45,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xff7F5AF0),
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
                    setState(() => searchQuery = "");
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(isDark ? 0.35 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xffFF4F8B),
                        Color(0xff7F5AF0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$count Favourite${count != 1 ? 's' : ''}",
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
                        "Your most loved notes in one place",
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    final isSearchEmpty = searchQuery.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter:
            ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.55),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.12),
                    ),
                    child: Icon(
                      isSearchEmpty
                          ? Icons.search_off_rounded
                          : Icons.favorite_border_rounded,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isSearchEmpty
                        ? "Nothing matched"
                        : "No favourites yet",
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
                        : "Tap the heart icon on any note to save it here.",
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
        ),
      ),
    );
  }

  Widget _favouriteCard(NoteModel note, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: note.color
                  .withOpacity(isDark ? 0.28 : 0.42),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(isDark ? 0.28 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // Note icon
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.black.withOpacity(0.18)
                        : Colors.white.withOpacity(0.45),
                  ),
                  child: Icon(
                    note.isLocked
                        ? Icons.lock_rounded
                        : Icons.sticky_note_2_rounded,
                    color: isDark
                        ? Colors.white
                        : const Color(0xff151225),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      // ✅ tap to open note detail
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NoteDetailScreen(
                            note: note,
                            onBack: () =>
                                Navigator.pop(context),
                            onEdit: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddNoteScreen(
                                        editNote: note,
                                      ),
                                ),
                              ).then((updated) {
                                if (updated != null &&
                                    mounted) {
                                  final idx = widget.notes
                                      .indexOf(note);
                                  if (idx != -1) {
                                    setState(() {
                                      widget.notes[idx] =
                                          updated;
                                    });
                                    widget.onChanged();
                                  }
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          note.isLocked
                              ? "Locked Note"
                              : (note.title.isEmpty
                              ? "Untitled"
                              : note.title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isDark
                                ? Colors.white
                                : const Color(0xff151225),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Note preview
                        Text(
                          note.isLocked
                              ? "Unlock from home screen to view"
                              : (note.note.isEmpty
                              ? "No content"
                              : note.preview),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            height: 1.4,
                            color: isDark
                                ? Colors.white70
                                : Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Meta row
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 13,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatDate(note.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.black45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(isDark
                                    ? 0.08
                                    : 0.35),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                note.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(
                                      0xff151225),
                                ),
                              ),
                            ),

                            // ✅ word count chip
                            const SizedBox(width: 6),
                            if (!note.isLocked)
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ✅ remove favourite + save
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    removeFavourite(note);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xffFF4F8B),
                          Color(0xffFF7A7A),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.red.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
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
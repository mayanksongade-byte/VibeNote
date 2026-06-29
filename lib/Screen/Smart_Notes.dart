import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rainbow_edge_lighting/rainbow_edge_lighting.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Add_note.dart';
import 'Settings_screen.dart';
import 'Templates_screen.dart';
import 'dataModle.dart';
import 'Favourite_screen.dart';
import '../main.dart';
import 'Note_Detail_Screen.dart';
import 'notification_service.dart';
import 'biometric_service.dart';

class MyApp2 extends StatefulWidget {
  final String? openNoteId;

  const MyApp2({super.key, this.openNoteId});

  @override
  State<MyApp2> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<MyApp2> with WidgetsBindingObserver {
  List<NoteModel> notes = [];
  List<NoteModel> filteredNotes = [];

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  bool isSearchFocused = false;
  String selectedCategory = "All";
  List<String> categories = ["All", "Study", "Work", "Personal", "Important"];
  String selectedSort = "Newest First";

  // ✅ search debounce timer
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    searchFocusNode.addListener(() {
      if (!mounted) return;
      if (isSearchFocused == searchFocusNode.hasFocus) return;
      setState(() {
        isSearchFocused = searchFocusNode.hasFocus;
      });
    });

    loadNotes();
    NotificationService.onOpenNoteRequest = (noteId) {
      if (mounted) openNoteFromNotification(noteId);
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("VibeNote lifecycle: $state");
  }

  void sortNotes() {
    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  void updateCategories() {
    final Set<String> categorySet = {
      "All",
      "Study",
      "Work",
      "Personal",
      "Important",
    };
    for (var note in notes) {
      categorySet.add(note.category);
    }
    categories = categorySet.toList();
  }

  Future<void> openNoteFromNotification(String noteId) async {
    final index = notes.indexWhere((n) => n.id == noteId);

    if (index == -1) {
      showMessage("Note not found.");
      return;
    }

    final note = notes[index];

    if (note.isLocked) {
      final ok = await checkPin(note);
      if (!ok || !mounted) return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          note: note,
          onBack: () => Navigator.pop(context),
          onEdit: () {
            Navigator.pop(context);
            openEditNote(note);
          },
        ),
      ),
    );
  }

  Future<void> saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = notes.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("notes", notesJson);
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList("notes");

    if (notesJson != null) {
      notes = notesJson.map((e) => NoteModel.fromJson(jsonDecode(e))).toList();
    }

    if (!mounted) return;
    setState(() {
      sortNotes();
      updateCategories();
      applyFilter();
    });
    final openId =
        widget.openNoteId ?? NotificationService.consumePendingOpenNoteId();

    if (openId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openNoteFromNotification(openId);
      });
    }
  }

  void applyFilter() {
    List<NoteModel> tempNotes = notes.where((n) => !n.isArchived).toList();

    if (selectedCategory != "All") {
      tempNotes = tempNotes
          .where((n) => n.category == selectedCategory)
          .toList();
    }

    if (searchController.text.trim().isNotEmpty) {
      final query = searchController.text.toLowerCase().trim();
      tempNotes = tempNotes.where((n) {
        return n.title.toLowerCase().contains(query) ||
            n.note.toLowerCase().contains(query) ||
            n.category.toLowerCase().contains(query);
      }).toList();
    }

    switch (selectedSort) {
      case "Oldest First":
        tempNotes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case "A-Z":
        tempNotes.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case "Z-A":
        tempNotes.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case "Favourite First":
        tempNotes.sort(
          (a, b) => (b.isFavourite ? 1 : 0).compareTo(a.isFavourite ? 1 : 0),
        );
        break;
      case "Pinned First":
        tempNotes.sort(
          (a, b) => (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0),
        );
        break;
      default:
        tempNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    filteredNotes = tempNotes;
  }

  void searchNotes(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(applyFilter);
    });
  }

  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case "all":
        return Icons.apps_rounded;
      case "study":
        return Icons.school_rounded;
      case "work":
        return Icons.work_rounded;
      case "personal":
        return Icons.person_rounded;
      case "important":
        return Icons.lightbulb_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  Future<String?> _openPinPage({
    required String title,
    required String actionText,
    String hintText = "Enter 4 digit PIN",
    bool allowBiometric = true,
  }) async {
    final result = await Navigator.of(context).push<String>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.45),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, __) {
          return _PinEntryPage(
            title: title,
            actionText: actionText,
            hintText: hintText,
            allowBiometric: allowBiometric,
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
    return result;
  }

  void showMessage(String message, {Color color = const Color(0xff7F5AF0)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<bool> checkPin(NoteModel note) async {
    // ✅ Try fingerprint first
    final bioAvailable = await BiometricService.isFingerprintAvailable();
    if (bioAvailable) {
      final result = await BiometricService.authenticate(
        reason: "Use fingerprint to unlock this note",
      );
      if (!mounted) return false;
      if (result == BiometricResult.success) return true;
      // If failed/cancelled, fall through to PIN
    }

    // Fall back to PIN
    final enteredPin = await _openPinPage(
      title: "Enter PIN",
      actionText: "Unlock",
    );

    if (enteredPin == null) return false;

    // Fingerprint success
    if (enteredPin == "__biometric__") return true;

    // Normal PIN
    if (enteredPin == note.pin) return true;
    showMessage("Wrong PIN. Please try again.", color: Colors.redAccent);
    return false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void showDeleteUndoSnackBar(NoteModel deletedNote, int deletedIndex) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: const Text("Note Archived"),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () {
            messenger.hideCurrentSnackBar();

            if (!mounted) return;
            setState(() {
              deletedNote.isArchived = false;
              sortNotes();
              updateCategories();
              applyFilter();
            });
            saveNotes();
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
    });
  }

  Future<void> openAddNote() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, __) => const AddNoteScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
      ),
    );

    if (result != null && mounted) {
      setState(() {
        notes.add(result);
        sortNotes();
        updateCategories();
        applyFilter();
      });
      saveNotes();
    }
  }

  Future<void> openTemplates() async {
    final template = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TemplatesScreen()),
    );

    if (template == null || !mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddNoteScreen(template: template)),
    );

    if (result != null && mounted) {
      setState(() {
        notes.add(result);
        sortNotes();
        updateCategories();
        applyFilter();
      });
      saveNotes();
    }
  }

  Future<void> openEditNote(NoteModel note) async {
    if (note.isLocked) {
      final isCorrect = await checkPin(note);
      if (!isCorrect) return;
    }

    if (!mounted) return;

    final realIndex = notes.indexOf(note);

    final updatedNote = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, __) =>
            AddNoteScreen(editNote: note, editIndex: realIndex),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );

    if (updatedNote != null && mounted) {
      setState(() {
        notes[realIndex] = updatedNote;
        sortNotes();
        updateCategories();
        applyFilter();
      });
      saveNotes();
    }
  }

  Future<void> setOrRemovePin(NoteModel note) async {
    if (!note.isLocked) {
      final pin = await _openPinPage(
        title: "Set 4 Digit PIN",
        actionText: "Save",
        allowBiometric: false,
      );
      if (pin == null) return;

      if (!mounted) return;
      setState(() {
        note.isLocked = true;
        note.pin = pin;
      });
      await saveNotes();
      showMessage("Note locked successfully.", color: const Color(0xff2CB67D));
    } else {
      final isCorrect = await checkPin(note);
      if (!mounted) return;
      if (isCorrect) {
        setState(() {
          note.isLocked = false;
          note.pin = null;
        });
        await saveNotes();
        showMessage("Note unlocked.", color: const Color(0xff2CB67D));
      }
    }
  }

  void openFullImage(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> cancelNoteReminder(NoteModel note) async {
    final int notificationId = note.notificationId;

    await NotificationService.cancelNotification(notificationId);
  }

  // ✅ permanently delete a note (with notification cancel)
  Future<void> permanentlyDeleteNote(NoteModel note) async {
    await cancelNoteReminder(note);
    if (!mounted) return;
    setState(() {
      notes.remove(note);
      applyFilter();
    });
    await saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark
          ? const Color(0xff090A12)
          : const Color(0xffF8F5FF),
      body: _premiumBackground(
        isDark: isDark,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _topHeader(isDark)),
              SliverToBoxAdapter(child: _searchBox(isDark)),
              SliverToBoxAdapter(child: _searchMeta(isDark)),
              SliverToBoxAdapter(child: _categoryList(isDark)),
              SliverToBoxAdapter(child: _statsPanel(isDark)),
              SliverToBoxAdapter(child: _sortRow(isDark)),
              filteredNotes.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _emptyState(isDark),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.68,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final note = filteredNotes[index];
                          return _noteDismissible(note, index, isDark);
                        }, childCount: filteredNotes.length),
                      ),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: _premiumFab(),
    );
  }

  Widget _premiumBackground({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xff090A12), Color(0xff151225), Color(0xff241B3A)]
              : const [Color(0xffF8F5FF), Color(0xffEFE7FF), Color(0xffFFEAF3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _glowCircle(const Color(0xff7F5AF0).withOpacity(0.30), 230),
          ),
          Positioned(
            top: 170,
            left: -95,
            child: _glowCircle(const Color(0xff2CB67D).withOpacity(0.18), 210),
          ),
          Positioned(
            bottom: -110,
            right: -70,
            child: _glowCircle(const Color(0xffFF6B9A).withOpacity(0.25), 250),
          ),
          child,
        ],
      ),
    );
  }

  Widget _glowCircle(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _topHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "VibeNote",
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xff151225),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Capture ideas. Lock secrets. Stay organized.",
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _headerIcon(
            isDark: isDark,
            icon: Icons.favorite_rounded,
            color: Colors.redAccent,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavouriteScreen(
                    notes: notes,
                    onChanged: () {
                      if (!mounted) return;

                      setState(() {
                        sortNotes();
                        updateCategories();
                        applyFilter();
                      });

                      saveNotes();
                    },
                  ),
                ),
              );
              if (!mounted) return;
              setState(() {
                sortNotes();
                updateCategories();
                applyFilter();
              });
              saveNotes();
            },
          ),
          const SizedBox(width: 10),
          _headerIcon(
            isDark: isDark,
            icon: Icons.settings_rounded,
            color: isDark ? Colors.white : const Color(0xff151225),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    notes: notes,
                    onNotesChanged: () {
                      if (!mounted) return;
                      setState(() {
                        updateCategories();
                        applyFilter();
                      });
                      saveNotes();
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerIcon({
    required bool isDark,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
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
                  : Colors.white.withOpacity(0.62),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
        ),
      ),
    );
  }

  Widget _searchBox(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
      child: RainbowEdgeLighting(
        enabled: isSearchFocused,
        radius: 26,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: TextField(
              focusNode: searchFocusNode,
              controller: searchController,
              onChanged: searchNotes,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xff151225),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: "Search notes, categories, reminders...",
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.white70 : const Color(0xff7F5AF0),
                ),
                suffixIcon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: searchController.text.isEmpty
                      ? const SizedBox(key: ValueKey("empty"), width: 0)
                      : IconButton(
                          key: const ValueKey("clear"),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            searchController.clear();
                            setState(applyFilter);
                          },
                        ),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.09)
                    : Colors.white.withOpacity(0.72),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 17,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchMeta(bool isDark) {
    final hasSearch = searchController.text.trim().isNotEmpty;
    final count = filteredNotes.length;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: hasSearch
          ? Padding(
              key: ValueKey("search-$count"),
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Row(
                children: [
                  Icon(
                    count == 0
                        ? Icons.search_off_rounded
                        : Icons.manage_search_rounded,
                    size: 16,
                    color: count == 0
                        ? Colors.redAccent
                        : const Color(0xff7F5AF0),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    count == 0
                        ? "Nothing matched your vibe"
                        : "$count note${count > 1 ? 's' : ''} found",
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(key: ValueKey("no-search"), height: 0),
    );
  }

  Widget _categoryList(bool isDark) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  selectedCategory = category;
                  applyFilter();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xff7F5AF0), Color(0xffFF6B9A)],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.white.withOpacity(0.66)),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xff7F5AF0).withOpacity(0.28)
                          : Colors.transparent,
                      blurRadius: isSelected ? 16 : 0,
                      offset: isSelected ? const Offset(0, 8) : Offset.zero,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      categoryIcon(category),
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xff7F5AF0)),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? Colors.white70
                                  : const Color(0xff151225)),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statsPanel(bool isDark) {
    final activeNotes = notes.where((e) => !e.isArchived).length;
    final lockedNotes = notes.where((e) => e.isLocked).length;
    final favNotes = notes.where((e) => e.isFavourite).length;
    final reminderNotes = notes.where((e) => e.hasActiveReminder).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.58),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                _statItem(
                  isDark,
                  Icons.sticky_note_2_rounded,
                  Colors.blueAccent,
                  "Total",
                  activeNotes,
                ),
                _divider(isDark),
                _statItem(
                  isDark,
                  Icons.lock_rounded,
                  Colors.orangeAccent,
                  "Locked",
                  lockedNotes,
                ),
                _divider(isDark),
                _statItem(
                  isDark,
                  Icons.favorite_rounded,
                  Colors.redAccent,
                  "Fav",
                  favNotes,
                ),
                _divider(isDark),
                _statItem(
                  isDark,
                  Icons.alarm_rounded,
                  Colors.deepPurpleAccent,
                  "Reminders",
                  reminderNotes,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(
    bool isDark,
    IconData icon,
    Color color,
    String label,
    int count,
  ) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.14),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 6),
          Text(
            "$count",
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xff151225),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      height: 45,
      width: 1,
      color: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.06),
    );
  }

  Widget _sortRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.60),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.20)),
            ),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xff7F5AF0), Color(0xffFF6B9A)],
                    ),
                  ),
                  child: const Icon(
                    Icons.sort_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sort Notes",
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xff151225),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        selectedSort,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: isDark ? const Color(0xff151522) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  icon: Icon(
                    Icons.tune_rounded,
                    color: isDark ? Colors.white70 : const Color(0xff151225),
                  ),
                  onSelected: (value) {
                    setState(() {
                      selectedSort = value;
                      applyFilter();
                    });
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: "Newest First",
                      child: Text("🕒 Newest First"),
                    ),
                    PopupMenuItem(
                      value: "Oldest First",
                      child: Text("📜 Oldest First"),
                    ),
                    PopupMenuItem(value: "A-Z", child: Text("🔤 A-Z")),
                    PopupMenuItem(value: "Z-A", child: Text("🔠 Z-A")),
                    PopupMenuItem(
                      value: "Favourite First",
                      child: Text("❤️ Favourite First"),
                    ),
                    PopupMenuItem(
                      value: "Pinned First",
                      child: Text("📌 Pinned First"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    final hasSearch = searchController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Image.asset(
              "assets/Vibe_note_illustration_1.png",
              height: 240,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch ? "Nothing matched your vibe" : "Your Ideas Start Here",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xff151225),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? "Try another keyword or choose a different category."
                : "Capture thoughts, save memories, and organize everything.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: openAddNote,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Create First Note"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff7F5AF0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _noteDismissible(NoteModel note, int index, bool isDark) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right = toggle favourite
          if (note.isLocked) {
            final isCorrect = await checkPin(note);
            if (!isCorrect) return false;
          }
          HapticFeedback.mediumImpact();
          if (!mounted) return false;
          setState(() {
            note.isFavourite = !note.isFavourite;
            applyFilter();
          });
          await saveNotes();
          showMessage(
            note.isFavourite
                ? "Added to favourites ❤️"
                : "Removed from favourites",
            color: note.isFavourite ? Colors.redAccent : Colors.blueGrey,
          );
          return false;
        }

        // Swipe left = archive
        if (note.isLocked) {
          return await checkPin(note);
        }
        return true;
      },
      onDismissed: (direction) async {
        await cancelNoteReminder(note);
        if (!mounted) return;
        setState(() {
          note.isArchived = true;
          applyFilter();
        });
        await saveNotes();
        showDeleteUndoSnackBar(note, 0);
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffFF6B9A), Color(0xffFF416C)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.favorite_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffFF9F1C), Color(0xffFF4B2B)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(Icons.archive_rounded, color: Colors.white, size: 28),
      ),
      child: SizedBox.expand(
        child: _TapScaleCard(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showNoteOptions(note, isDark);
          },
          onTap: () async {
            HapticFeedback.selectionClick();
            if (note.isLocked) {
              final isCorrect = await checkPin(note);
              if (!isCorrect) return;
            }
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteDetailScreen(
                  note: note,
                  onBack: () => Navigator.pop(context),
                  onEdit: () {
                    Navigator.pop(context);
                    openEditNote(note);
                  },
                ),
              ),
            );
          },
          child: _noteCard(note, isDark),
        ),
      ),
    );
  }

  // ✅ long press options bottom sheet
  void _showNoteOptions(NoteModel note, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Text(
                    note.isLocked
                        ? "Locked Note"
                        : (note.title.isEmpty ? "Untitled" : note.title),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: isDark ? Colors.white : const Color(0xff151225),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  _optionTile(
                    isDark: isDark,
                    icon: Icons.edit_rounded,
                    color: const Color(0xff7F5AF0),
                    label: "Edit Note",
                    onTap: () {
                      Navigator.pop(context);
                      openEditNote(note);
                    },
                  ),
                  _optionTile(
                    isDark: isDark,
                    icon: note.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    color: Colors.blueAccent,
                    label: note.isPinned ? "Unpin Note" : "Pin Note",
                    onTap: () async {
                      Navigator.pop(context);

                      if (note.isLocked) {
                        final ok = await checkPin(note);
                        if (!ok || !mounted) return;
                      }

                      setState(() {
                        note.isPinned = !note.isPinned;
                        sortNotes();
                        applyFilter();
                      });
                      saveNotes();
                    },
                  ),
                  _optionTile(
                    isDark: isDark,
                    icon: note.isFavourite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: Colors.redAccent,
                    label: note.isFavourite
                        ? "Remove Favourite"
                        : "Add to Favourite",
                    onTap: () async {
                      Navigator.pop(context);

                      if (note.isLocked) {
                        final ok = await checkPin(note);
                        if (!ok || !mounted) return;
                      }

                      setState(() {
                        note.isFavourite = !note.isFavourite;
                        applyFilter();
                      });
                      saveNotes();
                    },
                  ),
                  _optionTile(
                    isDark: isDark,
                    icon: note.isLocked
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    color: Colors.orangeAccent,
                    label: note.isLocked ? "Unlock Note" : "Lock Note",
                    onTap: () {
                      Navigator.pop(context);
                      setOrRemovePin(note);
                    },
                  ),
                  _optionTile(
                    isDark: isDark,
                    icon: Icons.archive_rounded,
                    color: Colors.teal,
                    label: "Archive Note",
                    onTap: () async {
                      Navigator.pop(context);

                      if (note.isLocked) {
                        final ok = await checkPin(note);
                        if (!ok || !mounted) return;
                      }

                      final deletedIndex = notes.indexOf(note);
                      await cancelNoteReminder(note);
                      if (!mounted) return;

                      setState(() {
                        note.isArchived = true;
                        applyFilter();
                      });

                      await saveNotes();
                      showDeleteUndoSnackBar(note, deletedIndex);
                    },
                  ),
                  // ✅ permanent delete option
                  _optionTile(
                    isDark: isDark,
                    icon: Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                    label: "Delete Permanently",
                    onTap: () async {
                      Navigator.pop(context);

                      if (note.isLocked) {
                        final ok = await checkPin(note);
                        if (!ok || !mounted) return;
                      }

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: isDark
                              ? const Color(0xff151225)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          title: const Text("Delete Permanently?"),
                          content: const Text(
                            "This note will be deleted forever and cannot be undone.",
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
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await permanentlyDeleteNote(note);
                        showMessage(
                          "Note deleted permanently",
                          color: Colors.redAccent,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  Widget _noteCard(NoteModel note, bool isDark) {
    final cardColor = note.color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cardColor.withOpacity(isDark ? 0.46 : 0.68),
                cardColor.withOpacity(isDark ? 0.24 : 0.38),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.30 : 0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRect(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: note.isLocked
                  ? _lockedCard(note, isDark)
                  : _normalCard(note, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lockedCard(NoteModel note, bool isDark) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.18)
                      : Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 66,
                width: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xff7F5AF0), Color(0xffFF6B9A)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff7F5AF0).withOpacity(0.32),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Private Note",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xff151225),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tap to unlock",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _miniIconButton(
            isDark: isDark,
            icon: Icons.lock_open_rounded,
            color: Colors.orangeAccent,
            onTap: () => setOrRemovePin(note),
          ),
        ),
      ],
    );
  }

  Widget _normalCard(NoteModel note, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                note.title.isEmpty ? "Untitled Note" : note.title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xff151225),
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _miniIconButton(
              isDark: isDark,
              icon: note.isPinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              color: note.isPinned
                  ? const Color(0xff7F5AF0)
                  : (isDark ? Colors.white : const Color(0xff151225)),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  note.isPinned = !note.isPinned;
                  sortNotes();
                  applyFilter();
                });
                saveNotes();
              },
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    categoryIcon(note.category),
                    size: 11,
                    color: isDark ? Colors.white70 : const Color(0xff7F5AF0),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    note.category,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                formatDate(note.createdAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white60 : Colors.black45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (note.reminderTime != null) ...[
          const SizedBox(height: 6),
          _reminderCountdownBadge(note, isDark),
        ],
        if (note.imagePath != null) ...[
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onTap: () => openFullImage(note.imagePath!),
              child: Container(
                height: 70,
                width: double.infinity,
                color: Colors.black.withOpacity(0.08),
                child: Image.file(
                  File(note.imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 70,
                  cacheWidth: 600,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image_rounded)),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        if (note.imagePath == null)
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                note.note.isEmpty ? "No content added." : note.note,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          const Spacer(),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _miniIconButton(
              isDark: isDark,
              icon: note.isLocked
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              color: note.isLocked
                  ? Colors.orangeAccent
                  : (isDark ? Colors.white : const Color(0xff151225)),
              onTap: () => setOrRemovePin(note),
            ),
            const SizedBox(width: 7),
            _favoriteIconButton(note, isDark),
          ],
        ),
      ],
    );
  }

  Widget _reminderCountdownBadge(NoteModel note, bool isDark) {
    final reminderTime = note.reminderTime!;
    final diff = reminderTime.difference(DateTime.now());
    final isExpired = diff.isNegative;
    final reminderColor = isExpired
        ? Colors.redAccent
        : const Color(0xff7F5AF0);

    final textStyle = TextStyle(
      fontSize: 10.5,
      color: isDark ? Colors.white70 : const Color(0xff151225),
      fontWeight: FontWeight.w900,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: reminderColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: reminderColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: reminderColor.withOpacity(0.20),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.alarm_off_rounded : Icons.alarm_rounded,
            size: 14,
            color: reminderColor,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: isExpired
                ? Text(
                    "Reminder Passed",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  )
                : FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SlideCountdownSeparated(
                          key: ValueKey(reminderTime.millisecondsSinceEpoch),
                          duration: diff,
                          separatorType: SeparatorType.symbol,
                          shouldShowDays: (d) => d.inDays > 0,
                          shouldShowHours: (d) => d.inHours > 0,
                          shouldShowMinutes: (d) => d.inMinutes > 0,
                          shouldShowSeconds: (d) => d.inHours < 1,
                          style: textStyle,
                          separatorStyle: textStyle,
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text("left", style: textStyle),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _favoriteIconButton(NoteModel note, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          note.isFavourite = !note.isFavourite;
        });
        saveNotes();
      },
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.white.withOpacity(0.50),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            note.isFavourite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            key: ValueKey(note.isFavourite),
            size: 16,
            color: note.isFavourite
                ? Colors.redAccent
                : (isDark ? Colors.white : const Color(0xff151225)),
          ),
        ),
      ),
    );
  }

  Widget _miniIconButton({
    required bool isDark,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.white.withOpacity(0.50),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _premiumFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "templateFab",
          mini: true,
          backgroundColor: const Color(0xff2CB67D),
          onPressed: openTemplates,
          child: const Icon(Icons.description_rounded, color: Colors.white),
        ),

        const SizedBox(height: 10),

        Container(
          height: 66,
          width: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xff7F5AF0), Color(0xffFF6B9A)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff7F5AF0).withOpacity(0.40),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: "addNoteFab",
            elevation: 0,
            backgroundColor: Colors.transparent,
            onPressed: openAddNote,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAP SCALE CARD
// ─────────────────────────────────────────────────────────────

class _TapScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _TapScaleCard({
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_TapScaleCard> createState() => _TapScaleCardState();
}

class _TapScaleCardState extends State<_TapScaleCard> {
  bool isPressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: isPressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PIN ENTRY PAGE
// ─────────────────────────────────────────────────────────────

class _PinEntryPage extends StatefulWidget {
  final String title;
  final String actionText;
  final String hintText;
  final bool allowBiometric;

  const _PinEntryPage({
    required this.title,
    required this.actionText,
    required this.hintText,
    this.allowBiometric = true,
  });

  @override
  State<_PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<_PinEntryPage> {
  final TextEditingController controller = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();
  bool isPinFocused = false;
  String? errorText;
  bool obscurePin = true;

  @override
  void initState() {
    super.initState();
    pinFocusNode.addListener(() {
      if (!mounted) return;
      setState(() => isPinFocused = pinFocusNode.hasFocus);
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) pinFocusNode.requestFocus();
    });
    // Auto-try fingerprint when PIN page opens
    if (widget.allowBiometric) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _tryBiometric();
      });
    }
  }

  Future<void> _tryBiometric() async {
    final result = await BiometricService.authenticate(
      reason: "Use fingerprint to unlock this note",
    );
    if (!mounted) return;

    if (result == BiometricResult.success) {
      Navigator.of(context).pop("__biometric__");
    }
  }

  @override
  void dispose() {
    controller.dispose();
    pinFocusNode.dispose();
    super.dispose();
    NotificationService.onOpenNoteRequest = null;
  }

  void submitPin() {
    final pin = controller.text.trim();
    if (pin.length != 4) {
      setState(() => errorText = "PIN must be exactly 4 digits");
      return;
    }
    if (!RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
      setState(() => errorText = "Only numbers allowed");
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      Navigator.of(context).pop(pin);
    });
  }

  void cancelPin() {
    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      Navigator.of(context).pop(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 22,
              bottom: MediaQuery.of(context).viewInsets.bottom + 22,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff171928).withOpacity(0.96)
                        : Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.45 : 0.16),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xff7F5AF0), Color(0xffFF6B9A)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff7F5AF0).withOpacity(0.30),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xff151225),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Enter exactly 4 digits",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      RainbowEdgeLighting(
                        enabled: isPinFocused,
                        radius: 18,
                        child: TextField(
                          controller: controller,
                          focusNode: pinFocusNode,
                          keyboardType: TextInputType.number,
                          obscureText: obscurePin,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xff151225),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            hintText: "••••",
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white30 : Colors.black26,
                              letterSpacing: 8,
                            ),
                            errorText: errorText,
                            counterText: "",
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xffF4F1FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xff7F5AF0),
                                width: 1.5,
                              ),
                            ),
                            // ✅ show/hide PIN toggle
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePin
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: isDark ? Colors.white54 : Colors.black38,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => obscurePin = !obscurePin),
                            ),
                          ),
                          onChanged: (_) {
                            if (errorText != null) {
                              setState(() => errorText = null);
                            }
                          },
                          onSubmitted: (_) => submitPin(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (widget.allowBiometric) ...[
                        Center(
                          child: TextButton.icon(
                            onPressed: _tryBiometric,
                            icon: const Icon(
                              Icons.fingerprint_rounded,
                              color: Color(0xff7F5AF0),
                            ),
                            label: const Text(
                              "Unlock with Fingerprint",
                              style: TextStyle(
                                color: Color(0xff7F5AF0),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: cancelPin,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.18)
                                      : Colors.black.withOpacity(0.12),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: submitPin,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xff7F5AF0),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                widget.actionText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

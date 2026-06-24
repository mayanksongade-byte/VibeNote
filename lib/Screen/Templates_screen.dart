  import 'dart:ui';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';

  // ─────────────────────────────────────────────────────────────
  // TEMPLATE MODEL
  // ─────────────────────────────────────────────────────────────

  class NoteTemplate {
    final String id;
    final String emoji;
    final String name;
    final String category;
    final String title;
    final String content;
    final Color color;

    const NoteTemplate({
      required this.id,
      required this.emoji,
      required this.name,
      required this.category,
      required this.title,
      required this.content,
      required this.color,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // ALL TEMPLATES
  // ─────────────────────────────────────────────────────────────

  final List<NoteTemplate> allTemplates = [
    NoteTemplate(
      id: "study",
      emoji: "📚",
      name: "Study Notes",
      category: "Study",
      title: "Study Notes — [Subject]",
      color: const Color(0xff90CAF9),
      content: """📖 Topic: 
  🗓️ Date: 
  
  ━━━━━━━━━━━━━━━━━━
  📌 Key Points:
  • 
  • 
  • 
  
  ━━━━━━━━━━━━━━━━━━
  💡 Important Concepts:
  
  
  ━━━━━━━━━━━━━━━━━━
  ❓ Questions to Review:
  1. 
  2. 
  3. 
  
  ━━━━━━━━━━━━━━━━━━
  📝 Summary:
  
  
  ━━━━━━━━━━━━━━━━━━
  🔁 Revision Done: ☐ Day 1  ☐ Day 3  ☐ Day 7""",
    ),
    NoteTemplate(
      id: "meeting",
      emoji: "💼",
      name: "Meeting Notes",
      category: "Work",
      title: "Meeting — [Topic]",
      color: const Color(0xffA5D6A7),
      content: """📅 Date & Time: 
  👥 Attendees: 
  📍 Location / Platform: 
  
  ━━━━━━━━━━━━━━━━━━
  🎯 Agenda:
  1. 
  2. 
  3. 
  
  ━━━━━━━━━━━━━━━━━━
  🗣️ Discussion Points:
  
  
  ━━━━━━━━━━━━━━━━━━
  ✅ Action Items:
  • [ ] Task 1 — Assigned to: 
  • [ ] Task 2 — Assigned to: 
  • [ ] Task 3 — Assigned to: 
  
  ━━━━━━━━━━━━━━━━━━
  📌 Decisions Made:
  
  
  ━━━━━━━━━━━━━━━━━━
  📅 Next Meeting: """,
    ),
    NoteTemplate(
      id: "todo",
      emoji: "📋",
      name: "To-Do List",
      category: "Personal",
      title: "To-Do — [Date]",
      color: const Color(0xffF6E58D),
      content: """🗓️ Date: 
  ⭐ Priority: High / Medium / Low
  
  ━━━━━━━━━━━━━━━━━━
  🔴 High Priority:
  • [ ] 
  • [ ] 
  
  ━━━━━━━━━━━━━━━━━━
  🟡 Medium Priority:
  • [ ] 
  • [ ] 
  
  ━━━━━━━━━━━━━━━━━━
  🟢 Low Priority:
  • [ ] 
  • [ ] 
  
  ━━━━━━━━━━━━━━━━━━
  ✅ Completed Today:
  • 
  • 
  
  ━━━━━━━━━━━━━━━━━━
  📌 Notes:""",
    ),
    NoteTemplate(
      id: "goal",
      emoji: "🎯",
      name: "Goal Setting",
      category: "Personal",
      title: "My Goal — [Goal Name]",
      color: const Color(0xffF48FB1),
      content: """🎯 Goal: 
  📅 Deadline: 
  💪 Why this matters to me:
  
  ━━━━━━━━━━━━━━━━━━
  🏆 What success looks like:
  
  
  ━━━━━━━━━━━━━━━━━━
  📋 Action Steps:
  1. 
  2. 
  3. 
  4. 
  5. 
  
  ━━━━━━━━━━━━━━━━━━
  🚧 Possible Challenges:
  • 
  • 
  
  ━━━━━━━━━━━━━━━━━━
  💡 How I'll overcome them:
  
  
  ━━━━━━━━━━━━━━━━━━
  📊 Progress Tracker:
  Week 1: 
  Week 2: 
  Week 3: 
  Week 4: 
  
  ━━━━━━━━━━━━━━━━━━
  🌟 Reward when achieved:""",
    ),
    NoteTemplate(
      id: "diary",
      emoji: "💭",
      name: "Daily Diary",
      category: "Personal",
      title: "Diary — [Date]",
      color: const Color(0xffFFCC80),
      content: """🗓️ Date: 
  🌤️ Mood Today: 😊 / 😐 / 😔 / 😤 / 🥳
  
  ━━━━━━━━━━━━━━━━━━
  ☀️ Morning Thoughts:
  
  
  ━━━━━━━━━━━━━━━━━━
  📌 What happened today:
  
  
  ━━━━━━━━━━━━━━━━━━
  💪 What I accomplished:
  • 
  • 
  
  ━━━━━━━━━━━━━━━━━━
  😔 What didn't go well:
  
  
  ━━━━━━━━━━━━━━━━━━
  🙏 Grateful for:
  1. 
  2. 
  3. 
  
  ━━━━━━━━━━━━━━━━━━
  🌙 Tonight's Reflection:
  
  
  ━━━━━━━━━━━━━━━━━━
  💫 Tomorrow I will:""",
    ),
    NoteTemplate(
      id: "idea",
      emoji: "💡",
      name: "Idea Brainstorm",
      category: "Personal",
      title: "Idea — [Topic]",
      color: const Color(0xffBDBDBD),
      content: """💡 Idea Title: 
  🗓️ Date: 
  🧠 Initial Thought:
  
  ━━━━━━━━━━━━━━━━━━
  🌪️ Brain Dump (write everything):
  
  
  ━━━━━━━━━━━━━━━━━━
  ✅ What's Good About This:
  • 
  • 
  
  ━━━━━━━━━━━━━━━━━━
  ⚠️ Challenges / Problems:
  • 
  • 
  
  ━━━━━━━━━━━━━━━━━━
  🔧 How to Make It Work:
  
  
  ━━━━━━━━━━━━━━━━━━
  🚀 Next Steps:
  1. 
  2. 
  3. 
  
  ━━━━━━━━━━━━━━━━━━
  ⭐ Excitement Level: ⭐⭐⭐⭐⭐""",
    ),
    NoteTemplate(
      id: "shopping",
      emoji: "🛒",
      name: "Shopping List",
      category: "Personal",
      title: "Shopping List — [Date]",
      color: const Color(0xff90CAF9),
      content: """🛒 Shopping For: 
  📅 Date: 
  💰 Budget: ₹
  
  ━━━━━━━━━━━━━━━━━━
  🥦 Groceries:
  • [ ] 
  • [ ] 
  • [ ] 
  
  ━━━━━━━━━━━━━━━━━━
  🏠 Household:
  • [ ] 
  • [ ] 
  
  ━━━━━━━━━━━━━━━━━━
  👕 Clothing:
  • [ ] 
  • [ ] 
  
  ━━━━━━━━━━━━━━━━━━
  💊 Medical / Personal:
  • [ ] 
  • [ ] 
  
  ━━━━━━━━━━━━━━━━━━
  📦 Other:
  • [ ] 
  • [ ] 
  
  ━━━━━━━━━━━━━━━━━━
  💸 Total Spent: ₹""",
    ),
    NoteTemplate(
      id: "workout",
      emoji: "💪",
      name: "Workout Log",
      category: "Personal",
      title: "Workout — [Date]",
      color: const Color(0xffF48FB1),
      content: """💪 Workout Type: 
  📅 Date: 
  ⏱️ Duration: 
  🔥 Calories Burned: 
  
  ━━━━━━━━━━━━━━━━━━
  🏋️ Exercises:
  
  Exercise 1: 
  Sets: ___ Reps: ___ Weight: ___
  
  Exercise 2: 
  Sets: ___ Reps: ___ Weight: ___
  
  Exercise 3: 
  Sets: ___ Reps: ___ Weight: ___
  
  Exercise 4: 
  Sets: ___ Reps: ___ Weight: ___
  
  ━━━━━━━━━━━━━━━━━━
  💧 Water Intake: ___ glasses
  
  ━━━━━━━━━━━━━━━━━━
  😴 Sleep Last Night: ___ hours
  
  ━━━━━━━━━━━━━━━━━━
  💬 How I Felt:
  
  
  ━━━━━━━━━━━━━━━━━━
  🎯 Tomorrow's Goal:""",
    ),
    NoteTemplate(
      id: "recipe",
      emoji: "🍽️",
      name: "Recipe",
      category: "Personal",
      title: "Recipe — [Dish Name]",
      color: const Color(0xffFFCC80),
      content: """🍽️ Dish Name: 
  ⏱️ Prep Time:     Cook Time: 
  🍽️ Servings: 
  ⭐ Difficulty: Easy / Medium / Hard
  
  ━━━━━━━━━━━━━━━━━━
  🛒 Ingredients:
  • 
  • 
  • 
  • 
  • 
  
  ━━━━━━━━━━━━━━━━━━
  👨‍🍳 Instructions:
  1. 
  2. 
  3. 
  4. 
  5. 
  
  ━━━━━━━━━━━━━━━━━━
  💡 Tips & Tricks:
  
  
  ━━━━━━━━━━━━━━━━━━
  📸 Notes for Next Time:
  
  
  ━━━━━━━━━━━━━━━━━━
  ⭐ Rating: ⭐⭐⭐⭐⭐""",
    ),
    NoteTemplate(
      id: "call",
      emoji: "📞",
      name: "Phone Call Notes",
      category: "Work",
      title: "Call Notes — [Name]",
      color: const Color(0xffA5D6A7),
      content: """📞 Call With: 
  📅 Date & Time: 
  ⏱️ Duration: 
  📱 Phone / Platform: 
  
  ━━━━━━━━━━━━━━━━━━
  🎯 Purpose of Call:
  
  
  ━━━━━━━━━━━━━━━━━━
  🗣️ Key Points Discussed:
  • 
  • 
  • 
  
  ━━━━━━━━━━━━━━━━━━
  ✅ Action Items:
  • [ ] 
  • [ ] 
  
  ━━━━━━━━━━━━━━━━━━
  📌 Important Information:
  
  
  ━━━━━━━━━━━━━━━━━━
  📅 Follow Up Date:""",
    ),
    NoteTemplate(
      id: "travel",
      emoji: "✈️",
      name: "Travel Plan",
      category: "Personal",
      title: "Trip — [Destination]",
      color: const Color(0xff90CAF9),
      content: """✈️ Destination: 
  📅 Travel Dates: From:      To: 
  👥 Travelers: 
  💰 Total Budget: ₹
  
  ━━━━━━━━━━━━━━━━━━
  🚌 Transport:
  • To destination: 
  • Local transport: 
  
  ━━━━━━━━━━━━━━━━━━
  🏨 Accommodation:
  • Hotel/Stay: 
  • Address: 
  • Check-in: 
  
  ━━━━━━━━━━━━━━━━━━
  📍 Places to Visit:
  • [ ] 
  • [ ] 
  • [ ] 
  
  ━━━━━━━━━━━━━━━━━━
  🍽️ Food to Try:
  • 
  • 
  
  ━━━━━━━━━━━━━━━━━━
  🎒 Packing List:
  • [ ] Passport / ID
  • [ ] Tickets
  • [ ] Charger
  • [ ] Medicines
  • [ ] 
  • [ ] 
  
  ━━━━━━━━━━━━━━━━━━
  💸 Expense Tracker:
  Transport: ₹
  Food: ₹
  Stay: ₹
  Shopping: ₹
  Other: ₹""",
    ),
    NoteTemplate(
      id: "budget",
      emoji: "💰",
      name: "Budget Tracker",
      category: "Personal",
      title: "Budget — [Month/Year]",
      color: const Color(0xffA5D6A7),
      content: """💰 Month: 
  💼 Total Income: ₹
  
  ━━━━━━━━━━━━━━━━━━
  📤 Fixed Expenses:
  • Rent / EMI: ₹
  • Bills (Electric, Gas): ₹
  • Internet / Phone: ₹
  • Insurance: ₹
  • Other: ₹
  
  ━━━━━━━━━━━━━━━━━━
  🛒 Variable Expenses:
  • Groceries: ₹
  • Transport: ₹
  • Eating Out: ₹
  • Shopping: ₹
  • Entertainment: ₹
  • Medical: ₹
  • Other: ₹
  
  ━━━━━━━━━━━━━━━━━━
  💸 Total Expenses: ₹
  
  ━━━━━━━━━━━━━━━━━━
  💵 Savings This Month: ₹
  
  ━━━━━━━━━━━━━━━━━━
  🎯 Savings Goal: ₹
  📊 Progress: ____%
  
  ━━━━━━━━━━━━━━━━━━
  📝 Notes:""",
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // TEMPLATES SCREEN
  // ─────────────────────────────────────────────────────────────

  class TemplatesScreen extends StatefulWidget {
    const TemplatesScreen({super.key});

    @override
    State<TemplatesScreen> createState() => _TemplatesScreenState();
  }

  class _TemplatesScreenState extends State<TemplatesScreen> {
    NoteTemplate? _selectedTemplate;
    String _searchQuery = "";
    final TextEditingController _searchController = TextEditingController();

    @override
    void dispose() {
      _searchController.dispose();
      super.dispose();
    }

    List<NoteTemplate> get filteredTemplates {
      if (_searchQuery.trim().isEmpty) return allTemplates;
      final q = _searchQuery.toLowerCase();
      return allTemplates
          .where(
            (t) =>
                t.name.toLowerCase().contains(q) ||
                t.category.toLowerCase().contains(q) ||
                t.emoji.contains(q),
          )
          .toList();
    }

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  const Color(0xff7F5AF0).withOpacity(0.30),
                  220,
                ),
              ),
              Positioned(
                bottom: -90,
                left: -80,
                child: _glowCircle(
                  const Color(0xffFF6B9A).withOpacity(0.28),
                  240,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _topBar(isDark),
                    const SizedBox(height: 8),
                    _searchBar(isDark),
                    const SizedBox(height: 8),

                    // Preview panel (shows when template selected)
                    if (_selectedTemplate != null) _previewPanel(isDark),

                    Expanded(
                      child: filteredTemplates.isEmpty
                          ? _emptySearch(isDark)
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.1,
                                  ),
                              itemCount: filteredTemplates.length,
                              itemBuilder: (context, index) {
                                final template = filteredTemplates[index];
                                final isSelected =
                                    _selectedTemplate?.id == template.id;
                                return _templateCard(
                                  template,
                                  isDark,
                                  isSelected,
                                );
                              },
                            ),
                    ),

                    // Use Template button
                    if (_selectedTemplate != null) _useButton(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Top Bar ──

    Widget _topBar(bool isDark) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(
          children: [
            _glassIconButton(
              icon: Icons.arrow_back_rounded,
              isDark: isDark,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Templates",
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xff151225),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    "${allTemplates.length} ready-made templates",
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Search Bar ──

    Widget _searchBar(bool isDark) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xff151225),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: "Search templates...",
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xff7F5AF0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ── Template Card ──

    Widget _templateCard(NoteTemplate template, bool isDark, bool isSelected) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedTemplate = isSelected ? null : template;
          });
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showFullPreview(template, isDark);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      template.color.withOpacity(0.85),
                      template.color.withOpacity(0.55),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark
                      ? Colors.white.withOpacity(0.07)
                      : template.color.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withOpacity(0.40)
                  : Colors.white.withOpacity(0.22),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? template.color.withOpacity(0.35)
                    : Colors.black.withOpacity(0.06),
                blurRadius: isSelected ? 20 : 8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          template.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),

                        const Spacer(),

                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showFullPreview(template, isDark);
                          },
                          child: Container(
                            height: 26,
                            width: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.25),
                            ),
                            child: const Icon(
                              Icons.visibility_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        if (isSelected)
                          Container(
                            height: 24,
                            width: 24,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Color(0xff7F5AF0),
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      template.name,
                      style: TextStyle(
                        color: isDark || isSelected
                            ? Colors.white
                            : const Color(0xff151225),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        template.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark || isSelected
                              ? Colors.white70
                              : Colors.black54,
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

    // ── Preview Panel ──

    Widget _previewPanel(bool isDark) {
      final t = _selectedTemplate!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.color.withOpacity(isDark ? 0.22 : 0.38),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        t.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xff151225),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "Preview",
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.content,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 11,
                      height: 1.4,
                      fontFamily: "monospace",
                    ),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    void _showFullPreview(NoteTemplate template, bool isDark) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff151225) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${template.emoji} ${template.name}",
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xff151225),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      template.content,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 13,
                        height: 1.5,
                        fontFamily: "monospace",
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context, template);
                        },
                        child: const Text("Use This Template"),
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

    // ── Use Template Button ──

    Widget _useButton(bool isDark) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context, _selectedTemplate);
          },
          child: Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff7F5AF0), Color(0xffFF6B9A)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff7F5AF0).withOpacity(0.38),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedTemplate!.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  "Use ${_selectedTemplate!.name}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Empty Search ──

    Widget _emptySearch(bool isDark) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🔍", style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              "No templates found",
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xff151225),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Try a different keyword",
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // ── Shared Widgets ──

    Widget _glassIconButton({
      required IconData icon,
      required bool isDark,
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
                    : Colors.white.withOpacity(0.50),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.20)),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : const Color(0xff151225),
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
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
    }
  }

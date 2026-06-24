import 'dart:ui';
import 'package:flutter/material.dart';
import 'Archive_screen.dart';
import 'dataModle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'package:flutter/services.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:rainbow_edge_lighting/rainbow_edge_lighting.dart';
import 'notification_service.dart';
import 'biometric_service.dart';


class SettingsScreen extends StatefulWidget {
  final List<NoteModel> notes;
  final VoidCallback onNotesChanged;

  const SettingsScreen({
    super.key,
    required this.notes,
    required this.onNotesChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsOn = true;
  bool appLockOn = false;
  String? appPin;
  String? alarmSoundName;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      notificationsOn = prefs.getBool("notificationsOn") ?? true;
      appLockOn = prefs.getBool("appLockOn") ?? false;
      appPin = prefs.getString("appPin");
      alarmSoundName = prefs.getString("alarmSoundName");
    });
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
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notificationsOn", value);
    if (!mounted) return;
    setState(() => notificationsOn = value);

    // ✅ cancel all notifications when turned off
    if (!value) {
      await NotificationService.cancelAllNotifications();
    }

    showMessage(
      value
          ? "Notifications turned on 🔔"
          : "Notifications turned off 🔕",
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PIN DIALOG
  // ─────────────────────────────────────────────────────────────
  Future<String?> showAppPinDialog({
    required String title,
    required String subtitle,
    required String actionText,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final controller = TextEditingController();
    final focusNode = FocusNode();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void submitPin() {
              final pin = controller.text.trim();
              if (pin.length != 4) {
                setDialogState(
                        () => errorText = "Enter 4-digit PIN");
                return;
              }
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(dialogContext).pop(pin);
            }

            return AlertDialog(
              backgroundColor: isDark
                  ? const Color(0xff151225)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              title: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xff7F5AF0),
                          Color(0xffFF6B9A)
                        ],
                      ),
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white60
                          : Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  RainbowEdgeLighting(
                    enabled: true,
                    radius: 18,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: isDark
                            ? Colors.white
                            : const Color(0xff151225),
                      ),
                      decoration: InputDecoration(
                        hintText: "••••",
                        errorText: errorText,
                        counterText: "",
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.08)
                            : const Color(0xffF4F1FF),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white
                                .withOpacity(0.25)
                                : Colors.black
                                .withOpacity(0.14),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xff7F5AF0),
                            width: 1.8,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.4,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.6,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (errorText != null) {
                          setDialogState(
                                  () => errorText = null);
                        }
                      },
                      onSubmitted: (_) => submitPin(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus
                        ?.unfocus();
                    Navigator.of(dialogContext).pop(null);
                  },
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff7F5AF0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: submitPin,
                  child: Text(actionText),
                ),
              ],
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.dispose();
      controller.dispose();
    });

    return result;
  }

  // ─────────────────────────────────────────────────────────────
  // VERIFY PIN
  // ─────────────────────────────────────────────────────────────
  Future<bool> verifyCurrentPin() async {
    if (appPin == null || appPin!.isEmpty) {
      showMessage("Please set PIN first", danger: true);
      return false;
    }

    // ✅ Try fingerprint first
    final bioAvailable = await BiometricService.isFingerprintAvailable();
    if (bioAvailable) {
      final result = await BiometricService.authenticate(
        reason: "Use fingerprint to verify",
      );
      if (!mounted) return false;
      if (result == BiometricResult.success) return true;
      // fall through to PIN if biometric fails
    }

    // PIN fallback
    final enteredPin = await showAppPinDialog(
      title: "Enter Current PIN",
      subtitle: "Enter your current 4-digit PIN.",
      actionText: "Verify",
    );
    if (!mounted) return false;
    if (enteredPin == null) return false;
    if (enteredPin != appPin) {
      showMessage("Wrong PIN ❌", danger: true);
      return false;
    }
    return true;
  }

  // ─────────────────────────────────────────────────────────────
  // CHANGE PIN
  // ─────────────────────────────────────────────────────────────
  Future<void> changePin() async {
    final newPin = await showAppPinDialog(
      title: "Set App PIN",
      subtitle: "Enter a 4-digit PIN to protect VibeNote.",
      actionText: "Save PIN",
    );

    if (!mounted) return;
    if (newPin == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("appPin", newPin);

    if (!mounted) return;
    setState(() => appPin = newPin);
    showMessage("PIN saved successfully ✅");
  }

  // ─────────────────────────────────────────────────────────────
  // APP LOCK
  // ─────────────────────────────────────────────────────────────
  Future<void> setAppLock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    if (value) {
      if (appPin == null || appPin!.isEmpty) {
        await changePin();
        if (!mounted) return;
        if (appPin == null || appPin!.isEmpty) {
          setState(() => appLockOn = false);
          return;
        }
      }

      await prefs.setBool("appLockOn", true);
      if (!mounted) return;
      setState(() => appLockOn = true);
      showMessage("App Lock enabled 🔒");
      return;
    }

    final verified = await verifyCurrentPin();
    if (!mounted) return;

    if (!verified) {
      setState(() => appLockOn = true);
      return;
    }

    await prefs.setBool("appLockOn", false);
    if (!mounted) return;
    setState(() => appLockOn = false);
    showMessage("App Lock disabled 🔓");
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE ALL NOTES
  // ─────────────────────────────────────────────────────────────
  Future<void> deleteAllNotes() async {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDark ? const Color(0xff151225) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          "Delete All Notes?",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          "This will permanently remove all notes and cancel all reminders. This action cannot be undone.",
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

    if (!mounted) return;

    if (confirm == true) {
      await NotificationService.cancelAllNotifications();

      if (!mounted) return;
      setState(() => widget.notes.clear());

      widget.onNotesChanged();
      showMessage("All notes deleted 🗑️", danger: true);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // NEW: Export notes count info
  // ─────────────────────────────────────────────────────────────
  void showNotesInfo() {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final total = widget.notes.length;
    final archived =
        widget.notes.where((n) => n.isArchived).length;
    final locked =
        widget.notes.where((n) => n.isLocked).length;
    final withReminder =
        widget.notes.where((n) => n.hasActiveReminder).length;
    final favourite =
        widget.notes.where((n) => n.isFavourite).length;
    final withImage =
        widget.notes.where((n) => n.imagePath != null).length;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? const Color(0xff151225) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_rounded, color: Color(0xff7F5AF0)),
            SizedBox(width: 10),
            Text(
              "Notes Info",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow("Total Notes", "$total",
                Icons.sticky_note_2_rounded, Colors.blueAccent,
                isDark: isDark),
            _infoRow("Archived", "$archived",
                Icons.archive_rounded, Colors.orange,
                isDark: isDark),
            _infoRow("Locked", "$locked", Icons.lock_rounded,
                Colors.orangeAccent,
                isDark: isDark),
            _infoRow("Favourites", "$favourite",
                Icons.favorite_rounded, Colors.redAccent,
                isDark: isDark),
            _infoRow("With Reminders", "$withReminder",
                Icons.alarm_rounded, const Color(0xff7F5AF0),
                isDark: isDark),
            _infoRow("With Images", "$withImage",
                Icons.image_rounded, const Color(0xff2CB67D),
                isDark: isDark),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff7F5AF0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      String label,
      String value,
      IconData icon,
      Color color, {
        required bool isDark,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.14),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.white70
                    : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color:
              isDark ? Colors.white : const Color(0xff151225),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final myApp = MyApp.of(context);

    final totalNotes = widget.notes.length;
    final archivedNotes =
        widget.notes.where((e) => e.isArchived).length;
    final lockedNotes =
        widget.notes.where((e) => e.isLocked).length;

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
                const Color(0xff7F5AF0).withOpacity(0.35),
                230,
              ),
            ),
            Positioned(
              bottom: -90,
              left: -80,
              child: _glowCircle(
                const Color(0xffFF6B9A).withOpacity(0.30),
                240,
              ),
            ),
            SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  _topBar(isDark),
                  const SizedBox(height: 16),
                  _profileCard(
                      isDark, totalNotes, archivedNotes, lockedNotes),
                  const SizedBox(height: 18),

                  // ── Appearance ──
                  _sectionTitle("Appearance", isDark),
                  _settingSwitch(
                    isDark: isDark,
                    icon: Icons.dark_mode_rounded,
                    title: "Dark Mode",
                    subtitle: "Switch between light and dark theme",
                    value: myApp?.isDark ?? false,
                    textOn: "Dark",
                    textOff: "Light",
                    iconOn: Icons.dark_mode_rounded,
                    iconOff: Icons.wb_sunny_rounded,
                    colorOn: const Color(0xff7F5AF0),
                    colorOff: Colors.orangeAccent,
                    onChanged: (value) {
                      myApp?.toggleTheme().then((_) {
                        if (mounted) setState(() {});
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  // ── Preferences ──
                  _sectionTitle("Preferences", isDark),
                  _settingSwitch(
                    isDark: isDark,
                    icon: Icons.notifications_rounded,
                    title: "Notifications",
                    subtitle: "Reminder notifications on/off",
                    value: notificationsOn,
                    textOn: "On",
                    textOff: "Off",
                    iconOn: Icons.notifications_active_rounded,
                    iconOff: Icons.notifications_off_rounded,
                    colorOn: const Color(0xff2CB67D),
                    colorOff: Colors.grey,
                    onChanged: setNotifications,
                  ),
                  _settingTile(
                    isDark: isDark,
                    icon: appLockOn
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    iconColor: const Color(0xffFF6B9A),
                    title: "App Lock",
                    subtitle: appLockOn
                        ? "App Lock is ON — tap to turn OFF"
                        : "App Lock is OFF — tap to turn ON",
                    onTap: () => setAppLock(!appLockOn),
                  ),
                  _settingTile(
                    isDark: isDark,
                    icon: Icons.key_rounded,
                    iconColor: const Color(0xff7F5AF0),
                    title: "Change App PIN",
                    subtitle: appPin == null
                        ? "No PIN set"
                        : "PIN is set — tap to change",
                    onTap: () async {
                      if (appPin != null &&
                          appPin!.isNotEmpty) {
                        final verified =
                        await verifyCurrentPin();
                        if (!mounted) return;
                        if (!verified) return;
                      }
                      await changePin();
                    },
                  ),

                  const SizedBox(height: 14),

                  // ── Notes Management ──
                  _sectionTitle("Notes Management", isDark),
                  _settingTile(
                    isDark: isDark,
                    icon: Icons.info_outline_rounded,
                    iconColor: Colors.blueAccent,
                    title: "Notes Info",
                    subtitle: "View statistics about your notes",
                    onTap: showNotesInfo,
                  ),
                  _settingTile(
                    isDark: isDark,
                    icon: Icons.archive_rounded,
                    iconColor: Colors.orange,
                    title: "Archived Notes",
                    subtitle: "View and restore archived notes",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArchiveScreen(
                            notes: widget.notes,
                            onRestore: (note) {
                              if (!mounted) return;
                              setState(() {
                                note.isArchived = false;
                              });
                              widget.onNotesChanged();
                              showMessage("Note restored ✅");
                            },
                            onDelete: (note) {
                              if (!mounted) return;
                              setState(() {
                                widget.notes.remove(note);
                              });
                              widget.onNotesChanged();
                              showMessage(
                                "Note deleted permanently",
                                danger: true,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  _settingTile(
                    isDark: isDark,
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.redAccent,
                    title: "Delete All Notes",
                    subtitle: "Remove all notes permanently",
                    onTap: deleteAllNotes,
                    danger: true,
                  ),

                  const SizedBox(height: 14),

                  // ── About ──
                  _sectionTitle("About", isDark),
                  _aboutCard(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(bool isDark) {
    return Row(
      children: [
        _glassIconButton(
          icon: Icons.arrow_back_rounded,
          isDark: isDark,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            "Settings",
            style: TextStyle(
              color: isDark
                  ? Colors.white
                  : const Color(0xff151225),
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _glassIconButton(
          icon: Icons.tune_rounded,
          isDark: isDark,
          onTap: showNotesInfo,
        ),
      ],
    );
  }

  Widget _profileCard(
      bool isDark,
      int totalNotes,
      int archivedNotes,
      int lockedNotes,
      ) {
    return _glassBox(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 62,
                width: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff7F5AF0),
                      Color(0xffFF6B9A)
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff7F5AF0)
                          .withOpacity(0.30),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      "VibeNote Control Center",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xff151225),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Manage notes, privacy & experience",
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
          const SizedBox(height: 18),
          Row(
            children: [
              _miniStat("Notes", "$totalNotes",
                  Icons.note_rounded, isDark),
              _miniStat("Archive", "$archivedNotes",
                  Icons.archive_rounded, isDark),
              _miniStat("Locked", "$lockedNotes",
                  Icons.lock_rounded, isDark),
              // ✅ favourite count stat
              _miniStat(
                "Fav",
                "${widget.notes.where((n) => n.isFavourite).length}",
                Icons.favorite_rounded,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
      String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 17, color: const Color(0xff7F5AF0)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: isDark
                    ? Colors.white
                    : const Color(0xff151225),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.white60
                    : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingSwitch({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required String textOn,
    required String textOff,
    required IconData iconOn,
    required IconData iconOff,
    required Color colorOn,
    required Color colorOff,
    required Function(bool) onChanged,
  }) {
    return _glassBox(
      isDark: isDark,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _iconBubble(icon, const Color(0xff7F5AF0)),
          const SizedBox(width: 14),
          Expanded(child: _tileTexts(isDark, title, subtitle)),
          SizedBox(
            width: 122,
            child: LiteRollingSwitch(
              value: value,
              textOn: textOn,
              textOff: textOff,
              colorOn: colorOn,
              colorOff: colorOff,
              iconOn: iconOn,
              iconOff: iconOff,
              textSize: 12,
              onChanged: onChanged,
              onTap: () {},
              onDoubleTap: () {},
              onSwipe: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: _glassBox(
        isDark: isDark,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        child: Row(
          children: [
            _iconBubble(icon, iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: _tileTexts(isDark, title, subtitle,
                  danger: danger),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tileTexts(
      bool isDark,
      String title,
      String subtitle, {
        bool danger = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: danger
                ? Colors.redAccent
                : (isDark
                ? Colors.white
                : const Color(0xff151225)),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _iconBubble(IconData icon, Color color) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _aboutCard(bool isDark) {
    return _glassBox(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff7F5AF0),
                      Color(0xffFF6B9A)
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.sticky_note_2_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      "VibeNote",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xff151225),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Developer: Mayank Songade\nVersion 1.0.0",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white60
                            : Colors.black54,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ✅feature highlights
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _featureChip(
                  "🔒 PIN Lock", isDark),
              _featureChip(
                  "🔔 Reminders", isDark),
              _featureChip(
                  "🎨 Color Notes", isDark),
              _featureChip(
                  "🎤 Voice Note", isDark),
              _featureChip(
                  "📸 Image Notes", isDark),
              _featureChip(
                  "📁 Archive", isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : const Color(0xff7F5AF0).withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xff7F5AF0).withOpacity(0.25),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark
              ? Colors.white70
              : const Color(0xff151225),
        ),
      ),
    );
  }

  Widget _glassBox({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
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
                  : Colors.white.withOpacity(0.58),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: Colors.white.withOpacity(0.25)),
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
                  color: Colors.white.withOpacity(0.20)),
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

  Widget _glowCircle(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration:
      BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
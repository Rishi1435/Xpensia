import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart'; // For image picking
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/services/notification_service.dart';
import 'package:xpensia/data/theme_provider.dart';
import 'package:xpensia/screens/login_page.dart';
import 'package:xpensia/screens/category/category_screen.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _dailyReminders = true;
  bool _budgetAlerts = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Section with Gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white24,
                          backgroundImage:
                              themeProvider.profileImagePath != null
                              ? FileImage(File(themeProvider.profileImagePath!))
                              : null,
                          child: themeProvider.profileImagePath == null
                              ? Text(
                                  user?.displayName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      user?.email
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user?.displayName ?? 'User',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white70,
                              ),
                              onPressed: _showEditProfileDialog,
                            ),
                          ],
                        ),
                        Text(
                          user?.email ?? 'No email',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Appearance Section (New)
            _buildSectionHeader("Appearance"),
            _buildSettingsTile(
              icon: isDark
                  ? CupertinoIcons.moon_fill
                  : CupertinoIcons.sun_max_fill,
              title: "Dark Mode",
              iconColor: isDark ? Colors.purpleAccent : Colors.orangeAccent,
              trailing: Switch(
                value: isDark,
                onChanged: (val) {
                  themeProvider.toggleTheme(val);
                },
                activeColor: Theme.of(context).colorScheme.secondary,
              ),
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 20),

            // Preferences
            _buildSectionHeader("Preferences"),
            _buildSettingsTile(
              icon: Icons.category_outlined,
              title: "Manage Categories",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Account Settings
            _buildSectionHeader("Account"),
            _buildSettingsTile(
              icon: CupertinoIcons.lock,
              title: "Change Password",
              onTap: _showChangePasswordDialog,
            ),
            _buildSettingsTile(
              icon: CupertinoIcons.bell,
              title: "Daily Reminders (8:00 PM)",
              trailing: Switch(
                value: _dailyReminders,
                onChanged: (val) async {
                  setState(() => _dailyReminders = val);
                  if (val) {
                    await NotificationService().scheduleDailyReminder(
                      title: "Time to log expenses! 📝",
                      body: "Don't forget to track your spending today.",
                      time: const TimeOfDay(hour: 20, minute: 0),
                    );
                  } else {
                    await NotificationService()
                        .cancelAll(); // Or cancel specific ID
                  }
                },
                activeColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
            _buildSettingsTile(
              icon: CupertinoIcons.exclamationmark_circle,
              title: "Budget Alerts",
              trailing: Switch(
                value: _budgetAlerts,
                // In a real app, we'd save this to Preferences/Provider
                // For now, it's state-only as requested by "everything notification"
                onChanged: (val) => setState(() => _budgetAlerts = val),
                activeColor: Theme.of(context).colorScheme.secondary,
              ),
            ),

            // Biometric Security
            _buildSettingsTile(
              icon: Icons.fingerprint,
              title: "Biometric Unlock",
              trailing: Switch(
                value: themeProvider.isBiometricEnabled,
                onChanged: (val) {
                  themeProvider.toggleBiometric(val);
                },
                activeColor: Theme.of(context).colorScheme.secondary,
              ),
            ),

            const SizedBox(height: 20),

            // App Settings
            _buildSectionHeader("App"),
            _buildSettingsTile(
              icon: CupertinoIcons.info,
              title: "About Xpensia",
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "Xpensia",
                  applicationVersion: "1.0.0",
                  applicationIcon: const Icon(
                    CupertinoIcons.money_dollar_circle,
                  ),
                  children: [
                    const Text(
                      "Smart Expense Tracker built with Flutter & MongoDB.",
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),

            // Log Out Button (Premium Style)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.shade700,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  "Log Out",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.tertiary, // Use Tertiary for card bg
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Theme.of(context).colorScheme.primary)
                .withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing:
            trailing ??
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: Theme.of(context).colorScheme.outline,
            ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final TextEditingController nameController = TextEditingController(
      text: user?.displayName,
    );

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Edit Profile"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "Display Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    await user?.updateDisplayName(nameController.text);
                    await user?.reload(); // Refresh user data
                    setState(() {}); // Rebuild UI
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error updating profile: $e")),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Clear navigation stack and go to Login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error signing out: $e")));
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        // Save path to ThemeProvider
        if (mounted) {
          Provider.of<ThemeProvider>(
            context,
            listen: false,
          ).setProfileImage(path);
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to pick image")));
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Change Password"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Current Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? "Enter current password"
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "Enter new password";
                        }
                        if (val.length < 6) return "At least 6 characters";
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val != newPasswordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isLoading)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              final email = user?.email;
                              if (user != null && email != null) {
                                // 1. Re-authenticate
                                final credential = EmailAuthProvider.credential(
                                  email: email,
                                  password: currentPasswordController.text,
                                );
                                await user.reauthenticateWithCredential(
                                  credential,
                                );

                                // 2. Update Password
                                await user.updatePassword(
                                  newPasswordController.text,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Password updated successfully!",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            } on FirebaseAuthException catch (e) {
                              String errorMsg = "Update failed";
                              if (e.code == 'wrong-password') {
                                errorMsg = "Incorrect current password";
                              } else if (e.code == 'weak-password') {
                                errorMsg = "Password is too weak";
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMsg),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() => isLoading = false);
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

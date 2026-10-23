import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  final int initialIndex;

  const LegalScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FA);
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final cardBorder = isDark ? const Color(0xFF242424) : const Color(0xFFE5E7EB);
    final indicatorColor = isDark ? Colors.white : const Color(0xFF4B5563);

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Legal & Policies',
            style: TextStyle(
              fontFamily: 'Sniglet',
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            indicatorColor: indicatorColor,
            indicatorWeight: 3,
            labelColor: textPrimary,
            unselectedLabelColor: textSecondary,
            dividerColor: cardBorder,
            labelStyle: const TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Privacy Policy'),
              Tab(text: 'Terms of Service'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _PolicyScrollView(
                lastUpdated: 'October 2026',
                sections: const [
                  _LegalSection(
                    title: '1. Overview',
                    content:
                        'TodoCat ("we", "our", or "the app") is developed by Nandakishore P. We respect your privacy and are committed to protecting your personal information. This Privacy Policy outlines the types of data we collect, how it is used, and how it is secured.',
                  ),
                  _LegalSection(
                    title: '2. Information We Collect',
                    content:
                        '• Account Information: When you create an account or sign in with Google, we collect your email address, display name, and an authentication identifier to sync your tasks across devices.\n\n• Task Data: Any tasks, descriptions, priorities, due dates, categories, and completion states you create in the app are stored to provide task management functionality.\n\n• Local Device Storage: Task caches and visual preferences (such as light/dark mode and cat color variants) are saved locally on your device for offline access and home screen widgets.',
                  ),
                  _LegalSection(
                    title: '3. Device Permissions & Services',
                    content:
                        '• Overlay Permission (SYSTEM_ALERT_WINDOW): Used strictly when you enable the floating cat running overlay to display your task companion on top of other apps.\n\n• Foreground Services (FOREGROUND_SERVICE): Powers the floating overlay service and widget updates while the app is running in the background.\n\n• Notifications (POST_NOTIFICATIONS): Optional notifications regarding task reminders and floating companion status.\n\n• Internet Access: Required to synchronize tasks with the cloud server and authenticate via Google Identity Services.',
                  ),
                  _LegalSection(
                    title: '4. Third-Party Services & Analytics',
                    content:
                        'We utilize Google Sign-In for secure authentication. We do not sell, rent, or trade your personal data or task details to third-party advertisers or data brokers.',
                  ),
                  _LegalSection(
                    title: '5. Data Retention & Deletion',
                    content:
                        'Your task data is retained as long as your account is active. You can delete individual tasks anytime from within the app. If you wish to delete your entire account and associated records, please reach out via the contact information below.',
                  ),
                  _LegalSection(
                    title: '6. Contact & Inquiries',
                    content:
                        'If you have questions or concerns regarding this Privacy Policy, please contact developer Nandakishore P via email at nandakishorep212@gmail.com or GitHub: https://github.com/nanda-kshr',
                  ),
                ],
              ),
              _PolicyScrollView(
                lastUpdated: 'October 2026',
                sections: const [
                  _LegalSection(
                    title: '1. Acceptance of Terms',
                    content:
                        'By downloading, installing, accessing, or using TodoCat, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please refrain from using the application.',
                  ),
                  _LegalSection(
                    title: '2. User Accounts',
                    content:
                        'You are responsible for safeguarding your login credentials and for any activity carried out under your account. You agree to notify us immediately of any unauthorized use or security breach.',
                  ),
                  _LegalSection(
                    title: '3. Permitted & Acceptable Use',
                    content:
                        'TodoCat is intended for personal and team productivity. You agree not to:\n• Use the application for any illegal, fraudulent, or harmful purposes.\n• Attempt to reverse engineer, disrupt, or overload our servers and backend APIs.\n• Exploit any vulnerabilities or circumvent authentication controls.',
                  ),
                  _LegalSection(
                    title: '4. Intellectual Property',
                    content:
                        'All rights, titles, and interests in and to TodoCat, including the software, UI design, animations, and branding, remain the exclusive property of Nandakishore P and its respective contributors.',
                  ),
                  _LegalSection(
                    title: '5. Disclaimer of Warranties',
                    content:
                        'TodoCat is provided on an "AS IS" and "AS AVAILABLE" basis without any express or implied warranties, including fitness for a particular purpose, uptime, or error-free operation.',
                  ),
                  _LegalSection(
                    title: '6. Limitation of Liability',
                    content:
                        'To the maximum extent permitted by applicable law, in no event shall the developer be liable for any indirect, incidental, or consequential damages resulting from the use or inability to use TodoCat.',
                  ),
                  _LegalSection(
                    title: '7. Changes to Terms',
                    content:
                        'We reserve the right to revise or update these terms at our sole discretion. Continued use of TodoCat following the posting of any changes constitutes acceptance of the new terms.',
                  ),
                  _LegalSection(
                    title: '8. Contact Information',
                    content:
                        'For any legal questions regarding these Terms, contact Nandakishore P via email at nandakishorep212@gmail.com or on GitHub: https://github.com/nanda-kshr',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyScrollView extends StatelessWidget {
  final String lastUpdated;
  final List<_LegalSection> sections;

  const _PolicyScrollView({
    required this.lastUpdated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last updated: $lastUpdated',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          for (final section in sections) ...[
            section,
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String content;

  const _LegalSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF181818) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF242424) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF4B5563);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Sniglet',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

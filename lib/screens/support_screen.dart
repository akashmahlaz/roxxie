/// 🆘 GIGMATCH Help & Support Screen
/// User support and FAQ
library;

import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import '../widgets/widgets.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  int _expandedIndex = -1;

  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I create an account?',
      answer:
          'Simply download the app, choose whether you\'re an artist or venue, and follow the setup wizard. You\'ll need to provide basic information and verify your email.',
    ),
    FAQItem(
      question: 'How does matching work?',
      answer:
          'Swipe right on profiles you like, left on those you don\'t. When both parties swipe right on each other, it\'s a match! You can then start chatting and arrange your gig.',
    ),
    FAQItem(
      question: 'Is GigMatch free to use?',
      answer:
          'Yes! GigMatch offers a free tier with basic features. We also offer Premium subscriptions with additional features like unlimited likes, profile boosts, and more.',
    ),
    FAQItem(
      question: 'How do I report inappropriate content?',
      answer:
          'Tap the three dots menu on any profile or message, then select "Report". We take safety seriously and review all reports promptly.',
    ),
    FAQItem(
      question: 'Can I change my account type?',
      answer:
          'Currently, you\'ll need to create a new account to switch between artist and venue roles. We\'re working on making this easier in a future update.',
    ),
    FAQItem(
      question: 'How do I cancel my Premium subscription?',
      answer:
          'Go to Settings > Premium Subscription > Cancel Subscription. You\'ll continue to have Premium features until the end of your billing period.',
    ),
    FAQItem(
      question: 'What payment methods do you accept?',
      answer:
          'We accept all major credit cards, debit cards, and PayPal. Payment is processed securely through our payment partners.',
    ),
    FAQItem(
      question: 'How do I delete my account?',
      answer:
          'Go to Settings > Account > Delete Account. Note that this action is permanent and cannot be undone. All your data will be deleted.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.surface(brightness),
        elevation: 0,
        leading: GlassBackButton(),
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.crimson, Colors.purple.shade600],
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How can we help you?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Find answers to common questions or contact us',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildActionCard(
                    'Email Support',
                    'Get help via email within 24 hours',
                    Icons.email_rounded,
                    () => _contactSupport('email'),
                    brightness,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    'Live Chat',
                    'Chat with our support team',
                    Icons.chat_rounded,
                    () => _contactSupport('chat'),
                    brightness,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    'Report a Bug',
                    'Help us improve the app',
                    Icons.bug_report_rounded,
                    () => _reportBug(),
                    brightness,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // FAQs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      color: AppColors.crimson,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._faqs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final faq = entry.value;
                    return _buildFAQItem(faq, index, brightness);
                  }),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Contact Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface(brightness),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Still need help?',
                      style: TextStyle(
                        color: AppColors.offWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our support team is available 24/7',
                      style: TextStyle(
                        color: AppColors.textSec(brightness),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildContactMethod(
                          Icons.email_rounded,
                          'Email',
                          'support@gigmatch.com',
                          brightness,
                        ),
                        _buildContactMethod(
                          Icons.phone_rounded,
                          'Phone',
                          '+1 (555) 123-4567',
                          brightness,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    Brightness brightness,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(brightness)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.crimson, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.text(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSec(brightness),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSec(brightness),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq, int index, Brightness brightness) {
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? AppColors.crimson : AppColors.border(brightness),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? -1 : index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      faq.question,
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.crimson,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  faq.answer,
                  style: TextStyle(
                    color: AppColors.textSec(brightness),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactMethod(
    IconData icon,
    String label,
    String value,
    Brightness brightness,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.crimson, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: AppColors.textSec(brightness), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.text(brightness),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _contactSupport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $type support...'),
        backgroundColor: AppColors.crimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _reportBug() {
    showDialog(
      context: context,
      builder: (context) {
        final descriptionController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.surface(Theme.of(context).brightness),
          title: const Text('Report a Bug'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please describe the issue you encountered:'),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe the bug...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Bug report submitted. Thank you!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}

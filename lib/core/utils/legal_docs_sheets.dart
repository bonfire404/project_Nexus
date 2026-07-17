import 'package:flutter/material.dart';

void showTosSheet(BuildContext context, ThemeData theme) {
  _showTextDocumentSheet(
    context,
    theme,
    'Terms of Service',
    'By using Excelerate Nexus, you agree to these internship terms. \n\n'
    '1. Professional Conduct: You will maintain a professional demeanor in all communications with mentors, administrators, and peers on the platform.\n'
    '2. Confidentiality: You agree not to disclose proprietary or sensitive information related to the programs, deliverables, or the organization.\n'
    '3. Deliverable Ownership: All internship deliverables submitted through the platform become the property of Excelerate Nexus unless explicitly stated otherwise.\n'
    '4. Account Responsibility: You are responsible for maintaining the security of your account, including biometric authentications.',
  );
}

void showPrivacySheet(BuildContext context, ThemeData theme) {
  _showTextDocumentSheet(
    context,
    theme,
    'Privacy Policy',
    'Your privacy matters to Excelerate Nexus. \n\n'
    '1. Data Collection: We collect information related to your application status, internship progress, and deliverables to provide you with tailored support.\n'
    '2. Data Usage: Your data is used exclusively to facilitate your internship and evaluation process. We do not sell your personal data to third parties.\n'
    '3. Biometric Data: If enabled, biometric data is stored securely on your local device and is never transmitted to our servers.\n'
    '4. Anonymized Analytics: We may use anonymized platform usage data to improve the application experience for future cohorts.',
  );
}

void _showTextDocumentSheet(BuildContext context, ThemeData theme, String title, String content) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Kameron',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ),
  );
}

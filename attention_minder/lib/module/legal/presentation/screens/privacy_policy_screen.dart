import 'package:flutter/material.dart';
import 'legal_screen.dart';
import 'terms_of_service_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LegalScreen(
      onTermsTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
        );
      },
      title: 'Privacy policy',
      introText:
          'Welcome to ADHD Mentor! Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information when you use our app. We are committed to safeguarding your privacy while providing a seamless experience to help you manage ADHD through our Cognitive Behavioral Therapy (CBT) tools.',
      children: [
        LegalAccordionItem(
          title: 'Data Collection',
          content:
              'Personal Information: Your name, email address, and phone number when you create an account.',
          isOpen: true,
        ),
        LegalAccordionItem(
          title: 'Data Usage',
          content:
              'We use your data to provide and improve our services, including personalizing your experience and communicating with you.',
        ),
        LegalAccordionItem(
          title: 'User Rights',
          content:
              'You have the right to access, correct, or delete your personal information at any time.',
        ),
        LegalAccordionItem(
          title: 'Security Practices',
          content:
              'We implement industry-standard security measures to protect your data from unauthorized access.',
        ),
        LegalAccordionItem(
          title: 'Legal Terms (in case of Terms and Conditions)',
          content:
              'Please refer to our Terms of Service for full legal details regarding the use of our application.',
        ),
        LegalAccordionItem(
          title: 'Data Usage',
          content: 'Additional details about data usage...',
        ),
      ],
    );
  }
}

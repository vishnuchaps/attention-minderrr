import 'package:flutter/material.dart';
import 'legal_screen.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Terms of Service',
      introText:
          'All content within the ADHD Mentor app, including text, graphics, logos, and software, is the property of ADHD Mentor and is protected by intellectual property laws. You may not use, reproduce, or distribute this content without our permission.\n\nThese terms are governed by and construed in accordance with the laws of the United States. Any disputes arising from these terms will be subject to the exclusive jurisdiction of the courts of San Francisco, California.',
      children: [
        // Note: The image shows these items inside a white card as well, similar to layout.
        // The image actually repeats "Data Usage", "User Rights" etc. matching the Privacy Policy.
        // I will replicate the list shown in the Terms image.
        LegalAccordionItem(
          title: 'Data Usage',
          content:
              'Personal Information: Your name, email address, and phone number when you create an account.',
          isOpen: true,
        ),
        LegalAccordionItem(
          title: 'User Rights',
          content: 'Content ownership and usage rights...',
        ),
        LegalAccordionItem(
          title: 'Security Practices',
          content: 'User responsibilities regarding account security...',
        ),
        LegalAccordionItem(
          title: 'Legal Terms (in case of Terms and Conditions)',
          content: 'Disclaimer of warranties and limitation of liability...',
        ),
        LegalAccordionItem(
          title: 'Data Usage',
          content: 'Termination clauses...',
        ),
      ],
    );
  }
}

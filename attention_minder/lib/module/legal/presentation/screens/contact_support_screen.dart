import 'dart:io';

import 'package:attention_minder/constant/colors.dart';
import 'package:attention_minder/constant/text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({Key? key}) : super(key: key);

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedAttachment;

  Future<void> _pickAttachment() async {
    final result = await FilePicker.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedAttachment = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitReport() async {
    if (_subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter both subject and description",
            style: TextStyles.poppinsR14White,
          ),
          backgroundColor: AppColor.redColor,
        ),
      );
      return;
    }

    // Construct the email URI
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'info@truefoxaiinc.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': _subjectController.text,
        'body':
            '${_descriptionController.text}\n\n'
            '${_selectedAttachment != null ? '(Attachment: ${_selectedAttachment!.path.split('/').last} was attached in app. Note: Some mail clients do not support auto-attachments via mailto links. Please re-attach if necessary.)' : ''}',
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
        // Clear fields on successful launch
        _subjectController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedAttachment = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Email client opened",
                style: TextStyles.poppinsR14White,
              ),
              backgroundColor: AppColor.greenColor,
            ),
          );
        }
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Could not open email app. Please send an email directly to info@truefoxaiinc.com.",
              style: TextStyles.poppinsR14White,
            ),
            backgroundColor: AppColor.redColor,
          ),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0), // Matching theme background
      body: Stack(
        children: [
          // Background decorations matching LegalScreen
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColor.appYellowColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColor.appYellowColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 60),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColor.whiteColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: AppColor.designBlackColor,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Contact Support",
                        textAlign: TextAlign.center,
                        style: TextStyles.poppinsB20Black,
                      ),
                    ),
                    const SizedBox(width: 40), // Balance back button
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Main content card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColor.bottomNavigatorColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "How can we help you?",
                            style: TextStyles.poppinsS18Black,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please provide the details below to submit your query to our support team.",
                            style: TextStyles.poppinsR14Black.copyWith(
                              color: AppColor.darkGreyColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Subject Field
                          Text("Subject", style: TextStyles.poppinsM16Black),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _subjectController,
                            style: TextStyles.poppinsR14Black,
                            decoration: InputDecoration(
                              hintText: "Enter the issue subject",
                              hintStyle: TextStyles.poppinsR14Black.copyWith(
                                color: AppColor.greyColor,
                              ),
                              filled: true,
                              fillColor: AppColor.whiteColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColor.borderGreyColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColor.borderGreyColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColor.appYellowColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Description Field
                          Text(
                            "Description",
                            style: TextStyles.poppinsM16Black,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            style: TextStyles.poppinsR14Black,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: "Describe your issue in detail...",
                              hintStyle: TextStyles.poppinsR14Black.copyWith(
                                color: AppColor.greyColor,
                              ),
                              filled: true,
                              fillColor: AppColor.whiteColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColor.borderGreyColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColor.borderGreyColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColor.appYellowColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Attachment Option
                          Text(
                            "Attachment (Optional)",
                            style: TextStyles.poppinsM16Black,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickAttachment,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColor.whiteColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColor.appYellowColor,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    color: AppColor.appYellowColor,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedAttachment == null
                                        ? "Tap to upload file"
                                        : "Selected: ${_selectedAttachment!.path.split('/').last}",
                                    style: TextStyles.poppinsM14Black,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitReport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColor.lightBlueColor, // Matching theme
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                "Submit Report",
                                style: TextStyles.poppinsS16Black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

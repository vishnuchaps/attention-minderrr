import 'package:attention_minder/Config/widgets/user_profile_avatar_widget.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/video_treatment_screen.dart';
import 'package:attention_minder/module/file_handler/data/model/video_file_model.dart';
import 'package:attention_minder/module/file_handler/presentation/bloc/file_handler_bloc.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/pdf_treatment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AttentionProgramScreen extends StatefulWidget {
  const AttentionProgramScreen({super.key});

  @override
  State<AttentionProgramScreen> createState() => _AttentionProgramScreenState();
}

class _AttentionProgramScreenState extends State<AttentionProgramScreen> {
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    // Fetch files when screen initializes
    context.read<FileHandlerBloc>().add(FetchFilesEvent(isManagement: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(child: _content()),
            _bottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const UserProfileAvatar(size: 40),
        ],
      ),
    );
  }

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            "Attention management using AI",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "This is your personal program based on\nThe assessment you have taken",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          _daySelector(),
          const SizedBox(height: 24),
          Expanded(child: _taskSection()),
        ],
      ),
    );
  }

  Widget _daySelector() {
    return Row(
      children: [
        _dayCard("Day 1", 1),
        _dayCard("Day 2", 2),
        _dayCard("Day 3", 3),
        _dayCard("Day 4", 4),
      ],
    );
  }

  Widget _dayCard(String text, int day) {
    final bool active = _selectedDay == day;
    final bool locked =
        false; // keys.day > 1; // Unlocked for now as per requirement

    return GestureDetector(
      onTap: () {
        if (!locked) {
          setState(() {
            _selectedDay = day;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFF7C14A) : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: active ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (active)
              const Padding(
                padding: EdgeInsets.all(8),
                child: CircleAvatar(radius: 3, backgroundColor: Colors.black),
              ),
            // Locked visual removed as per requirement to unlock all days
            /*
            if (locked)
              const Padding(
                padding: EdgeInsets.all(8),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFFF7C14A),
                  child: Icon(Icons.lock, size: 12, color: Colors.black),
                ),
              ),
            */
          ],
        ),
      ),
    );
  }

  Widget _taskSection() {
    return BlocBuilder<FileHandlerBloc, FileHandlerState>(
      builder: (context, state) {
        if (state is FileHandlerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FileHandlerError) {
          return Center(
            child: Text(
              'Error: ${state.errorMessage}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (state is FilesLoadedSuccess) {
          final files = state.filesData
              .where((f) => f.day == _selectedDay)
              .toList();

          if (files.isEmpty) {
            return const Center(
              child: Text(
                "No content for this day yet.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            itemCount: files.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _fileTile(files[index]);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _fileTile(VideoFile file) {
    bool isPdf = file.mediaType == 'file' || file.key.endsWith('.pdf');
    IconData icon = isPdf ? Icons.picture_as_pdf : Icons.play_circle_fill;

    return GestureDetector(
      onTap: () {
        if (isPdf) {
          _openPdf(file);
        } else {
          // Navigate to video treatment
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoTreatmentScreen(
                day: _selectedDay,
                videos: [
                  file,
                ], // Passing single video for now as per API structure/UI click
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                file.fileName,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF7C14A),
              child: Icon(icon, color: Colors.black, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPdf(VideoFile file) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final url = file.url;
      final filename = file.fileName;
      final request = await http.get(Uri.parse(url));
      final bytes = request.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final File f = File('${dir.path}/$filename');
      await f.writeAsBytes(bytes, flush: true);

      if (mounted) {
        Navigator.pop(context); // hide loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfTreatmentScreen(
              day: _selectedDay,
              fileData: file,
              localPath: f.path,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // hide loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error opening PDF: $e")));
      }
    }
  }

  Widget _bottomButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3D7BFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {},
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Next", style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }
}

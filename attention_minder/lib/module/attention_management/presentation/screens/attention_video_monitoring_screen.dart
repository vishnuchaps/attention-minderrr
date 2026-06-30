import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:attention_minder/module/attention_management/presentation/screens/pdf_treatment_screen.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/video_treatment_screen.dart';
import 'package:attention_minder/module/file_handler/data/model/video_file_model.dart';
import 'package:attention_minder/module/file_handler/presentation/bloc/file_handler_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttentionVideoMonitoringScreen extends StatefulWidget {
  final int day;

  const AttentionVideoMonitoringScreen({super.key, this.day = 1});

  @override
  State<AttentionVideoMonitoringScreen> createState() =>
      _AttentionVideoMonitoringScreenState();
}

class _AttentionVideoMonitoringScreenState
    extends State<AttentionVideoMonitoringScreen> {
  bool isAIActive = false;
  bool isVideoPlaying = false;
  List<VideoFile> dayVideos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<FileHandlerBloc>().add(FetchFilesEvent(isManagement: true));
  }

  Future<void> _openPdf(BuildContext context, VideoFile file) async {
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
              day: widget.day,
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: BlocListener<FileHandlerBloc, FileHandlerState>(
        listener: (context, state) {
          if (state is FilesLoadedSuccess) {
            try {
              setState(() {
                dayVideos = state.filesData
                    .where((video) => video.day == widget.day)
                    .toList();
                isLoading = false;
              });
            } catch (e) {
              setState(() {
                isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading videos: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else if (state is FileHandlerError) {
            setState(() {
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5), Color(0xFFFFFFFF)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios),
                        color: const Color(0xFF42A5F5),
                      ),
                      Expanded(
                        child: Text(
                          'AI Video Session',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF42A5F5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI Info Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF42A5F5).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.psychology,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AI Monitoring',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isAIActive
                                                    ? const Color(0xFF66BB6A)
                                                    : Colors.white60,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isAIActive
                                                  ? 'Active'
                                                  : 'Inactive',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.035,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                'AI will monitor your attention. When attention drops, the video pauses and feedback is given.',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.038,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Video Player Placeholder
                        Container(
                          width: double.infinity,
                          height: screenHeight * 0.25,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: isVideoPlaying
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.videocam,
                                            size: 50,
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Video Playing...',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              fontSize: screenWidth * 0.04,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.play_circle_outline,
                                            size: 60,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Understanding Attention',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: screenWidth * 0.04,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              if (isAIActive)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF66BB6A),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'AI Active',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.03,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Video List
                        Text(
                          'Video Lessons',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF42A5F5),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Display videos from API
                        if (isLoading)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.05,
                              ),
                              child: const CircularProgressIndicator(
                                color: Color(0xFF42A5F5),
                              ),
                            ),
                          )
                        else if (dayVideos.isEmpty)
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.05),
                            margin: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange.shade700,
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: Text(
                                    'No videos available for Day ${widget.day}',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.038,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...dayVideos.asMap().entries.map((entry) {
                            int index = entry.key;
                            VideoFile video = entry.value;
                            return _buildVideoCard(
                              screenWidth,
                              screenHeight,
                              video.fileName
                                  .replaceAll('.mp4', '')
                                  .replaceAll('-', ' '),
                              'Video ${index + 1}',
                              index == 0,
                            );
                          }),

                        SizedBox(height: screenHeight * 0.03),

                        // Start Session Button
                        GestureDetector(
                          onTap: () {
                            if (isLoading) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Loading videos, please wait...',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (dayVideos.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'No videos available for Day ${widget.day}',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            // Navigate based on media type of the first item (assuming session contains same type)
                            final firstFile = dayVideos.first;
                            if (firstFile.mediaType == 'file' ||
                                firstFile.url.endsWith('.pdf')) {
                              _openPdf(context, firstFile);
                            } else {
                              // Default to video treatment
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoTreatmentScreen(
                                    day: widget.day,
                                    videos: dayVideos,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.022,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF42A5F5,
                                  ).withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isLoading)
                                  SizedBox(
                                    width: screenWidth * 0.05,
                                    height: screenWidth * 0.05,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: screenWidth * 0.06,
                                  ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  isLoading
                                      ? 'Loading Videos...'
                                      : 'Start AI Video Session',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(
    double screenWidth,
    double screenHeight,
    String title,
    String duration,
    bool isPlaying,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlaying ? const Color(0xFF42A5F5) : const Color(0xFFE0E0E0),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF42A5F5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPlaying ? Icons.play_arrow : Icons.play_circle_outline,
              color: const Color(0xFF42A5F5),
              size: 32,
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        duration,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isPlaying)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Playing',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAIFeedback(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && isAIActive) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFA726), Color(0xFFFF9800)],
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'Attention Detected Low',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEF6C00),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Take a moment to refocus. Video is paused.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Resume',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });
  }
}

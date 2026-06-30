import 'dart:io';

import 'package:attention_minder/Config/widgets/user_profile_avatar_widget.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/attention_video_monitoring_screen.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/pdf_treatment_screen.dart';
import 'package:attention_minder/module/attention_management/presentation/screens/video_treatment_screen.dart';
import 'package:attention_minder/module/file_handler/data/model/video_file_model.dart';
import 'package:attention_minder/module/file_handler/presentation/bloc/file_handler_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class AttentionProgramOverviewScreen extends StatefulWidget {
  final bool showBackButton;

  const AttentionProgramOverviewScreen({super.key, this.showBackButton = true});

  @override
  State<AttentionProgramOverviewScreen> createState() =>
      _AttentionProgramOverviewScreenState();
}

class _AttentionProgramOverviewScreenState
    extends State<AttentionProgramOverviewScreen> {
  static const _ink = Color(0xFF08112F);
  static const _muted = Color(0xFF68738F);
  static const _orange = Color(0xFFFFA300);
  static const _green = Color(0xFF31A322);
  static const _purple = Color(0xFF9652F4);
  static const _pageBackground = Color(0xFFFBFCFF);

  List<VideoFile> allVideos = [];
  bool isLoading = true;
  String? errorMessage;
  int maxDay = 0;
  int selectedDay = 1;
  Map<int, List<VideoFile>> videosByDay = {};

  @override
  void initState() {
    super.initState();
    context.read<FileHandlerBloc>().add(FetchFilesEvent(isManagement: true));
  }

  void _processVideoData(List<VideoFile> videos) {
    allVideos = videos;
    videosByDay.clear();
    maxDay = 0;

    int latestUnlockedDay = 1;

    for (final video in videos) {
      if (video.day > maxDay) {
        maxDay = video.day;
      }

      videosByDay.putIfAbsent(video.day, () => []);
      videosByDay[video.day]!.add(video);

      if (video.isLocked == false && video.day > latestUnlockedDay) {
        latestUnlockedDay = video.day;
      }
    }

    for (final entry in videosByDay.entries) {
      entry.value.sort((a, b) => a.orderNumber.compareTo(b.orderNumber));
    }

    setState(() {
      isLoading = false;
      selectedDay = latestUnlockedDay;
    });
  }

  Future<void> _openPdf(BuildContext context, VideoFile file) async {
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

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfTreatmentScreen(
              day: selectedDay,
              fileData: file,
              localPath: f.path,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error opening PDF: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: BlocListener<FileHandlerBloc, FileHandlerState>(
        listener: (context, state) {
          if (state is FilesLoadedSuccess) {
            try {
              _processVideoData(state.filesData);
            } catch (e) {
              setState(() {
                isLoading = false;
                errorMessage = 'Error loading videos: $e';
              });
            }
          } else if (state is FileHandlerError) {
            setState(() {
              isLoading = false;
              errorMessage = state.errorMessage;
            });
          }
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: _orange))
            : errorMessage != null
            ? _errorState()
            : SafeArea(bottom: false, child: _content()),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: _textStyle(fontSize: 15, color: _muted, height: 1.45),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                context.read<FileHandlerBloc>().add(FetchFilesEvent());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width < 360 ? 14.0 : 20.0;
        final maxContentWidth = width > 560 ? 520.0 : width;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                20 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroHeader(width),
                  const SizedBox(height: 22),
                  _daySelector(),
                  const SizedBox(height: 24),
                  _sectionTitle("Video Lessons"),
                  const SizedBox(height: 12),
                  _videoLessons(),
                  const SizedBox(height: 24),
                  _sectionTitle("Daily Activities"),
                  const SizedBox(height: 12),
                  _dailyActivities(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _heroHeader(double width) {
    final compact = width < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.showBackButton) _backButton(),
            const Spacer(),
            const UserProfileAvatar(size: 48),
          ],
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Text(
            "Let's continue your journey to better focus and mental well-being.",
            style: _textStyle(
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: _ink,
              height: 1.24,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Your program is ready for today.",
          style: _textStyle(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: _muted,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.maybePop(context),
        customBorder: const CircleBorder(),
        child: Ink(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE9ECF3), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC9D0DF).withValues(alpha: .35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.chevron_left_rounded, color: _ink, size: 30),
        ),
      ),
    );
  }

  Widget _daySelector() {
    final days = videosByDay.keys.toList()..sort();
    final displayDays = days.isEmpty
        ? List<int>.generate(4, (index) => index + 1)
        : days.length < 4
        ? List<int>.generate(4, (index) => index + 1)
        : days;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 360 ? 8.0 : 10.0;
        final tileWidth = (constraints.maxWidth - (gap * 3)) / 4;

        return SizedBox(
          height: 66,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: displayDays.length <= 4
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            itemCount: displayDays.length,
            separatorBuilder: (_, index) => SizedBox(width: gap),
            itemBuilder: (context, index) {
              final day = displayDays[index];
              final files = videosByDay[day] ?? [];
              final isActive = day == selectedDay;
              final isLocked =
                  files.isEmpty || files.every((file) => file.isLocked == true);

              return GestureDetector(
                onTap: () {
                  if (!isLocked) {
                    setState(() {
                      selectedDay = day;
                    });
                  }
                },
                child: _dayCard(
                  day,
                  width: tileWidth.clamp(68.0, 88.0),
                  active: isActive,
                  locked: isLocked,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _dayCard(
    int day, {
    required double width,
    bool active = false,
    bool locked = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      height: 66,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFF7DA) : const Color(0xFFF8F8FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? const Color(0xFFFFCF62) : const Color(0xFFEFF0F5),
          width: active ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? const Color(0xFFFFD56F).withValues(alpha: .22)
                : const Color(0xFFBFC7DA).withValues(alpha: .13),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day == 1 ? "Day 1☀️" : "Day $day",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _ink,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          if (active)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _orange,
                shape: BoxShape.circle,
              ),
            )
          else if (locked)
            const Icon(Icons.lock_outline_rounded, size: 16, color: _muted)
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: _textStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: _ink,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  Widget _videoLessons() {
    final selectedVideos = videosByDay[selectedDay] ?? [];

    if (selectedVideos.isEmpty) {
      return _emptyContentCard();
    }

    return Column(
      children: selectedVideos.asMap().entries.map((entry) {
        final index = entry.key;
        final file = entry.value;
        final isPdf = file.mediaType == 'file' || file.key.endsWith('.pdf');
        final locked = file.isLocked == true;
        final title = _cleanTitle(file.fileName);

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == selectedVideos.length - 1 ? 0 : 12,
          ),
          child: _lessonCard(
            file: file,
            number: index + 1,
            title: title,
            subtitle: isPdf
                ? "Learn from today's focus document."
                : index == 0
                ? "Learn the basics of attention\nand how it works."
                : "Practice techniques to\nimprove your focus.",
            duration: _lessonDuration(index),
            locked: locked,
            isPdf: isPdf,
            onTap: () {
              if (isPdf) {
                _openPdf(context, file);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VideoTreatmentScreen(day: selectedDay, videos: [file]),
                  ),
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _lessonCard({
    required VideoFile file,
    required int number,
    required String title,
    required String subtitle,
    required String duration,
    required bool locked,
    required bool isPdf,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final thumbWidth = compact ? 92.0 : 104.0;
        final thumbHeight = compact ? 82.0 : 90.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDDE3F2).withValues(alpha: .62),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _lessonThumbnail(
                    file: file,
                    isPdf: isPdf,
                    locked: locked,
                    width: thumbWidth,
                    height: thumbHeight,
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: thumbHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$number. $title",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              height: 1.18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _textStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _muted,
                              height: 1.32,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: _muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    duration,
                                    style: _textStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                              _statusPill(
                                locked
                                    ? "Locked • Complete Video 1"
                                    : "Ready to start",
                                foreground: locked ? _purple : _green,
                                background: locked
                                    ? const Color(0xFFF0DEFF)
                                    : const Color(0xFFE4F6E3),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    _roundArrow(size: 40, iconSize: 28),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _lessonThumbnail({
    required VideoFile file,
    required bool isPdf,
    required bool locked,
    required double width,
    required double height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: height,
        width: width,
        child: isPdf
            ? _pdfThumbnail()
            : _VideoFrameThumbnail(videoUrl: file.url, locked: locked),
      ),
    );
  }

  Widget _pdfThumbnail() {
    return Container(
      color: const Color(0xFFF4F6FA),
      child: const Icon(
        Icons.picture_as_pdf_rounded,
        color: Color(0xFFE05252),
        size: 34,
      ),
    );
  }

  Widget _emptyContentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDDE3F2).withValues(alpha: .7),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        "No content available for this day yet.",
        style: _textStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _muted,
        ),
      ),
    );
  }

  Widget _dailyActivities() {
    final selectedVideos = videosByDay[selectedDay] ?? [];
    final hasVideos = selectedVideos.isNotEmpty;
    final isLocked =
        selectedVideos.isEmpty ||
        selectedVideos.every((file) => file.isLocked == true);
    final canStart = hasVideos && !isLocked;

    return Column(
      children: [
        _activityCard(
          icon: Icons.track_changes_rounded,
          title: "Goal Setting",
          subtitle: "Set today's focus goal\nand intention.",
          status: "Not started",
          statusColor: _green,
          iconColor: _green,
          background: const Color(0xFFF1FAED),
          onTap: canStart
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AttentionVideoMonitoringScreen(day: selectedDay),
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: 12),
        _activityCard(
          icon: Icons.menu_book_rounded,
          title: "Daily Reflection",
          subtitle: "Reflect on your learning\nand progress.",
          status: "Not started",
          statusColor: _purple,
          iconColor: _purple,
          background: const Color(0xFFF7F0FF),
        ),
        const SizedBox(height: 12),
        _activityCard(
          icon: Icons.star_border_rounded,
          title: "Progress Tracking",
          subtitle: "View your progress\nand insights.",
          status: "View",
          statusColor: _orange,
          iconColor: const Color(0xFFFFB000),
          background: const Color(0xFFFFF6DE),
        ),
      ],
    );
  }

  Widget _activityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required Color iconColor,
    required Color background,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: background.withValues(alpha: .55),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusPill(
                    status,
                    foreground: statusColor,
                    background: Colors.white.withValues(alpha: .45),
                  ),
                  const SizedBox(height: 10),
                  _roundArrow(size: 40, iconSize: 28),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundArrow({double size = 44, double iconSize = 30}) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC9D0DF).withValues(alpha: .45),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: const Color(0xFFE9ECF3), width: 1),
      ),
      child: Icon(
        Icons.chevron_right_rounded,
        color: const Color(0xFF222738),
        size: iconSize,
      ),
    );
  }

  Widget _statusPill(
    String text, {
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _textStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
          height: 1,
        ),
      ),
    );
  }

  String _cleanTitle(String fileName) {
    final normalized = fileName
        .replaceAll('.mp4', '')
        .replaceAll('.pdf', '')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .trim();

    if (normalized.isEmpty) {
      return "Understanding Attention";
    }

    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.length == 1) {
            return word.toUpperCase();
          }
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _lessonDuration(int index) {
    const durations = ["08:24", "12:16", "09:40", "10:32"];
    return durations[index % durations.length];
  }

  TextStyle _textStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = _ink,
    double? height,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}

class _VideoFrameThumbnail extends StatefulWidget {
  final String videoUrl;
  final bool locked;

  const _VideoFrameThumbnail({required this.videoUrl, required this.locked});

  @override
  State<_VideoFrameThumbnail> createState() => _VideoFrameThumbnailState();
}

class _VideoFrameThumbnailState extends State<_VideoFrameThumbnail> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadVideoFrame();
  }

  @override
  void didUpdateWidget(covariant _VideoFrameThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _loadVideoFrame();
    }
  }

  Future<void> _loadVideoFrame() async {
    final generation = ++_loadGeneration;
    final url = widget.videoUrl.trim();
    if (url.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
      return;
    }

    VideoPlayerController? controller;

    try {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;
      await controller.initialize();
      await controller.setVolume(0);
      await controller.pause();

      if (mounted && generation == _loadGeneration) {
        setState(() {
          _hasError = false;
        });
      } else {
        await controller.dispose();
      }
    } catch (_) {
      if (generation == _loadGeneration) {
        _controller = null;
      }
      await controller?.dispose();

      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    _loadGeneration++;
    final controller = _controller;
    _controller = null;
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: const Color(0xFF111827),
          child: isReady
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                )
              : Center(
                  child: _hasError
                      ? const SizedBox.shrink()
                      : const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                ),
        ),
        if (widget.locked)
          ColoredBox(color: Colors.black.withValues(alpha: .28)),
      ],
    );
  }
}

import 'package:attention_minder/module/attention_management/presentation/screens/hybrid_video_treatment_screen.dart';
import 'package:attention_minder/module/file_handler/data/model/video_file_model.dart';
import 'package:attention_minder/module/file_handler/presentation/bloc/file_handler_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

class AiAssessmentListScreen extends StatefulWidget {
  const AiAssessmentListScreen({super.key});

  @override
  State<AiAssessmentListScreen> createState() => _AiAssessmentListScreenState();
}

class _AiAssessmentListScreenState extends State<AiAssessmentListScreen> {
  static const _navy = Color(0xFF071443);
  static const _body = Color(0xFF52617E);
  static const _blue = Color(0xFF157CF3);

  @override
  void initState() {
    super.initState();
    context.read<FileHandlerBloc>().add(FetchFilesEvent(isManagement: false));
  }

  Future<void> _refresh() async {
    final bloc = context.read<FileHandlerBloc>();
    bloc.add(FetchFilesEvent(isManagement: false));
    await bloc.stream.firstWhere(
      (state) => state is FilesLoadedSuccess || state is FileHandlerError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = (width / 430).clamp(.82, 1.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      body: SafeArea(
        child: BlocBuilder<FileHandlerBloc, FileHandlerState>(
          builder: (context, state) {
            final videos = state is FilesLoadedSuccess
                ? state.filesData.where((file) => file.isVideo).toList()
                : const <VideoFile>[];

            return RefreshIndicator(
              color: _blue,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      22 * scale,
                      28 * scale,
                      22 * scale,
                      0,
                    ),
                    sliver: SliverList.list(
                      children: [
                        _PageHeader(scale: scale),
                        SizedBox(height: 24 * scale),
                        _IntroCard(scale: scale),
                        SizedBox(height: 25 * scale),
                        _LibraryHeader(
                          scale: scale,
                          videoCount: videos.length,
                          showCount: state is FilesLoadedSuccess,
                        ),
                        SizedBox(height: 14 * scale),
                      ],
                    ),
                  ),
                  _contentSliver(state, videos, scale),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 28 * scale + MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _contentSliver(
    FileHandlerState state,
    List<VideoFile> videos,
    double scale,
  ) {
    if (state is FileHandlerLoading || state is FileHandlerInitial) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 22 * scale),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12 * scale,
            mainAxisSpacing: 13 * scale,
            mainAxisExtent: (205 * scale).clamp(174, 205),
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _VideoCardSkeleton(scale: scale),
            childCount: 4,
          ),
        ),
      );
    }

    if (state is FileHandlerError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _MessageState(
          icon: Icons.cloud_off_rounded,
          title: 'Unable to load videos',
          message: state.errorMessage,
          actionLabel: 'Try again',
          onAction: () => context.read<FileHandlerBloc>().add(
            FetchFilesEvent(isManagement: false),
          ),
        ),
      );
    }

    if (videos.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _MessageState(
          icon: Icons.video_library_outlined,
          title: 'No videos yet',
          message: 'Your assessment videos will appear here when available.',
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 22 * scale),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12 * scale,
          mainAxisSpacing: 13 * scale,
          mainAxisExtent: (205 * scale).clamp(174, 205),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _VideoCard(
            file: videos[index],
            index: index,
            scale: scale,
            onTap: () => _openVideo(videos[index]),
          ),
          childCount: videos.length,
        ),
      ),
    );
  }

  void _openVideo(VideoFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => buildVideoTreatmentScreen(
          day: file.day,
          videos: [file],
          isAssessment: true,
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final double scale;

  const _PageHeader({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 7,
          shadowColor: const Color(0xFF243557).withValues(alpha: .18),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: SizedBox(
              width: 42 * scale,
              height: 42 * scale,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _AiAssessmentListScreenState._navy,
                size: 20 * scale,
              ),
            ),
          ),
        ),
        SizedBox(width: 14 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Assessment',
                style: TextStyle(
                  color: _AiAssessmentListScreenState._navy,
                  fontSize: (24 * scale).clamp(21, 24),
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 5 * scale),
              Text(
                'Video library',
                style: TextStyle(
                  color: _AiAssessmentListScreenState._body,
                  fontSize: 12 * scale,
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  final double scale;

  const _IntroCard({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16 * scale),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF03102E), Color(0xFF0B3473)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E3473).withValues(alpha: .18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48 * scale,
            height: 48 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13 * scale),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF589DFF), Color(0xFF6E6FF2)],
              ),
            ),
            child: Icon(
              Icons.smart_display_rounded,
              color: Colors.white,
              size: 27 * scale,
            ),
          ),
          SizedBox(width: 13 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a video to begin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (15 * scale).clamp(13.5, 15),
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7 * scale),
                Text(
                  'During playback, AI monitors your attention and provides helpful feedback whenever your focus shifts.',
                  style: TextStyle(
                    color: const Color(0xFFD6DEEC),
                    fontSize: (11.5 * scale).clamp(10.5, 11.5),
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 11 * scale),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * scale,
                    vertical: 5 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .13),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        color: const Color(0xFF89B8FF),
                        size: 13 * scale,
                      ),
                      SizedBox(width: 5 * scale),
                      Text(
                        'Attention monitoring',
                        style: TextStyle(
                          color: const Color(0xFFE6EDFA),
                          fontSize: 9.5 * scale,
                          fontFamily: 'Nunito Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  final double scale;
  final int videoCount;
  final bool showCount;

  const _LibraryHeader({
    required this.scale,
    required this.videoCount,
    required this.showCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.video_library_outlined,
          color: const Color(0xFF719BEF),
          size: 22 * scale,
        ),
        SizedBox(width: 9 * scale),
        Expanded(
          child: Text(
            'Assessment videos',
            style: TextStyle(
              color: _AiAssessmentListScreenState._navy,
              fontSize: (17 * scale).clamp(15, 17),
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (showCount)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 9 * scale,
              vertical: 5 * scale,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$videoCount ${videoCount == 1 ? 'video' : 'videos'}',
              style: TextStyle(
                color: _AiAssessmentListScreenState._blue,
                fontSize: 10.5 * scale,
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final VideoFile file;
  final int index;
  final double scale;
  final VoidCallback onTap;

  const _VideoCard({
    required this.file,
    required this.index,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = file.displayTitle.isEmpty
        ? 'Assessment video ${index + 1}'
        : file.displayTitle;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(14 * scale),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14 * scale),
            border: Border.all(color: const Color(0xFFE2E8F2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF243657).withValues(alpha: .08),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(13 * scale),
                    topRight: Radius.circular(13 * scale),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _VideoThumbnail(videoUrl: file.url, scale: scale),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x40000B24)],
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 36 * scale,
                          height: 36 * scale,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .94),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .18),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: _AiAssessmentListScreenState._blue,
                            size: 25 * scale,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8 * scale,
                        left: 8 * scale,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7 * scale,
                            vertical: 4 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF071443,
                            ).withValues(alpha: .78),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${index + 1}'.padLeft(2, '0'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5 * scale,
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  10 * scale,
                  9 * scale,
                  10 * scale,
                  10 * scale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _AiAssessmentListScreenState._navy,
                        fontSize: (12.5 * scale).clamp(11.2, 12.5),
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w800,
                        height: 1.22,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: _AiAssessmentListScreenState._body,
                          size: 13 * scale,
                        ),
                        SizedBox(width: 5 * scale),
                        Expanded(
                          child: Text(
                            'AI monitored',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _AiAssessmentListScreenState._body,
                              fontSize: 9.5 * scale,
                              fontFamily: 'Nunito Sans',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: _AiAssessmentListScreenState._blue,
                          size: 16 * scale,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  final double scale;

  const _VideoThumbnail({required this.videoUrl, required this.scale});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri == null || !uri.hasScheme) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.pause();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant _VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl == widget.videoUrl) return;
    _controller?.dispose();
    _controller = null;
    _failed = false;
    _initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_failed && controller != null && controller.value.isInitialized) {
      return ColoredBox(
        color: const Color(0xFF071443),
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }

    return _ThumbnailFallback(scale: widget.scale, showLoader: !_failed);
  }
}

class _ThumbnailFallback extends StatelessWidget {
  final double scale;
  final bool showLoader;

  const _ThumbnailFallback({required this.scale, required this.showLoader});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F2FF), Color(0xFFDDE6FF)],
        ),
      ),
      child: Center(
        child: showLoader
            ? SizedBox(
                width: 20 * scale,
                height: 20 * scale,
                child: const CircularProgressIndicator(
                  color: Color(0xFF6B8ED5),
                  strokeWidth: 2,
                ),
              )
            : Icon(
                Icons.ondemand_video_rounded,
                color: const Color(0xFF6B8ED5),
                size: 35 * scale,
              ),
      ),
    );
  }
}

class _VideoCardSkeleton extends StatelessWidget {
  final double scale;

  const _VideoCardSkeleton({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(13 * scale),
                  topRight: Radius.circular(13 * scale),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(width: 110 * scale),
                SizedBox(height: 7 * scale),
                _SkeletonLine(width: 72 * scale),
                SizedBox(height: 10 * scale),
                _SkeletonLine(width: 86 * scale, height: 7 * scale),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonLine({required this.width, this.height = 9});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF6),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF4E83DC), size: 31),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _AiAssessmentListScreenState._navy,
                fontSize: 17,
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _AiAssessmentListScreenState._body,
                fontSize: 12,
                fontFamily: 'Nunito Sans',
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: _AiAssessmentListScreenState._blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

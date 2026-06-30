import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/assigment/data/model/article_model.dart';
import 'package:attention_minder/module/assigment/presentation/bloc/assignment_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArticleDetailsScreen extends StatefulWidget {
  final Blog article;

  const ArticleDetailsScreen({super.key, required this.article});

  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  double _progress = 0;
  String? _helpfulAnswer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateProgress)
      ..dispose();
    super.dispose();
  }

  void _updateProgress() {
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final nextProgress = maxScrollExtent <= 0
        ? 0.0
        : (_scrollController.offset / maxScrollExtent).clamp(0.0, 1.0);

    if ((nextProgress - _progress).abs() > 0.01) {
      setState(() => _progress = nextProgress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final screenSize = MediaQuery.sizeOf(context);
    final imageUrl = _absoluteUrl(article.featuredImage);
    final title = article.title?.trim();
    final summary = _cleanText(article.shortDescription);
    final content = _cleanText(article.content);
    final paragraphs = _paragraphs(content);
    final publishedAt = _formatDate(article.publishedAt);
    final authorName = article.authorName?.trim();
    final readTime = _readTime(content ?? summary ?? title);
    final relatedArticles = _relatedArticles(context, article);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HeroImage(
                imageUrl: imageUrl,
                progress: _progress,
                height: (screenSize.height * 0.38).clamp(285, 365).toDouble(),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -14),
                child: _ArticleSheet(
                  article: article,
                  title: title,
                  summary: summary,
                  paragraphs: paragraphs,
                  authorName: authorName,
                  publishedAt: publishedAt,
                  readTime: readTime,
                  relatedArticles: relatedArticles,
                  helpfulAnswer: _helpfulAnswer,
                  onHelpfulChanged: (value) {
                    setState(() => _helpfulAnswer = value);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Blog> _relatedArticles(BuildContext context, Blog article) {
    final articles =
        context.read<AssignmentBloc>().articleResponse?.data?.results ??
        const <Blog>[];

    return articles.where((item) => item.id != article.id).take(2).toList();
  }

  String? _absoluteUrl(String? url) {
    final trimmedUrl = url?.trim();
    if (trimmedUrl == null || trimmedUrl.isEmpty) return null;
    if (trimmedUrl.startsWith('http')) return trimmedUrl;

    return Uri.parse(baseUrl).resolve(trimmedUrl).toString();
  }

  String? _cleanText(String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) return null;

    return trimmedValue
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  List<String> _paragraphs(String? value) {
    if (value == null || value.isEmpty) return const [];

    return value
        .split(RegExp(r'\n{2,}'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();
  }

  String? _formatDate(String? value) {
    final date = DateTime.tryParse(value ?? '');
    if (date == null) return null;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String? _readTime(String? text) {
    final wordCount = text?.trim().split(RegExp(r'\s+')).length ?? 0;
    if (wordCount == 0) return null;

    final minutes = (wordCount / 200).ceil().clamp(1, 99);
    return '$minutes min read';
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  final double progress;
  final double height;

  const _HeroImage({
    required this.imageUrl,
    required this.progress,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: height,
      child: ClipRRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const _HeroFallback();
                },
              )
            else
              const _HeroFallback(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x77000000), Color(0x00000000)],
                ),
              ),
            ),
            Positioned(
              top: topSafe + 16,
              left: 18,
              child: _CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,

                onTap: () => Navigator.maybePop(context),
              ),
            ),
            Positioned(
              top: topSafe + 16,
              right: 18,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  _CircleIconButton(icon: Icons.share_rounded, onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07183C), Color(0xFF0A66D8)],
        ),
      ),
      child: const Icon(Icons.article_rounded, color: Colors.white, size: 88),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: const Color(0xFF111827), size: 20),
        ),
      ),
    );
  }
}

class _ArticleSheet extends StatelessWidget {
  final Blog article;
  final String? title;
  final String? summary;
  final List<String> paragraphs;
  final String? authorName;
  final String? publishedAt;
  final String? readTime;
  final List<Blog> relatedArticles;
  final String? helpfulAnswer;
  final ValueChanged<String> onHelpfulChanged;

  const _ArticleSheet({
    required this.article,
    required this.title,
    required this.summary,
    required this.paragraphs,
    required this.authorName,
    required this.publishedAt,
    required this.readTime,
    required this.relatedArticles,
    required this.helpfulAnswer,
    required this.onHelpfulChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ArticleSheetClipper(),
      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArticleLabel(article: article),
            if (title != null && title!.isNotEmpty) ...[
              const SizedBox(height: 15),
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF07183C),
                ),
              ),
            ],
            const SizedBox(height: 15),
            _MetaRow(
              authorName: authorName,
              publishedAt: publishedAt,
              readTime: readTime,
            ),
            if (summary != null && summary!.isNotEmpty) ...[
              const SizedBox(height: 18),
              _SummaryCard(summary: summary!),
            ],
            if (paragraphs.isNotEmpty) ...[
              const SizedBox(height: 21),
              _ArticleContent(paragraphs: paragraphs),
            ],
            const SizedBox(height: 24),
            if (relatedArticles.isNotEmpty) ...[
              const SizedBox(height: 22),
              _RelatedArticles(articles: relatedArticles),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArticleSheetClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 26)
      ..quadraticBezierTo(0, 0, 26, 0)
      ..lineTo(size.width * .68, 0)
      ..cubicTo(size.width * .79, 0, size.width * .77, 50, size.width, 50)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ArticleLabel extends StatelessWidget {
  final Blog article;

  const _ArticleLabel({required this.article});

  @override
  Widget build(BuildContext context) {
    final status = article.status?.trim();
    final label = article.isFeatured == true
        ? 'AI Assessment'
        : status != null && status.isNotEmpty
        ? status[0].toUpperCase() + status.substring(1)
        : null;

    if (label == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCBE3FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A84FF).withValues(alpha: .10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.psychology_alt_rounded,
            color: Color(0xFF0A84FF),
            size: 18,
          ),
          const SizedBox(width: 9),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0A66D8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String? authorName;
  final String? publishedAt;
  final String? readTime;

  const _MetaRow({
    required this.authorName,
    required this.publishedAt,
    required this.readTime,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 9,
      runSpacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (authorName != null && authorName!.isNotEmpty)
          _AuthorMeta(authorName: authorName!),
        if ((publishedAt != null && publishedAt!.isNotEmpty) ||
            (readTime != null && readTime!.isNotEmpty))
          _InlineMeta(publishedAt: publishedAt, readTime: readTime),
      ],
    );
  }
}

class _AuthorMeta extends StatelessWidget {
  final String authorName;

  const _AuthorMeta({required this.authorName});

  @override
  Widget build(BuildContext context) {
    final initial = authorName.trim().isNotEmpty
        ? authorName.trim()[0].toUpperCase()
        : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFFEAF4FF),
          child: Text(
            initial,
            style: const TextStyle(
              color: Color(0xFF0A66D8),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 95),
          child: Text(
            authorName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineMeta extends StatelessWidget {
  final String? publishedAt;
  final String? readTime;

  const _InlineMeta({required this.publishedAt, required this.readTime});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (publishedAt != null && publishedAt!.isNotEmpty) ...[
          const Icon(
            Icons.calendar_today_outlined,
            size: 12,
            color: Color(0xFF4B5563),
          ),
          const SizedBox(width: 9),
          Text(
            publishedAt!,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (publishedAt != null &&
            publishedAt!.isNotEmpty &&
            readTime != null &&
            readTime!.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '·',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (readTime != null && readTime!.isNotEmpty) ...[
          const Icon(
            Icons.access_time_rounded,
            size: 18,
            color: Color(0xFF4B5563),
          ),
          const SizedBox(width: 8),
          Text(
            readTime!,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB9D9FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFF0A84FF),
            child: Icon(
              Icons.format_quote_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(
                    color: Color(0xFF0A66D8),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  summary,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
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

class _ArticleContent extends StatelessWidget {
  final List<String> paragraphs;

  const _ArticleContent({required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < paragraphs.length; index++) ...[
          if (_looksLikeHeading(paragraphs[index]))
            Text(
              paragraphs[index],
              style: const TextStyle(
                color: Color(0xFF07183C),
                fontSize: 22,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            )
          else
            Text(
              paragraphs[index],
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 17,
                height: 1.75,
                fontWeight: FontWeight.w400,
              ),
            ),
          if (index != paragraphs.length - 1)
            SizedBox(height: _looksLikeHeading(paragraphs[index]) ? 10 : 18),
        ],
      ],
    );
  }

  bool _looksLikeHeading(String value) {
    return value.length <= 70 && !value.endsWith('.') && !value.contains(',');
  }
}

class _HelpfulButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _HelpfulButton({
    required this.icon,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAF4FF) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0A84FF)
                  : const Color(0xFFD8E2EE),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF0A84FF)),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF0A66D8),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelatedArticles extends StatelessWidget {
  final List<Blog> articles;

  const _RelatedArticles({required this.articles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Related Articles',
                style: TextStyle(
                  color: Color(0xFF07183C),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'View all',
              style: TextStyle(
                color: Color(0xFF0A84FF),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 560;
            if (stacked) {
              return Column(
                children: [
                  for (var index = 0; index < articles.length; index++) ...[
                    _RelatedArticleCard(article: articles[index]),
                    if (index != articles.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (var index = 0; index < articles.length; index++) ...[
                  Expanded(
                    child: _RelatedArticleCard(article: articles[index]),
                  ),
                  if (index != articles.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RelatedArticleCard extends StatelessWidget {
  final Blog article;

  const _RelatedArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final imageUrl = _absoluteUrl(article.featuredImage);
    final title = article.title?.trim() ?? '';
    final readTime = _readTime(article.content ?? article.shortDescription);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailsScreen(article: article),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9E3EF)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 72,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const _MiniFallback();
                        },
                      )
                    : const _MiniFallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (readTime != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFF64748B),
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          readTime,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _absoluteUrl(String? url) {
    final trimmedUrl = url?.trim();
    if (trimmedUrl == null || trimmedUrl.isEmpty) return null;
    if (trimmedUrl.startsWith('http')) return trimmedUrl;

    return Uri.parse(baseUrl).resolve(trimmedUrl).toString();
  }

  String? _readTime(String? text) {
    final wordCount = text?.trim().split(RegExp(r'\s+')).length ?? 0;
    if (wordCount == 0) return null;

    final minutes = (wordCount / 200).ceil().clamp(1, 99);
    return '$minutes min read';
  }
}

class _MiniFallback extends StatelessWidget {
  const _MiniFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF4FF),
      child: const Icon(Icons.article_rounded, color: Color(0xFF0A84FF)),
    );
  }
}

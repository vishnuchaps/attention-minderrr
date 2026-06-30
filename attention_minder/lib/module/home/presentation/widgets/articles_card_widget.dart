import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/assigment/data/model/article_model.dart';
import 'package:attention_minder/module/home/presentation/widgets/articles_details_screen.dart';
import 'package:flutter/material.dart';

enum ArticlesCardVariant { dark, home }

class ArticlesCardWidget extends StatelessWidget {
  final Blog? article;
  final String? title;
  final String? shortDesc;
  final String? image;
  final ArticlesCardVariant variant;

  const ArticlesCardWidget({
    super.key,
    this.article,
    this.image,
    this.shortDesc,
    this.title,
    this.variant = ArticlesCardVariant.dark,
  });

  @override
  Widget build(BuildContext context) {
    final articleTitle = article?.title ?? title;
    final articleShortDesc = article?.shortDescription ?? shortDesc;
    final articleImage = article?.featuredImage ?? image;

    if (variant == ArticlesCardVariant.home) {
      return _buildHomeCard(
        context: context,
        articleTitle: articleTitle,
        articleShortDesc: articleShortDesc,
        articleImage: articleImage,
      );
    }

    return _buildDarkCard(
      context: context,
      articleTitle: articleTitle,
      articleShortDesc: articleShortDesc,
      articleImage: articleImage,
    );
  }

  Widget _buildDarkCard({
    required BuildContext context,
    required String? articleTitle,
    required String? articleShortDesc,
    required String? articleImage,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openArticle(context),
      child: Container(
        width: double.infinity,
        height: 102.50,
        padding: const EdgeInsets.all(5),
        decoration: ShapeDecoration(
          color: const Color(0xFF282828),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArticleImage(
              image: articleImage,
              width: 114,
              height: 92.50,
              radius: 7,
              imageUrlResolver: _imageUrl,
              isDarkStyle: true,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    articleTitle?.trim() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      height: 1.40,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    articleShortDesc?.trim() ?? '',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      height: 1.40,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeCard({
    required BuildContext context,
    required String? articleTitle,
    required String? articleShortDesc,
    required String? articleImage,
  }) {
    final screenSize = MediaQuery.sizeOf(context);
    final scale = (screenSize.width / 430).clamp(.78, 1.0).toDouble();
    final titleText = articleTitle?.trim() ?? '';
    final descriptionText = articleShortDesc?.trim() ?? '';
    final readTime = _readTime(
      article?.content ?? descriptionText.ifEmpty(titleText),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(16 * scale),
        onTap: () => _openArticle(context),
        child: Ink(
          padding: EdgeInsets.all(9 * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(color: const Color(0xFFE3E9F2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF21324F).withValues(alpha: .08),
                blurRadius: 18 * scale,
                offset: Offset(0, 8 * scale),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 320;
              final imageWidth = (constraints.maxWidth * (compact ? .29 : .30))
                  .clamp(86.0, 118.0)
                  .toDouble();
              final imageHeight = (compact ? 96.0 : 106.0) * scale;
              final textGap = (compact ? 10.0 : 12.0) * scale;
              final titleSize = (15.4 * scale).clamp(13.2, 15.4).toDouble();
              final descSize = (13.4 * scale).clamp(11.4, 13.4).toDouble();
              final metaSize = (12.4 * scale).clamp(10.8, 12.4).toDouble();

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ArticleImage(
                    image: articleImage,
                    width: imageWidth,
                    height: imageHeight,
                    radius: 9 * scale,
                    imageUrlResolver: _imageUrl,
                    isDarkStyle: false,
                  ),
                  SizedBox(width: textGap),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: imageHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (titleText.isNotEmpty)
                            Text(
                              titleText,
                              maxLines: compact ? 2 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF07123A),
                                fontSize: titleSize,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w800,
                                height: 1.18,
                              ),
                            ),
                          if (descriptionText.isNotEmpty) ...[
                            SizedBox(height: 8 * scale),
                            Text(
                              descriptionText,
                              maxLines: compact ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF59627D),
                                fontSize: descSize,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.w500,
                                height: 1.32,
                              ),
                            ),
                          ],
                          SizedBox(height: 12 * scale),
                          Row(
                            children: [
                              if (readTime != null) ...[
                                Icon(
                                  Icons.access_time_rounded,
                                  color: const Color(0xFF59627D),
                                  size: 17 * scale,
                                ),
                                SizedBox(width: 6 * scale),
                                Flexible(
                                  child: Text(
                                    readTime,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFF59627D),
                                      fontSize: metaSize,
                                      fontFamily: 'Nunito Sans',
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Icon(
                                Icons.bookmark_border_rounded,
                                color: const Color(0xFF59627D),
                                size: 25 * scale,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openArticle(BuildContext context) {
    if (article == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailsScreen(article: article!),
      ),
    );
  }

  String? _imageUrl(String? imageUrlValue) {
    if (imageUrlValue != null && imageUrlValue.trim().isNotEmpty) {
      return imageUrlValue.startsWith('http')
          ? imageUrlValue
          : Uri.parse(baseUrl).resolve(imageUrlValue).toString();
    }

    return null;
  }

  String? _readTime(String? value) {
    final plainText = value
        ?.replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (plainText == null || plainText.isEmpty) return null;

    final wordCount = plainText.split(' ').length;
    final minutes = (wordCount / 180).ceil().clamp(1, 99);
    return '$minutes min read';
  }
}

class _ArticleImage extends StatelessWidget {
  final String? image;
  final double width;
  final double height;
  final double radius;
  final String? Function(String?) imageUrlResolver;
  final bool isDarkStyle;

  const _ArticleImage({
    required this.image,
    required this.width,
    required this.height,
    required this.radius,
    required this.imageUrlResolver,
    required this.isDarkStyle,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = imageUrlResolver(image);
    final fallback = _ArticleImageFallback(
      width: width,
      height: height,
      radius: radius,
      isDarkStyle: isDarkStyle,
    );

    if (imageUrl == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return fallback;
        },
      ),
    );
  }
}

class _ArticleImageFallback extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final bool isDarkStyle;

  const _ArticleImageFallback({
    required this.width,
    required this.height,
    required this.radius,
    required this.isDarkStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkStyle
              ? const [Color(0xFF343A46), Color(0xFF1F2530)]
              : const [Color(0xFFE9F5FF), Color(0xFFF6F9FF)],
        ),
      ),
      child: Icon(
        Icons.article_outlined,
        color: isDarkStyle ? Colors.white70 : const Color(0xFF0A84FF),
        size: width * .26,
      ),
    );
  }
}

extension on String {
  String? ifEmpty(String fallback) {
    return isEmpty ? fallback : this;
  }
}

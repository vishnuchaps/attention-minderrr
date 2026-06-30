import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/assigment/data/model/article_model.dart';
import 'package:attention_minder/module/assigment/presentation/bloc/assignment_bloc.dart';
import 'package:attention_minder/module/home/presentation/widgets/articles_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AllArticlesScreen extends StatefulWidget {
  const AllArticlesScreen({super.key});

  @override
  State<AllArticlesScreen> createState() => _AllArticlesScreenState();
}

class _AllArticlesScreenState extends State<AllArticlesScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final bloc = context.read<AssignmentBloc>();
      if (bloc.articleResponse == null && !bloc.isFetchingArticles) {
        bloc.add(GetArticleListEvent());
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 280) return;

    final bloc = context.read<AssignmentBloc>();
    if (!bloc.hasMoreArticles || bloc.isFetchingNextArticlePage) return;

    bloc.add(GetArticleListEvent(page: bloc.articlePage + 1, append: true));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (width * .07).clamp(22.0, 32.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: BlocBuilder<AssignmentBloc, AssignmentState>(
          buildWhen: (previous, current) {
            return current is GetArticlesLoading ||
                current is GetArticlesSuccess ||
                current is GetArticlesFailed;
          },
          builder: (context, state) {
            final bloc = context.read<AssignmentBloc>();
            final articles = bloc.articleResponse?.data?.results ?? const [];

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    34,
                    horizontalPadding,
                    22,
                  ),
                  sliver: const SliverToBoxAdapter(child: _AllArticlesHeader()),
                ),
                if (articles.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      28,
                    ),
                    sliver: SliverList.separated(
                      itemCount:
                          articles.length +
                          (bloc.isFetchingNextArticlePage ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index >= articles.length) {
                          return const _PaginationLoader();
                        }

                        return _AllArticleCard(article: articles[index]);
                      },
                    ),
                  )
                else if (state is GetArticlesFailed ||
                    bloc.articleError != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ArticleMessage(
                      icon: Icons.error_outline_rounded,
                      title: 'Unable to load articles',
                      message: bloc.articleError ?? 'Please try again.',
                      actionLabel: 'Retry',
                      onAction: () {
                        bloc.add(
                          GetArticleListEvent(forceRefresh: true, page: 1),
                        );
                      },
                    ),
                  )
                else
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0A84FF),
                        strokeWidth: 2.4,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AllArticlesHeader extends StatelessWidget {
  const _AllArticlesHeader();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = (width / 430).clamp(.84, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 8,
              shadowColor: const Color(0xFF21324F).withValues(alpha: .15),
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: const Color(0xFF0A84FF).withValues(alpha: .08),
                highlightColor: const Color(0xFF0A84FF).withValues(alpha: .06),
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  width: (44 * scale).clamp(24, 34),
                  height: (44 * scale).clamp(24, 34),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 2 * scale),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: const Color(0xFF07123A),
                        size: (22 * scale).clamp(19, 22),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16 * scale),
            Expanded(
              child: Text(
                'All Articles',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF07123A),
                  fontSize: (10 * scale).clamp(22, 24),
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w500,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 18 * scale),
        Text(
          'Explore helpful resources and expert insights',
          style: _subtitleStyle(scale),
        ),
        SizedBox(height: 10 * scale),
        Text(
          'to improve your attention and well-being.',
          style: _subtitleStyle(scale),
        ),
      ],
    );
  }

  TextStyle _subtitleStyle(double scale) {
    return TextStyle(
      color: const Color(0xFF45577C),
      fontSize: (15 * scale).clamp(13, 14),
      fontFamily: 'Nunito Sans',
      fontWeight: FontWeight.w400,
      height: 1.25,
    );
  }
}

class _AllArticleCard extends StatelessWidget {
  final Blog article;

  const _AllArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = (width / 430).clamp(.82, 1.0).toDouble();
    final title = article.title?.trim() ?? '';
    final description = article.shortDescription?.trim() ?? '';
    final readTime = _readTime(article.content ?? description.ifEmpty(title));

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(17 * scale),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailsScreen(article: article),
            ),
          );
        },
        child: Ink(
          padding: EdgeInsets.all(7 * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17 * scale),
            border: Border.all(color: const Color(0xFFE5EBF3)),
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
              final compact = constraints.maxWidth < 330;
              final imageWidth = (constraints.maxWidth * .35)
                  .clamp(compact ? 96.0 : 112.0, 132.0)
                  .toDouble();
              final imageHeight = (124 * scale).clamp(108.0, 124.0);
              final gap = (14 * scale).clamp(10.0, 14.0);
              final titleSize = (16 * scale).clamp(15.4, 18.0);
              final descSize = (14 * scale).clamp(13.1, 15.2);
              final metaSize = (12 * scale).clamp(12.2, 14.0);

              return ConstrainedBox(
                constraints: BoxConstraints(minHeight: imageHeight),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ArticleImage(
                      image: article.featuredImage,
                      width: imageWidth,
                      height: imageHeight,
                      radius: 10 * scale,
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: SizedBox(
                        height: imageHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title.isNotEmpty)
                              Text(
                                title,
                                maxLines: compact ? 2 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF07123A),
                                  fontSize: titleSize,
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w600,
                                  height: 1.12,
                                ),
                              ),
                            if (description.isNotEmpty) ...[
                              SizedBox(height: 10 * scale),
                              Text(
                                description,
                                maxLines: compact ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF45577C),
                                  fontSize: descSize,
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.28,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: const Color(0xFF45577C),
                                  size: 16 * scale,
                                ),
                                SizedBox(width: 7 * scale),
                                Expanded(
                                  child: Text(
                                    readTime,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFF45577C),
                                      fontSize: metaSize,
                                      fontFamily: 'Nunito Sans',
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.bookmark_border_rounded,
                                  color: Colors.white,
                                  size: 27 * scale,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _readTime(String? value) {
    final plainText = value
        ?.replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (plainText == null || plainText.isEmpty) return '1 min read';

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

  const _ArticleImage({
    required this.image,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl(image);
    final fallback = _ArticleImageFallback(
      width: width,
      height: height,
      radius: radius,
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

  String? _imageUrl(String? imageUrlValue) {
    if (imageUrlValue == null || imageUrlValue.trim().isEmpty) {
      return null;
    }

    return imageUrlValue.startsWith('http')
        ? imageUrlValue
        : Uri.parse(baseUrl).resolve(imageUrlValue).toString();
  }
}

class _ArticleImageFallback extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ArticleImageFallback({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF7FF), Color(0xFFF6FAFF)],
        ),
      ),
      child: Icon(
        Icons.checklist_rounded,
        color: const Color(0xFF0A84FF),
        size: width * .28,
      ),
    );
  }
}

class _PaginationLoader extends StatelessWidget {
  const _PaginationLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Color(0xFF0A84FF),
            strokeWidth: 2.4,
          ),
        ),
      ),
    );
  }
}

class _ArticleMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _ArticleMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF59627D), size: 38),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF07123A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF59627D),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF0A84FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String? ifEmpty(String fallback) {
    return isEmpty ? fallback : this;
  }
}

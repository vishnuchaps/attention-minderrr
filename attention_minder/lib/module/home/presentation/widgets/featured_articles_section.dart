import 'package:attention_minder/module/assigment/data/model/article_model.dart';
import 'package:attention_minder/module/assigment/presentation/bloc/assignment_bloc.dart';
import 'package:attention_minder/module/home/presentation/widgets/all_articles_screen.dart';
import 'package:attention_minder/module/home/presentation/widgets/articles_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum FeaturedArticlesStyle { dark, home, assessment }

class FeaturedArticlesSection extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  final double itemSpacing;
  final FeaturedArticlesStyle style;

  const FeaturedArticlesSection({
    super.key,
    this.padding = EdgeInsets.zero,
    this.itemSpacing = 5,
    this.style = FeaturedArticlesStyle.dark,
  });

  @override
  State<FeaturedArticlesSection> createState() =>
      _FeaturedArticlesSectionState();
}

class _FeaturedArticlesSectionState extends State<FeaturedArticlesSection> {
  bool get _isHomeStyle => widget.style == FeaturedArticlesStyle.home;
  bool get _isAssessmentStyle =>
      widget.style == FeaturedArticlesStyle.assessment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final bloc = context.read<AssignmentBloc>();
      if (bloc.articleResponse == null && !bloc.isFetchingArticles) {
        bloc.add(GetArticleListEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssignmentBloc, AssignmentState>(
      buildWhen: (previous, current) {
        return current is GetArticlesLoading ||
            current is GetArticlesSuccess ||
            current is GetArticlesFailed;
      },
      builder: (context, state) {
        final bloc = context.read<AssignmentBloc>();
        final articles = _articlesFrom(bloc.articleResponse);

        return Padding(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                isHomeStyle: _isHomeStyle,
                isAssessmentStyle: _isAssessmentStyle,
              ),
              SizedBox(height: _isHomeStyle ? 16 : 10),
              if (articles.isNotEmpty)
                ..._buildArticleCards(articles)
              else if (state is GetArticlesFailed || bloc.articleError != null)
                _ErrorText(
                  error: bloc.articleError ?? 'Failed to load articles',
                  isHomeStyle: _isHomeStyle || _isAssessmentStyle,
                )
              else
                _ArticlesLoadingIndicator(
                  isHomeStyle: _isHomeStyle || _isAssessmentStyle,
                ),
            ],
          ),
        );
      },
    );
  }

  List<Blog> _articlesFrom(BlogResponse? response) {
    return response?.data?.results ?? const [];
  }

  List<Widget> _buildArticleCards(List<Blog> articles) {
    return [
      for (var index = 0; index < articles.length; index++) ...[
        ArticlesCardWidget(
          article: articles[index],
          title: articles[index].title,
          shortDesc: articles[index].shortDescription,
          image: articles[index].featuredImage,
          variant: _isHomeStyle || _isAssessmentStyle
              ? ArticlesCardVariant.home
              : ArticlesCardVariant.dark,
        ),
        if (index != articles.length - 1) SizedBox(height: widget.itemSpacing),
      ],
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  final bool isHomeStyle;
  final bool isAssessmentStyle;

  const _SectionHeader({
    required this.isHomeStyle,
    required this.isAssessmentStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (!isHomeStyle && !isAssessmentStyle) {
      return Row(
        children: [
          const Text(
            'Featured Articles',
            style: TextStyle(
              color: Color(0xFFA9A9A9),
              fontSize: 12,
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final scale = (width / 430).clamp(.86, 1.0).toDouble();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isAssessmentStyle) ...[
          Icon(
            Icons.menu_book_outlined,
            color: const Color(0xFF7098E8),
            size: 21 * scale,
          ),
          SizedBox(width: 8 * scale),
        ],
        Expanded(
          child: Text(
            isAssessmentStyle ? 'Featured articles' : 'Featured Articles',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF07123A),
              fontSize: isAssessmentStyle
                  ? (16 * scale).clamp(14.5, 16).toDouble()
                  : (21 * scale).clamp(18, 21).toDouble(),
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
        SizedBox(width: 12 * scale),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllArticlesScreen()),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View all',
                style: TextStyle(
                  color: const Color(0xFF0A84FF),
                  fontSize: isAssessmentStyle ? 11.5 : 13,
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: const Color(0xFF0A84FF),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArticlesLoadingIndicator extends StatelessWidget {
  final bool isHomeStyle;

  const _ArticlesLoadingIndicator({required this.isHomeStyle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isHomeStyle ? 120 : 102.5,
      child: Center(
        child: CircularProgressIndicator(
          color: isHomeStyle ? const Color(0xFF07123A) : Colors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String error;
  final bool isHomeStyle;

  const _ErrorText({required this.error, required this.isHomeStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        error,
        style: TextStyle(
          color: isHomeStyle ? const Color(0xFFB42318) : Colors.red,
          fontSize: isHomeStyle ? 13 : 12,
          fontFamily: 'Nunito Sans',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

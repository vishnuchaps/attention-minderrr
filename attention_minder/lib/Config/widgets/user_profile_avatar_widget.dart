import 'package:attention_minder/module/profile/presentation/bloc/profile_bloc.dart';
import 'package:attention_minder/module/profile/presentation/screens/profile_screen.dart';
import 'package:attention_minder/constant/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileAvatar extends StatefulWidget {
  final double size;
  final BoxFit fit;
  final VoidCallback? onTap;
  final Color borderColor;
  final double borderWidth;
  final bool showAccentRing;

  const UserProfileAvatar({
    super.key,
    this.size = 44.53,
    this.fit = BoxFit.cover,
    this.onTap,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
    this.showAccentRing = true,
  });

  @override
  State<UserProfileAvatar> createState() => _UserProfileAvatarState();
}

class _UserProfileAvatarState extends State<UserProfileAvatar> {
  static const String _fallbackAsset = 'asset/images/Ellipse 125.png';

  String? _cachedProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadCachedProfileImage();
  }

  Future<void> _loadCachedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _cachedProfileImageUrl = prefs.getString('profileImageUrl');
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) {
        return current is FetchProfileSuccess ||
            current is UpdateProfilePictureSuccess ||
            current is ProfileInitial;
      },
      builder: (context, state) {
        final profileImageUrl = _resolveProfileImageUrl(context, state);
        final avatar = AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: widget.size,
          height: widget.size,
          padding: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.showAccentRing
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFDDEEFF),
                      Color(0xFF74B8FF),
                    ],
                  )
                : null,
            color: widget.showAccentRing ? null : widget.borderColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF2387EA).withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.borderColor,
            ),
            child: ClipOval(
              child: Image(
                image: _imageProvider(profileImageUrl),
                width: widget.size,
                height: widget.size,
                fit: widget.fit,
                errorBuilder: (context, error, stackTrace) {
                  return _FallbackAvatar(size: widget.size);
                },
              ),
            ),
          ),
        );

        return Semantics(
          button: true,
          label: 'Open profile',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap ?? () => _openProfile(context),
            child: avatar,
          ),
        );
      },
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => ProfileScreen()));
  }

  String? _resolveProfileImageUrl(BuildContext context, ProfileState state) {
    if (state is FetchProfileSuccess) {
      return state.data.profileImageUrl ?? _cachedProfileImageUrl;
    }

    if (state is UpdateProfilePictureSuccess) {
      return state.profileImageUrl ??
          context.read<ProfileBloc>().profileImageUrl ??
          _cachedProfileImageUrl;
    }

    return context.read<ProfileBloc>().profileImageUrl ??
        _cachedProfileImageUrl;
  }

  ImageProvider _imageProvider(String? profileImageUrl) {
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      if (profileImageUrl.startsWith('asset/')) {
        return AssetImage(profileImageUrl);
      }

      final imageUrl = profileImageUrl.startsWith('http')
          ? profileImageUrl
          : Uri.parse(baseUrl).resolve(profileImageUrl).toString();

      return NetworkImage(imageUrl);
    }

    return const AssetImage(_fallbackAsset);
  }
}

class _FallbackAvatar extends StatelessWidget {
  final double size;

  const _FallbackAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF4FF), Color(0xFFB9DCFF)],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        color: const Color(0xFF1F6FB8),
        size: size * 0.52,
      ),
    );
  }
}

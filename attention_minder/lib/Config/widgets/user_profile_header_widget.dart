import 'package:flutter/material.dart';

import '../../module/landing/presentation/screens/landing_screen.dart';
import 'arrow_left_icon_widget.dart';
import 'user_profile_avatar_widget.dart';

class UserProfileHeader extends StatelessWidget {
  final String? username;
  final TextStyle? style;

  const UserProfileHeader({super.key, this.username, this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Row(
        children: [
          username != null && username!.isNotEmpty
              ? Text(
                  username!,
                  style:
                      style ??
                      const TextStyle(
                        color: Color(0xFF2F2F2F),
                        fontSize: 24,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w600,
                        height: 1.40,
                      ),
                )
              : ArrowLeftIconWidget(
                  callback: () async {
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) {
                      navigator.pop();
                    } else {
                      navigator.pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const LandingScreen(),
                        ),
                      );
                    }
                  },
                ),
          const Spacer(),
          const UserProfileAvatar(),
        ],
      ),
    );
  }
}

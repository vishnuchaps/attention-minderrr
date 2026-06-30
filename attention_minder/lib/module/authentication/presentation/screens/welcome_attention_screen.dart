import 'dart:math';
import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/module/landing/presentation/screens/landing_screen.dart';
import 'package:attention_minder/module/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeAttentionScreen extends StatefulWidget {
  const WelcomeAttentionScreen({super.key});

  @override
  State<WelcomeAttentionScreen> createState() => _WelcomeAttentionScreenState();
}

class _WelcomeAttentionScreenState extends State<WelcomeAttentionScreen> {
  String? selectedUser;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final h = size.height;
    final w = size.width;
    final isSmall = h < 700;

    final sheetTop = isSmall ? 205.0 : h * 0.265;

    return Scaffold(
      backgroundColor: const Color(0xFFF9EBC6),
      body: Stack(
        children: [
          Positioned(
            top: 34,
            left: -w * .22,
            child: CustomPaint(
              size: Size(w * .65, 170),
              painter: YellowLinePainter(),
            ),
          ),

          Positioned(
            top: isSmall ? 62 : 78,
            left: w * .30,
            child: Transform.rotate(
              angle: -0.035,
              child: Container(
                width: min(w * .42, 175),
                height: isSmall ? 135 : 145,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  onBoardingImage,
                  height: h * 0.35,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Positioned(
            top: sheetTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomSheetContent(
              selectedUser: selectedUser,
              onChanged: (value) {
                setState(() => selectedUser = value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  final String? selectedUser;
  final ValueChanged<String> onChanged;

  const _BottomSheetContent({
    required this.selectedUser,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final isSmall = h < 700;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFC8C8C8),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: isSmall ? 18 : 28, bottom: 18),
                child: Column(
                  children: [
                    const Text(
                      'Welcome to',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      'Attention Minder',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                        color: Color(0xFF0A84FF),
                      ),
                    ),
                    SizedBox(height: isSmall ? 16 : 22),
                    const Text(
                      'Who will be using this app?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: isSmall ? 12 : 16),

                    _OptionTile(
                      selected: selectedUser == 'myself',
                      title: 'Myself',
                      subtitle: 'I will be using the app',
                      icon: Icons.person,
                      iconColor: const Color(0xFF1597F5),
                      bgColor: const Color(0xFFEAF6FF),
                      onTap: () => onChanged('myself'),
                    ),
                    const SizedBox(height: 11),
                    _OptionTile(
                      selected: selectedUser == 'child',
                      title: 'My Child',
                      subtitle: 'A child will be using the app',
                      icon: Icons.child_care,
                      iconColor: const Color(0xFFF2B400),
                      bgColor: const Color(0xFFFFF6DB),
                      onTap: () => onChanged('child'),
                    ),
                    const SizedBox(height: 11),
                    _OptionTile(
                      selected: selectedUser == 'someone_else',
                      title: 'Someone Else',
                      subtitle: 'Another person will be using\nthe app',
                      icon: Icons.groups,
                      iconColor: const Color(0xFF9C4DFF),
                      bgColor: const Color(0xFFF3EAFE),
                      onTap: () => onChanged('someone_else'),
                    ),

                    SizedBox(height: isSmall ? 16 : 22),
                    const _InfoBox(),
                  ],
                ),
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: selectedUser == null
                    ? null
                    : () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('showHomeWalkthrough', true);

                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF0A84FF),
                  disabledBackgroundColor: const Color(0xFF0A84FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              width: selected ? 1.6 : 1,
              color: selected
                  ? const Color(0xFF0A84FF)
                  : const Color(0xFFE4E4E4),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: bgColor,
                child: Icon(icon, color: iconColor, size: 25),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.16,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 1.4,
                    color: selected
                        ? const Color(0xFF0A84FF)
                        : const Color(0xFFBDBDBD),
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0A84FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBEDCFF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: Color(0xFF2387EA),
                child: Icon(
                  Icons.star_border_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Why we ask this?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF173A65),
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
          Text(
            'Please enter the details of the person who\nwill actually use the app.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: Color(0xFF1F2D3D),
            ),
          ),
          SizedBox(height: 13),
          _CheckText('Show age-appropriate questions'),
          SizedBox(height: 9),
          _CheckText('Personalize attention exercises'),
          SizedBox(height: 9),
          _CheckText('Track progress accurately'),
        ],
      ),
    );
  }
}

class _CheckText extends StatelessWidget {
  final String text;

  const _CheckText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 17,
          color: Color(0xFF3C91D5),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF26384C)),
          ),
        ),
      ],
    );
  }
}

class YellowLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE6A900)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * .95, 0)
      ..cubicTo(
        size.width * 1.00,
        size.height * .28,
        size.width * .55,
        size.height * .19,
        size.width * .36,
        size.height * .32,
      )
      ..cubicTo(
        -size.width * .14,
        size.height * .62,
        size.width * .20,
        size.height * 1.05,
        size.width * .65,
        size.height * .80,
      );

    canvas.drawPath(path, paint);

    canvas.drawLine(
      Offset(size.width * .96, 0),
      Offset(size.width * 1.12, size.height * 1.85),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

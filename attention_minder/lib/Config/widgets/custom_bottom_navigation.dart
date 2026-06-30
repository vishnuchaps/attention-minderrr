import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final List<GlobalKey>? itemKeys;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.itemKeys,
  });

  static const List<_NavigationItemData> _items = [
    _NavigationItemData(label: 'Home', icon: Icons.home_rounded),
    _NavigationItemData(label: 'Assessment', icon: Icons.assignment_rounded),
    _NavigationItemData(
      label: 'Management',
      icon: Icons.health_and_safety_rounded,
    ),
    _NavigationItemData(label: 'Result', icon: Icons.bar_chart_rounded),
    _NavigationItemData(label: 'Privacy', icon: Icons.lock_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final widthScale = (size.width / 430).clamp(.86, 1.0).toDouble();
    final heightScale = widthScale;
    final horizontalPadding = (23 * widthScale).clamp(16, 28).toDouble();
    final navHeight = (76 * heightScale).clamp(64, 76).toDouble();

    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: 8 * heightScale),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          7 * heightScale,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(navHeight / 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF07123A).withValues(alpha: .28),
                blurRadius: 24 * widthScale,
                offset: Offset(0, 10 * heightScale),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(navHeight / 2),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              height: navHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF001D43), Color(0xFF052A58)],
                ),
                borderRadius: BorderRadius.circular(navHeight / 2),
              ),
              child: Row(
                children: [
                  for (var index = 0; index < _items.length; index++)
                    Expanded(
                      child: _NavigationItem(
                        key: itemKeys != null && index < itemKeys!.length
                            ? itemKeys![index]
                            : null,
                        data: _items[index],
                        isSelected: selectedIndex == index,
                        widthScale: widthScale,
                        heightScale: heightScale,
                        onTap: () => onItemTapped(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final _NavigationItemData data;
  final bool isSelected;
  final double widthScale;
  final double heightScale;
  final VoidCallback onTap;

  const _NavigationItem({
    super.key,
    required this.data,
    required this.isSelected,
    required this.widthScale,
    required this.heightScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF0A84FF);
    final inactiveColor = const Color(0xFFB9C4D2);
    final iconSize = (28 * widthScale).clamp(23, 28).toDouble();
    final labelSize = (12 * widthScale).clamp(11, 13).toDouble();

    return InkResponse(
      onTap: onTap,
      containedInkWell: false,
      highlightShape: BoxShape.circle,
      radius: 34 * widthScale,
      splashColor: Colors.white.withValues(alpha: .10),
      highlightColor: Colors.white.withValues(alpha: .06),
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10 * heightScale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.icon,
              color: isSelected ? activeColor : inactiveColor,
              size: iconSize,
            ),
            SizedBox(height: 5 * heightScale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2 * widthScale),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  data.label,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected ? activeColor : inactiveColor,
                    fontSize: labelSize,
                    fontFamily: 'Nunito Sans',
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItemData {
  final String label;
  final IconData icon;

  const _NavigationItemData({required this.label, required this.icon});
}

import 'package:flutter/material.dart';

class AnimatedBottomNavBar extends StatefulWidget {
  final ValueChanged<int>? onItemSelected;
  const AnimatedBottomNavBar({Key? key, this.onItemSelected})
      : super(key: key);

  @override
  _AnimatedBottomNavBarState createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar> {
  int _selectedIndex = 0;
  final List<IconData> _icons = [
    Icons.dashboard,
    Icons.inventory_2_outlined,
    Icons.category,
    Icons.business,
    Icons.people_outline,
    Icons.receipt_long,
    Icons.local_offer_outlined,
    Icons.percent,
    Icons.chat_bubble_outline,
  ];

  final GlobalKey _barKey = GlobalKey();
  late List<GlobalKey> _itemKeys;
  double _indicatorLeft = 0, _indicatorWidth = 0;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(_icons.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());
  }

  void _updateIndicator() {
    final barBox = _barKey.currentContext!.findRenderObject() as RenderBox;
    final itemBox =
    _itemKeys[_selectedIndex].currentContext!.findRenderObject()
    as RenderBox;
    final barPos = barBox.localToGlobal(Offset.zero);
    final itemPos = itemBox.localToGlobal(Offset.zero);

    setState(() {
      _indicatorLeft = itemPos.dx - barPos.dx;
      _indicatorWidth = itemBox.size.width;
    });
  }

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
    _updateIndicator();
    widget.onItemSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: Container(
        key: _barKey,
        height: 60,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_icons.length, (i) {
                return GestureDetector(
                  key: _itemKeys[i],
                  onTap: () => _onTap(i),
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    width: 60,
                    height: double.infinity,
                    child: Icon(
                      _icons[i],
                      color: _selectedIndex == i
                          ? Colors.blueAccent
                          : Colors.grey,
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: _indicatorLeft + (_indicatorWidth - 24) / 2,
              bottom: 8,
              child: Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

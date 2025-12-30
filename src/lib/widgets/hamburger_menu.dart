import 'package:flutter/cupertino.dart';

class HamburgerMenu extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const HamburgerMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<HamburgerMenu> createState() => _HamburgerMenuState();
}

class _HamburgerMenuState extends State<HamburgerMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
    setState(() {
      _isOpen = true;
    });
  }

  void _closeMenu() {
    _controller.reverse().then((_) {
      _removeOverlay();
      if (mounted) {
        setState(() {
          _isOpen = false;
        });
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                child: FadeTransition(
                  opacity: _controller,
                  child: Container(
                    color: CupertinoColors.black.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            // Menu
            Positioned(
              width: 200,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(-152, 48),
                child: FadeTransition(
                  opacity: _controller,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuItem(
                          icon: CupertinoIcons.home,
                          label: 'Home',
                          index: 0,
                        ),
                        Container(
                          height: 1,
                          color: CupertinoColors.separator,
                        ),
                        _buildMenuItem(
                          icon: CupertinoIcons.settings,
                          label: 'Admin',
                          index: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () {
        widget.onItemSelected(index);
        _closeMenu();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.activeBlue.withOpacity(0.1)
              : null,
          borderRadius: BorderRadius.circular(
            index == 0 ? 12 : 0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.label,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.label,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: CupertinoButton(
        padding: const EdgeInsets.all(12),
        onPressed: _toggleMenu,
        child: AnimatedRotation(
          turns: _isOpen ? 0.25 : 0,
          duration: const Duration(milliseconds: 300),
          child: const Icon(
            CupertinoIcons.line_horizontal_3,
            size: 24,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

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
                  child: Container(color: Colors.black.withOpacity(0.5)),
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
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).cardColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuItem(
                          icon: Icons.home,
                          label: 'Home',
                          index: 0,
                        ),
                        const Divider(height: 1),
                        _buildMenuItem(
                          icon: Icons.settings,
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
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        widget.onItemSelected(index);
        _closeMenu();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? colorScheme.primaryContainer : null,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      child: IconButton(
        icon: AnimatedIcon(
          icon: AnimatedIcons.menu_close,
          progress: _controller,
        ),
        onPressed: _toggleMenu,
      ),
    );
  }
}

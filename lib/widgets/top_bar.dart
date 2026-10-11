import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Custom macOS-style window bar shown on desktop: traffic-light buttons
/// on the left, centered app title, and a drag-to-move area.
class WindowTopBar extends StatelessWidget {
  const WindowTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border:
            Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const _TrafficLight(
            key: ValueKey('traffic-close'),
            color: Color(0xFFFF5F57),
            icon: Icons.close,
            action: _TrafficAction.close,
          ),
          const SizedBox(width: 8),
          const _TrafficLight(
            key: ValueKey('traffic-min'),
            color: Color(0xFFFEBC2E),
            icon: Icons.remove,
            action: _TrafficAction.minimize,
          ),
          const SizedBox(width: 8),
          const _TrafficLight(
            key: ValueKey('traffic-max'),
            color: Color(0xFF28C840),
            icon: Icons.add,
            action: _TrafficAction.maximize,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: DragToMoveArea(
              child: Center(
                child: Text(
                  'mcse',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
    );
  }
}

enum _TrafficAction { close, minimize, maximize }

class _TrafficLight extends StatefulWidget {
  final Color color;
  final IconData icon;
  final _TrafficAction action;

  const _TrafficLight({
    super.key,
    required this.color,
    required this.icon,
    required this.action,
  });

  @override
  State<_TrafficLight> createState() => _TrafficLightState();
}

class _TrafficLightState extends State<_TrafficLight> {
  bool _hover = false;

  Future<void> _run() async {
    switch (widget.action) {
      case _TrafficAction.close:
        await windowManager.close();
      case _TrafficAction.minimize:
        await windowManager.minimize();
      case _TrafficAction.maximize:
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _run,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
          ),
          child: _hover
              ? Icon(widget.icon, size: 10, color: Colors.black87)
              : null,
        ),
      ),
    );
  }
}

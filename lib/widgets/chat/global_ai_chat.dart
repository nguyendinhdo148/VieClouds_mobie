import 'package:flutter/material.dart';
import 'ai_chat_widget.dart';

class GlobalAIChat extends StatefulWidget {
  final Widget child;

  const GlobalAIChat({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<GlobalAIChat> createState() => _GlobalAIChatState();

  static _GlobalAIChatState? of(BuildContext context) {
    return context.findAncestorStateOfType<_GlobalAIChatState>();
  }
}

class _GlobalAIChatState extends State<GlobalAIChat> {
  bool _isChatVisible = false;
  Offset? _floatingButtonPosition;

  static const double _buttonSize = 72.0;

  @override
  void initState() {
    super.initState();

    // Khởi tạo vị trí nút sau khi layout xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;

      setState(() {
        _floatingButtonPosition ??= Offset(
          size.width - _buttonSize - 20,
          size.height - _buttonSize - 20,
        );
      });
    });
  }

  void showChat() => setState(() => _isChatVisible = true);
  void hideChat() => setState(() => _isChatVisible = false);
  void toggleChat() => setState(() => _isChatVisible = !_isChatVisible);

  void _onPanUpdate(DragUpdateDetails details) {
    if (_floatingButtonPosition == null) return;

    final screenSize = MediaQuery.of(context).size;

    setState(() {
      final dx = (_floatingButtonPosition!.dx + details.delta.dx)
          .clamp(0.0, screenSize.width - _buttonSize);

      final dy = (_floatingButtonPosition!.dy + details.delta.dy)
          .clamp(0.0, screenSize.height - _buttonSize);

      _floatingButtonPosition = Offset(dx, dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_floatingButtonPosition == null) {
      return widget.child;
    }

    final entries = <OverlayEntry>[
      // Toàn bộ app
      OverlayEntry(
        builder: (_) => widget.child,
      ),

      // Floating AI Chat
      OverlayEntry(
        builder: (_) {
          if (_isChatVisible) {
            return AIChatWidget(onClose: hideChat);
          }

          return Positioned(
            left: _floatingButtonPosition!.dx,
            top: _floatingButtonPosition!.dy,
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onTap: showChat,
              child: Material(
  color: Colors.white,
  elevation: 6,
  shape: const CircleBorder(),
  child: SizedBox(
    width: _buttonSize,
    height: _buttonSize,
    child: Padding(
      padding: const EdgeInsets.all(8), // ít padding → icon to hơn
      child: Image.asset(
        'assets/images/ai_logo.png',
        fit: BoxFit.contain,
      ),
    ),
  ),

),

            ),
          );
        },
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: Overlay(
        initialEntries: entries,
      ),
    );
  }
}
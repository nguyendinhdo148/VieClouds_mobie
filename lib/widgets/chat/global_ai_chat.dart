// widgets/chat/global_ai_chat.dart
import 'package:flutter/material.dart';
import 'ai_chat_widget.dart';

class GlobalAIChat extends StatefulWidget {
  final Widget child;

  const GlobalAIChat({Key? key, required this.child}) : super(key: key);

  @override
  State<GlobalAIChat> createState() => _GlobalAIChatState();

  static _GlobalAIChatState? of(BuildContext context) {
    return context.findAncestorStateOfType<_GlobalAIChatState>();
  }
}

class _GlobalAIChatState extends State<GlobalAIChat> {
  bool _isChatVisible = false;
  Offset? _floatingButtonPosition;

  @override
  void initState() {
    super.initState();
    // Khởi tạo vị trí của button sau khi layout xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      const buttonSize = 72.0;

      setState(() {
        _floatingButtonPosition ??= Offset(
          size.width - buttonSize - 20,
          size.height - buttonSize - 20,
        );
      });
    });
  }

  void showChat() => setState(() => _isChatVisible = true);
  void hideChat() => setState(() => _isChatVisible = false);
  void toggleChat() => setState(() => _isChatVisible = !_isChatVisible);

  void _onPanUpdate(DragUpdateDetails details) {
    final screenSize = MediaQuery.of(context).size;
    const buttonSize = 72.0;

    if (_floatingButtonPosition == null) return;

    setState(() {
      double dx = (_floatingButtonPosition!.dx + details.delta.dx)
          .clamp(0, screenSize.width - buttonSize);

      double dy = (_floatingButtonPosition!.dy + details.delta.dy)
          .clamp(0, screenSize.height - buttonSize);

      _floatingButtonPosition = Offset(dx, dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_floatingButtonPosition == null) {
      return widget.child;
    }

    const buttonSize = 72.0;

    final List<OverlayEntry> entries = [
      // toàn bộ app
      OverlayEntry(builder: (overlayContext) {
        return widget.child;
      }),

      // Chat hoặc Floating button
      OverlayEntry(builder: (overlayContext) {
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
              color: Colors.transparent,
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(buttonSize / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.smart_toy, color: Colors.white, size: 32),
              ),
            ),
          ),
        );
      }),
    ];

    return Material(
      color: Colors.transparent,
      child: Overlay(initialEntries: entries),
    );
  }
}

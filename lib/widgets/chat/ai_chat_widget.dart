// widgets/chat/ai_chat_widget.dart
import 'package:flutter/material.dart';
import '../../services/AI_service.dart';
import 'ai_chat_bubble.dart';

class AIChatWidget extends StatefulWidget {
  final VoidCallback? onClose;

  const AIChatWidget({Key? key, this.onClose}) : super(key: key);

  @override
  State<AIChatWidget> createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  late AIChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _chatSession = AIChatSession();

    // CÂU CHÀO THÂN THIỆN HƠN
    _chatSession.addMessage('bot',
        '👋 **CHÀO BẠN!** Rất vui được gặp bạn trên **VieJobs!**\n\n'
        '💎 **Tôi là trợ lý AI của VieJobs**, sẵn sàng hỗ trợ bạn:\n'
        '✅ **Tìm việc làm** phù hợp với kinh nghiệm và sở thích\n'
        '✅ **Tư vấn cách viết CV** ấn tượng\n'
        '✅ **Chuẩn bị cho buổi phỏng vấn**\n'
        '✅ **Tìm hiểu về văn hóa công ty**\n'
        '✅ **Các mẹo phát triển sự nghiệp**\n\n'
        '🎯 **Hôm nay bạn muốn bắt đầu từ đâu?** Hãy chia sẻ với tôi nhé! 😊');

    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Add temporary user message and mark loading in one setState
    String tempId = _chatSession.addTemporaryUserMessage(message);
    setState(() {
      _isLoading = true;
      _messageController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      // Pass tempId so sendMessage doesn't duplicate the user message
      final response = await _chatSession.sendMessage(message, tempId: tempId);

      if (!response.success) {
        _chatSession.addMessage(
            'assistant', '❌ **Xin lỗi bạn**, tôi gặp chút khó khăn: ${response.message ?? "Lỗi kết nối"}\n\nBạn có thể thử lại sau một chút không? 🙏');
      }
    } catch (e) {
      _chatSession.addMessage('assistant', '⚠️ **Xin lỗi**, có vẻ như kết nối của chúng ta gặp trục trặc. \n\nBạn có thể thử lại lúc khác được không? ❤️');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    try {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (_) {}
  }

  void _clearChat() {
    setState(() {
      _chatSession.clearHistory();
      // CÂU CHÀO KHI XÓA LỊCH SỬ
      _chatSession.addMessage('bot',
          '👋 **CHÀO BẠN!** Cuộc trò chuyện mới đã sẵn sàng.\n\n'
          '💎 **Tôi vẫn ở đây** để hỗ trợ bạn tìm **công việc mơ ước!** 💼\n\n'
          '🎯 **Bạn muốn tìm hiểu điều gì hôm nay?**');
    });
  }

  void _closeChat() => widget.onClose?.call();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Overlay background
          GestureDetector(
            onTap: _closeChat,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),

          // Chat window
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: media.width > 420 ? 420 : media.width * 0.95,
              height: media.height > 700 ? 580 : media.height * 0.82,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFA8D8EA).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // Header - NỔI BẬT HƠN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFA8D8EA), // Màu primary
                          const Color(0xFF7EC5E9), // Màu đậm hơn
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // LOGO MỚI - NỔI BẬT
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(4), // Padding nhỏ để logo to
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/ai_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'VIEJOBS ASSISTANT',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '🔹 LUÔN SẴN SÀNG HỖ TRỢ BẠN 🔹',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withOpacity(0.95),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_chatSession.messageCount > 1)
                          Tooltip(
                            message: 'XÓA LỊCH SỬ TRÒ CHUYỆN',
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.delete_outline, 
                                  size: 22,
                                  color: Colors.red[700],
                                ),
                                onPressed: _clearChat,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'ĐÓNG CHAT',
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, 
                                size: 22,
                                color: Color(0xFF2D3748),
                              ),
                              onPressed: _closeChat,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Messages
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF7FAFC),
                            const Color(0xFFEDF2F7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _chatSession.messages.length,
                        itemBuilder: (_, index) {
                          final msg = _chatSession.messages[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: AIChatBubble(
                              message: msg.content,
                              isUser: msg.role == 'user',
                              timestamp: msg.timestamp,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA8D8EA).withOpacity(0.1),
                        border: Border(
                          top: BorderSide(
                            color: const Color(0xFFA8D8EA).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFFA8D8EA),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            "💭 TÔI ĐANG SUY NGHĨ...",
                            style: TextStyle(
                              color: const Color(0xFF4A5568),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Input - NỔI BẬT
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFA8D8EA).withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: '💬 HÃY CHIA SẺ ĐIỀU BẠN THẮC MẮC...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3748),
                              ),
                              minLines: 1,
                              maxLines: 4,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: (_isLoading || _messageController.text.trim().isEmpty)
                                  ? Colors.grey[300]
                                  : const Color(0xFFA8D8EA),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: (_isLoading || _messageController.text.trim().isEmpty)
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFFA8D8EA).withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                              gradient: (_isLoading || _messageController.text.trim().isEmpty)
                                  ? null
                                  : LinearGradient(
                                      colors: [
                                        const Color(0xFFA8D8EA),
                                        const Color(0xFF7EC5E9),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                            ),
                            child: IconButton(
                              onPressed: (_isLoading || _messageController.text.trim().isEmpty)
                                  ? null
                                  : _sendMessage,
                              icon: Icon(
                                Icons.send_rounded,
                                color: (_isLoading || _messageController.text.trim().isEmpty)
                                    ? Colors.grey[600]
                                    : Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
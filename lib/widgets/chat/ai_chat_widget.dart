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

    _chatSession.addMessage('bot',
        '👋 Xin chào! Tôi là VieJobs Assistant.\n\n'
        'Tôi có thể giúp bạn:\n'
        '• Gợi ý việc làm phù hợp\n'
        '• Tư vấn CV và phỏng vấn\n'
        '• Tra cứu thông tin tuyển dụng\n'
        '• Hỗ trợ tìm kiếm công việc\n\n'
        'Bạn muốn bắt đầu với điều gì?');

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
            'assistant', 'Xin lỗi, không thể gửi: ${response.message ?? "Lỗi"}');
      }
    } catch (e) {
      _chatSession.addMessage('assistant', 'Lỗi kết nối: $e');
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
      _chatSession.addMessage('bot',
          '👋 Xin chào! Tôi là VieJobs Assistant.\n\nBạn cần hỗ trợ gì hôm nay?');
    });
  }

  void _closeChat() => widget.onClose?.call();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return Material( // ĐẢM BẢO CÓ MATERIAL Ở ĐÂY
      color: Colors.transparent, // QUAN TRỌNG: phải là transparent
      child: Stack(
        children: [
          // Overlay background - SỬA LẠI
          GestureDetector(
            onTap: _closeChat,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          // Chat window
          Positioned( // DÙNG POSITIONED THAY VÌ ALIGN
            bottom: 20,
            right: 20,
            child: Container(
              width: media.width > 420 ? 400 : media.width * 0.95,
              height: media.height > 700 ? 560 : media.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.blue[100]!],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.blue[200]!, width: 2),
                          ),
                          child: const Icon(Icons.smart_toy, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'VieJobs Assistant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        if (_chatSession.messageCount > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _clearChat,
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _closeChat,
                        ),
                      ],
                    ),
                  ),

                  // Messages
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _chatSession.messages.length,
                      itemBuilder: (_, index) {
                        final msg = _chatSession.messages[index];
                        return AIChatBubble(
                          message: msg.content,
                          isUser: msg.role == 'user',
                          timestamp: msg.timestamp,
                        );
                      },
                    ),
                  ),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(width: 12),
                          Text("AI đang trả lời..."),
                        ],
                      ),
                    ),

                  // Input
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Nhập câu hỏi...',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            minLines: 1,
                            maxLines: 4,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: (_isLoading || _messageController.text.trim().isEmpty)
                                ? Colors.grey[300]
                                : Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: (_isLoading || _messageController.text.trim().isEmpty)
                                ? null
                                : _sendMessage,
                            icon: Icon(
                              Icons.send,
                              color: (_isLoading || _messageController.text.trim().isEmpty)
                                  ? Colors.grey[600]
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
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
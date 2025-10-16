import 'package:flutter/material.dart';
import '../../common/constants/ui_constants.dart';
import '../../common/utils/ui_helpers.dart';

/// 채팅 입력 위젯
///
/// 사용자가 메시지를 입력하고 전송할 수 있는 입력창입니다.
/// 텍스트가 비어있을 때 전송 버튼이 비활성화됩니다.
class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;

  const ChatInput({
    super.key,
    required this.onSendMessage,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  /// 텍스트 변경 리스너
  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  /// 메시지 전송 처리
  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _controller.clear();
      // clear() 호출 시 리스너가 자동으로 _hasText를 false로 업데이트
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return UIHelpers.buildFloatingGlass(
      isDark: isDark,
      borderRadius: UIConstants.radiusXLarge,
      margin: const EdgeInsets.all(UIConstants.spacing8),
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing16,
        vertical: UIConstants.spacing12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요...',
                hintStyle: UIHelpers.getTextStyle(
                  isDark: isDark,
                  fontSize: UIConstants.fontMedium,
                  isSecondary: true,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: UIHelpers.getTextStyle(
                isDark: isDark,
                fontSize: UIConstants.fontMedium,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: UIConstants.spacing8),
          _buildSendButton(isDark),
        ],
      ),
    );
  }

  /// 전송 버튼 빌더
  Widget _buildSendButton(bool isDark) {
    return IconButton(
      icon: Icon(
        Icons.send_rounded,
        color: _hasText
            ? (isDark ? Colors.white : Colors.black87)
            : (isDark ? Colors.white38 : Colors.black26),
        size: UIConstants.iconLarge,
      ),
      onPressed: _hasText ? _handleSend : null,
      tooltip: '전송',
    );
  }
}

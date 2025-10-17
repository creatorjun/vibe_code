import 'package:flutter/material.dart';
import '../../common/constants/ui_constants.dart';
import '../../common/utils/ui_helpers.dart';

/// 채팅 입력 위젯
///
/// 사용자가 메시지를 입력하고 전송할 수 있는 입력창입니다.
/// 파일 첨부, 폴더 첨부, GitHub 링크 기능을 포함합니다.
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
        horizontal: UIConstants.spacing8, // 내부 패딩 조정
        vertical: UIConstants.spacing8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Column이 최소한의 높이만 차지하도록 설정
        children: [
          // 텍스트 입력 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing8),
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
              maxLines: 5, // 여러 줄 입력 가능
              minLines: 1,
              textInputAction: TextInputAction.newline, // Enter키로 줄바꿈
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),
          // 버튼 영역
          Row(
            children: [
              // 왼쪽 첨부 버튼들
              _buildAttachmentButton(
                icon: Icons.attach_file,
                tooltip: '파일 첨부',
                onPressed: () {
                  // TODO: 파일 첨부 로직
                },
              ),
              _buildAttachmentButton(
                icon: Icons.folder_open,
                tooltip: '폴더 첨부',
                onPressed: () {
                  // TODO: 폴더 첨부 로직
                },
              ),
              _buildAttachmentButton(
                icon: Icons.code, // GitHub 아이콘으로 code 사용
                tooltip: 'GitHub 링크',
                onPressed: () {
                  // TODO: GitHub 링크 로직
                },
              ),
              const Spacer(), // 오른쪽으로 밀어내기
              // 오른쪽 전송 버튼
              _buildSendButton(isDark),
            ],
          ),
        ],
      ),
    );
  }

  /// 첨부 파일 버튼 빌더
  Widget _buildAttachmentButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        color: Theme.of(context).iconTheme.color?.withAlpha(UIConstants.glassAlphaHigh),
        size: UIConstants.iconMedium,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
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
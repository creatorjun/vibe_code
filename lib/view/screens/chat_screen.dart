import 'dart:ui';
import 'package:flutter/material.dart';
import '../../common/constants/app_colors.dart';
import '../../common/constants/ui_constants.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/app_sidebar.dart';
import '../../models/message.dart';

/// 메인 채팅 화면
///
/// 사이드바, 메시지 목록, 입력창으로 구성된 채팅 인터페이스입니다.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  // 목 메시지 리스트를 빈 리스트로 초기화합니다.
  final List<Message> _messages = [
    Message.mock(
      content: '안녕하세요! Vibe Code입니다. 무엇을 도와드릴까요?',
      role: MessageRole.assistant,
    ),
    Message.mock(
      content:
      'Flutter 프로젝트를 macOS와 Windows에서 실행하고 싶어요. '
          'Riverpod 3.0을 사용해서 MVVM 패턴으로 구성하려면 어떻게 해야하나요?',
      role: MessageRole.user,
    ),
    Message.mock(
      content:
      '좋은 질문입니다! Flutter 데스크톱 앱을 MVVM 패턴과 Riverpod 3.0으로 '
          '구성하는 방법을 알려드리겠습니다.\n\n'
          '먼저 프로젝트 구조는 다음과 같이 구성하는 것을 추천합니다:\n\n'
          '1. lib/view - UI 레이어\n'
          '2. lib/providers - Riverpod providers\n'
          '3. lib/models - 데이터 모델\n'
          '4. lib/common - 공통 유틸, 상수, 테마\n\n'
          'Riverpod 3.0은 code generation을 지원하므로 '
          'riverpod_annotation과 riverpod_generator를 사용하는 것이 좋습니다.',
      role: MessageRole.assistant,
    ),
    Message.mock(
      content: '감사합니다, main.dart 예제 코드를 보여주실 수 있나요?',
      role: MessageRole.user,
    ),
    Message.mock(
      content: '''
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import '../../common/constants/app_colors.dart';
    import '../../common/constants/ui_constants.dart';
    import '../../common/utils/ui_helpers.dart';
    import '../../providers/sidebar_provider.dart';
    import '../screens/settings_screen.dart';
    import 'profile_card.dart';

    /// 애플리케이션 사이드바 위젯
    ///
    /// 마우스 호버 시 확장되며, 대화 내역과 프로필 카드를 표시합니다.
    class AppSidebar extends ConsumerStatefulWidget {
      const AppSidebar({super.key});

      @override
      ConsumerState<AppSidebar> createState() => _AppSidebarState();
    }

    class _AppSidebarState extends ConsumerState<AppSidebar> {
      bool _showExpandedContent = false;

      @override
      Widget build(BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isExpanded = ref.watch(sidebarExpandedProvider);

        return MouseRegion(
          onEnter: (_) => _handleExpand(),
          onExit: (_) => _handleCollapse(),
          child: AnimatedContainer(
            duration: UIConstants.animationNormal,
            width: isExpanded
                ? UIConstants.sidebarWidthExpanded
                : UIConstants.sidebarWidthCollapsed,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.darkSurface.withValues(alpha: 0.95),
                        AppColors.darkSurface.withValues(alpha: 0.85),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.85),
                      ],
              ),
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: UIConstants.spacing24,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(isDark, isExpanded),
                const SizedBox(height: UIConstants.spacing16),
                _buildNewChatButton(isDark, isExpanded),
                const SizedBox(height: UIConstants.spacing16),
                Expanded(
                  child: _buildConversationList(isDark, isExpanded),
                ),
                _buildBottomSection(isDark, isExpanded),
              ],
            ),
          ),
        );
      }

      /// 확장 처리
      void _handleExpand() {
        ref.read(sidebarExpandedProvider.notifier).expand();
        Future.delayed(
          const Duration(milliseconds: 150),
          () {
            if (mounted) {
              setState(() => _showExpandedContent = true);
            }
          },
        );
      }

      /// 축소 처리
      void _handleCollapse() {
        ref.read(sidebarExpandedProvider.notifier).collapse();
        setState(() => _showExpandedContent = false);
      }

      /// 헤더 빌더
      Widget _buildHeader(bool isDark, bool isExpanded) {
        return Padding(
          padding: const EdgeInsets.all(UIConstants.spacing16),
          child: isExpanded
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: UIConstants.iconLarge,
                      height: UIConstants.iconLarge,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradient,
                        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.code_rounded,
                        color: Colors.white,
                        size: UIConstants.iconMedium,
                      ),
                    ),
                    if (_showExpandedContent) ...[
                      const SizedBox(width: UIConstants.spacing12),
                      Flexible(
                        child: Text(
                          'Vibe Code',
                          style: UIHelpers.getTextStyle(
                            isDark: isDark,
                            fontSize: UIConstants.fontLarge,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                )
              : Center(
                  child: Container(
                    width: UIConstants.iconLarge,
                    height: UIConstants.iconLarge,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      color: Colors.white,
                      size: UIConstants.iconMedium,
                    ),
                  ),
                ),
        );
      }

      /// 새 대화 버튼 빌더
      Widget _buildNewChatButton(bool isDark, bool isExpanded) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? UIConstants.spacing16 : UIConstants.spacing8,
          ),
          child: UIHelpers.buildFloatingButton(
            isDark: isDark,
            onTap: () {
              // TODO: 새 대화 시작 로직
            },
            opacity: UIConstants.glassOpacityLow,
            padding: EdgeInsets.symmetric(
              horizontal: UIConstants.spacing12,
              vertical: isExpanded ? UIConstants.spacing12 : UIConstants.spacing10,
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: UIConstants.iconMedium,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                if (isExpanded && _showExpandedContent) ...[
                  const SizedBox(width: UIConstants.spacing8),
                  Text(
                    '새 대화',
                    style: UIHelpers.getTextStyle(
                      isDark: isDark,
                      fontSize: UIConstants.fontMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      /// 대화 목록 빌더
      Widget _buildConversationList(bool isDark, bool isExpanded) {
        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? UIConstants.spacing16 : UIConstants.spacing8,
          ),
          children: [
            _buildConversationItem(
              isDark: isDark,
              isExpanded: isExpanded,
              title: 'Flutter 프로젝트 구조',
              lastMessage: 'MVVM 패턴 설명...',
              isActive: true,
            ),
            const SizedBox(height: UIConstants.spacing8),
            _buildConversationItem(
              isDark: isDark,
              isExpanded: isExpanded,
              title: 'Riverpod 3.0 사용법',
              lastMessage: '상태 관리 방법...',
              isActive: false,
            ),
          ],
        );
      }

      /// 대화 항목 빌더
      Widget _buildConversationItem({
        required bool isDark,
        required bool isExpanded,
        required String title,
        required String lastMessage,
        required bool isActive,
      }) {
        return UIHelpers.buildFloatingButton(
          isDark: isDark,
          onTap: () {
            // TODO: 대화 선택 로직
          },
          opacity: isActive
              ? UIConstants.glassOpacityMedium
              : UIConstants.glassOpacityLow,
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacing12,
            vertical: UIConstants.spacing10,
          ),
          child: isExpanded && _showExpandedContent
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: UIHelpers.getTextStyle(
                        isDark: isDark,
                        fontSize: UIConstants.fontSmall,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: UIConstants.spacing3),
                    Text(
                      lastMessage,
                      style: UIHelpers.getTextStyle(
                        isDark: isDark,
                        fontSize: UIConstants.fontTiny,
                        isSecondary: true,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: UIConstants.iconMedium,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
        );
      }

      /// 하단 섹션 빌더
      Widget _buildBottomSection(bool isDark, bool isExpanded) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? UIConstants.spacing16 : UIConstants.spacing8,
            vertical: UIConstants.spacing16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingsButton(isDark, isExpanded),
              const SizedBox(height: UIConstants.spacing8),
              ProfileCard(isExpanded: isExpanded),
            ],
          ),
        );
      }
    ```
    요청하신 코드 제공이 완료되었습니다.
    ''',
      role: MessageRole.assistant,
    ),
    Message.mock(
      content: '''
    알겠습니다.
    코드를 제공합니다.
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import '../../common/constants/app_colors.dart';
    import '../../common/constants/ui_constants.dart';
    import '../../common/utils/ui_helpers.dart';
    import '../../providers/sidebar_provider.dart';
    import '../screens/settings_screen.dart';
    import 'profile_card.dart';

    /// 애플리케이션 사이드바 위젯
    ///
    /// 마우스 호버 시 확장되며, 대화 내역과 프로필 카드를 표시합니다.
    class AppSidebar extends ConsumerStatefulWidget {
      const AppSidebar({super.key});

      @override
      ConsumerState<AppSidebar> createState() => _AppSidebarState();
    }

    class _AppSidebarState extends ConsumerState<AppSidebar> {
      bool _showExpandedContent = false;

      @override
      Widget build(BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isExpanded = ref.watch(sidebarExpandedProvider);

        return MouseRegion(
          onEnter: (_) => _handleExpand(),
          onExit: (_) => _handleCollapse(),
          child: AnimatedContainer(
            duration: UIConstants.animationNormal,
            width: isExpanded
                ? UIConstants.sidebarWidthExpanded
                : UIConstants.sidebarWidthCollapsed,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.darkSurface.withValues(alpha: 0.95),
                        AppColors.darkSurface.withValues(alpha: 0.85),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.85),
                      ],
              ),
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: UIConstants.spacing24,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(isDark, isExpanded),
                const SizedBox(height: UIConstants.spacing16),
                _buildNewChatButton(isDark, isExpanded),
                const SizedBox(height: UIConstants.spacing16),
                Expanded(
                  child: _buildConversationList(isDark, isExpanded),
                ),
                _buildBottomSection(isDark, isExpanded),
              ],
            ),
          ),
        );
      }

      /// 확장 처리
      void _handleExpand() {
        ref.read(sidebarExpandedProvider.notifier).expand();
        Future.delayed(
          const Duration(milliseconds: 150),
          () {
            if (mounted) {
              setState(() => _showExpandedContent = true);
            }
          },
        );
      }

      /// 축소 처리
      void _handleCollapse() {
        ref.read(sidebarExpandedProvider.notifier).collapse();
        setState(() => _showExpandedContent = false);
      }

      /// 헤더 빌더
      Widget _buildHeader(bool isDark, bool isExpanded) {
        return Padding(
          padding: const EdgeInsets.all(UIConstants.spacing16),
          child: isExpanded
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: UIConstants.iconLarge,
                      height: UIConstants.iconLarge,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradient,
                        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.code_rounded,
                        color: Colors.white,
                        size: UIConstants.iconMedium,
                      ),
                    ),
                    if (_showExpandedContent) ...[
                      const SizedBox(width: UIConstants.spacing12),
                      Flexible(
                        child: Text(
                          'Vibe Code',
                          style: UIHelpers.getTextStyle(
                            isDark: isDark,
                            fontSize: UIConstants.fontLarge,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                )
              : Center(
                  child: Container(
                    width: UIConstants.iconLarge,
                    height: UIConstants.iconLarge,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      color: Colors.white,
                      size: UIConstants.iconMedium,
                    ),
                  ),
                ),
        );
      }

      /// 새 대화 버튼 빌더
      Widget _buildNewChatButton(bool isDark, bool isExpanded) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? UIConstants.spacing16 : UIConstants.spacing8,
          ),
          child: UIHelpers.buildFloatingButton(
            isDark: isDark,
            onTap: () {
              // TODO: 새 대화 시작 로직
            },
            opacity: UIConstants.glassOpacityLow,
            padding: EdgeInsets.symmetric(
              horizontal: UIConstants.spacing12,
              vertical: isExpanded ? UIConstants.spacing12 : UIConstants.spacing10,
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: UIConstants.iconMedium,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                if (isExpanded && _showExpandedContent) ...[
                  const SizedBox(width: UIConstants.spacing8),
                  Text(
                    '새 대화',
                    style: UIHelpers.getTextStyle(
                      isDark: isDark,
                      fontSize: UIConstants.fontMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      /// 대화 목록 빌더
      Widget _buildConversationList(bool isDark, bool isExpanded) {
        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? UIConstants.spacing16 : UIConstants.spacing8,
          ),
          children: [
            _buildConversationItem(
              isDark: isDark,
              isExpanded: isExpanded,
              title: 'Flutter 프로젝트 구조',
              lastMessage: 'MVVM 패턴 설명...',
              isActive: true,
            ),
            const SizedBox(height: UIConstants.spacing8),
            _buildConversationItem(
              isDark: isDark,
              isExpanded: isExpanded,
              title: 'Riverpod 3.0 사용법',
              lastMessage: '상태 관리 방법...',
              isActive: false,
            ),
          ],
        );
      }

      /// 대화 항목 빌더
      Widget _buildConversationItem({
        required bool isDark,
        required bool isExpanded,
        required String title,
        required String lastMessage,
        required bool isActive,
      }) {
        return UIHelpers.buildFloatingButton(
          isDark: isDark,
          onTap: () {
            // TODO: 대화 선택 로직
          },
          opacity: isActive
              ? UIConstants.glassOpacityMedium
              : UIConstants.glassOpacityLow,
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacing12,
            vertical: UIConstants.spacing10,
          ),
          child: isExpanded && _showExpandedContent
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: UIHelpers.getTextStyle(
                        isDark: isDark,
                        fontSize: UIConstants.fontSmall,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: UIConstants.spacing3),
                    Text(
                      lastMessage,
                      style: UIHelpers.getTextStyle(
                        isDark: isDark,
                        fontSize: UIConstants.fontTiny,
                        isSecondary: true,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: UIConstants.iconMedium,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
        );
      }

      /// 하단 섹션 빌더
      Widget _buildBottomSection(bool isDark, bool isExpanded) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? UIConstants.spacing16 : UIConstants.spacing8,
            vertical: UIConstants.spacing16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingsButton(isDark, isExpanded),
              const SizedBox(height: UIConstants.spacing8),
              ProfileCard(isExpanded: isExpanded),
            ],
          ),
        );
      }
    ```
    요청하신 코드 제공이 완료되었습니다.
    ''',
      role: MessageRole.user,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 초기 메시지를 추가하려면 여기에 추가할 수 있습니다.
    // 예: _messages.add(Message.mock(content: '안녕하세요!', role: MessageRole.assistant));
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 메시지 전송 핸들러
  void _handleSendMessage(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(Message.mock(content: message, role: MessageRole.user));
    });

    // 새 메시지 추가 후 스크롤
    _scrollToBottom();

    // TODO: AI 응답 생성 로직 구현
    // 임시로 봇 응답을 추가하여 테스트합니다.
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(Message.mock(
          content: '에코: $message',
          role: MessageRole.assistant,
        ));
      });
      _scrollToBottom();
    });
  }

  /// 하단으로 스크롤
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: UIConstants.animationNormal,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(isDark),
          Row(
            children: [
              const AppSidebar(),
              Expanded(
                child: Stack(
                  children: [
                    _buildMessageList(),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ChatInput(onSendMessage: _handleSendMessage),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 배경 그라데이션 빌더
  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkBackground, AppColors.darkSurface]
              : [AppColors.lightBackground, const Color(0xFFE8EAF6)],
        ),
      ),
    );
  }

  /// 메시지 리스트 빌더
  Widget _buildMessageList() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Sliver로 변환된 AppBar를 CustomScrollView의 첫 번째 자식으로 추가
        const ChatAppBar(),
        const SliverToBoxAdapter(
          child: SizedBox(height: UIConstants.spacing16),
        ),
        // 각 메시지에 대해 ChatBubble 인스턴스를 만들고 buildSlivers 메서드를 호출하여
        // Sliver 리스트를 가져온 뒤, spread operator(...)를 사용해 펼쳐 넣습니다.
        ..._messages.expand(
                (message) => ChatBubble(message: message).buildSlivers(context)),
        // 하단 입력창(ChatInput) 영역이 가려지지 않도록 여백 추가
        const SliverToBoxAdapter(
          child: SizedBox(height: 150), // 대략적인 ChatInput 높이 + 추가 여유 공간
        ),
      ],
    );
  }
}
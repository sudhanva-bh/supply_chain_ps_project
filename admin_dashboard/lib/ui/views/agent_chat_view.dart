import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/agent_response.dart';
import '../../services/agent_api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_container.dart';
import '../components/dynamic_message_widget.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final AgentResponse? agentResponse;
  final String? error;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.agentResponse,
    this.error,
  });
}

class ChatStateNotifier extends Notifier<List<ChatMessage>> {
  bool isLoading = false;
  String loadingMessage = "Agent is reasoning...";

  @override
  List<ChatMessage> build() {
    return [
      ChatMessage(
        text:
            "Hello! I am your AI Stockx Assistant. Ask me anything about suppliers, inventory, or purchase orders.",
        isUser: false,
        agentResponse: AgentResponse(
          responseType: "text_only",
          conversationalText:
              "Hello! I am your AI Stockx Assistant. Ask me anything about suppliers, inventory, or purchase orders.",
        ),
      ),
    ];
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final apiService = ref.read(agentApiServiceProvider);

    state = [...state, ChatMessage(text: message, isUser: true)];
    isLoading = true;
    loadingMessage = "Connecting to agent...";
    state = [...state]; // trigger rebuild for loading state

    try {
      final stream = apiService.sendMessageStream(message);

      await for (final event in stream) {
        if (event['type'] == 'status') {
          loadingMessage = event['message'] as String;
          state = [...state]; // trigger rebuild to update loading text
        } else if (event['type'] == 'final') {
          final response = AgentResponse.fromJson(event['data']);
          state = [
            ...state,
            ChatMessage(
              text: response.conversationalText,
              isUser: false,
              agentResponse: response,
            ),
          ];
        }
      }
    } catch (e) {
      state = [
        ...state,
        ChatMessage(text: "Error", isUser: false, error: e.toString()),
      ];
    } finally {
      isLoading = false;
      loadingMessage = "Agent is reasoning...";
      state = [...state];
    }
  }

  Future<void> confirmAndExecuteTool(String toolName, String argsJson) async {
    final apiService = ref.read(agentApiServiceProvider);

    isLoading = true;
    loadingMessage = "Executing $toolName...";
    state = [...state];

    try {
      final result = await apiService.executeTool(toolName, argsJson);

      state = [
        ...state,
        ChatMessage(
          text: "Action '$toolName' executed successfully.",
          isUser: false,
          agentResponse: AgentResponse(
            responseType: "text_only",
            conversationalText:
                "Action '$toolName' executed successfully.\n\nResult:\n```json\n${result['result']}\n```",
          ),
        ),
      ];
    } catch (e) {
      state = [
        ...state,
        ChatMessage(
          text: "Failed to execute '$toolName'",
          isUser: false,
          error: e.toString(),
        ),
      ];
    } finally {
      isLoading = false;
      loadingMessage = "Agent is reasoning...";
      state = [...state];
    }
  }

  void abortAction() {
    state = [
      ...state,
      ChatMessage(
        text: "Action aborted by user.",
        isUser: false,
        agentResponse: AgentResponse(
          responseType: "text_only",
          conversationalText: "Action aborted by user.",
        ),
      ),
    ];
  }
}

final chatProvider = NotifierProvider<ChatStateNotifier, List<ChatMessage>>(
  ChatStateNotifier.new,
);

class AgentChatView extends ConsumerStatefulWidget {
  const AgentChatView({super.key});

  @override
  ConsumerState<AgentChatView> createState() => _AgentChatViewState();
}

class _AgentChatViewState extends ConsumerState<AgentChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final isLoading = ref.watch(chatProvider.notifier).isLoading;

    // Auto-scroll when new messages arrive
    ref.listen<List<ChatMessage>>(chatProvider, (previous, next) {
      if (previous?.length != next.length) {
        _scrollToBottom();
      }
    });

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Expanded(
            child: GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return _buildLoadingIndicator();
                    }

                    final msg = messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: AppTheme.primaryText),
                      decoration: const InputDecoration(
                        hintText: 'Ask about Stockx...',
                        hintStyle: TextStyle(color: AppTheme.secondaryText),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) {
                        ref.read(chatProvider.notifier).sendMessage(val);
                        _textController.clear();
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primaryText),
                    onPressed: () {
                      ref
                          .read(chatProvider.notifier)
                          .sendMessage(_textController.text);
                      _textController.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final loadingMessage = ref.watch(chatProvider.notifier).loadingMessage;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0, right: 64.0),
        child: GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  loadingMessage,
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16.0, left: 64.0),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(
              16,
            ).copyWith(bottomRight: const Radius.circular(4)),
            border: Border.all(color: Colors.white60),
          ),
          padding: const EdgeInsets.all(16.0),
          child: SelectableText(
            message.text,
            style: const TextStyle(color: AppTheme.primaryText),
          ),
        ),
      );
    } else if (message.error != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16.0, right: 64.0),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              16,
            ).copyWith(bottomLeft: const Radius.circular(4)),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: SelectableText(
            message.error!,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24.0, right: 64.0),
          child: DynamicMessageWidget(response: message.agentResponse!),
        ),
      );
    }
  }
}

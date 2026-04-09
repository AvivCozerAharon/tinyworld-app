import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/features/chats/widgets/typing_indicator.dart';
import 'package:tinyworld_app/features/onboarding/onboarding_controller.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';

const _firstQuestion = "Como é um domingo perfeito pra você?";

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});
  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Message> _messages = [
    _Message(text: _firstQuestion, isAi: true),
  ];
  int _questionIndex = 0;
  bool _done = false;
  bool _sending = false;

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending || _done) return;
    setState(() {
      _messages.add(_Message(text: text, isAi: false));
      _ctrl.clear();
      _sending = true;
    });
    _scrollToBottom();

    final userId = ref.read(onboardingControllerProvider).userId;
    try {
      final resp = await apiClient.post('/onboarding/chat', data: {
        'user_id': userId,
        'question_index': _questionIndex,
        'answer': text,
      });
      final data = resp.data as Map<String, dynamic>;
      _questionIndex++;
      if (data['done'] == true) {
        setState(() {
          _done = true;
          _sending = false;
        });
      } else {
        setState(() {
          _messages
              .add(_Message(text: data['question'] as String, isAi: true));
          _sending = false;
        });
      }
    } catch (_) {
      setState(() => _sending = false);
    }
    _scrollToBottom();
  }

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (mounted) context.go('/onboarding/welcome');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 5,
      title: 'Conte sobre você',
      subtitle: 'Quanto mais você compartilha, melhor o match.',
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isAi = msg.isAi;
                return Align(
                  alignment:
                      isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width * 0.75),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isAi
                          ? Colors.white.withValues(alpha: 0.07)
                          : const Color(0xFF6C63FF).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                            Radius.circular(isAi ? 4 : 16),
                        bottomRight:
                            Radius.circular(isAi ? 16 : 4),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isAi ? Colors.white70 : Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_sending)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const TypingIndicator(
                    dotColor: Color(0xFF6C63FF),
                  ),
                ),
              ),
            ),
          if (_done)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: OnboardingButton(
                onPressed: _finish,
                child: const Text('Pronto!'),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Sua resposta...',
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.2)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _sending
                        ? const Color(0xFF6C63FF).withOpacity(0.4)
                        : const Color(0xFF6C63FF),
                    child: IconButton(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isAi;
  _Message({required this.text, required this.isAi});
}

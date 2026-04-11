import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/api/sse_client.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
import 'package:tinyworld_app/features/chats/widgets/typing_indicator.dart';
import 'package:tinyworld_app/features/onboarding/onboarding_controller.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';
import 'package:tinyworld_app/shared/widgets/voice_wave.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});
  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _stt = SpeechToText();
  final List<_ChatMessage> _messages = [];
  int _questionIndex = 0;
  int _totalQuestions = 5;
  bool _done = false;
  bool _sending = false;
  bool _isTyping = false;
  bool _initialized = false;
  bool _sttAvailable = false;
  bool _isListening = false;
  bool _voiceMode = false;
  String _partialText = '';
  double _soundLevel = 0;
  String _streamingText = '';
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _initStt();
    _startChat();
  }

  Future<void> _initStt() async {
    _sttAvailable = await _stt.initialize(
      onError: (_) {},
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _startListening() {
    if (!_sttAvailable || _isListening) return;
    setState(() {
      _isListening = true;
      _partialText = '';
      _soundLevel = 0;
    });
    _stt.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _partialText = result.recognizedWords;
        });
        if (result.finalResult) {
          setState(() {
            _isListening = false;
            _soundLevel = 0;
          });
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            _ctrl.text = text;
            _send();
          }
        }
      },
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _soundLevel = level);
      },
      localeId: 'pt_BR',
      listenOptions: SpeechListenOptions(listenMode: ListenMode.confirmation),
    );
  }

  void _stopListening() {
    _stt.stop();
    setState(() {
      _isListening = false;
      _soundLevel = 0;
    });
  }

  void _toggleVoiceMode() {
    setState(() => _voiceMode = !_voiceMode);
    if (_voiceMode && !_done && !_sending && _initialized) {
      _startListening();
    } else {
      _stopListening();
    }
  }

  Future<void> _startChat() async {
    final userId = ref.read(onboardingControllerProvider).userId;
    if (userId == null) return;
    try {
      final resp = await apiClient.post('/onboarding/chat/start', data: {
        'user_id': userId,
      });
      final data = resp.data as Map<String, dynamic>;
      _totalQuestions = data['total_questions'] ?? 5;
      final firstQ = data['first_question'] as String;
      setState(() => _initialized = true);
      _showTinyzinhoMessage(firstQ);
    } catch (_) {
      setState(() => _initialized = true);
      _showTinyzinhoMessage('Como é um domingo perfeito pra você?');
    }
  }

  Future<void> _showTinyzinhoMessage(String text) async {
    setState(() => _isTyping = true);
    _scrollToBottom();
    final delay = 800 + Random().nextInt(1500);
    await Future.delayed(Duration(milliseconds: delay));
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(text: text, isTinyzinho: true));
    });
    _scrollToBottom();

    if (_voiceMode && !_done) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && _voiceMode && !_done && !_sending) {
        _startListening();
      }
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending || _done) return;
    _stopListening();
    setState(() {
      _messages.add(_ChatMessage(text: text, isTinyzinho: false));
      _ctrl.clear();
      _partialText = '';
      _sending = true;
    });
    _scrollToBottom();

    try {
      final token = await localStorage.getIdToken();
      sseClient.post('/onboarding/chat/stream', data: {
        'question_index': _questionIndex,
        'answer': text,
      }).listen((event) {
        if (!mounted) return;

        if (event.event == 'done') {
          setState(() {
            _done = true;
            _sending = false;
            _isStreaming = false;
            _streamingText = '';
          });
          _showTinyzinhoMessage(
              'Obrigado por me contar tudo! Agora já te conheço bem melhor. 💙');
          return;
        }

        if (event.event == 'question_start') {
          setState(() {
            _isStreaming = true;
            _streamingText = '';
          });
          return;
        }

        if (event.event == 'token' && event.data != null) {
          final tokenChar = event.data!['token'] as String? ?? '';
          setState(() {
            _streamingText += tokenChar;
          });
          _scrollToBottom();
          return;
        }

        if (event.event == 'question_end' && event.data != null) {
          final question = event.data!['question'] as String? ?? '';
          _questionIndex++;
          setState(() {
            _sending = false;
            _isStreaming = false;
            _streamingText = '';
          });
          _showTinyzinhoMessage(question);
        }
      }, onError: (_) {
        if (mounted) setState(() => _sending = false);
      });
    } catch (_) {
      setState(() => _sending = false);
    }
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
      step: 8,
      totalSteps: 9,
      title: 'Conversa com Tinyzinho',
      subtitle: 'Quanto mais você compartilha, melhor o match.',
      child: Column(
        children: [
          _buildTinyzinhoHeader(),
          Expanded(child: _buildMessageList()),
          if (_isTyping) _buildTypingBubble(),
          if (_isStreaming && _streamingText.isNotEmpty)
            _buildStreamingBubble(),
          if (_isListening && _partialText.isNotEmpty)
            _buildLiveTranscription(),
          if (_done)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: OnboardingButton(
                onPressed: _finish,
                child: const Text('Pronto!'),
              ),
            )
          else if (!_sending && _initialized)
            _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTinyzinhoHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B76F2), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: const Center(
              child: Text(
                'T',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tinyzinho',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                _isTyping
                    ? 'digitando...'
                    : _isListening
                        ? 'ouvindo...'
                        : 'online',
                style: TextStyle(
                  fontSize: 11,
                  color: _isListening
                      ? Colors.orange
                      : _isTyping
                          ? const Color(0xFF1B76F2)
                          : const Color(0xFF22C55E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_sttAvailable)
            GestureDetector(
              onTap: _toggleVoiceMode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _voiceMode
                      ? const Color(0xFF1B76F2).withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _voiceMode
                        ? const Color(0xFF1B76F2)
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.headset_mic,
                      size: 14,
                      color: _voiceMode
                          ? const Color(0xFF1B76F2)
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Voz',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _voiceMode
                            ? const Color(0xFF1B76F2)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            '$_questionIndex/$_totalQuestions',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        return _buildMessageBubble(msg.text, msg.isTinyzinho);
      },
    );
  }

  Widget _buildMessageBubble(String text, bool isTiny) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isTiny ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isTiny) ...[
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF1B76F2), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              child: const Center(
                child: Text('T',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isTiny ? const Color(0xFFF5F7FA) : const Color(0xFF1B76F2),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isTiny ? 4 : 14),
                  bottomRight: Radius.circular(isTiny ? 14 : 4),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isTiny ? const Color(0xFF1A1A2E) : Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF1B76F2), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: const Center(
              child: Text('T',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const TypingIndicator(dotColor: Color(0xFF1B76F2)),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingBubble() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF1B76F2), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: const Center(
              child: Text('T',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _streamingText,
                      style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 2,
                    height: 14,
                    color: const Color(0xFF1B76F2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTranscription() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1B76F2).withValues(alpha: 0.15),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _partialText.isEmpty ? 'Ouvindo...' : _partialText,
                  style: TextStyle(
                    color: _partialText.isEmpty
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF1A1A2E),
                    fontSize: 14,
                    fontStyle: _partialText.isEmpty ? FontStyle.italic : null,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 2,
                height: 14,
                color: const Color(0xFF1B76F2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    if (_voiceMode) return _buildVoiceInput();
    return _buildTextInput();
  }

  Widget _buildVoiceInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              VoiceWaveButton(
                isListening: _isListening,
                onTap: () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
                size: 64,
                soundLevel: _soundLevel,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isListening ? 'Toque para parar' : 'Toque para falar',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
      child: Row(
        children: [
          if (_sttAvailable)
            VoiceWaveButton(
              isListening: _isListening,
              onTap: () {
                if (_isListening) {
                  _stopListening();
                  if (_ctrl.text.trim().isNotEmpty) _send();
                } else {
                  _startListening();
                }
              },
              size: 44,
              soundLevel: _soundLevel,
            ),
          if (_sttAvailable) const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Sua resposta...',
                  hintStyle: TextStyle(color: Color(0xFFC4C9D0)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF1B76F2),
            child: IconButton(
              onPressed: _send,
              icon: const Icon(Icons.send, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isTinyzinho;
  _ChatMessage({required this.text, required this.isTinyzinho});
}

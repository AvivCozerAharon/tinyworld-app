import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/api/sse_client.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
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
  bool _voiceMode = true;
  int _listenSession = 0;
  String _partialText = '';
  double _soundLevel = 0;
  String _streamingText = '';
  bool _isStreaming = false;
  StreamSubscription<SSEEvent>? _sseSub;

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
    final session = ++_listenSession;
    setState(() {
      _isListening = true;
      _partialText = '';
      _soundLevel = 0;
    });
    _stt.listen(
      onResult: (result) {
        if (!mounted || _listenSession != session) return;
        setState(() => _partialText = result.recognizedWords);
        if (result.finalResult) {
          setState(() {
            _isListening = false;
            _soundLevel = 0;
          });
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            _ctrl.text = text;
            _send(byVoice: _voiceMode);
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

  void _stopAndSend() {
    _stt.stop();
    setState(() {
      _isListening = false;
      _soundLevel = 0;
    });
    final text = _partialText.trim();
    if (text.isNotEmpty) {
      _ctrl.text = text;
      _send(byVoice: true);
    }
  }

  void _switchToTextMode() {
    _stopListening();
    setState(() => _voiceMode = false);
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
  }

  Future<void> _send({bool byVoice = false}) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending || _done) return;
    _stopListening();
    setState(() {
      _messages.add(_ChatMessage(text: text, isTinyzinho: false, isVoice: byVoice));
      _ctrl.clear();
      _partialText = '';
      _sending = true;
    });
    _scrollToBottom();

    try {
      await _sseSub?.cancel();
      _sseSub = sseClient.post('/onboarding/chat/stream', data: {
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
          setState(() => _streamingText += event.data!['token'] as String? ?? '');
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
    _sseSub?.cancel();
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
          if (_isStreaming && _streamingText.isNotEmpty) _buildStreamingBubble(),
          if (_voiceMode && _isListening && _partialText.isNotEmpty)
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
        color: TwColors.surface,
        border: Border(bottom: BorderSide(color: TwColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: TwGradients.accent,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Center(
              child: Text('T',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  )),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tinyzinho',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TwColors.onBg,
                  )),
              Text(
                _isTyping
                    ? 'digitando...'
                    : _isListening
                        ? 'ouvindo...'
                        : 'online',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: _isListening
                      ? TwColors.warning
                      : _isTyping
                          ? TwColors.primary
                          : TwColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$_questionIndex/$_totalQuestions',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: TwColors.muted,
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
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isTiny = msg.isTinyzinho;
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
                gradient: TwGradients.accent,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              child: Center(
                child: Text('T',
                    style: GoogleFonts.spaceGrotesk(
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
                color: isTiny ? TwColors.card : null,
                gradient: isTiny ? null : TwGradients.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isTiny ? 4 : 14),
                  bottomRight: Radius.circular(isTiny ? 14 : 4),
                ),
                border: isTiny
                    ? Border.all(color: TwColors.border, width: 0.5)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      msg.text,
                      style: GoogleFonts.spaceGrotesk(
                        color: isTiny ? TwColors.onBg : Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (!isTiny && msg.isVoice) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.mic,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ],
                ],
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
              gradient: TwGradients.accent,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Center(
              child: Text('T',
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: TwColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TwColors.border, width: 0.5),
            ),
            child: const TypingIndicator(dotColor: TwColors.primary),
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
              gradient: TwGradients.accent,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Center(
              child: Text('T',
                  style: GoogleFonts.spaceGrotesk(
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
                color: TwColors.card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(14),
                ),
                border: Border.all(color: TwColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _streamingText,
                      style: GoogleFonts.spaceGrotesk(
                          color: TwColors.onBg, fontSize: 14, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(width: 2, height: 14, color: TwColors.primary),
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
            color: TwColors.primary.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(4),
            ),
            border:
                Border.all(color: TwColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _partialText,
                  style: GoogleFonts.spaceGrotesk(
                    color: TwColors.onBg,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(width: 2, height: 14, color: TwColors.primary),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VoiceWaveButton(
            isListening: _isListening,
            onTap: _isListening ? _stopAndSend : _startListening,
            size: 72,
            soundLevel: _soundLevel,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _isListening ? 'Toque para enviar' : 'Toque para responder',
              key: ValueKey(_isListening),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: TwColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _switchToTextMode,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Prefiro digitar',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: TwColors.muted,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: TwColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      decoration: const BoxDecoration(
        color: TwColors.surface,
        border: Border(top: BorderSide(color: TwColors.border, width: 0.5)),
      ),
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
                color: TwColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: TwColors.border),
              ),
              child: TextField(
                controller: _ctrl,
                style:
                    GoogleFonts.spaceGrotesk(color: TwColors.onBg, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Sua resposta...',
                  hintStyle: GoogleFonts.spaceGrotesk(
                      color: TwColors.muted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: TwGradients.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, size: 18, color: Colors.white),
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
  final bool isVoice;
  _ChatMessage({
    required this.text,
    required this.isTinyzinho,
    this.isVoice = false,
  });
}

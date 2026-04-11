import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tinyworld_app/features/chats/widgets/typing_indicator.dart';
import 'package:tinyworld_app/features/profile/profile_controller.dart';

class TrainAgentScreen extends ConsumerStatefulWidget {
  const TrainAgentScreen({super.key});

  @override
  ConsumerState<TrainAgentScreen> createState() => _TrainAgentScreenState();
}

class _TrainAgentScreenState extends ConsumerState<TrainAgentScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _stt = SpeechToText();
  final List<_TrainMsg> _messages = [];
  bool _sttAvailable = false;
  bool _isListening = false;
  bool _isTyping = false;
  int? _selectedOption;

  @override
  void initState() {
    super.initState();
    _initStt();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainControllerProvider.notifier).fetchQuestion();
    });
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

  void _toggleMic() {
    if (_isListening) {
      _stt.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _stt.listen(
        onResult: (result) {
          if (result.finalResult) {
            _ctrl.text = result.recognizedWords;
            setState(() => _isListening = false);
          }
        },
        localeId: 'pt_BR',
        listenOptions: SpeechListenOptions(listenMode: ListenMode.confirmation),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  Future<void> _showTypingThenMessage(String text) async {
    setState(() => _isTyping = true);
    _scrollToBottom();
    final delay = 800 + Random().nextInt(1500);
    await Future.delayed(Duration(milliseconds: delay));
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_TrainMsg(text: text, isTinyzinho: true));
    });
    _scrollToBottom();
  }

  void _onQuestionLoaded(TrainQuestion? q) {
    if (q != null && _messages.where((m) => m.text == q.question).isEmpty) {
      _showTypingThenMessage(q.question);
    }
  }

  void _submitAnswer(String answer) {
    if (answer.isEmpty) return;
    setState(() {
      _messages.add(_TrainMsg(text: answer, isTinyzinho: false));
      _selectedOption = null;
      _ctrl.clear();
    });
    _scrollToBottom();
    ref.read(trainControllerProvider.notifier).submitAnswer(answer).then((_) {
      final state = ref.read(trainControllerProvider);
      if (state.currentQuestion != null) {
        _onQuestionLoaded(state.currentQuestion);
      } else {
        _showTypingThenMessage(
            'Obrigado por compartilhar! Vou lembrar de tudo. 💙');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainControllerProvider);

    ref.listen<TrainState>(trainControllerProvider, (prev, next) {
      if (prev?.currentQuestion?.questionId !=
          next.currentQuestion?.questionId) {
        _onQuestionLoaded(next.currentQuestion);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFDFB),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1B76F2), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('T',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Tinyzinho',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          if (state.totalAnswered > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${state.totalAnswered} respondidas',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isTyping) _buildTypingBubble(),
          if (state.isLoading &&
              state.currentQuestion == null &&
              _messages.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.currentQuestion == null && _messages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sem perguntas no momento',
                      style: TextStyle(color: Color(0xFF6B7280))),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref
                        .read(trainControllerProvider.notifier)
                        .fetchQuestion(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          else if (!_isTyping)
            _buildInputArea(state),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Responda perguntas para que seu\nagente te conheça melhor',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
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
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1B76F2), Color(0xFF3B82F6)]),
                    borderRadius: BorderRadius.circular(6),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isTiny
                        ? const Color(0xFFF5F7FA)
                        : const Color(0xFF1B76F2),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isTiny ? 4 : 14),
                      bottomRight: Radius.circular(isTiny ? 14 : 4),
                    ),
                  ),
                  child: Text(
                    msg.text,
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
      },
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
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1B76F2), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(6),
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

  Widget _buildInputArea(TrainState state) {
    final q = state.currentQuestion;
    if (q == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: q.questionType == 'multiple_choice' && q.options != null
              ? _buildMultipleChoiceOptions(state, q.options!)
              : _buildTextInput(state),
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(TrainState state, List<String> options) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(options.length, (i) {
          final selected = _selectedOption == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: state.isLoading
                  ? null
                  : () => setState(() => _selectedOption = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1B76F2).withValues(alpha: 0.08)
                      : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        selected ? const Color(0xFF1B76F2) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? const Color(0xFF1B76F2)
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF1B76F2)
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? const Color(0xFF1B76F2)
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _selectedOption != null && !state.isLoading
                ? () => _submitAnswer(options[_selectedOption!])
                : null,
            child: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enviar',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput(TrainState state) {
    return Row(
      children: [
        if (_sttAvailable)
          GestureDetector(
            onTap: _toggleMic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.red.shade400
                    : const Color(0xFFF5F7FA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                size: 20,
                color: _isListening ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
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
              onSubmitted: (_) {
                final text = _ctrl.text.trim();
                if (text.isNotEmpty) _submitAnswer(text);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: const Color(0xFF1B76F2),
          child: IconButton(
            onPressed: state.isLoading
                ? null
                : () {
                    final text = _ctrl.text.trim();
                    if (text.isNotEmpty) _submitAnswer(text);
                  },
            icon: const Icon(Icons.send, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _TrainMsg {
  final String text;
  final bool isTinyzinho;
  _TrainMsg({required this.text, required this.isTinyzinho});
}

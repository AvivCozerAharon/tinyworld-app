import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/chats/widgets/typing_indicator.dart';
import 'package:tinyworld_app/features/profile/profile_controller.dart' show TrainState, TrainQuestion, trainControllerProvider;

class TrainAgentScreen extends ConsumerStatefulWidget {
  const TrainAgentScreen({super.key});

  @override
  ConsumerState<TrainAgentScreen> createState() => _TrainAgentScreenState();
}

class _TrainAgentScreenState extends ConsumerState<TrainAgentScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_TrainMsg> _messages = [];
  bool _isTyping = false;
  int? _selectedOption;
  // Track which question IDs have already been queued for display
  final Set<String> _shownIds = {};

  @override
  void initState() {
    super.initState();
    // Provider already calls fetchQuestion on creation — listen for first result
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = ref.read(trainControllerProvider).currentQuestion;
      if (q != null) _maybeShowQuestion(q);
    });
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

  void _maybeShowQuestion(TrainQuestion q) {
    if (_shownIds.contains(q.questionId)) return;
    _shownIds.add(q.questionId);
    _showTypingThenMessage(q.question);
  }

  Future<void> _showTypingThenMessage(String text) async {
    setState(() => _isTyping = true);
    _scrollToBottom();
    // Shorter, fixed delay — feels snappy but still human
    await Future.delayed(Duration(milliseconds: 400 + Random().nextInt(400)));
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_TrainMsg(text: text, isTinyzinho: true));
    });
    _scrollToBottom();
  }

  void _submitAnswer(String answer) {
    if (answer.isEmpty) return;
    setState(() {
      _messages.add(_TrainMsg(text: answer, isTinyzinho: false));
      _selectedOption = null;
      _ctrl.clear();
    });
    _scrollToBottom();
    ref.read(trainControllerProvider.notifier).submitAnswer(answer).then((reaction) {
      if (!mounted) return;
      final state = ref.read(trainControllerProvider);
      _showReactionThenQuestion(
        reaction: reaction,
        nextQuestion: state.currentQuestion,
      );
    });
  }

  Future<void> _showReactionThenQuestion({
    required String reaction,
    required TrainQuestion? nextQuestion,
  }) async {
    // Show reaction first if we have one
    if (reaction.isNotEmpty) {
      await _showTypingThenMessage(reaction);
      if (!mounted) return;
    }
    if (nextQuestion != null) {
      _maybeShowQuestion(nextQuestion);
    } else {
      _showTypingThenMessage('Obrigado por compartilhar! Vou lembrar de tudo. 💙');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainControllerProvider);



    return Scaffold(
      backgroundColor: TwColors.bg,
      appBar: AppBar(
        backgroundColor: TwColors.bg,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: TwGradients.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('T',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            Text('Tinyzinho',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TwColors.onBg)),
          ],
        ),
        actions: [
          if (state.totalAnswered > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TwColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(TwRadius.pill),
                    border: Border.all(
                        color: TwColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${state.totalAnswered} ✓',
                    style: GoogleFonts.spaceGrotesk(
                      color: TwColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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
              child: Center(
                  child: CircularProgressIndicator(color: TwColors.primary)),
            )
          else if (state.currentQuestion == null && _messages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sem perguntas no momento',
                      style: GoogleFonts.spaceGrotesk(
                          color: TwColors.muted, fontSize: 14)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.read(trainControllerProvider.notifier).fetchQuestion(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          else if (!_isTyping && state.currentQuestion != null)
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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: TwColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: TwColors.border),
                ),
                child: const Icon(Icons.psychology_outlined,
                    size: 32, color: TwColors.muted),
              ),
              const SizedBox(height: 16),
              Text(
                'Responda perguntas para que seu\nagente te conheça melhor',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                    color: TwColors.muted, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final isTiny = msg.isTinyzinho;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isTiny ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isTiny) ...[
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    gradient: TwGradients.accent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text('T',
                        style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isTiny ? null : TwGradients.primary,
                    color: isTiny ? TwColors.card : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isTiny ? 4 : 16),
                      bottomRight: Radius.circular(isTiny ? 16 : 4),
                    ),
                    border: isTiny
                        ? Border.all(color: TwColors.border, width: 0.5)
                        : null,
                  ),
                  child: Text(
                    msg.text,
                    style: GoogleFonts.spaceGrotesk(
                      color: isTiny ? TwColors.onBg : Colors.white,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              gradient: TwGradients.accent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text('T',
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 12,
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

  Widget _buildInputArea(TrainState state) {
    final q = state.currentQuestion!;
    return Container(
      decoration: const BoxDecoration(
        color: TwColors.surface,
        border: Border(top: BorderSide(color: TwColors.border, width: 0.5)),
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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? TwColors.primary.withValues(alpha: 0.1)
                      : TwColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? TwColors.primary.withValues(alpha: 0.6)
                        : TwColors.border,
                    width: selected ? 1.5 : 1,
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
                        color: selected ? TwColors.primary : Colors.transparent,
                        border: Border.all(
                          color: selected ? TwColors.primary : TwColors.muted,
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
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? TwColors.primary : TwColors.onBg,
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
          child: Container(
            decoration: BoxDecoration(
              gradient: _selectedOption != null && !state.isLoading
                  ? TwGradients.primary
                  : null,
              color: _selectedOption != null && !state.isLoading
                  ? null
                  : TwColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
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
                  : Text('Enviar',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 15,
                      )),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput(TrainState state) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: TwColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: TwColors.border),
            ),
            child: TextField(
              controller: _ctrl,
              style: GoogleFonts.spaceGrotesk(
                  color: TwColors.onBg, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Sua resposta...',
                hintStyle:
                    GoogleFonts.spaceGrotesk(color: TwColors.muted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
              ),
              onSubmitted: (_) {
                final text = _ctrl.text.trim();
                if (text.isNotEmpty) _submitAnswer(text);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: state.isLoading
              ? null
              : () {
                  final text = _ctrl.text.trim();
                  if (text.isNotEmpty) _submitAnswer(text);
                },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: state.isLoading ? null : TwGradients.primary,
              color: state.isLoading ? TwColors.border : null,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, size: 18, color: Colors.white),
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

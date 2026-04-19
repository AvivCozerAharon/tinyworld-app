import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/companion/companion_controller.dart';

class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(companionControllerProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    await ref.read(companionControllerProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companionControllerProvider);

    ref.listen(companionControllerProvider, (_, next) {
      if (!next.isSending) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: TwColors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: TwGradients.accent,
                borderRadius: BorderRadius.circular(TwRadius.pill),
              ),
              child: const Center(
                child: Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tinyzinho',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('seu companheiro de IA',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Limpar conversa',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Limpar conversa?'),
                  content: const Text('O histórico será apagado.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Limpar')),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(companionControllerProvider.notifier).clearHistory();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.messages.isEmpty
                    ? _buildEmpty(context)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: state.messages.length + (state.isSending ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == state.messages.length) {
                            return _buildTyping(context);
                          }
                          final msg = state.messages[i];
                          return _buildBubble(context, msg);
                        },
                      ),
          ),
          _buildInput(context, state.isSending),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TwSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: TwGradients.accent,
                borderRadius: BorderRadius.circular(TwRadius.pill),
              ),
              child: const Center(
                child: Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32)),
              ),
            ),
            const SizedBox(height: TwSpacing.lg),
            Text('Oi! Sou o Tinyzinho 👋',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: TwSpacing.sm),
            Text(
              'Pode me contar qualquer coisa — seu dia, suas dúvidas, o que quiser. Eu te conheço e estou aqui.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context, CompanionMessage msg) {
    final isMe = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: TwGradients.accent,
                borderRadius: BorderRadius.circular(TwRadius.pill),
              ),
              child: const Center(
                child: Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe ? TwGradients.primary : null,
                color: isMe ? null : TwColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(TwRadius.lg),
                  topRight: const Radius.circular(TwRadius.lg),
                  bottomLeft: Radius.circular(isMe ? TwRadius.lg : 4),
                  bottomRight: Radius.circular(isMe ? 4 : TwRadius.lg),
                ),
              ),
              child: Text(
                msg.content,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTyping(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: TwGradients.accent,
              borderRadius: BorderRadius.circular(TwRadius.pill),
            ),
            child: const Center(
              child: Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: TwColors.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(TwRadius.lg),
                topRight: Radius.circular(TwRadius.lg),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(TwRadius.lg),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _Dot(delay: i * 200)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context, bool isSending) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
      ),
      decoration: const BoxDecoration(
        color: TwColors.surface,
        border: Border(top: BorderSide(color: TwColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !isSending,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              style: GoogleFonts.spaceGrotesk(color: TwColors.onBg, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Manda uma mensagem...',
                hintStyle: GoogleFonts.spaceGrotesk(color: TwColors.muted, fontSize: 14),
                filled: true,
                fillColor: TwColors.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.pill),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.pill),
                  borderSide: const BorderSide(color: TwColors.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.pill),
                  borderSide: const BorderSide(color: TwColors.primary, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSending ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isSending ? null : TwGradients.accent,
                color: isSending ? TwColors.border : null,
                borderRadius: BorderRadius.circular(TwRadius.pill),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: isSending ? TwColors.muted : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: TwColors.muted.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(TwRadius.pill),
        ),
      ),
    );
  }
}

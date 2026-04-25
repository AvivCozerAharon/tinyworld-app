import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final int replyingToIndex;
  final VoidCallback onCancelReply;
  final void Function(int) onReply;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.replyingToIndex = -1,
    required this.onCancelReply,
    required this.onReply,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final FocusNode _focusNode = FocusNode();
  int _maxLines = 1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateMaxLines);
  }

  void _updateMaxLines() {
    final lines = '\n'.allMatches(widget.controller.text).length;
    final newMax = lines >= 5 ? 5 : lines + 1;
    if (newMax != _maxLines) {
      setState(() => _maxLines = newMax);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateMaxLines);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      decoration: const BoxDecoration(
        color: TwColors.surface,
        border: Border(top: BorderSide(color: TwColors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyingToIndex >= 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 28,
                    decoration: BoxDecoration(
                      color: TwColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Respondendo',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: TwColors.muted,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onCancelReply,
                    child: const Icon(Icons.close,
                        size: 16, color: TwColors.muted),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: TwColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: TwColors.border),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    style: GoogleFonts.spaceGrotesk(color: TwColors.onBg, fontSize: 14),
                    maxLines: _maxLines,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Escreva uma mensagem...',
                      hintStyle: GoogleFonts.spaceGrotesk(color: TwColors.muted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => widget.onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onLongPress: () {
                  if (widget.replyingToIndex >= 0) {
                    widget.onCancelReply();
                  }
                },
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
        ],
      ),
    );
  }
}

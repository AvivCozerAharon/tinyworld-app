import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';

class MessageBubble extends StatefulWidget {
  final String text;
  final bool isMe;
  final String senderLabel;
  final Color senderColor;
  final String avatarSeed;
  final bool isSimulation;
  final int? interesse;
  final String? reaction;
  final String? replyText;
  final String? replyLabel;
  final VoidCallback? onLongPress;
  final String? photoBase64;
  final String? audioBase64;
  final String readStatus;
  final VoidCallback? onPhotoTap;
  final DateTime timestamp;
  final bool showAvatar;

  const MessageBubble({
    required super.key,
    required this.text,
    required this.isMe,
    required this.senderLabel,
    required this.senderColor,
    required this.avatarSeed,
    this.isSimulation = true,
    this.interesse,
    this.reaction,
    this.replyText,
    this.replyLabel,
    this.onLongPress,
    this.photoBase64,
    this.audioBase64,
    this.readStatus = 'sent',
    this.onPhotoTap,
    required this.timestamp,
    this.showAvatar = true,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  bool _audioLoading = false;

  static String _avatarUrl(String seed) =>
      'https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(seed)}&backgroundColor=1C1C2E';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    if (widget.audioBase64 != null) {
      _initAudioPlayer();
    }
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _playerStateSub = _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _positionSub = _audioPlayer!.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _durationSub = _audioPlayer!.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
  }

  Future<void> _playAudio() async {
    if (_audioPlayer == null) return;
    if (_isPlaying) {
      await _audioPlayer!.pause();
      return;
    }
    if (_position > Duration.zero && _position < _duration) {
      await _audioPlayer!.resume();
      return;
    }
    setState(() => _audioLoading = true);
    try {
      final bytes = base64Decode(widget.audioBase64!);
      await _audioPlayer!.setSourceBytes(bytes, mimeType: 'audio/wav');
      await _audioPlayer!.resume();
    } catch (_) {}
    setState(() => _audioLoading = false);
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _audioPlayer?.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Color _interestBorder(int? interesse) {
    if (interesse == null) return TwColors.border;
    if (interesse >= 7) return TwColors.primary;
    if (interesse >= 4) return TwColors.onSurface;
    return TwColors.muted;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onLongPress: widget.onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
            child: Row(
              mainAxisAlignment: widget.isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isMe && widget.showAvatar) ...[
                  _avatar(),
                  const SizedBox(width: 8),
                ] else if (!widget.isMe && !widget.showAvatar) ...[
                  const SizedBox(width: 36),
                ],
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    child: Column(
                      crossAxisAlignment: widget.isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        _label(),
                        if (widget.replyText != null) _replyPreview(),
                        _bubble(),
                        if (widget.reaction != null) _reactionChip(),
                      ],
                    ),
                  ),
                ),
                if (widget.isMe && widget.showAvatar) ...[
                  const SizedBox(width: 8),
                  _avatar(),
                ] else if (widget.isMe && !widget.showAvatar) ...[
                  const SizedBox(width: 36),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar() => ClipOval(
        child: SvgPicture.network(
          _avatarUrl(widget.avatarSeed),
          width: 28,
          height: 28,
          placeholderBuilder: (_) => Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: TwColors.card,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 14, color: TwColors.muted),
          ),
        ),
      );

  Widget _label() => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(
          widget.senderLabel,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: widget.senderColor.withValues(alpha: 0.7),
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _replyPreview() => Container(
        margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: TwColors.surface,
          borderRadius: BorderRadius.circular(TwRadius.md),
          border: Border(
            left: BorderSide(
              color: widget.isMe ? TwColors.primary : TwColors.secondary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.replyLabel ?? '',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: widget.isMe ? TwColors.primary : TwColors.secondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.replyText!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: TwColors.onSurface,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildAudioPlayer() {
    final progress = _duration > Duration.zero ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          GestureDetector(
            onTap: _audioLoading ? null : _playAudio,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : TwColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: _audioLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 20,
                      color: widget.isMe ? Colors.white : TwColors.primary,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: widget.isMe
                        ? Colors.white.withValues(alpha: 0.2)
                        : TwColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isMe ? Colors.white : TwColors.primary,
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDuration(_duration > Duration.zero ? _position : Duration.zero),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    color: widget.isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : TwColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble() {
    final borderColor = widget.isMe ? null : _interestBorder(widget.interesse);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: widget.isMe ? TwGradients.primary : null,
        color: widget.isMe ? null : TwColors.card,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
          bottomRight: Radius.circular(widget.isMe ? 4 : 16),
        ),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.photoBase64 != null && widget.photoBase64!.isNotEmpty)
            GestureDetector(
              onTap: widget.onPhotoTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(widget.photoBase64!),
                  fit: BoxFit.cover,
                  width: 220,
                  errorBuilder: (_, __, ___) => Container(
                    width: 220,
                    height: 160,
                    color: TwColors.surface,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: TwColors.muted),
                    ),
                  ),
                ),
              ),
            ),
          if (widget.audioBase64 != null && widget.audioBase64!.isNotEmpty)
            _buildAudioPlayer(),
          if (widget.text.isNotEmpty) ...[
            if (widget.photoBase64 != null || widget.audioBase64 != null) const SizedBox(height: 8),
            Text(
              widget.text,
              style: GoogleFonts.spaceGrotesk(
                color: widget.isMe ? Colors.white : TwColors.onBg,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(widget.timestamp),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    color: widget.isMe
                        ? Colors.white.withValues(alpha: 0.6)
                        : TwColors.muted,
                  ),
                ),
                if (widget.isMe && !widget.isSimulation) ...[
                  const SizedBox(width: 4),
                  _readStatusIcon(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  Widget _readStatusIcon() {
    if (widget.readStatus == 'read') {
      return const Icon(Icons.done_all, size: 14, color: TwColors.primary);
    }
    if (widget.readStatus == 'delivered') {
      return Icon(Icons.done_all, size: 14, color: TwColors.muted.withValues(alpha: 0.6));
    }
    return Icon(Icons.check, size: 14, color: TwColors.muted.withValues(alpha: 0.6));
  }

  Widget _reactionChip() => Padding(
        padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: TwColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: TwColors.border),
          ),
          child: Text(widget.reaction!, style: const TextStyle(fontSize: 14)),
        ),
      );
}

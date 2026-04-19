import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/api/sse_client.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';
import 'package:tinyworld_app/features/chats/widgets/humanize_button.dart';
import 'package:tinyworld_app/features/chats/widgets/typing_indicator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum _ViewMode { loading, replaying, replayDone, liveStreaming, humanized }

class _ChatMsg {
  final String agentId;
  final String text;
  final bool isMe;
  final String senderLabel;
  final Color senderColor;
  final int? interesse;
  final int? engajamento;
  final bool? continua;
  String? reaction;

  _ChatMsg({
    required this.agentId,
    required this.text,
    required this.isMe,
    required this.senderLabel,
    this.senderColor = TwColors.primary,
    this.interesse,
    this.engajamento,
    this.continua,
  });
}

const _reactionEmojis = ['❤️', '😄', '😮', '🔥', '😂', '👏'];

const _compatPhrases = [
  (0, 30, 'Conexão fraca — mas toda amizade começa em algum lugar.'),
  (30, 60, 'Boa energia! Vocês têm bastante em comum.'),
  (60, 80, 'Ótima química! Essa poderia ser uma amizade incrível.'),
  (80, 101, 'Conexão rara! Vocês foram feitos um para o outro.'),
];

class ConversationScreen extends ConsumerStatefulWidget {
  final String simId;
  final bool isLive;

  const ConversationScreen(
      {super.key, required this.simId, this.isLive = false});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen>
    with TickerProviderStateMixin {
  _ViewMode _mode = _ViewMode.loading;
  final List<_ChatMsg> _messages = [];
  bool _showTyping = false;
  late Alignment _typingSide;
  String _typingLabel = '';
  Color _typingColor = TwColors.primary;

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _inputCtrl = TextEditingController();
  WebSocketChannel? _wsChannel;
  Stream? _sseStream;

  String? _userId;
  String? _token;
  String? _userAId;
  String? _userBId;
  String _labelMe = 'Você';
  String _labelOther = 'Amigo';
  static const _colorMe = TwColors.primary;
  static const _colorOther = TwColors.secondary;

  // streaming token state
  String _streamingAgentId = '';
  String _streamingText = '';

  double? _compatibility;
  double? _scoreA;
  double? _scoreB;
  int? _completedTurns;
  bool? _earlyStopped;
  int _totalTurns = 0;

  List<Map<String, dynamic>> _pendingTurns = [];
  bool _disposed = false;
  bool _skipping = false;

  // Speed: 1.0, 1.5, 2.0
  double _speed = 1.0;

  String _labelFor(String agentId) =>
      agentId == _userId ? _labelMe : _labelOther;

  Color _colorFor(String agentId) =>
      agentId == _userId ? _colorMe : _colorOther;

  @override
  void initState() {
    super.initState();
    _typingSide = Alignment.centerLeft;
    if (widget.isLive) {
      _startLiveStream();
    } else {
      _loadAndReplay();
    }
  }

  Future<void> _loadAndReplay() async {
    _userId = await localStorage.getUserId();
    _token = await localStorage.getIdToken();
    try {
      final resp = await apiClient.get(
        '/chats/${widget.simId}',
        queryParams: {'user_id': _userId},
      );
      final data = resp.data as Map<String, dynamic>;
      final simData = data['state'] as Map<String, dynamic>? ?? data;
      _userAId = simData['user_a_id'] as String?;
      _userBId = simData['user_b_id'] as String?;
      _compatibility = (simData['compatibility'] as num?)?.toDouble();
      _scoreA = (simData['score_a'] as num?)?.toDouble();
      _scoreB = (simData['score_b'] as num?)?.toDouble();

      final nameA = data['name_a'] as String?;
      final nameB = data['name_b'] as String?;
      if (_userAId == _userId) {
        _labelMe = nameA ?? _userAId?.substring(0, 6) ?? 'Você';
        _labelOther = nameB ?? _userBId?.substring(0, 6) ?? 'Amigo';
      } else {
        _labelMe = nameB ?? _userBId?.substring(0, 6) ?? 'Você';
        _labelOther = nameA ?? _userAId?.substring(0, 6) ?? 'Amigo';
      }

      final turns = (data['turns'] as List?) ?? [];
      if (turns.isEmpty && _userAId != null && _userBId != null) {
        _loadFullSimulation();
        return;
      }

      _pendingTurns = turns.cast<Map<String, dynamic>>();
      _totalTurns = _pendingTurns.length;
      _connectWebSocket();
      _startReplay();
      _checkHumanizedAndLoadHistory();
    } catch (e) {
      if (mounted) {
        setState(() => _mode = _ViewMode.replayDone);
      }
    }
  }

  Future<void> _checkHumanizedAndLoadHistory() async {
    try {
      final chatListResp = await apiClient.get('/chats');
      final chatList = chatListResp.data as List;
      final chat =
          chatList.where((c) => c['sim_id'] == widget.simId).firstOrNull;
      if (chat != null && chat['humanize_state'] == 'humanized') {
        _loadHumanMessages();
      }
    } catch (_) {}
  }

  Future<void> _loadHumanMessages() async {
    try {
      final resp = await apiClient.get('/chats/${widget.simId}/messages');
      final messages = resp.data as List;
      if (messages.isEmpty || !mounted) return;
      final humanMsgs =
          messages.where((m) => m['event'] == 'chat.message').toList();
      setState(() {
        for (final m in humanMsgs) {
          final isMe = m['user_id'] == _userId;
          _messages.add(_ChatMsg(
            agentId: m['user_id'] as String? ?? '',
            text: m['text'] as String? ?? '',
            isMe: isMe,
            senderLabel: isMe ? _labelMe : _labelOther,
            senderColor: isMe ? _colorMe : _colorOther,
          ));
        }
        _mode = _ViewMode.humanized;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      if (humanMsgs.isEmpty) _showIcebreakers();
    } catch (_) {}
  }

  Future<void> _loadFullSimulation() async {
    if (_userAId == null || _userBId == null) return;
    _connectWebSocket();
    _startReplay();
  }

  Future<void> _startReplay() async {
    if (_pendingTurns.isEmpty) {
      setState(() => _mode = _ViewMode.replayDone);
      return;
    }
    setState(() => _mode = _ViewMode.replaying);
    _replayNextTurn(0);
  }

  Future<void> _replayNextTurn(int index) async {
    if (_disposed || index >= _pendingTurns.length) {
      if (!_disposed && mounted) {
        setState(() {
          _showTyping = false;
          _mode = _ViewMode.replayDone;
        });
      }
      return;
    }

    if (_skipping) {
      // Add remaining turns instantly
      for (int i = index; i < _pendingTurns.length; i++) {
        final t = _pendingTurns[i];
        final agentId = t['agent_id'] as String? ?? '';
        _messages.add(_ChatMsg(
          agentId: agentId,
          text: t['resposta'] as String? ?? '',
          isMe: agentId == _userId,
          senderLabel: _labelFor(agentId),
          senderColor: _colorFor(agentId),
          interesse: t['interesse'] as int?,
          engajamento: t['engajamento'] as int?,
          continua: t['continua'] as bool?,
        ));
      }
      if (!_disposed && mounted) {
        setState(() {
          _showTyping = false;
          _skipping = false;
          _mode = _ViewMode.replayDone;
        });
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
      return;
    }

    final turn = _pendingTurns[index];
    final agentId = turn['agent_id'] as String? ?? '';
    final isMe = agentId == _userId;

    setState(() {
      _showTyping = true;
      _typingSide = isMe ? Alignment.centerRight : Alignment.centerLeft;
      _typingLabel = _labelFor(agentId);
      _typingColor = _colorFor(agentId);
    });
    _scrollToBottom();

    final rawDelay = turn['typing_indicator_ms'] as int? ??
        turn['delay_ms'] as int? ??
        800;
    final delayMs = (rawDelay / _speed).round().clamp(250, 3000);
    await Future.delayed(Duration(milliseconds: delayMs));

    if (_disposed || !mounted) return;

    setState(() {
      _showTyping = false;
      _messages.add(_ChatMsg(
        agentId: agentId,
        text: turn['resposta'] as String? ?? '',
        isMe: isMe,
        senderLabel: _labelFor(agentId),
        senderColor: _colorFor(agentId),
        interesse: turn['interesse'] as int?,
        engajamento: turn['engajamento'] as int?,
        continua: turn['continua'] as bool?,
      ));
    });
    _scrollToBottom();

    final pauseMs = (500 / _speed).round().clamp(150, 800);
    await Future.delayed(Duration(milliseconds: pauseMs));
    _replayNextTurn(index + 1);
  }

  void _startLiveStream() async {
    _userId = await localStorage.getUserId();
    _token = await localStorage.getIdToken();
    setState(() => _mode = _ViewMode.liveStreaming);
    _sseStream = sseClient.post('/debug/simulate', data: {
      'user_a_id': _userId,
      'user_b_id': widget.simId,
    }).asBroadcastStream();

    _sseStream!.listen((event) {
      final data = event.data;
      if (data == null) return;
      final type = data['type'] as String;

      switch (type) {
        case 'sim.start':
          _userAId = data['user_a_id'] as String?;
          _userBId = data['user_b_id'] as String?;
          break;

        case 'turn.start':
          final agentId = data['agent_id'] as String? ?? '';
          setState(() {
            _streamingAgentId = agentId;
            _streamingText = '';
            _showTyping = false;
          });
          _scrollToBottom();
          break;

        case 'token':
          final token = data['token'] as String? ?? '';
          setState(() => _streamingText += token);
          _scrollToBottom();
          break;

        case 'turn.complete':
          final turn = data['turn'] as Map<String, dynamic>;
          final agentId = turn['agent_id'] as String? ?? '';
          final isMe = agentId == _userId;
          setState(() {
            _streamingAgentId = '';
            _streamingText = '';
            _totalTurns++;
            _messages.add(_ChatMsg(
              agentId: agentId,
              text: turn['resposta'] as String? ?? '',
              isMe: isMe,
              senderLabel: _labelFor(agentId),
              senderColor: _colorFor(agentId),
              interesse: turn['interesse'] as int?,
              engajamento: turn['engajamento'] as int?,
              continua: turn['continua'] as bool?,
            ));
          });
          _scrollToBottom();
          break;

        case 'sim.complete':
          _compatibility = (data['compatibility'] as num).toDouble();
          _scoreA = (data['score_a'] as num).toDouble();
          _scoreB = (data['score_b'] as num).toDouble();
          _completedTurns = data['completed_turns'] as int;
          _earlyStopped = data['early_stopped'] as bool;
          setState(() => _mode = _ViewMode.replayDone);
          break;
      }
    });
  }

  Future<void> _showIcebreakers() async {
    if (!mounted) return;
    final icebreakers = await ref
        .read(chatsControllerProvider.notifier)
        .getIcebreakers(widget.simId);
    if (!mounted || icebreakers.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: TwColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TwRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: TwColors.border,
                  borderRadius: BorderRadius.circular(TwRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Sugestões para começar',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Toque para usar como mensagem',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ...icebreakers.map((msg) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  _inputCtrl.text = msg;
                  _inputCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: msg.length),
                  );
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: TwColors.card,
                    borderRadius: BorderRadius.circular(TwRadius.md),
                    border: Border.all(color: TwColors.border),
                  ),
                  child: Text(msg,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TwColors.onBg,
                      )),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _connectWebSocket() {
    final wsBase = apiClient.baseUrl.replaceFirst('http', 'ws');
    final token = _token ?? '';
    _wsChannel = WebSocketChannel.connect(
      Uri.parse(
          '$wsBase/ws/chat/${widget.simId}?token=${Uri.encodeComponent(token)}'),
    );
    _wsChannel!.stream.cast<String>().listen((raw) {
      final event = jsonDecode(raw) as Map<String, dynamic>;
      if (event['event'] == 'humanize.activated') {
        setState(() => _mode = _ViewMode.humanized);
        _showIcebreakers();
      } else if (event['event'] == 'chat.message') {
        if (event['user_id'] != _userId) {
          setState(() => _messages.add(_ChatMsg(
                agentId: event['user_id'],
                text: event['text'] as String,
                isMe: false,
                senderLabel: _labelOther,
                senderColor: _colorOther,
              )));
          _scrollToBottom();
        }
      }
    });
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _mode != _ViewMode.humanized) return;
    _wsChannel?.sink.add(jsonEncode({'text': text}));
    setState(() => _messages.add(_ChatMsg(
          agentId: _userId ?? '',
          text: text,
          isMe: true,
          senderLabel: _labelMe,
          senderColor: _colorMe,
        )));
    _inputCtrl.clear();
    _scrollToBottom();
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

  void _skipReplay() {
    setState(() => _skipping = true);
  }

  void _cycleSpeed() {
    setState(() {
      if (_speed == 1.0) {
        _speed = 1.5;
      } else if (_speed == 1.5) {
        _speed = 2.0;
      } else {
        _speed = 1.0;
      }
    });
  }

  Future<void> _showReactionPicker(int msgIndex) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: TwColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TwRadius.xl)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reação',
              style: GoogleFonts.spaceGrotesk(
                color: TwColors.onBg,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _reactionEmojis.map((e) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context, e),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: TwColors.surface,
                      borderRadius: BorderRadius.circular(TwRadius.md),
                    ),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _messages[msgIndex].reaction = selected);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    _wsChannel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsState = ref.watch(chatsControllerProvider);
    final chat =
        chatsState.chats.where((c) => c.simId == widget.simId).firstOrNull;
    final humanizeState = chat?.humanizeState ?? 'simulated';

    return Scaffold(
      backgroundColor: TwColors.bg,
      appBar: _buildAppBar(humanizeState),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length +
                  (_showTyping ? 1 : 0) +
                  (_streamingText.isNotEmpty ? 1 : 0) +
                  1,
              itemBuilder: (_, i) {
                final extras = (_showTyping ? 1 : 0) +
                    (_streamingText.isNotEmpty ? 1 : 0);
                if (i == _messages.length + extras) {
                  if (_mode == _ViewMode.replayDone ||
                      _mode == _ViewMode.humanized) {
                    return _buildResultCard(context);
                  }
                  return const SizedBox.shrink();
                }
                if (_showTyping && i == _messages.length) {
                  return _buildTypingRow();
                }
                if (_streamingText.isNotEmpty &&
                    i == _messages.length + (_showTyping ? 1 : 0)) {
                  return _buildStreamingBubble();
                }
                return _buildMessage(_messages[i], i);
              },
            ),
          ),
          if (_mode == _ViewMode.humanized) _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar(String humanizeState) {
    return AppBar(
      backgroundColor: TwColors.bg,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _mode == _ViewMode.humanized ? _labelOther : 'Conversa simulada',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TwColors.onBg,
            ),
          ),
          Text(
            _mode == _ViewMode.replaying
                ? '${_messages.length} / $_totalTurns turnos'
                : _mode == _ViewMode.liveStreaming
                    ? 'Ao vivo'
                    : _mode == _ViewMode.humanized
                        ? 'Conexão humana'
                        : '',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: TwColors.muted,
            ),
          ),
        ],
      ),
      actions: [
        if (_mode == _ViewMode.replaying || _mode == _ViewMode.liveStreaming)
          _SpeedButton(speed: _speed, onTap: _cycleSpeed),
        if (_mode == _ViewMode.replaying)
          TextButton(
            onPressed: _skipReplay,
            child: Text(
              'Pular',
              style: GoogleFonts.spaceGrotesk(
                color: TwColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        if (_mode == _ViewMode.replayDone)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: HumanizeButton(
                simId: widget.simId, currentState: humanizeState),
          ),
      ],
    );
  }

  Widget _buildStreamingBubble() {
    final isMe = _streamingAgentId == _userId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildSenderLabel(_labelFor(_streamingAgentId),
                _colorFor(_streamingAgentId)),
            _buildBubble(
              text: _streamingText,
              isMe: isMe,
              isStreaming: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingRow() {
    return Align(
      alignment: _typingSide,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: TwColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                Radius.circular(_typingSide == Alignment.centerRight ? 16 : 4),
            bottomRight:
                Radius.circular(_typingSide == Alignment.centerRight ? 4 : 16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_typingLabel,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _typingColor,
                )),
            const SizedBox(width: 8),
            const TypingIndicator(dotColor: TwColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(_ChatMsg msg, int index) {
    final isMe = msg.isMe;

    return GestureDetector(
      onLongPress: () => _showReactionPicker(index),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              _buildSenderLabel(msg.senderLabel, msg.senderColor),
              _buildBubble(text: msg.text, isMe: isMe),
              if (msg.reaction != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: TwColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: TwColors.border),
                    ),
                    child: Text(msg.reaction!,
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSenderLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: TwColors.muted,
              )),
        ],
      ),
    );
  }

  Widget _buildBubble(
      {required String text, required bool isMe, bool isStreaming = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isMe ? TwGradients.primary : null,
        color: isMe ? null : TwColors.card,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: isMe
            ? null
            : Border.all(color: TwColors.border, width: 0.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          color: isMe ? Colors.white : TwColors.onBg,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    if (_compatibility == null) return const SizedBox.shrink();
    final pct = (_compatibility! * 100).toInt();

    final phrase = _compatPhrases
        .where((p) => pct >= p.$1 && pct < p.$2)
        .map((p) => p.$3)
        .firstOrNull;

    final ringColor = pct > 70
        ? TwColors.success
        : pct > 40
            ? TwColors.warning
            : TwColors.error;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TwColors.card, TwColors.cardAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TwRadius.xl),
        border: Border.all(color: TwColors.border),
        boxShadow: [
          BoxShadow(
            color: TwColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient header band
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: TwGradients.accent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(TwRadius.xl)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              children: [
                // Compatibility ring
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: _compatibility,
                          strokeWidth: 6,
                          backgroundColor: TwColors.border,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(ringColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$pct%',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: ringColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Compatibilidade',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: TwColors.muted,
                    letterSpacing: 0.5,
                  ),
                ),
                if (phrase != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    phrase,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: TwColors.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Score bars
                Row(
                  children: [
                    _buildScoreBar('Você', _scoreA, _colorMe),
                    const SizedBox(width: 12),
                    _buildScoreBar(_labelOther, _scoreB, _colorOther),
                  ],
                ),
                if (_completedTurns != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: TwColors.surface,
                      borderRadius:
                          BorderRadius.circular(TwRadius.pill),
                    ),
                    child: Text(
                      '$_completedTurns turnos${_earlyStopped == true ? ' · encerrado cedo' : ''}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: TwColors.muted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, double? score, Color color) {
    final v = score ?? 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: TwColors.muted,
                  )),
              Text(
                '${(v * 100).toInt()}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: TwColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: const BoxDecoration(
        color: TwColors.surface,
        border: Border(top: BorderSide(color: TwColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: TwColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: TwColors.border),
              ),
              child: TextField(
                controller: _inputCtrl,
                style: GoogleFonts.spaceGrotesk(
                    color: TwColors.onBg, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Escreva uma mensagem...',
                  hintStyle:
                      GoogleFonts.spaceGrotesk(color: TwColors.muted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
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

class _SpeedButton extends StatelessWidget {
  final double speed;
  final VoidCallback onTap;

  const _SpeedButton({required this.speed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: TwColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(TwRadius.pill),
          border: Border.all(
            color: TwColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '${speed == speed.toInt() ? speed.toInt() : speed}×',
          style: GoogleFonts.spaceGrotesk(
            color: TwColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/api/sse_client.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
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

  const _ChatMsg({
    required this.agentId,
    required this.text,
    required this.isMe,
    required this.senderLabel,
    this.senderColor = Colors.blue,
    this.interesse,
    this.engajamento,
    this.continua,
  });
}

class ConversationScreen extends ConsumerStatefulWidget {
  final String simId;
  final bool isLive;

  const ConversationScreen({super.key, required this.simId, this.isLive = false});

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
  Color _typingColor = Colors.blue;

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _inputCtrl = TextEditingController();
  WebSocketChannel? _wsChannel;
  Stream? _sseStream;

  String? _userId;
  String? _userAId;
  String? _userBId;
  String _labelA = 'Agente A';
  String _labelB = 'Agente B';
  Color _colorA = const Color(0xFF6C63FF);
  Color _colorB = const Color(0xFFFF6B6B);

  double? _compatibility;
  double? _scoreA;
  double? _scoreB;
  int? _completedTurns;
  bool? _earlyStopped;

  List<Map<String, dynamic>> _pendingTurns = [];
  bool _disposed = false;

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
      _labelA = data['name_a'] as String? ?? _userAId?.substring(0, 6) ?? 'A';
      _labelB = data['name_b'] as String? ?? _userBId?.substring(0, 6) ?? 'B';

      final turns = (data['turns'] as List?) ?? [];
      if (turns.isEmpty && _userAId != null && _userBId != null) {
        _loadFullSimulation();
        return;
      }

      _pendingTurns = turns.cast<Map<String, dynamic>>();
      _connectWebSocket();
      _startReplay();
    } catch (e) {
      if (mounted) {
        setState(() => _mode = _ViewMode.replayDone);
      }
    }
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
        setState(() => _mode = _ViewMode.replayDone);
      }
      return;
    }

    final turn = _pendingTurns[index];
    final agentId = turn['agent_id'] as String? ?? '';
    final isMe = agentId == _userId;

    setState(() {
      _showTyping = true;
      _typingSide = isMe ? Alignment.centerRight : Alignment.centerLeft;
      _typingLabel = isMe ? _labelA : _labelB;
      _typingColor = isMe ? _colorA : _colorB;
    });
    _scrollToBottom();

    final delayMs = turn['typing_indicator_ms'] as int? ??
        turn['delay_ms'] as int? ?? 800;
    await Future.delayed(Duration(milliseconds: delayMs.clamp(200, 3000)));

    if (_disposed || !mounted) return;

    setState(() {
      _showTyping = false;
      _messages.add(_ChatMsg(
        agentId: agentId,
        text: turn['resposta'] as String? ?? '',
        isMe: isMe,
        senderLabel: isMe ? _labelA : _labelB,
        senderColor: isMe ? _colorA : _colorB,
        interesse: turn['interesse'] as int?,
        engajamento: turn['engajamento'] as int?,
        continua: turn['continua'] as bool?,
      ));
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 250));
    _replayNextTurn(index + 1);
  }

  void _startLiveStream() async {
    _userId = await localStorage.getUserId();
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
        case 'turn.start':
          final side = data['side'] as String;
          final isMe = side == 'a';
          setState(() {
            _showTyping = true;
            _typingSide = isMe ? Alignment.centerRight : Alignment.centerLeft;
            _typingLabel = isMe ? _labelA : _labelB;
            _typingColor = isMe ? _colorA : _colorB;
          });
          _scrollToBottom();
          break;

        case 'token':
          // Tokens are raw JSON fragments — ignore for display, typing indicator is already shown
          break;

        case 'turn.complete':
          final turn = data['turn'] as Map<String, dynamic>;
          final agentId = turn['agent_id'] as String? ?? '';
          final isMe = agentId == _userId;
          setState(() {
            _showTyping = false;
            _messages.add(_ChatMsg(
              agentId: agentId,
              text: turn['resposta'] as String? ?? '',
              isMe: isMe,
              senderLabel: isMe ? _labelA : _labelB,
              senderColor: isMe ? _colorA : _colorB,
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

  void _connectWebSocket() {
    final wsBase = apiClient.baseUrl.replaceFirst('http', 'ws');
    _wsChannel = WebSocketChannel.connect(
      Uri.parse('$wsBase/ws/chat/${widget.simId}?user_id=$_userId'),
    );
    _wsChannel!.stream.cast<String>().listen((raw) {
      final event = jsonDecode(raw) as Map<String, dynamic>;
      if (event['event'] == 'humanize.activated') {
        setState(() => _mode = _ViewMode.humanized);
      } else if (event['event'] == 'chat.message') {
        if (event['user_id'] != _userId) {
          setState(() => _messages.add(_ChatMsg(
                agentId: event['user_id'],
                text: event['text'] as String,
                isMe: false,
                senderLabel: _labelB,
                senderColor: _colorB,
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
          senderLabel: _labelA,
          senderColor: _colorA,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Conversa simulada', style: TextStyle(fontSize: 16)),
            Text(
              _mode == _ViewMode.replaying
                  ? 'Reproduzindo...'
                  : _mode == _ViewMode.liveStreaming
                      ? 'Ao vivo'
                      : _mode == _ViewMode.humanized
                          ? 'Conexão humana'
                          : '',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          if (_mode == _ViewMode.replayDone)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: HumanizeButton(
                  simId: widget.simId, currentState: humanizeState),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length + (_showTyping ? 1 : 0) + 1,
              itemBuilder: (_, i) {
                if (i == _messages.length + (_showTyping ? 1 : 0)) {
                  if (_mode == _ViewMode.replayDone ||
                      _mode == _ViewMode.humanized) {
                    return _buildResultCard(context);
                  }
                  return const SizedBox.shrink();
                }
                if (_showTyping && i == _messages.length) {
                  return _buildTypingRow();
                }
                final msg = _messages[i];
                return _buildMessage(msg, i);
              },
            ),
          ),
          if (_mode == _ViewMode.humanized) _buildInputBar(colorScheme),
        ],
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(_typingSide == Alignment.centerRight ? 16 : 4),
            bottomRight: Radius.circular(_typingSide == Alignment.centerRight ? 4 : 16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_typingLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _typingColor,
                )),
            const SizedBox(width: 8),
            const TypingIndicator(dotColor: Color(0xFF888888)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(_ChatMsg msg, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMe = msg.isMe;

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
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: msg.senderColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(msg.senderLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    if (_compatibility == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final pct = (_compatibility! * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: pct > 60
                  ? const Color(0xFF4CAF50)
                  : pct > 30
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Compatibilidade',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreChip('Você', _scoreA, colorScheme),
              _buildScoreChip('Outro', _scoreB, colorScheme),
            ],
          ),
          if (_completedTurns != null) ...[
            const SizedBox(height: 12),
            Text(
              '$_completedTurns turnos${_earlyStopped == true ? ' · encerrado cedo' : ''}',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreChip(String label, double? score, ColorScheme cs) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          score != null ? '${(score * 100).toInt()}' : '--',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _inputCtrl,
                decoration: const InputDecoration(
                  hintText: 'Escreva uma mensagem...',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            child: IconButton(
              onPressed: _sendMessage,
              icon: Icon(Icons.send, size: 18, color: colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

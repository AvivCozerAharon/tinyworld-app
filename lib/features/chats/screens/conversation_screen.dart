import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/api/sse_client.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';
import 'package:tinyworld_app/features/chats/widgets/humanize_button.dart';
import 'package:tinyworld_app/features/chats/widgets/typing_indicator.dart';
import 'package:tinyworld_app/features/chats/widgets/compatibility_result_card.dart';
import 'package:tinyworld_app/features/chats/widgets/chat_input_bar.dart';
import 'package:tinyworld_app/features/chats/widgets/speed_button.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum _ViewMode { loading, replaying, replayDone, liveStreaming, humanized, error }

class _ChatMsg {
  final String agentId;
  final String text;
  final bool isMe;
  final String senderLabel;
  final Color senderColor;
  final int? interesse;
  final int? engajamento;
  final bool? continua;
  final bool isHuman;
  String? reaction;
  String? replyText;
  String? replyLabel;

  _ChatMsg({
    required this.agentId,
    required this.text,
    required this.isMe,
    required this.senderLabel,
    this.senderColor = TwColors.primary,
    this.interesse,
    this.engajamento,
    this.continua,
    this.isHuman = false,
    this.reaction,
    this.replyText,
    this.replyLabel,
  });

  _ChatMsg withReply({String? text, String? label}) {
    return _ChatMsg(
      agentId: agentId,
      text: text ?? this.text,
      isMe: isMe,
      senderLabel: senderLabel,
      senderColor: senderColor,
      interesse: interesse,
      engajamento: engajamento,
      continua: continua,
      isHuman: isHuman,
      reaction: reaction,
      replyText: text != null ? this.text : replyText,
      replyLabel: text != null ? label : replyLabel,
    );
  }
}

const _reactionEmojis = ['❤️', '😄', '😮', '🔥', '😂', '👏'];

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
  String? _errorMsg;
  final List<_ChatMsg> _messages = [];
  bool _showTyping = false;
  late Alignment _typingSide;
  String _typingLabel = '';
  Color _typingColor = TwColors.primary;

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _inputCtrl = TextEditingController();
  WebSocketChannel? _wsChannel;
  StreamSubscription? _sseSub;

  String? _userId;
  String? _token;
  String? _userAId;
  String? _userBId;
  String _labelMe = 'Você';
  String _labelOther = 'Amigo';
  String? _otherAvatarUrl;
  static const _colorMe = TwColors.primary;
  static const _colorOther = TwColors.secondary;

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
  double _speed = 1.0;
  int _replyingToIndex = -1;
  late AnimationController _cursorCtrl;

  static String _avatarUrl(String seed) =>
      'https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(seed)}&backgroundColor=1C1C2E';

  Widget _buildAvatarWidget(String seed) {
    return ClipOval(
      child: SvgPicture.network(
        _avatarUrl(seed),
        width: 24,
        height: 24,
        placeholderBuilder: (_) => Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: TwColors.card,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 14, color: TwColors.muted),
        ),
      ),
    );
  }

  String _labelFor(String agentId) =>
      agentId == _userId ? _labelMe : _labelOther;

  Color _colorFor(String agentId) =>
      agentId == _userId ? _colorMe : _colorOther;

  Color _interestBorder(int? interesse) {
    if (interesse == null) return TwColors.border;
    if (interesse >= 7) return const Color(0xFF7B4FFF);
    if (interesse >= 4) return TwColors.onSurface;
    return TwColors.muted;
  }

  @override
  void initState() {
    super.initState();
    _typingSide = Alignment.centerLeft;
    _cursorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
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

      final otherId = _userAId == _userId ? _userBId : _userAId;
      if (otherId != null) {
        try {
          final otherResp = await apiClient.get('/profile/$otherId');
          final found = otherResp.data as Map<String, dynamic>;
          _otherAvatarUrl = found['avatar_url'] as String? ?? '';
          final name = found['name'] as String?;
          if (name != null && name.isNotEmpty) _labelOther = name;
        } catch (_) {}
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
        setState(() {
          _mode = _ViewMode.error;
          _errorMsg = e.toString();
        });
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
            isHuman: true,
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
        _loadReactions();
      }
      return;
    }

    if (_skipping) {
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
        _loadReactions();
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

    if (_userId == null) {
      if (mounted) setState(() { _mode = _ViewMode.error; _errorMsg = 'Usuário não identificado.'; });
      return;
    }

    try {
      final otherResp = await apiClient.get('/profile/${widget.simId}');
      final found = otherResp.data as Map<String, dynamic>;
      _labelOther = (found['name'] as String?)?.isNotEmpty == true
          ? found['name'] as String
          : _labelOther;
      _otherAvatarUrl = found['avatar_url'] as String? ?? '';
    } catch (_) {}

    if (mounted) setState(() => _mode = _ViewMode.liveStreaming);

    _sseSub = sseClient.post('/debug/simulate', data: {
      'user_a_id': _userId,
      'user_b_id': widget.simId,
    }).listen(
      (event) {
        if (_disposed) return;
        final data = event.data;
        if (data == null) return;
        final type = data['type'] as String? ?? '';

        switch (type) {
          case 'sim.start':
            _userAId = data['user_a_id'] as String?;
            _userBId = data['user_b_id'] as String?;
            break;
          case 'turn.start':
            final agentId = data['agent_id'] as String? ?? '';
            if (mounted) {
              setState(() {
                _streamingAgentId = agentId;
                _streamingText = '';
                _showTyping = false;
              });
              _scrollToBottom();
            }
            break;
          case 'token':
            final token = data['token'] as String? ?? '';
            if (mounted) {
              setState(() => _streamingText += token);
              _scrollToBottom();
            }
            break;
          case 'turn.complete':
            final turn = data['turn'] as Map<String, dynamic>? ?? {};
            final agentId = turn['agent_id'] as String? ?? '';
            final isMe = agentId == _userId;
            if (mounted) {
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
            }
            break;
          case 'sim.complete':
            if (mounted) {
              setState(() {
                _compatibility = (data['compatibility'] as num?)?.toDouble();
                _scoreA = (data['score_a'] as num?)?.toDouble();
                _scoreB = (data['score_b'] as num?)?.toDouble();
                _completedTurns = data['completed_turns'] as int?;
                _earlyStopped = data['early_stopped'] as bool?;
                _streamingAgentId = '';
                _streamingText = '';
                _mode = _ViewMode.replayDone;
              });
            }
            break;
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _mode = _ViewMode.error;
            _errorMsg = 'Erro na simulação ao vivo. Tente novamente.';
          });
        }
      },
      onDone: () {
        if (mounted && _mode == _ViewMode.liveStreaming) {
          setState(() => _mode = _ViewMode.replayDone);
        }
      },
    );
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
                isHuman: true,
              )));
          _scrollToBottom();
        }
      }
    });
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _mode != _ViewMode.humanized) return;
    if (_replyingToIndex >= 0 && _replyingToIndex < _messages.length) {
      final orig = _messages[_replyingToIndex];
      _messages[_replyingToIndex] = orig.withReply(
        text: text,
        label: orig.isMe ? _labelMe : _labelOther,
      );
      setState(() => _replyingToIndex = -1);
    }
    _wsChannel?.sink.add(jsonEncode({'text': text}));
    setState(() => _messages.add(_ChatMsg(
          agentId: _userId ?? '',
          text: text,
          isMe: true,
          senderLabel: _labelMe,
          senderColor: _colorMe,
          isHuman: true,
        )));
    _inputCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 50,
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

  void _setReply(int index) {
    setState(() {
      _replyingToIndex = _replyingToIndex == index ? -1 : index;
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
      try {
        await apiClient.post(
          '/chats/${widget.simId}/reactions/$msgIndex',
          data: {'emoji': selected},
        );
      } catch (_) {}
    }
  }

  Future<void> _loadReactions() async {
    try {
      final resp = await apiClient.get('/chats/${widget.simId}/reactions');
      final data = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        for (final entry in data.entries) {
          final idx = int.tryParse(entry.key);
          if (idx == null || idx >= _messages.length) continue;
          final reaction = entry.value as Map<String, dynamic>;
          _messages[idx].reaction = reaction['emoji'] as String? ?? '';
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _sseSub?.cancel();
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    _wsChannel?.sink.close();
    _cursorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsState = ref.watch(chatsControllerProvider);
    final chat =
        chatsState.chats.where((c) => c.simId == widget.simId).firstOrNull;
    final humanizeState = chat?.humanizeState ?? 'simulated';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TwColors.bg, TwColors.surface],
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(context, humanizeState),
            Expanded(
              child: _mode == _ViewMode.error
                  ? _buildErrorState()
                  : (_mode == _ViewMode.liveStreaming &&
                          _messages.isEmpty &&
                          _streamingText.isEmpty &&
                          _streamingAgentId.isEmpty)
                      ? _buildLiveLoadingState()
                  : ListView.builder(
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
                            return CompatibilityResultCard(
                              compatibility: _compatibility,
                              scoreA: _scoreA,
                              scoreB: _scoreB,
                              labelMe: _labelMe,
                              labelOther: _labelOther,
                              colorMe: _colorMe,
                              colorOther: _colorOther,
                              completedTurns: _completedTurns,
                              earlyStopped: _earlyStopped,
                            );
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
            if (_mode == _ViewMode.humanized)
              ChatInputBar(
                controller: _inputCtrl,
                onSend: _sendMessage,
                replyingToIndex: _replyingToIndex,
                onCancelReply: () => setState(() => _replyingToIndex = -1),
                onReply: _setReply,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String humanizeState) {
    final compatColor = _compatibility != null
        ? (_compatibility! > 0.7
            ? TwColors.success
            : _compatibility! > 0.4
                ? TwColors.warning
                : TwColors.error)
        : TwColors.muted;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: TwColors.onBg),
          ),
          Expanded(
            child: Row(
              children: [
                if (_otherAvatarUrl != null && _otherAvatarUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: compatColor, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          _otherAvatarUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: TwColors.card,
                            child: const Icon(Icons.person, size: 18, color: TwColors.muted),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mode == _ViewMode.humanized ? _labelOther : 'Conversa simulada',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: TwColors.onBg,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _mode == _ViewMode.replaying
                            ? '${_messages.length} / $_totalTurns turnos'
                            : _mode == _ViewMode.liveStreaming
                                ? 'Ao vivo'
                                : _mode == _ViewMode.humanized
                                    ? 'Conexão humana'
                                    : _mode == _ViewMode.replayDone
                                        ? (_compatibility != null ? '${(_compatibility! * 100).toInt()}% compatível' : '')
                                        : '',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: TwColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_mode == _ViewMode.replaying || _mode == _ViewMode.liveStreaming)
            SpeedButton(speed: _speed, onTap: _cycleSpeed),
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
            HumanizeButton(
                simId: widget.simId, currentState: humanizeState),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: TwColors.error),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar conversa',
              style: GoogleFonts.spaceGrotesk(
                color: TwColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMsg ?? 'Tente novamente mais tarde.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: TwColors.muted, fontSize: 13, height: 1.4),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _mode = _ViewMode.loading;
                  _errorMsg = null;
                });
                _loadAndReplay();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                TwColors.primary.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Preparando simulação...',
            style: GoogleFonts.spaceGrotesk(
              color: TwColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Os agentes estão se conhecendo',
            style: GoogleFonts.spaceGrotesk(
              color: TwColors.muted.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingBubble() {
    final isMe = _streamingAgentId == _userId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatarWidget(_streamingAgentId),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _buildInlineSenderLabel(
                      _labelFor(_streamingAgentId),
                      _colorFor(_streamingAgentId)),
                  AnimatedBuilder(
                    animation: _cursorCtrl,
                    builder: (_, __) => _buildBubble(
                      text: _streamingText,
                      isMe: isMe,
                      isStreaming: true,
                      cursorOpacity: _cursorCtrl.value,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatarWidget(_streamingAgentId),
          ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              _buildAvatarWidget(msg.agentId),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    _buildInlineSenderLabel(msg.senderLabel, msg.senderColor),
                    if (msg.replyText != null)
                      Container(
                        margin: const EdgeInsets.only(
                            left: 8, right: 8, bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: TwColors.surface,
                          borderRadius: BorderRadius.circular(TwRadius.md),
                          border: Border(
                            left: BorderSide(
                              color: isMe
                                  ? TwColors.primary
                                  : TwColors.secondary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.replyLabel ?? '',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isMe
                                    ? TwColors.primary
                                    : TwColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              msg.replyText!,
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
                      ),
                    TweenAnimationBuilder(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      builder: (ctx, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 12),
                            child: _buildBubble(
                              text: msg.text,
                              isMe: isMe,
                              interesse: msg.interesse,
                            ),
                          ),
                        );
                      },
                    ),
                    if (msg.reaction != null)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 2, left: 4, right: 4),
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
                    if (msg.isHuman && isMe)
                      const Padding(
                        padding: EdgeInsets.only(top: 2, left: 4, right: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.done_all,
                                size: 12, color: TwColors.muted),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              _buildAvatarWidget(msg.agentId),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInlineSenderLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildBubble({
    required String text,
    required bool isMe,
    bool isStreaming = false,
    int? interesse,
    double? cursorOpacity,
  }) {
    final borderColor = isMe ? null : _interestBorder(interesse);

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
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
      ),
      child: Text.rich(
        TextSpan(
          text: text,
          children: cursorOpacity != null
              ? [
                  TextSpan(
                    text: '|',
                    style: TextStyle(
                      color: (isMe ? Colors.white : TwColors.onBg)
                          .withValues(alpha: cursorOpacity),
                    ),
                  ),
                ]
              : null,
        ),
        style: GoogleFonts.spaceGrotesk(
          color: isMe ? Colors.white : TwColors.onBg,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}

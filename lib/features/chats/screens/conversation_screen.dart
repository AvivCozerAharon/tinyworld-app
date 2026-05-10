import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/api/sse_client.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';
import 'package:tinyworld_app/features/chats/widgets/chat_input_bar.dart';
import 'package:tinyworld_app/features/chats/widgets/humanization_divider.dart';
import 'package:tinyworld_app/features/chats/widgets/humanize_button.dart';
import 'package:tinyworld_app/features/chats/widgets/humanized_profile_sheet.dart';
import 'package:tinyworld_app/features/chats/widgets/message_bubble.dart';
import 'package:tinyworld_app/shared/widgets/media_gallery.dart';
import 'package:tinyworld_app/shared/widgets/photo_viewer.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _ChatMsg {
  final String agentId;
  final String text;
  final bool isMe;
  final String senderLabel;
  final Color senderColor;
  final int? interesse;
  final bool isHuman;
  final String? photoBase64;
  final String? audioBase64;
  int humanIndex;
  String status;
  String? reaction;
  String? replyText;
  String? replyLabel;
  final DateTime timestamp;

  _ChatMsg({
    required this.agentId,
    required this.text,
    required this.isMe,
    required this.senderLabel,
    this.senderColor = TwColors.primary,
    this.interesse,
    this.isHuman = false,
    this.photoBase64,
    this.audioBase64,
    this.humanIndex = -1,
    this.status = 'sent',
    this.reaction,
    this.replyText,
    this.replyLabel,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

const _reactionEmojis = ['❤️', '😄', '😮', '🔥', '😂', '👏'];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

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
  // ── state ────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMsg;

  final List<_ChatMsg> _messages = [];

  // ── scroll ───────────────────────────────────────────────────────────────
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _inputCtrl = TextEditingController();

  // ── WebSocket / SSE ──────────────────────────────────────────────────────
  WebSocketChannel? _wsChannel;
  StreamSubscription? _sseSub;

  // ── user / participants ──────────────────────────────────────────────────
  String? _userId;
  String? _token;
  String? _userAId;
  String? _userBId;
  String _labelMe = 'Você';
  String _labelOther = 'Agente';
  String _genderMe = 'Eu';
  String _genderOther = 'Ele';
  String _avatarMe = '';
  String _avatarOther = '';
  static const _colorMe = TwColors.primary;
  static const _colorOther = TwColors.secondary;

  // ── live streaming state (live/debug mode only) ──────────────────────────
  String _streamingAgentId = '';
  String _streamingText = '';
  late AnimationController _cursorCtrl;

  // ── misc ─────────────────────────────────────────────────────────────────
  bool _disposed = false;

  // ── reply ────────────────────────────────────────────────────────────────
  int _replyingToIndex = -1;

  // ── humanized ────────────────────────────────────────────────────────────
  bool _isHumanized = false;
  int _humanizationMessageCount = -1;
  bool _isOtherOnline = false;
  int _otherReadUpTo = -1;
  int _nextHumanIndex = 0;

  // ── audio recording ──────────────────────────────────────────────────────
  bool _isRecording = false;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _recordSub;
  final List<Uint8List> _recordChunks = [];
  Timer? _recordingTimer;
  int _recordingElapsed = 0;

  // ── photo reveal ──────────────────────────────────────────────────────────
  List<String> _otherPhotos = [];
  List<String> _myPhotos = [];
  String? _otherRealName;
  int? _otherAge;
  List<String> _otherHobbies = [];
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _showRevealBanner = false;

  // ── helpers ──────────────────────────────────────────────────────────────

  static String _dicebearUrl(String seed) =>
      'https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(seed)}&backgroundColor=1C1C2E';

  String _avatarFor(String agentId) =>
      agentId == _userId ? _avatarMe : _avatarOther;

  String _labelFor(String agentId) =>
      agentId == _userId ? _labelMe : _labelOther;

  Color _colorFor(String agentId) =>
      agentId == _userId ? _colorMe : _colorOther;

  // ── lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cursorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatsControllerProvider.notifier).clearUnread(widget.simId);
    });
    if (widget.isLive) {
      _startLiveStream();
    } else {
      _loadAndReplay();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sseSub?.cancel();
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    _wsChannel?.sink.close();
    _cursorCtrl.dispose();
    _flipCtrl.dispose();
    _recordingTimer?.cancel();
    _recorder?.dispose();
    super.dispose();
  }

  // ── data loading ─────────────────────────────────────────────────────────

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

      final nameA = data['name_a'] as String?;
      final nameB = data['name_b'] as String?;
      final genderA = data['gender_a'] as String?;
      final genderB = data['gender_b'] as String?;

      if (_userAId == _userId) {
        _labelMe = nameA ?? _userAId?.substring(0, 6) ?? 'Você';
        _labelOther = nameB ?? _userBId?.substring(0, 6) ?? 'Agente';
        _genderMe = _genderLabel(genderA);
        _genderOther = _genderLabel(genderB);
      } else {
        _labelMe = nameB ?? _userBId?.substring(0, 6) ?? 'Você';
        _labelOther = nameA ?? _userAId?.substring(0, 6) ?? 'Agente';
        _genderMe = _genderLabel(genderB);
        _genderOther = _genderLabel(genderA);
      }

      _avatarMe = _dicebearUrl(_userId ?? 'me');

      final otherId = _userAId == _userId ? _userBId : _userAId;
      if (otherId != null) {
        try {
          final otherResp = await apiClient.get('/profile/$otherId');
          final found = otherResp.data as Map<String, dynamic>;
          _avatarOther =
              found['avatar_url'] as String? ?? _dicebearUrl(otherId);
          final name = found['name'] as String?;
          if (name != null && name.isNotEmpty) _labelOther = name;
          final gender = found['gender'] as String?;
          _genderOther = _genderLabel(gender);
        } catch (_) {
          _avatarOther = _dicebearUrl(otherId);
        }
      }

      final existingChat = ref
          .read(chatsControllerProvider)
          .chats
          .where((c) => c.simId == widget.simId)
          .firstOrNull;
      if (existingChat?.humanizeState == 'humanized') {
        _isHumanized = true;
      }

      // Load all agent turns immediately — no animation
      final turns = (data['turns'] as List?) ?? [];
      final agentMsgs = turns.cast<Map<String, dynamic>>().map((t) {
        final agentId = t['agent_id'] as String? ?? '';
        return _ChatMsg(
          agentId: agentId,
          text: t['resposta'] as String? ?? '',
          isMe: agentId == _userId,
          senderLabel: _labelFor(agentId),
          senderColor: _colorFor(agentId),
          interesse: t['interesse'] as int?,
          isHuman: false,
        );
      }).toList();

      setState(() {
        _messages.addAll(agentMsgs);
        _isLoading = false;
      });

      _connectWebSocket();
      _loadReactions();

      if (_isHumanized) {
        _loadHumanMessages();
      }

      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom(animated: false));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMsg = e.toString();
        });
      }
    }
  }

  String _genderLabel(String? gender) {
    if (gender == null) return 'Ele';
    final g = gender.toLowerCase();
    if (g == 'female' || g == 'feminino' || g == 'f') return 'Ela';
    return 'Ele';
  }

  Future<void> _loadHumanMessages() async {
    try {
      final resp = await apiClient.get('/chats/${widget.simId}/messages');
      final data = resp.data as Map<String, dynamic>;
      final messages = (data['messages'] as List?) ?? [];
      final otherReadUpTo = data['other_read_up_to'] as int? ?? -1;
      final otherOnline = data['other_online'] as bool? ?? false;
      if (messages.isEmpty && otherReadUpTo < 0 && !mounted) return;
      final humanMsgs =
          messages.where((m) => m['event'] == 'chat.message' || m['event'] == 'chat.photo' || m['event'] == 'chat.audio').toList();
      setState(() {
        _humanizationMessageCount = _messages.length;
        _isOtherOnline = otherOnline;
        _otherReadUpTo = otherReadUpTo;
        for (int mi = 0; mi < humanMsgs.length; mi++) {
          final m = humanMsgs[mi];
          final isMe = m['user_id'] == _userId;
          final idx = _nextHumanIndex++;
          String status = 'sent';
          if (isMe && idx <= otherReadUpTo) {
            status = 'read';
          } else if (isMe) {
            status = otherOnline ? 'delivered' : 'sent';
          }
          _messages.add(_ChatMsg(
            agentId: m['user_id'] as String? ?? '',
            text: m['text'] as String? ?? '',
            isMe: isMe,
            senderLabel: isMe ? _labelMe : _labelOther,
            senderColor: isMe ? _colorMe : _colorOther,
            isHuman: true,
            photoBase64: (m['photo'] as String?)?.isNotEmpty == true ? m['photo'] as String? : null,
            audioBase64: (m['audio'] as String?)?.isNotEmpty == true ? m['audio'] as String? : null,
            humanIndex: idx,
            status: status,
          ));
        }
      });
      if (humanMsgs.isNotEmpty) {
        _sendReadReceipt(humanMsgs.length - 1);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: false));
      if (humanMsgs.isEmpty) _showIcebreakers();
    } catch (_) {}
  }

  Future<void> _fetchAndRevealPhotos() async {
    try {
      final resp = await apiClient.get('/humanize/${widget.simId}/photos');
      final data = resp.data as Map<String, dynamic>;
      final myId = _userId ?? '';
      final aId = data['user_a_id'] as String? ?? '';
      final iAmA = aId == myId;

      final aPhotos = (data['user_a_photos'] as List? ?? []).cast<String>();
      final bPhotos = (data['user_b_photos'] as List? ?? []).cast<String>();
      final aName = data['user_a_name'] as String?;
      final bName = data['user_b_name'] as String?;
      final aAge = data['user_a_age'] as int?;
      final bAge = data['user_b_age'] as int?;
      final aHobbies = (data['user_a_hobbies'] as List? ?? []).cast<String>();
      final bHobbies = (data['user_b_hobbies'] as List? ?? []).cast<String>();

      if (!mounted) return;
      setState(() {
        _myPhotos = iAmA ? aPhotos : bPhotos;
        _otherPhotos = iAmA ? bPhotos : aPhotos;
        _otherRealName = iAmA ? bName : aName;
        _otherAge = iAmA ? bAge : aAge;
        _otherHobbies = iAmA ? bHobbies : aHobbies;
        _showRevealBanner = true;
      });
      _flipCtrl.forward();
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) setState(() => _showRevealBanner = false);
    } catch (_) {}
  }

  // ── live stream ──────────────────────────────────────────────────────────

  void _startLiveStream() async {
    _userId = await localStorage.getUserId();
    _token = await localStorage.getIdToken();

    if (_userId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMsg = 'Usuário não identificado.';
        });
      }
      return;
    }

    try {
      final otherResp = await apiClient.get('/profile/${widget.simId}');
      final found = otherResp.data as Map<String, dynamic>;
      _labelOther = (found['name'] as String?)?.isNotEmpty == true
          ? found['name'] as String
          : _labelOther;
      _avatarOther =
          found['avatar_url'] as String? ?? _dicebearUrl(widget.simId);
      _genderOther = _genderLabel(found['gender'] as String?);
    } catch (_) {
      _avatarOther = _dicebearUrl(widget.simId);
    }

    _avatarMe = _dicebearUrl(_userId ?? 'me');
    if (mounted) setState(() => _isLoading = false);

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
              });
              _cursorCtrl.repeat(reverse: true);
            }
            break;
          case 'token':
            final token = data['token'] as String? ?? '';
            if (mounted) {
              setState(() => _streamingText += token);
              _scrollToBottomInstant();
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
                _messages.add(_ChatMsg(
                  agentId: agentId,
                  text: turn['resposta'] as String? ?? '',
                  isMe: isMe,
                  senderLabel: _labelFor(agentId),
                  senderColor: _colorFor(agentId),
                  interesse: turn['interesse'] as int?,
                ));
              });
              _cursorCtrl.stop();
              _scrollToBottomInstant();
            }
            break;
          case 'sim.complete':
            if (mounted) {
              setState(() {
                _streamingAgentId = '';
                _streamingText = '';
              });
              _cursorCtrl.stop();
              _scrollToBottom(animated: false);
            }
            break;
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _isError = true;
            _errorMsg = 'Erro na simulação ao vivo. Tente novamente.';
          });
        }
      },
      onDone: () {
        if (mounted) _scrollToBottom(animated: false);
      },
    );
  }

  // ── WebSocket ────────────────────────────────────────────────────────────

  void _connectWebSocket() {
    final wsBase = apiClient.baseUrl.replaceFirst('http', 'ws');
    final token = _token ?? '';
    _wsChannel = WebSocketChannel.connect(
      Uri.parse(
          '$wsBase/ws/chat/${widget.simId}?token=${Uri.encodeComponent(token)}'),
    );
    _wsChannel!.stream.cast<String>().listen((raw) {
      if (_disposed || !mounted) return;
      final event = jsonDecode(raw) as Map<String, dynamic>;
      if (event['event'] == 'humanize.activated') {
        setState(() {
          _isHumanized = true;
          _humanizationMessageCount = _messages.length;
        });
        _fetchAndRevealPhotos();
        _showIcebreakers();
      } else if (event['event'] == 'chat.message') {
        if (event['user_id'] != _userId) {
          final idx = _nextHumanIndex++;
          setState(() => _messages.add(_ChatMsg(
                agentId: event['user_id'],
                text: event['text'] as String,
                isMe: false,
                senderLabel: _labelOther,
                senderColor: _colorOther,
                isHuman: true,
                humanIndex: idx,
              )));
          _scrollToBottom();
          _sendReadReceipt(idx);
        }
      } else if (event['event'] == 'chat.photo') {
        if (event['user_id'] != _userId) {
          final idx = _nextHumanIndex++;
          setState(() => _messages.add(_ChatMsg(
                agentId: event['user_id'],
                text: event['text'] as String,
                isMe: false,
                senderLabel: _labelOther,
                senderColor: _colorOther,
                isHuman: true,
                photoBase64: event['photo'] as String?,
                humanIndex: idx,
              )));
          _scrollToBottom();
          _sendReadReceipt(idx);
        }
      } else if (event['event'] == 'chat.audio') {
        if (event['user_id'] != _userId) {
          final idx = _nextHumanIndex++;
          setState(() => _messages.add(_ChatMsg(
                agentId: event['user_id'],
                text: event['text'] as String,
                isMe: false,
                senderLabel: _labelOther,
                senderColor: _colorOther,
                isHuman: true,
                audioBase64: event['audio'] as String?,
                humanIndex: idx,
              )));
          _scrollToBottom();
          _sendReadReceipt(idx);
        }
      } else if (event['event'] == 'chat.read') {
        if (event['user_id'] != _userId) {
          final lastIdx = event['last_index'] as int? ?? -1;
          setState(() {
            _otherReadUpTo = lastIdx;
            for (final m in _messages) {
              if (m.isMe && m.isHuman && m.humanIndex >= 0 && m.humanIndex <= lastIdx) {
                m.status = 'read';
              }
            }
          });
        }
      } else if (event['event'] == 'presence.online') {
        if (event['user_id'] != _userId) {
          setState(() => _isOtherOnline = true);
        }
      } else if (event['event'] == 'presence.offline') {
        if (event['user_id'] != _userId) {
          setState(() => _isOtherOnline = false);
        }
      }
    });
  }

  // ── send message ─────────────────────────────────────────────────────────

  void _sendReadReceipt(int lastIndex) {
    _wsChannel?.sink.add(jsonEncode({'type': 'read', 'last_index': lastIndex}));
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || !_isHumanized) return;
    if (_replyingToIndex >= 0 && _replyingToIndex < _messages.length) {
      final orig = _messages[_replyingToIndex];
      orig.replyText = text;
      orig.replyLabel = orig.isMe ? _labelMe : _labelOther;
      setState(() => _replyingToIndex = -1);
    }
    final idx = _nextHumanIndex++;
    _wsChannel?.sink.add(jsonEncode({'text': text}));
    setState(() => _messages.add(_ChatMsg(
          agentId: _userId ?? '',
          text: text,
          isMe: true,
          senderLabel: _labelMe,
          senderColor: _colorMe,
          isHuman: true,
          humanIndex: idx,
          status: _isOtherOnline ? 'delivered' : 'sent',
        )));
    _inputCtrl.clear();
    _scrollToBottom();
  }

  void _sendPhoto(String b64, {String text = ''}) {
    if (!_isHumanized) return;
    final idx = _nextHumanIndex++;
    _wsChannel?.sink.add(jsonEncode({'photo': b64, 'text': text}));
    setState(() => _messages.add(_ChatMsg(
          agentId: _userId ?? '',
          text: text,
          isMe: true,
          senderLabel: _labelMe,
          senderColor: _colorMe,
          isHuman: true,
          photoBase64: b64,
          humanIndex: idx,
          status: _isOtherOnline ? 'delivered' : 'sent',
        )));
    _inputCtrl.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndSendPhoto() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isEmpty) return;
    try {
      final b64List = <String>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        Uint8List compressed;
        if (kIsWeb) {
          compressed = bytes;
        } else {
          compressed = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 800,
            minHeight: 800,
            quality: 80,
            format: CompressFormat.jpeg,
          );
        }
        b64List.add(base64Encode(compressed));
      }
      if (!mounted || b64List.isEmpty) return;

      final text = await _showPhotoPreview(b64List);
      if (text != null) {
        for (final b64 in b64List) {
          _sendPhoto(b64, text: text);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar foto: $e')),
        );
      }
    }
  }

  Future<String?> _showPhotoPreview(List<String> b64List) {
    final textCtrl = TextEditingController(text: _inputCtrl.text);
    final pageCtrl = PageController();
    int currentPage = 0;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TwColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      controller: pageCtrl,
                      itemCount: b64List.length,
                      onPageChanged: (i) => setSheetState(() => currentPage = i),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(b64List[i]),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: TwColors.card,
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  color: TwColors.muted, size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (b64List.length > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(b64List.length, (i) {
                        return Container(
                          width: currentPage == i ? 8 : 6,
                          height: currentPage == i ? 8 : 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentPage == i
                                ? TwColors.primary
                                : TwColors.muted.withValues(alpha: 0.4),
                          ),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: textCtrl,
                    autofocus: true,
                    style: GoogleFonts.spaceGrotesk(
                        color: TwColors.onBg, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: b64List.length > 1
                          ? 'Adicionar legenda para todas...'
                          : 'Adicionar legenda...',
                      hintStyle: GoogleFonts.spaceGrotesk(
                          color: TwColors.muted, fontSize: 14),
                      filled: true,
                      fillColor: TwColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.spaceGrotesk(color: TwColors.muted),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: TwGradients.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () =>
                              Navigator.pop(ctx, textCtrl.text),
                          icon: const Icon(Icons.send,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    ).then((result) {
      textCtrl.dispose();
      pageCtrl.dispose();
      return result;
    });
  }

  Uint8List _buildWavHeader(int dataLength, {int sampleRate = 44100, int numChannels = 1, int bitsPerSample = 16}) {
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = dataLength;
    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, 36 + dataSize, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    // fmt chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // chunk size
    header.setUint16(20, 1, Endian.little); // PCM format
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);
    return header.buffer.asUint8List();
  }

  void _sendAudio(String b64) {
    if (!_isHumanized) return;
    final idx = _nextHumanIndex++;
    _wsChannel?.sink.add(jsonEncode({'audio': b64}));
    setState(() => _messages.add(_ChatMsg(
          agentId: _userId ?? '',
          text: '',
          isMe: true,
          senderLabel: _labelMe,
          senderColor: _colorMe,
          isHuman: true,
          audioBase64: b64,
          humanIndex: idx,
          status: _isOtherOnline ? 'delivered' : 'sent',
        )));
    _scrollToBottom();
  }

  Future<void> _startRecording() async {
    final recorder = AudioRecorder();
    final hasPerm = await recorder.hasPermission();
    if (!hasPerm) return;
    try {
      final stream = await recorder.startStream(
        const RecordConfig(encoder: AudioEncoder.pcm16bits),
      );
      _recordChunks.clear();
      _recordSub = stream.listen((chunk) => _recordChunks.add(chunk));
    } catch (_) {
      recorder.dispose();
      return;
    }
    setState(() {
      _isRecording = true;
      _recorder = recorder;
      _recordingElapsed = 0;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingElapsed++);
    });
  }

  Future<void> _stopRecording() async {
    final recorder = _recorder;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    await _recordSub?.cancel();
    _recordSub = null;
    setState(() => _isRecording = false);
    _recorder = null;
    if (recorder == null) return;
    try {
      await recorder.stop();
      final totalLen = _recordChunks.fold<int>(0, (s, c) => s + c.length);
      if (totalLen == 0) return;
      final pcm = Uint8List(totalLen);
      int offset = 0;
      for (final chunk in _recordChunks) {
        pcm.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      _recordChunks.clear();
      final wavHeader = _buildWavHeader(totalLen);
      final wav = Uint8List(wavHeader.length + totalLen);
      wav.setRange(0, wavHeader.length, wavHeader);
      wav.setRange(wavHeader.length, wav.length, pcm);
      _sendAudio(base64Encode(wav));
    } catch (_) {}
    _recordChunks.clear();
    recorder.dispose();
  }

  void _cancelRecording() async {
    final recorder = _recorder;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    await _recordSub?.cancel();
    _recordSub = null;
    setState(() => _isRecording = false);
    _recorder = null;
    _recordChunks.clear();
    if (recorder == null) return;
    try {
      await recorder.cancel();
    } catch (_) {}
    recorder.dispose();
  }

  bool _showScrollFab = false;

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final show = _scrollCtrl.position.maxScrollExtent - _scrollCtrl.offset > 600;
    if (show != _showScrollFab) {
      setState(() => _showScrollFab = show);
    }
  }

  // ── scroll helpers ───────────────────────────────────────────────────────

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      if (animated && (max - _scrollCtrl.offset) > 200) {
        _scrollCtrl.animateTo(
          max + 50,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(max + 50);
      }
    });
  }

  void _scrollToBottomInstant() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent + 50);
      }
    });
  }

  // ── reactions ────────────────────────────────────────────────────────────

  Future<void> _showReactionPicker(int msgIndex) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: TwColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(TwRadius.xl)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reação',
                style: GoogleFonts.spaceGrotesk(
                    color: TwColors.onBg,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
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
                        child:
                            Text(e, style: const TextStyle(fontSize: 24))),
                  ),
                );
              }).toList(),
            ),
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

  // ── icebreakers ──────────────────────────────────────────────────────────

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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(TwRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
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
                          TextPosition(offset: msg.length));
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: TwColors.card,
                        borderRadius: BorderRadius.circular(TwRadius.md),
                        border: Border.all(color: TwColors.border),
                      ),
                      child: Text(msg,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: TwColors.onBg)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final humanizeState = ref.watch(
      chatsControllerProvider.select((s) =>
          s.chats.where((c) => c.simId == widget.simId).firstOrNull?.humanizeState ??
          'simulated'),
    );

    if (_isLoading) {
      return Scaffold(
        backgroundColor: TwColors.bg,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(TwColors.primary),
          ),
        ),
      );
    }

    if (_isError) return _buildErrorScaffold();

    return Scaffold(
      backgroundColor: TwColors.bg,
      body: _buildTranscriptPage(humanizeState),
    );
  }

  Widget _buildTranscriptPage(String humanizeState) {
    final column = Column(
      children: [
        _buildTranscriptHeader(humanizeState),
        Expanded(child: _buildMessageList()),
        if (_isHumanized && _isRecording)
          _buildRecordingBar()
        else if (_isHumanized)
          ChatInputBar(
            controller: _inputCtrl,
            onSend: _sendMessage,
            replyingToIndex: _replyingToIndex,
            onCancelReply: () => setState(() => _replyingToIndex = -1),
            onReply: (i) => setState(
                () => _replyingToIndex = _replyingToIndex == i ? -1 : i),
            onPhoto: _isHumanized ? _pickAndSendPhoto : null,
            onAudio: _isHumanized ? _startRecording : null,
          ),
      ],
    );

    return Stack(
      children: [
        column,
        if (_showScrollFab)
          Positioned(
            right: 16,
            bottom: (_isHumanized && !_isRecording) ? 80 : 16,
            child: GestureDetector(
              onTap: () => _scrollToBottom(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TwColors.card,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_downward,
                    size: 20, color: TwColors.primary),
              ),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          top: _showRevealBanner ? MediaQuery.of(context).padding.top + 80 : -120,
          left: 24,
          right: 24,
          child: _buildRevealBanner(),
        ),
      ],
    );
  }

  Widget _buildRecordingBar() {
    final minutes = (_recordingElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingElapsed % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      decoration: const BoxDecoration(
        color: TwColors.surface,
        border: Border(top: BorderSide(color: TwColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: TwColors.card,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, size: 18, color: Color(0xFFEF4444)),
          ),
          const SizedBox(width: 12),
          Text(
            '$minutes:$seconds',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: TwColors.onBg,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: TwColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: TwColors.border),
              ),
              child: const Icon(Icons.close, size: 18, color: TwColors.muted),
            ),
          ),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: TwGradients.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stop, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealBanner() {
    if (_otherPhotos.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => HumanizedProfileSheet.show(
        context,
        photos: _otherPhotos,
        name: _otherRealName ?? _labelOther,
        age: _otherAge,
        hobbies: _otherHobbies,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: TwGradients.primary,
          borderRadius: BorderRadius.circular(TwRadius.xl),
          boxShadow: [
            BoxShadow(
              color: TwColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_otherRealName ?? _labelOther} revelou as fotos! Toque para ver',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFlipAvatar(String svgOrUrlFront, List<String> photosBack) {
    return AnimatedBuilder(
      animation: _flipAnim,
      builder: (_, __) {
        final angle = _flipAnim.value * math.pi;
        final showFront = angle < math.pi / 2;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: showFront || photosBack.isEmpty
              ? _smallAvatar(svgOrUrlFront)
              : Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _smallPhotoAvatar(photosBack.first),
                ),
        );
      },
    );
  }

  Widget _smallPhotoAvatar(String base64) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: TwColors.primary, width: 2),
      ),
      child: ClipOval(
        child: Image.memory(
          base64Decode(base64),
          width: 32,
          height: 32,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTranscriptHeader(String humanizeState) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding:
          EdgeInsets.only(top: top + 8, left: 12, right: 12, bottom: 8),
      decoration: const BoxDecoration(
        color: TwColors.surface,
        border:
            Border(bottom: BorderSide(color: TwColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: TwColors.muted),
            tooltip: 'Voltar',
          ),
          GestureDetector(
            onTap: _otherPhotos.isNotEmpty
                ? () => HumanizedProfileSheet.show(
                      context,
                      photos: _otherPhotos,
                      name: _otherRealName ?? _labelOther,
                      age: _otherAge,
                      hobbies: _otherHobbies,
                    )
                : null,
            child: SizedBox(
              width: 52,
              height: 36,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: _buildFlipAvatar(_avatarOther, _otherPhotos),
                  ),
                  Positioned(
                    left: 20,
                    child: _buildFlipAvatar(_avatarMe, _myPhotos),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversa dos agentes',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TwColors.onBg,
                  ),
                ),
                if (_isHumanized && _isOtherOnline)
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: TwColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Online',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: TwColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '${_messages.length} mensagens',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: TwColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          if (_isHumanized)
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MediaGallery(simId: widget.simId),
                ),
              ),
              icon: const Icon(Icons.photo_library_outlined,
                  color: TwColors.muted, size: 22),
              tooltip: 'Mídia',
            ),
          if (!_isHumanized)
            HumanizeButton(simId: widget.simId, currentState: humanizeState),
        ],
      ),
    );
  }

  Widget _smallAvatar(String url) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: TwColors.surface, width: 2),
      ),
      child: ClipOval(
        child: url.contains('dicebear') || url.endsWith('.svg')
            ? SvgPicture.network(url, width: 32, height: 32)
            : Image.network(url, width: 32, height: 32, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: TwColors.card,
                  child: const Icon(Icons.person,
                      size: 16, color: TwColors.muted),
                )),
      ),
    );
  }

  Widget _buildMessageList() {
    final items = <_ListItem>[];
    String? lastDateKey;

    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final dateKey = '${msg.timestamp.year}-${msg.timestamp.month}-${msg.timestamp.day}';
      if (dateKey != lastDateKey) {
        items.add(_DateSeparatorItem(date: msg.timestamp));
        lastDateKey = dateKey;
      }
      if (_isHumanized &&
          _humanizationMessageCount >= 0 &&
          i == _humanizationMessageCount) {
        items.add(const _DividerItem());
      }
      final showAvatar = i == 0 ||
          _messages[i - 1].agentId != msg.agentId ||
          _messages[i - 1].isHuman != msg.isHuman;
      items.add(_MsgItem(index: i, msg: msg, showAvatar: showAvatar));
    }

    if (_streamingText.isNotEmpty) {
      items.add(_StreamItem(
          text: _streamingText,
          agentId: _streamingAgentId,
          cursorCtrl: _cursorCtrl,
          userId: _userId));
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i].build(context, this),
    );
  }

  Widget _buildErrorScaffold() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TwColors.bg, TwColors.surface],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: TwColors.error),
                const SizedBox(height: 16),
                Text('Erro ao carregar conversa',
                    style: GoogleFonts.spaceGrotesk(
                        color: TwColors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(_errorMsg ?? 'Tente novamente.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                        color: TwColors.muted, fontSize: 13, height: 1.4)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _isError = false;
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
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List item types
// ---------------------------------------------------------------------------

abstract class _ListItem {
  const _ListItem();
  Widget build(BuildContext context, _ConversationScreenState s);
}

class _DateSeparatorItem extends _ListItem {
  final DateTime date;
  const _DateSeparatorItem({required this.date});
  @override
  Widget build(BuildContext context, _ConversationScreenState s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(msgDate).inDays;
    String label;
    if (diff == 0) {
      label = 'Hoje';
    } else if (diff == 1) {
      label = 'Ontem';
    } else {
      label = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: TwColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: TwColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerItem extends _ListItem {
  const _DividerItem();
  @override
  Widget build(BuildContext context, _ConversationScreenState s) =>
      const HumanizationDivider();
}

class _MsgItem extends _ListItem {
  final int index;
  final _ChatMsg msg;
  final bool showAvatar;
  const _MsgItem({required this.index, required this.msg, this.showAvatar = true});

  @override
  Widget build(BuildContext context, _ConversationScreenState s) {
    final isSimMsg = !msg.isHuman;
    final dimmed = isSimMsg && s._isHumanized;

    final label = isSimMsg
        ? '${msg.senderLabel}  ·  ${msg.agentId == s._userId ? s._genderMe : s._genderOther}'
        : msg.senderLabel;

    final bubble = MessageBubble(
      key: ValueKey('msg_$index'),
      text: msg.text,
      isMe: msg.isMe,
      senderLabel: label,
      senderColor: msg.senderColor,
      avatarSeed: msg.agentId,
      isSimulation: isSimMsg,
      interesse: msg.interesse,
      reaction: msg.reaction,
      replyText: msg.replyText,
      replyLabel: msg.replyLabel,
      onLongPress: () => s._showReactionPicker(index),
      photoBase64: msg.photoBase64,
      audioBase64: msg.audioBase64,
      readStatus: msg.status,
      timestamp: msg.timestamp,
      showAvatar: showAvatar,
      onPhotoTap: msg.photoBase64 != null
          ? () {
              final bytes = base64Decode(msg.photoBase64!);
              PhotoViewer.show(s.context, bytes);
            }
          : null,
    );

    return dimmed ? Opacity(opacity: 0.65, child: bubble) : bubble;
  }
}

class _StreamItem extends _ListItem {
  final String text;
  final String agentId;
  final AnimationController cursorCtrl;
  final String? userId;
  const _StreamItem(
      {required this.text,
      required this.agentId,
      required this.cursorCtrl,
      required this.userId});

  @override
  Widget build(BuildContext context, _ConversationScreenState s) {
    final isMe = agentId == userId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe ? TwGradients.primary : null,
                  color: isMe ? null : TwColors.card,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: cursorCtrl,
                  builder: (_, __) => Text.rich(
                    TextSpan(
                      text: text,
                      children: [
                        TextSpan(
                          text: '|',
                          style: TextStyle(
                            color: (isMe ? Colors.white : TwColors.onBg)
                                .withValues(alpha: cursorCtrl.value),
                          ),
                        ),
                      ],
                    ),
                    style: GoogleFonts.spaceGrotesk(
                      color: isMe ? Colors.white : TwColors.onBg,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

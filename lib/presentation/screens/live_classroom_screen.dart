import 'dart:convert';
import 'dart:io' show Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show Helper;
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

// ── Data-channel message type keys ───────────────────────────────────────────
const _kDraw = 'draw';
const _kClear = 'clear';
const _kBoardOpen = 'board_open';
const _kBoardClose = 'board_close';
const _kHand = 'hand';
const _kApplause = 'applause';
const _kSpotlight = 'spotlight';
const _kStateRequest = 'state_req'; // student → instructor: resend full board state

// ── Screen ────────────────────────────────────────────────────────────────────

class LiveClassroomScreen extends StatefulWidget {
  final String roomId;
  final String accessToken;
  final String livekitUrl;
  final String sessionTitle;
  final bool isInstructor;

  const LiveClassroomScreen({
    super.key,
    required this.roomId,
    required this.accessToken,
    required this.livekitUrl,
    required this.sessionTitle,
    this.isInstructor = false,
  });

  @override
  State<LiveClassroomScreen> createState() => _LiveClassroomScreenState();
}

class _LiveClassroomScreenState extends State<LiveClassroomScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _connecting = true;
  String? _error;

  // ── Controls ──
  bool _micOn = true;
  bool _camOn = true;
  bool _screenSharing = false;
  bool _boardOpen = false;
  bool _handRaised = false;
  bool _navigatedAway = false;

  // ── Interactive state ──
  bool _showApplause = false;
  String? _spotlightId;
  final Set<String> _raisedHands = {};
  final List<_DrawingPoint?> _boardPoints = [];

  final _audio = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _connect();
  }

  // ── Connection ───────────────────────────────────────────────────────────────

  Future<void> _connect() async {
    await [Permission.camera, Permission.microphone].request();

    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );
    final listener = room.createListener();

    void rebuild(dynamic _) { if (mounted) setState(() {}); }

    listener
      ..on<RoomConnectedEvent>(rebuild)
      ..on<RoomDisconnectedEvent>((_) => _navigateBack())
      ..on<ParticipantConnectedEvent>(rebuild)
      ..on<ParticipantDisconnectedEvent>((e) {
        if (mounted) {
          setState(() {
          _raisedHands.remove(e.participant.identity);
          if (_spotlightId == e.participant.identity) _spotlightId = null;
        });
        }
      })
      ..on<TrackPublishedEvent>(rebuild)
      ..on<TrackUnpublishedEvent>(rebuild)
      ..on<TrackSubscribedEvent>(rebuild)
      ..on<TrackUnsubscribedEvent>(rebuild)
      ..on<TrackMutedEvent>(rebuild)
      ..on<TrackUnmutedEvent>(rebuild)
      ..on<DataReceivedEvent>(_onData)
      ..on<RoomReconnectedEvent>((_) {
        // Students request a full board resync after reconnecting mid-class
        if (!widget.isInstructor) _send({'type': _kStateRequest});
        if (mounted) setState(() {});
      });

    try {
      await room.connect(widget.livekitUrl, widget.accessToken);
      await room.localParticipant?.setCameraEnabled(true);
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (mounted) setState(() { _room = room; _listener = listener; _connecting = false; });
    } catch (e) {
      await listener.dispose();
      if (mounted) setState(() { _connecting = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  // ── Data channel ─────────────────────────────────────────────────────────────

  void _onData(DataReceivedEvent event) {
    if (!mounted) return;
    try {
      final msg = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      final sender = event.participant?.identity ?? '';
      switch (type) {
        case _kHand:
          final up = msg['up'] as bool? ?? false;
          setState(() { if (up) {
            _raisedHands.add(sender);
          } else {
            _raisedHands.remove(sender);
          } });
        case _kApplause:
          _triggerApplause(fromSelf: false);
        case _kDraw:
          setState(() => _boardPoints.add(_DrawingPoint(
            x: (msg['x'] as num).toDouble(),
            y: (msg['y'] as num).toDouble(),
            color: Color(msg['c'] as int),
            strokeWidth: (msg['w'] as num).toDouble(),
            isStart: msg['s'] as bool? ?? false,
          )));
        case _kClear:
          setState(() => _boardPoints.clear());
        case _kBoardOpen:
          if (!widget.isInstructor) setState(() => _boardOpen = true);
        case _kBoardClose:
          if (!widget.isInstructor) setState(() { _boardOpen = false; _boardPoints.clear(); });
        case _kSpotlight:
          setState(() => _spotlightId = msg['id'] as String?);
        case _kStateRequest:
          if (!widget.isInstructor) break;
          // Clear then replay the full board so the reconnecting student catches up.
          // Broadcasting _kClear first keeps already-connected students in sync too.
          _send({'type': _kClear});
          if (_boardOpen) {
            _send({'type': _kBoardOpen});
            for (final pt in _boardPoints) {
              if (pt == null) continue; // null = stroke separator; isStart handles this
              _send({'type': _kDraw, 'x': pt.x, 'y': pt.y, 'c': pt.color.toARGB32(), 'w': pt.strokeWidth, 's': pt.isStart});
            }
          }
          if (_spotlightId != null) _send({'type': _kSpotlight, 'id': _spotlightId});
      }
    } catch (_) {}
  }

  void _send(Map<String, dynamic> msg) {
    try {
      _room?.localParticipant?.publishData(
        Uint8List.fromList(utf8.encode(jsonEncode(msg))),
      );
    } catch (_) {}
  }

  // ── Controls ─────────────────────────────────────────────────────────────────

  Future<void> _toggleMic() async {
    final next = !_micOn;
    await _room?.localParticipant?.setMicrophoneEnabled(next);
    if (mounted) setState(() => _micOn = next);
  }

  Future<void> _toggleCam() async {
    final next = !_camOn;
    await _room?.localParticipant?.setCameraEnabled(next);
    if (mounted) setState(() => _camOn = next);
  }

  Future<void> _toggleScreenShare() async {
    if (!widget.isInstructor) return;
    final next = !_screenSharing;
    try {
      if (next) {
        if (Platform.isAndroid) {
          // Android: show "Share screen?" system dialog and get MediaProjection token
          final granted = await Helper.requestCapturePermission();
          if (!granted || !mounted) return;
          // Start a foreground service so Android 10+ keeps the MediaProjection alive
          const androidConfig = FlutterBackgroundAndroidConfig(
            notificationTitle: 'Screen Sharing',
            notificationText: 'eduBridge is sharing your screen',
            notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
            enableWifiLock: false,
          );
          await FlutterBackground.initialize(androidConfig: androidConfig);
          await FlutterBackground.enableBackgroundExecution();
        }
        await _room?.localParticipant?.setScreenShareEnabled(true, captureScreenAudio: false);
      } else {
        await _room?.localParticipant?.setScreenShareEnabled(false);
        if (Platform.isAndroid) {
          try { await FlutterBackground.disableBackgroundExecution(); } catch (_) {}
        }
      }
      if (mounted) setState(() => _screenSharing = next);
    } catch (e) {
      // Clean up the foreground service if we failed to start sharing
      if (next && Platform.isAndroid) {
        try { await FlutterBackground.disableBackgroundExecution(); } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _toggleBoard() {
    if (!widget.isInstructor) return;
    final next = !_boardOpen;
    setState(() { _boardOpen = next; if (!next) _boardPoints.clear(); });
    _send({'type': next ? _kBoardOpen : _kBoardClose});
    if (!next) _send({'type': _kClear});
  }

  void _raiseHand() {
    if (widget.isInstructor) return;
    final next = !_handRaised;
    setState(() => _handRaised = next);
    _send({'type': _kHand, 'up': next});
  }

  void _sendApplause() {
    _send({'type': _kApplause});
    _triggerApplause(fromSelf: true);
  }

  void _triggerApplause({required bool fromSelf}) {
    if (!mounted) return;
    setState(() => _showApplause = true);
    try {
      _audio.play(AssetSource('sounds/clap.mp3'));
    } catch (_) {
      HapticFeedback.mediumImpact();
    }
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showApplause = false);
    });
  }

  void _spotlightParticipant(String id) {
    final next = _spotlightId == id ? null : id;
    setState(() => _spotlightId = next);
    _send({'type': _kSpotlight, 'id': next});
  }

  void _navigateBack() {
    if (_navigatedAway || !mounted) return;
    _navigatedAway = true;
    Navigator.of(context).pop();
  }

  Future<void> _leave() async {
    await _room?.disconnect();
    _navigateBack();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _audio.dispose();
    _listener?.dispose();
    _room?.disconnect();
    if (Platform.isAndroid && _screenSharing) {
      FlutterBackground.disableBackgroundExecution().catchError((_) => false);
    }
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  VideoTrack? _cameraTrack(Participant p) {
    for (final pub in p.videoTrackPublications) {
      if (pub.source == TrackSource.camera && pub.track is VideoTrack) return pub.track as VideoTrack;
    }
    return null;
  }

  VideoTrack? _screenTrack(Participant p) {
    for (final pub in p.videoTrackPublications) {
      if (pub.source == TrackSource.screenShareVideo && pub.track is VideoTrack) return pub.track as VideoTrack;
    }
    return null;
  }

  Color _avatarColor(String name) {
    const p = [Color(0xFF37474F), Color(0xFF00695C), Color(0xFF283593), Color(0xFF4A148C), Color(0xFF006064)];
    return name.isEmpty ? p[0] : p[name.codeUnitAt(0) % p.length];
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _connecting ? _buildConnecting() : _error != null ? _buildError() : _buildRoom(),
      ),
    );
  }

  Widget _buildConnecting() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: Colors.white),
      SizedBox(height: 16),
      Text('Joining classroom…', style: TextStyle(color: Colors.white70, fontSize: 15)),
    ]),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 52),
        const SizedBox(height: 16),
        const Text('Could not join classroom',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Go Back'),
        ),
      ]),
    ),
  );

  Widget _buildRoom() {
    final room = _room!;
    final remotes = room.remoteParticipants.values.toList();
    final total = remotes.length + 1;

    // Spotlight first, then raised hands
    remotes.sort((a, b) {
      if (a.identity == _spotlightId) return -1;
      if (b.identity == _spotlightId) return 1;
      final aH = _raisedHands.contains(a.identity) ? 0 : 1;
      final bH = _raisedHands.contains(b.identity) ? 0 : 1;
      return aH - bH;
    });

    // Detect active screen share (remote first, then local)
    VideoTrack? activeScreen;
    String screenOwner = '';
    for (final rp in remotes) {
      final t = _screenTrack(rp);
      if (t != null) { activeScreen = t; screenOwner = rp.identity; break; }
    }
    if (activeScreen == null && _screenSharing) {
      final local = room.localParticipant;
      if (local != null) {
        final t = _screenTrack(local);
        if (t != null) { activeScreen = t; screenOwner = 'You'; }
      }
    }

    return Column(children: [
      _buildTopBar(total),
      Expanded(
        child: Stack(children: [
          // Main content
          if (_boardOpen)
            _WhiteboardOverlay(
              points: List.unmodifiable(_boardPoints),
              canDraw: widget.isInstructor,
              onDraw: (pt) {
                setState(() => _boardPoints.add(pt));
                if (pt != null) _send({'type': _kDraw, 'x': pt.x, 'y': pt.y, 'c': pt.color.toARGB32(), 'w': pt.strokeWidth, 's': pt.isStart});
              },
              onClear: widget.isInstructor ? () { setState(() => _boardPoints.clear()); _send({'type': _kClear}); } : null,
            )
          else if (activeScreen != null)
            _buildScreenView(activeScreen, screenOwner)
          else
            _buildVideoGrid(room, remotes),
          // Local PiP — always visible (even over board, so instructor can see themselves)
          if (!_boardOpen)
            Positioned(right: 12, bottom: 12, child: _buildLocalPip(room)),
          // Applause overlay
          if (_showApplause) _buildApplauseOverlay(),
        ]),
      ),
      _buildControls(),
    ]);
  }

  Widget _buildTopBar(int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: Colors.black,
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.sessionTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis),
          Text('$total participant${total == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ])),
        if (_raisedHands.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('✋', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 3),
              Text('${_raisedHands.length}',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
          ),
        ],
        const _LiveBadge(),
      ]),
    );
  }

  Widget _buildVideoGrid(Room room, List<RemoteParticipant> remotes) {
    if (remotes.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_outline, color: Colors.white24, size: 72),
        SizedBox(height: 16),
        Text('Waiting for others to join…', style: TextStyle(color: Colors.white54, fontSize: 15)),
      ]));
    }

    // Spotlight: one participant full-screen + others in strip
    if (_spotlightId != null) {
      final lit = remotes.where((p) => p.identity == _spotlightId).firstOrNull;
      if (lit != null) {
        final others = remotes.where((p) => p.identity != _spotlightId).toList();
        return Column(children: [
          Expanded(child: _participantTile(lit, spotlit: true)),
          if (others.isNotEmpty)
            SizedBox(
              height: 78,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(3),
                itemCount: others.length,
                itemBuilder: (_, i) => SizedBox(width: 56, child: _participantTile(others[i])),
              ),
            ),
        ]);
      }
    }

    if (remotes.length == 1) return _participantTile(remotes.first);
    final cols = remotes.length <= 2 ? 1 : 2;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: cols == 1 ? 16 / 9 : 3 / 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      padding: EdgeInsets.zero,
      itemCount: remotes.length,
      itemBuilder: (_, i) => _participantTile(remotes[i]),
    );
  }

  Widget _buildScreenView(VideoTrack track, String owner) {
    return Stack(children: [
      VideoTrackRenderer(track),
      Positioned(
        top: 8, left: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.screen_share_rounded, color: Colors.white70, size: 13),
            const SizedBox(width: 4),
            Text('$owner is sharing screen',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
      ),
    ]);
  }

  Widget _participantTile(Participant participant, {bool spotlit = false}) {
    final name = participant.identity;
    final camTrack = _cameraTrack(participant);
    final camOn = camTrack != null;
    final micOn = participant.audioTrackPublications
        .any((pub) => pub.source == TrackSource.microphone && pub.track != null);
    final handUp = _raisedHands.contains(name);
    final vid = camTrack;

    return GestureDetector(
      onTap: (widget.isInstructor && handUp) ? () => _spotlightParticipant(name) : null,
      child: Container(
        color: spotlit ? const Color(0xFF0D1B3E) : const Color(0xFF181828),
        child: Stack(fit: StackFit.expand, children: [
          // ── Video or avatar ──
          if (vid != null)
            VideoTrackRenderer(vid)
          else
            Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(
                radius: spotlit ? 44 : 28,
                backgroundColor: _avatarColor(name),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(color: Colors.white, fontSize: spotlit ? 34 : 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              Text(name, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              if (!camOn) const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.videocam_off, color: Colors.white38, size: 12),
                  SizedBox(width: 3),
                  Text('Camera off', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ]),
              ),
            ])),
          // ── Bottom strip: name + indicators ──
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              color: Colors.black54,
              child: Row(children: [
                Expanded(child: Text(name,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    overflow: TextOverflow.ellipsis)),
                if (!micOn) const _StatusIcon(Icons.mic_off, Colors.redAccent),
                if (!camOn) const _StatusIcon(Icons.videocam_off, Colors.redAccent),
                if (handUp) const Padding(
                  padding: EdgeInsets.only(left: 3),
                  child: Text('✋', style: TextStyle(fontSize: 11)),
                ),
              ]),
            ),
          ),
          // ── Spotlight badge ──
          if (spotlit)
            Positioned(top: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                child: const Text('SPOTLIGHT',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black)),
              )),
          // ── Tap-to-call-on hint (instructor only) ──
          if (widget.isInstructor && handUp && !spotlit)
            Positioned(top: 6, left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
                child: const Text('Tap to call on',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
              )),
        ]),
      ),
    );
  }

  Widget _buildLocalPip(Room room) {
    final local = room.localParticipant;
    final vid = (_camOn && local != null) ? _cameraTrack(local) : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 96, height: 136,
        color: const Color(0xFF222244),
        child: Stack(children: [
          vid != null
              ? VideoTrackRenderer(vid)
              : Center(child: Icon(
                  _camOn ? Icons.person : Icons.videocam_off,
                  color: Colors.white54, size: 28,
                )),
          if (!_micOn)
            const Positioned(bottom: 4, right: 4,
              child: _StatusIcon(Icons.mic_off, Colors.redAccent)),
        ]),
      ),
    );
  }

  Widget _buildApplauseOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _showApplause ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            color: Colors.black45,
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('👏', style: TextStyle(fontSize: 72)),
              SizedBox(height: 8),
              Text('Applause!', style: TextStyle(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      color: Colors.black,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Row 1 — universal controls
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _CtrlBtn(
            icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: _micOn ? 'Mute' : 'Unmute',
            color: _micOn ? Colors.white24 : Colors.orange,
            onTap: _toggleMic,
          ),
          _CtrlBtn(
            icon: _camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            label: _camOn ? 'Camera' : 'Cam Off',
            color: _camOn ? Colors.white24 : Colors.orange,
            onTap: _toggleCam,
          ),
          if (!widget.isInstructor)
            _CtrlBtn(
              icon: _handRaised ? Icons.front_hand_rounded : Icons.front_hand_outlined,
              label: _handRaised ? 'Lower ✋' : 'Raise ✋',
              color: _handRaised ? Colors.amber : Colors.white24,
              onTap: _raiseHand,
            ),
          _CtrlBtn(
            icon: Icons.waving_hand_rounded,
            label: 'Applause',
            color: Colors.white24,
            onTap: _sendApplause,
          ),
          _CtrlBtn(
            icon: Icons.call_end_rounded,
            label: 'Leave',
            color: Colors.red,
            onTap: _leave,
          ),
        ]),
        // Row 2 — instructor extras
        if (widget.isInstructor) ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _CtrlBtn(
              icon: _screenSharing ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded,
              label: _screenSharing ? 'Stop Share' : 'Share Screen',
              color: _screenSharing ? Colors.orange : Colors.white24,
              onTap: _toggleScreenShare,
            ),
            _CtrlBtn(
              icon: _boardOpen ? Icons.close_rounded : Icons.draw_rounded,
              label: _boardOpen ? 'Close Board' : 'Whiteboard',
              color: _boardOpen ? Colors.teal : Colors.white24,
              onTap: _toggleBoard,
            ),
          ]),
        ],
      ]),
    );
  }
}

// ── Drawing point ─────────────────────────────────────────────────────────────

class _DrawingPoint {
  final double x, y; // 0.0–1.0 (relative to canvas size)
  final Color color;
  final double strokeWidth;
  final bool isStart; // true = first point of a new stroke

  const _DrawingPoint({
    required this.x,
    required this.y,
    required this.color,
    required this.strokeWidth,
    required this.isStart,
  });
}

// ── Whiteboard overlay ────────────────────────────────────────────────────────

class _WhiteboardOverlay extends StatefulWidget {
  final List<_DrawingPoint?> points;
  final bool canDraw;
  final void Function(_DrawingPoint? point) onDraw;
  final VoidCallback? onClear;

  const _WhiteboardOverlay({
    required this.points,
    required this.canDraw,
    required this.onDraw,
    this.onClear,
  });

  @override
  State<_WhiteboardOverlay> createState() => _WhiteboardOverlayState();
}

class _WhiteboardOverlayState extends State<_WhiteboardOverlay> {
  Color _color = Colors.black;
  double _strokeWidth = 3;
  bool _erasing = false;

  static const _palette = [Colors.black, Colors.red, Colors.blue, Colors.green, Colors.orange];
  static const _sizes = [2.0, 4.0, 7.0];

  void _onPanStart(DragStartDetails d, Size size) {
    widget.onDraw(_DrawingPoint(
      x: (d.localPosition.dx / size.width).clamp(0.0, 1.0),
      y: (d.localPosition.dy / size.height).clamp(0.0, 1.0),
      color: _erasing ? Colors.white : _color,
      strokeWidth: _erasing ? 22 : _strokeWidth,
      isStart: true,
    ));
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    widget.onDraw(_DrawingPoint(
      x: (d.localPosition.dx / size.width).clamp(0.0, 1.0),
      y: (d.localPosition.dy / size.height).clamp(0.0, 1.0),
      color: _erasing ? Colors.white : _color,
      strokeWidth: _erasing ? 22 : _strokeWidth,
      isStart: false,
    ));
  }

  void _onPanEnd(DragEndDetails _) => widget.onDraw(null); // stroke separator

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Toolbar ──
      Container(
        color: const Color(0xFF1C1C2E),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          const Text('Whiteboard', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          const Spacer(),
          if (widget.canDraw) ...[
            // Color swatches
            ..._palette.map((c) => GestureDetector(
              onTap: () => setState(() { _color = c; _erasing = false; }),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (!_erasing && _color == c) ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            )),
            const SizedBox(width: 6),
            // Stroke sizes
            ..._sizes.map((s) => GestureDetector(
              onTap: () => setState(() { _strokeWidth = s; _erasing = false; }),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 18, height: 18,
                child: Center(child: Container(
                  width: s * 2, height: s * 2,
                  decoration: BoxDecoration(
                    color: (!_erasing && _strokeWidth == s) ? Colors.white : Colors.white38,
                    shape: BoxShape.circle,
                  ),
                )),
              ),
            )),
            const SizedBox(width: 6),
            // Eraser
            GestureDetector(
              onTap: () => setState(() => _erasing = !_erasing),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _erasing ? Colors.white24 : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('⌫ Erase', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: widget.onClear,
              child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 10)),
            ),
          ] else
            const Text('Instructor is writing…', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ),
      // ── Canvas ──
      Expanded(child: LayoutBuilder(builder: (_, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        Widget canvas = CustomPaint(
          size: size,
          painter: _BoardPainter(widget.points),
        );
        if (widget.canDraw) {
          canvas = GestureDetector(
            onPanStart: (d) => _onPanStart(d, size),
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd: _onPanEnd,
            child: canvas,
          );
        }
        return canvas;
      })),
    ]);
  }
}

// ── Whiteboard painter ────────────────────────────────────────────────────────

class _BoardPainter extends CustomPainter {
  final List<_DrawingPoint?> points;
  const _BoardPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);
    final paint = Paint()..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    for (int i = 0; i < points.length - 1; i++) {
      final p = points[i];
      final q = points[i + 1];
      if (p == null || q == null || q.isStart) {
        // Draw dot for lone points
        if (p != null && p.isStart) {
          canvas.drawCircle(
            Offset(p.x * size.width, p.y * size.height),
            p.strokeWidth / 2,
            paint..color = p.color..strokeWidth = p.strokeWidth,
          );
        }
        continue;
      }
      canvas.drawLine(
        Offset(p.x * size.width, p.y * size.height),
        Offset(q.x * size.width, q.y * size.height),
        paint..color = p.color..strokeWidth = p.strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) => true;
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.circle, color: Colors.white, size: 7),
      SizedBox(width: 4),
      Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    ]),
  );
}

class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _StatusIcon(this.icon, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 3),
    child: Icon(icon, color: color, size: 12),
  );
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CtrlBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]),
  );
}

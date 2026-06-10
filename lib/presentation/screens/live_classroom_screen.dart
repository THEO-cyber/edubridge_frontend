import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveClassroomScreen extends StatefulWidget {
  final String roomId;
  final String accessToken;
  final String livekitUrl;
  final String sessionTitle;

  const LiveClassroomScreen({
    super.key,
    required this.roomId,
    required this.accessToken,
    required this.livekitUrl,
    required this.sessionTitle,
  });

  @override
  State<LiveClassroomScreen> createState() => _LiveClassroomScreenState();
}

class _LiveClassroomScreenState extends State<LiveClassroomScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _connecting = true;
  String? _error;
  bool _micOn = true;
  bool _camOn = true;

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

  Future<void> _connect() async {
    await [Permission.camera, Permission.microphone].request();

    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );
    final listener = room.createListener();
    listener
      ..on<RoomConnectedEvent>((_) { if (mounted) setState(() {}); })
      ..on<RoomDisconnectedEvent>((_) { if (mounted) Navigator.of(context).pop(); })
      ..on<ParticipantConnectedEvent>((_) { if (mounted) setState(() {}); })
      ..on<ParticipantDisconnectedEvent>((_) { if (mounted) setState(() {}); })
      ..on<TrackPublishedEvent>((_) { if (mounted) setState(() {}); })
      ..on<TrackUnpublishedEvent>((_) { if (mounted) setState(() {}); })
      ..on<TrackSubscribedEvent>((_) { if (mounted) setState(() {}); })
      ..on<TrackUnsubscribedEvent>((_) { if (mounted) setState(() {}); });

    try {
      await room.connect(widget.livekitUrl, widget.accessToken);
      await room.localParticipant?.setCameraEnabled(true);
      await room.localParticipant?.setMicrophoneEnabled(true);

      if (mounted) {
        setState(() {
          _room = room;
          _listener = listener;
          _connecting = false;
        });
      }
    } catch (e) {
      await listener.dispose();
      if (mounted) {
        setState(() {
          _connecting = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _toggleMic() async {
    final local = _room?.localParticipant;
    if (local == null) return;
    final next = !_micOn;
    await local.setMicrophoneEnabled(next);
    if (mounted) setState(() => _micOn = next);
  }

  Future<void> _toggleCam() async {
    final local = _room?.localParticipant;
    if (local == null) return;
    final next = !_camOn;
    await local.setCameraEnabled(next);
    if (mounted) setState(() => _camOn = next);
  }

  Future<void> _leave() async {
    await _room?.disconnect();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _listener?.dispose();
    _room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _connecting
            ? _buildConnecting()
            : _error != null
                ? _buildError()
                : _buildRoom(),
      ),
    );
  }

  Widget _buildConnecting() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Joining classroom…',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 52),
            const SizedBox(height: 16),
            const Text('Could not join classroom',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoom() {
    final room = _room!;
    final remotes = room.remoteParticipants.values.toList();
    final total = remotes.length + 1;

    return Column(
      children: [
        // Top bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          color: Colors.black,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sessionTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$total participant${total == 1 ? '' : 's'}',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const _LiveBadge(),
            ],
          ),
        ),
        // Main video area
        Expanded(
          child: Stack(
            children: [
              remotes.isEmpty
                  ? _buildWaiting()
                  : _buildRemoteGrid(remotes),
              // Local picture-in-picture
              Positioned(
                right: 12,
                bottom: 12,
                child: _buildLocalPip(room),
              ),
            ],
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildWaiting() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, color: Colors.white24, size: 72),
          SizedBox(height: 16),
          Text('Waiting for others to join…',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildRemoteGrid(List<RemoteParticipant> participants) {
    if (participants.length == 1) {
      return _participantTile(participants.first);
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      padding: EdgeInsets.zero,
      itemCount: participants.length,
      itemBuilder: (_, i) => _participantTile(participants[i]),
    );
  }

  Widget _participantTile(Participant participant) {
    final videoTrack = _videoTrackFor(participant);
    final name = participant.identity;

    return Container(
      color: const Color(0xFF1A1A2E),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoTrack != null)
            VideoTrackRenderer(videoTrack)
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blueGrey[700],
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
          // Name tag
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(name,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalPip(Room room) {
    final local = room.localParticipant;
    final videoTrack = local != null ? _videoTrackFor(local) : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 96,
        height: 136,
        color: const Color(0xFF222244),
        child: videoTrack != null && _camOn
            ? VideoTrackRenderer(videoTrack)
            : Center(
                child: Icon(
                  _camOn ? Icons.person : Icons.videocam_off,
                  color: Colors.white54,
                  size: 28,
                ),
              ),
      ),
    );
  }

  VideoTrack? _videoTrackFor(Participant participant) {
    for (final pub in participant.videoTrackPublications) {
      final track = pub.track;
      if (track is VideoTrack) return track;
    }
    return null;
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CtrlBtn(
            icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: _micOn ? 'Mute' : 'Unmute',
            color: _micOn ? Colors.white24 : Colors.orange,
            onTap: _toggleMic,
          ),
          _CtrlBtn(
            icon: _camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            label: _camOn ? 'Cam Off' : 'Cam On',
            color: _camOn ? Colors.white24 : Colors.orange,
            onTap: _toggleCam,
          ),
          _CtrlBtn(
            icon: Icons.call_end_rounded,
            label: 'Leave',
            color: Colors.red,
            onTap: _leave,
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.white, size: 7),
          SizedBox(width: 4),
          Text('LIVE',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CtrlBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}

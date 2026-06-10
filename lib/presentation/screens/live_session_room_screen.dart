import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../constants/app_config.dart';
import '../../core/secure_storage.dart';
import '../../presentation/blocs/live_session_bloc.dart';

class LiveSessionRoomScreen extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;
  final bool isInstructor;

  const LiveSessionRoomScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
    required this.isInstructor,
  });

  @override
  State<LiveSessionRoomScreen> createState() => _LiveSessionRoomScreenState();
}

class _LiveSessionRoomScreenState extends State<LiveSessionRoomScreen> {
  WebViewController? _controller;
  bool _permissionsGranted = false;
  bool _loadError = false;
  bool _isLoading = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    await _loadUserName();
    if (mounted && _permissionsGranted) {
      _setupWebView();
    }
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final granted = statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted;

    setState(() => _permissionsGranted = granted);

    if (!granted && mounted) {
      final denied = !statuses[Permission.camera]!.isGranted
          ? 'Camera'
          : 'Microphone';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$denied permission denied. Video calls may not work properly.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
      setState(() => _permissionsGranted = true); // allow loading anyway
    }
  }

  Future<void> _loadUserName() async {
    final token = await SecureStorage.getToken();
    if (token != null && mounted) {
      setState(() => _userName = widget.isInstructor ? 'Instructor' : 'Student');
    }
  }

  void _setupWebView() {
    final roomName = 'edubridge-${widget.sessionId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';
    final displayName = Uri.encodeComponent(_userName ?? 'User');

    // Build Jitsi Meet URL with configuration options via URL hash
    final url =
        '${AppConfig.jitsiServerUrl}/$roomName'
        '#userInfo.displayName="$displayName"'
        '&config.startWithAudioMuted=false'
        '&config.startWithVideoMuted=false'
        '&config.disableDeepLinking=true'
        '&config.prejoinPageEnabled=false'
        '&interfaceConfig.TOOLBAR_BUTTONS=["microphone","camera","hangup"'
        '${widget.isInstructor ? ',"desktop","participants-pane"' : ''}]';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            setState(() {
              _loadError = true;
              _isLoading = false;
            });
          },
        ),
      );

    // Permissions granted above via permission_handler before the WebView loads.
    controller.loadRequest(Uri.parse(url));
    setState(() => _controller = controller);
  }

  Future<void> _leaveOrEndSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.isInstructor ? 'End Session?' : 'Leave Session?'),
        content: Text(
          widget.isInstructor
              ? 'This will end the session for all participants.'
              : 'Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              widget.isInstructor ? 'End Session' : 'Leave',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final token = await SecureStorage.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.isInstructor) {
      context
          .read<LiveSessionBloc>()
          .add(EndLiveSessionEvent(widget.sessionId, token));
    } else {
      context
          .read<LiveSessionBloc>()
          .add(LeaveLiveSessionEvent(widget.sessionId, token));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sessionTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const Text('LIVE',
                    style: TextStyle(fontSize: 10, color: Colors.red)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leaveOrEndSession,
        ),
        actions: [
          if (widget.isInstructor)
            TextButton.icon(
              onPressed: _leaveOrEndSession,
              icon: const Icon(Icons.call_end, color: Colors.red, size: 18),
              label: const Text('End',
                  style: TextStyle(color: Colors.red, fontSize: 13)),
            )
          else
            TextButton(
              onPressed: _leaveOrEndSession,
              child: const Text('Leave',
                  style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: BlocListener<LiveSessionBloc, LiveSessionState>(
        listener: (context, state) {
          if (state is LiveSessionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is LiveSessionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Could not connect to the video call.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loadError = false;
                  _isLoading = true;
                });
                _setupWebView();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Setting up video call...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Joining session...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

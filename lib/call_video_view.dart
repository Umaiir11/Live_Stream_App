import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart' as RtcLocalView;
import 'package:agora_rtc_engine/agora_rtc_engine.dart' as RtcRemoteView;

import 'call_controller.dart';

class CallScreen extends StatefulWidget {
  final bool isVideoCall;
  final String contactName;
  final String? channelId;
  final bool isGroupCall;
  final List<String> participants;

  const CallScreen({
    Key? key,
    this.isVideoCall = true,
    this.contactName = "User",
    this.channelId,
    this.isGroupCall = false,
    this.participants = const [],
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  final CallController _callController = Get.put(CallController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero, () {
      _initializeCall();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Get.delete<CallController>(); // Clean up controller
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      if (_callController.isVideoCall.value && !_callController.isCameraOff.value) {
        _callController.toggleCamera();
      }
    }
  }

  void _initializeCall() {
    _callController.initializeCall(
      isVideo: widget.isVideoCall,
      channel: widget.channelId,
      isGroup: widget.isGroupCall,
      participants: widget.participants,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showEndCallConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body:Stack(
          children: [
            _buildCallBackground(),
            _buildCallContent(),
            _buildCallStatusBar(),
            _buildCallControls(),
          ],
        )
      ),
    );
  }

  Widget _buildCallBackground() {
    return Obx(() {
      if (_callController.isVideoCall.value && !_callController.isCameraOff.value) {
        return Container(color: Colors.black);
      }
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCallContent() {
    return Obx(() {
      if (_callController.isCallEnded.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _callController.callStatus.value == "No answer"
                    ? Icons.call_missed
                    : Icons.call_end_rounded,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                _callController.callStatus.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.isGroupCall
                    ? "Group call (${widget.participants.length} participants)"
                    : widget.contactName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              if (_callController.callDuration.value > 0) ...[
                const SizedBox(height: 10),
                Text(
                  "Duration: ${_callController.formattedCallDuration}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        );
      } else if (!_callController.isCallAccepted.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.contactName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.contactName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _callController.callStatus.value,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              const _PulsingCircle(),
            ],
          ),
        );
      } else {
        return _buildActiveCallView();
      }
    });
  }

  Widget _buildActiveCallView() {
    return Obx(() {
      if (_callController.isVideoCall.value && !_callController.isCameraOff.value) {
        return Stack(
          children: [
            if (_callController.remoteUids.isNotEmpty)
              Positioned.fill(
                child: _buildRemoteVideo(),
              ),
            Positioned(
              right: 16,
              top: 90,
              width: 120,
              height: 180,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                clipBehavior: Clip.hardEdge,
                child: _buildLocalVideo(),
              ),
            ),
          ],
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.isGroupCall && widget.participants.isNotEmpty
                        ? widget.participants.first.substring(0, 1).toUpperCase()
                        : widget.contactName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isGroupCall
                    ? "Group call (${widget.participants.length} participants)"
                    : widget.contactName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _callController.formattedCallDuration,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              if (widget.isGroupCall && widget.participants.isNotEmpty) ...[
                const SizedBox(height: 40),
                const Text(
                  "Participants",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount: _callController.participantNames.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white24,
                              child: Text(
                                _callController.participantNames[index]
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _callController.participantNames[index],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      }
    });
  }

  Widget _buildLocalVideo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: _callController.engine != null
          ? RtcLocalView.AgoraVideoView(
        controller: RtcLocalView.VideoViewController(
          rtcEngine: _callController.engine!,
          canvas: const RtcLocalView.VideoCanvas(uid: 0),
        ),
      )
          : Container(color: Colors.grey.shade800),
    );
  }

  Widget _buildRemoteVideo() {
    if (_callController.remoteUids.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              "Waiting for remote video...",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    return RtcLocalView.AgoraVideoView(
      controller: RtcLocalView.VideoViewController.remote(
        rtcEngine: _callController.engine!,
        canvas: RtcLocalView.VideoCanvas(uid: _callController.remoteUids.first),
        connection: RtcLocalView.RtcConnection(channelId: _callController.callChannelId.value),
      ),
    );
  }

  Widget _buildCallStatusBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.black45,
          child: Row(
            children: [
              Obx(() {
                return Icon(
                  _callController.isVideoCall.value ? Icons.videocam : Icons.call,
                  color: Colors.white,
                );
              }),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.isGroupCall ? "Group call" : widget.contactName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Obx(() {
                      return Text(
                        _callController.isCallAccepted.value
                            ? _callController.formattedCallDuration
                            : _callController.callStatus.value,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                onPressed: () {
                  _callController.toggleCallView();
                  Get.snackbar(
                    "Feature Unavailable",
                    "Call minimizing is not implemented in this demo",
                    backgroundColor: Colors.black45,
                    colorText: Colors.white,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        color: Colors.black45,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCallControlButton(
              icon: Obx(() => Icon(
                _callController.isSpeakerOn.value
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: Colors.white,
              )),
              backgroundColor: Colors.grey.shade800,
              onPressed: _callController.toggleSpeaker,
            ),
            Obx(() {
              return _callController.isVideoCall.value
                  ? _buildCallControlButton(
                icon: Icon(
                  _callController.isCameraOff.value
                      ? Icons.videocam_off
                      : Icons.videocam,
                  color: Colors.white,
                ),
                backgroundColor: Colors.grey.shade800,
                onPressed: _callController.toggleCamera,
              )
                  : const SizedBox(width: 56);
            }),
            _buildCallControlButton(
              icon: Obx(() => Icon(
                _callController.isMuted.value ? Icons.mic_off : Icons.mic,
                color: Colors.white,
              )),
              backgroundColor: Colors.grey.shade800,
              onPressed: _callController.toggleMute,
            ),
            _buildCallControlButton(
              icon: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 30,
              ),
              backgroundColor: Colors.red,
              size: 70,
              onPressed: _showEndCallConfirmation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControlButton({
    required Widget icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
    double size = 56,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showEndCallConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("End Call"),
        content: Text(
            "Are you sure you want to end the ${widget.isGroupCall ? 'group' : ''} call?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _callController.endCall();
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit call screen
            },
            child: const Text(
              "End Call",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingCircle extends StatefulWidget {
  const _PulsingCircle();

  @override
  _PulsingCircleState createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
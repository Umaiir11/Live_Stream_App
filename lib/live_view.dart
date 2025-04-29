import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'live_controller.dart';

class LiveScreen extends StatefulWidget {
  final RxBool isBroadcaster;
  final String streamId;

  const LiveScreen({
    super.key,
    required this.isBroadcaster,
    this.streamId = '',
  });

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final LiveController controller = Get.put(LiveController());
  bool hasShownIdInfo = false;

  @override
  Widget build(BuildContext context) {
    final String channelToUse = widget.streamId.isNotEmpty ? widget.streamId : 'testapp';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initAgora(widget.isBroadcaster.value, channelToUse);

      if (widget.isBroadcaster.value && !hasShownIdInfo) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && controller.isJoined.value) {
            _showStreamIdInfo();
            hasShownIdInfo = true;
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          widget.isBroadcaster.value ? "Broadcasting" : "Watching Stream",
        )),
        backgroundColor: Colors.black,
        actions: [
          if (widget.isBroadcaster.value)
            Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: GestureDetector(
                  onTap: () => _copyStreamId(controller.channelId.value),
                  child: Row(
                    children: [
                      Text(
                        "ID: ${controller.channelId.value}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            )),
          if (widget.isBroadcaster.value)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _showStreamIdInfo(),
              tooltip: "Share Stream ID",
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (!controller.isJoined.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              return Stack(
                children: [
                  Positioned.fill(
                    child: widget.isBroadcaster.value
                        ? _localBroadcasterView()
                        : _remoteView(),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.remove_red_eye, color: Colors.white, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            "${controller.remoteUid.value != 0 ? "1" : "0"} watching",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.isBroadcaster.value)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => _copyStreamId(controller.channelId.value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.copy, color: Colors.white, size: 18),
                              const SizedBox(width: 5),
                              Text(
                                "ID: ${controller.channelId.value}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.isBroadcaster.value)
                  _buildControlButton(
                    icon: controller.isAudioEnabled.value ? Icons.mic : Icons.mic_off,
                    label: controller.isAudioEnabled.value ? "Mute" : "Unmute",
                    onPressed: () => controller.toggleAudio(),
                    isActive: controller.isAudioEnabled.value,
                  ),
                if (widget.isBroadcaster.value)
                  _buildControlButton(
                    icon: controller.isVideoEnabled.value ? Icons.videocam : Icons.videocam_off,
                    label: controller.isVideoEnabled.value ? "Video Off" : "Video On",
                    onPressed: () => controller.toggleVideo(),
                    isActive: controller.isVideoEnabled.value,
                  ),
                if (widget.isBroadcaster.value)
                  _buildControlButton(
                    icon: Icons.switch_camera,
                    label: "Switch",
                    onPressed: () => controller.switchCamera(),
                  ),
                _buildControlButton(
                  icon: Icons.call_end,
                  label: widget.isBroadcaster.value ? "End" : "Leave",
                  onPressed: () => controller.leaveChannel(),
                  backgroundColor: Colors.red,
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  void _copyStreamId(String streamId) {
    Clipboard.setData(ClipboardData(text: streamId)).then((_) {
      Get.snackbar(
        "Copied to Clipboard",
        "Stream ID: $streamId has been copied. Share with viewers.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(10),
      );
    });
  }

  void _showStreamIdInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Stream Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share this Stream ID with viewers:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      controller.channelId.value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      _copyStreamId(controller.channelId.value);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Viewers need to paste this ID in the "Join Stream" screen',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = true,
    Color? backgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: backgroundColor ??
                (isActive ? Colors.grey.shade800 : Colors.red.shade700),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(12),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Widget _localBroadcasterView() {
    if (controller.engine == null) {
      return Container(color: Colors.black);
    }
    return Obx(() => controller.isVideoEnabled.value
        ? AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: controller.engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    )
        : Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          "Camera Off",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    ));
  }

  Widget _remoteView() {
    return Obx(() {
      if (controller.remoteUid.value != 0 && controller.engine != null) {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: controller.engine!,
            canvas: VideoCanvas(uid: controller.remoteUid.value),
            connection: RtcConnection(channelId: controller.channelId.value),
          ),
        );
      } else {
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_empty, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text(
                  "Waiting for stream to start...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Channel: ${controller.channelId.value}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Obx(() => Text(
                  controller.isJoined.value
                      ? "✅ Successfully joined channel"
                      : "🔄 Joining channel...",
                  style: TextStyle(
                    color: controller.isJoined.value ? Colors.green : Colors.orange,
                  ),
                )),
                const SizedBox(height: 30),
                if (controller.isJoined.value)
                  ElevatedButton(
                    onPressed: () {
                      controller.leaveChannel();
                      Future.delayed(const Duration(seconds: 1), () {
                        controller.initAgora(false, controller.channelId.value);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text("Refresh Connection"),
                  ),
              ],
            ),
          ),
        );
      }
    });
  }
}
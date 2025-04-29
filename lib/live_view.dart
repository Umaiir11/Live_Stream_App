import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import 'live_controller.dart';

class LiveScreen extends StatefulWidget {
  final bool isBroadcaster;
  final String streamId;

  LiveScreen({
    super.key,
    required this.isBroadcaster,
    this.streamId = ''
  });

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final LiveController controller = Get.put(LiveController());

  @override
  Widget build(BuildContext context) {
    // Use the fixed channel name from your document
    final String channelToUse = widget.streamId.isNotEmpty ? widget.streamId : 'testapp';

    // Initialize in a post-frame callback to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initAgora(widget.isBroadcaster, channelToUse);
    });

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
            widget.isBroadcaster
                ? "Broadcasting (ID: ${controller.channelId})"
                : "Watching Stream"
        )),
        backgroundColor: Colors.black,
        actions: [
          if (widget.isBroadcaster)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                // Copy stream ID to clipboard functionality would go here
                Get.snackbar(
                    "Stream ID Copied",
                    "Share this ID with viewers: ${controller.channelId}",
                    backgroundColor: Colors.green.withOpacity(0.7),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM
                );
              },
              tooltip: "Copy Stream ID",
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Main video area
          Expanded(
            child: Obx(() {
              if (!controller.isJoined.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              return Stack(
                children: [
                  // Main video - either local or remote depending on role
                  Positioned.fill(
                    child: widget.isBroadcaster
                        ? _localBroadcasterView()
                        : _remoteView(),
                  ),

                  // Stream info overlay
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
                ],
              );
            }),
          ),

          // Bottom controls
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.mic,
                  label: "Mute",
                  onPressed: () => controller.toggleAudio(),
                  isActive: controller.isAudioEnabled.value,
                ),
                _buildControlButton(
                  icon: Icons.videocam,
                  label: "Video",
                  onPressed: () => controller.toggleVideo(),
                  isActive: controller.isVideoEnabled.value,
                ),
                _buildControlButton(
                  icon: Icons.switch_camera,
                  label: "Switch",
                  onPressed: () => controller.switchCamera(),
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  label: "End",
                  onPressed: () => controller.leaveChannel(),
                  backgroundColor: Colors.red,
                ),
              ],
            ),
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
            color: backgroundColor ?? (isActive ? Colors.grey.shade800 : Colors.red),
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
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: controller.engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
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
                      fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Channel: ${controller.channelId.value}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                // Status indicator
                Obx(() {
                  return Text(
                    controller.isJoined.value
                        ? "✅ Successfully joined channel"
                        : "🔄 Joining channel...",
                    style: TextStyle(
                      color: controller.isJoined.value ? Colors.green : Colors.orange,
                    ),
                  );
                }),
                const SizedBox(height: 30),
                if (controller.isJoined.value)
                  ElevatedButton(
                    onPressed: () {
                      // Force reinitialize
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

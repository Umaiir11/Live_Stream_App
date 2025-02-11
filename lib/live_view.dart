import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'live_controller.dart';

class LiveScreen extends StatelessWidget {
  final bool isBroadcaster;
  LiveScreen({super.key, required this.isBroadcaster});

  final LiveController controller = Get.put(LiveController());

  @override
  Widget build(BuildContext context) {
    controller.initAgora(isBroadcaster);

    return Scaffold(
      appBar: AppBar(title: Text(isBroadcaster ? "Go Live" : "Watch Live")),
      body: Stack(
        children: [
          Positioned.fill(
            child: Obx(() {
              if (!controller.isJoined.value || controller.engine == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return isBroadcaster ? _broadcasterVideo() : _remoteVideo();
            }),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: () => controller.leaveChannel(),
              child: const Text("Close"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _broadcasterVideo() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: controller.engine!, // Ensured non-null
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _remoteVideo() {
    return Obx(() {
      if (controller.remoteUid.value != 0 && controller.engine != null) {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: controller.engine!, // Ensured non-null
            canvas: VideoCanvas(uid: controller.remoteUid.value),
            connection: const RtcConnection(channelId: channelName),
          ),
        );
      } else {
        return const Center(
          child: Text(
            "No broadcaster is live",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
      }
    });
  }
}

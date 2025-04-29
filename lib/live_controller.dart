import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

// Using your Agora app ID and token
const String appId = "fff60e8b5bdf4187b84ab1291dd80c09";
const String token = "007eJxTYJDZte1mnXFRRTqDi0qP3p6V6p8LX/1sntqes+fW77/WjScVGNLS0swMUi2STJNS0kwMLcyTLEwSkwyNLA1TUiwMkg0sP5YJZDQEMjIUv/dhYIRCEJ+doSS1uCSxoICBAQBRUSMe";
const String defaultChannel = "testapp";

class LiveController extends GetxController {
  RtcEngine? engine;
  final RxBool isJoined = false.obs;
  final RxInt remoteUid = 0.obs;
  final RxBool isBroadcaster = false.obs;
  final RxBool isAudioEnabled = true.obs;
  final RxBool isVideoEnabled = true.obs;
  final RxString channelId = "".obs;

  Future<void> initAgora(bool broadcaster, String streamId) async {
    isBroadcaster.value = broadcaster;
    channelId.value = streamId.isEmpty ? defaultChannel : streamId;
    debugPrint("⚡️ Initializing Agora with channel: ${channelId.value}, role: ${broadcaster ? 'broadcaster' : 'audience'}");

    try {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        debugPrint("❌ Camera or Microphone permission denied");
        Get.snackbar(
          "Permission Error",
          "Camera and microphone permissions are required",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Initialize engine
      if (engine == null) {
        engine = createAgoraRtcEngine();
        await engine!.initialize(const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ));
        debugPrint("✅ Engine initialized");
      }

      // Configure engine
      if (broadcaster) {
        await engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        await engine!.enableVideo();
        await engine!.enableAudio();
        await engine!.startPreview();
        debugPrint("👤 Set as broadcaster");
      } else {
        await engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
        debugPrint("👥 Set as audience");
      }

      // Set up event handlers
      engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("✅ Successfully joined channel: ${connection.channelId}");
          isJoined.value = true;
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          debugPrint("👋 Remote user $uid joined channel");
          remoteUid.value = uid;
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          debugPrint("👋 Remote user $uid left channel");
          remoteUid.value = 0;
        },
        onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
          debugPrint("Connection state changed to: $state because of $reason");
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("❌ Error: $err - $msg");
          Get.snackbar(
            "Agora Error",
            msg,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
      ));

      // Join channel
      debugPrint("🔄 Joining channel: ${channelId.value}");
      await engine!.joinChannel(
        token: token,
        channelId: channelId.value,
        uid: 0,
        options: ChannelMediaOptions(
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
          publishCameraTrack: broadcaster,
          publishMicrophoneTrack: broadcaster,
          clientRoleType: broadcaster
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience,
        ),
      );

      debugPrint("✅ Join channel request sent");
    } catch (e) {
      debugPrint("❌ Error initializing Agora: $e");
      Get.snackbar(
        "Error",
        "Failed to initialize live streaming: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void toggleAudio() async {
    if (engine != null && isBroadcaster.value) {
      try {
        isAudioEnabled.value = !isAudioEnabled.value;
        await engine!.muteLocalAudioStream(!isAudioEnabled.value);
        debugPrint("🎙️ Audio ${isAudioEnabled.value ? 'enabled' : 'muted'}");
        Get.snackbar(
          "Audio",
          isAudioEnabled.value ? "Microphone enabled" : "Microphone muted",
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        debugPrint("❌ Error toggling audio: $e");
        isAudioEnabled.value = !isAudioEnabled.value; // Revert state on error
        Get.snackbar(
          "Error",
          "Failed to toggle audio",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void toggleVideo() async {
    if (engine != null && isBroadcaster.value) {
      try {
        isVideoEnabled.value = !isVideoEnabled.value;
        await engine!.muteLocalVideoStream(!isVideoEnabled.value);
        if (isVideoEnabled.value) {
          await engine!.startPreview();
        } else {
          await engine!.stopPreview();
        }
        debugPrint("📹 Video ${isVideoEnabled.value ? 'enabled' : 'muted'}");
        Get.snackbar(
          "Video",
          isVideoEnabled.value ? "Camera enabled" : "Camera muted",
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        debugPrint("❌ Error toggling video: $e");
        isVideoEnabled.value = !isVideoEnabled.value; // Revert state on error
        Get.snackbar(
          "Error",
          "Failed to toggle video",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void switchCamera() async {
    if (engine != null && isBroadcaster.value) {
      try {
        await engine!.switchCamera();
        debugPrint("🔄 Camera switched");
        Get.snackbar(
          "Camera",
          "Camera switched",
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        debugPrint("❌ Error switching camera: $e");
        Get.snackbar(
          "Error",
          "Failed to switch camera",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> leaveChannel() async {
    try {
      if (engine != null) {
        await engine!.leaveChannel();
        await engine!.release();
        debugPrint("✅ Left channel and released engine");
      }
    } catch (e) {
      debugPrint("❌ Error leaving channel: $e");
    } finally {
      engine = null;
      isJoined.value = false;
      remoteUid.value = 0;
      isAudioEnabled.value = true;
      isVideoEnabled.value = true;
    }
    Get.back();
  }

  @override
  void onClose() {
    leaveChannel();
    super.onClose();
  }
}
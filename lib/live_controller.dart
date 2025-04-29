// Replace with your own Agora app ID and token
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:permission_handler/permission_handler.dart';


// Using your Agora app ID and token from th  e uploaded document
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
    // Set default values
    isBroadcaster.value = broadcaster;
    channelId.value = streamId.isEmpty ? defaultChannel : streamId;
    debugPrint("⚡️ Initializing Agora with channel: ${channelId.value}, role: ${broadcaster ? 'broadcaster' : 'audience'}");

    try {
      // Request permissions first
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone
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

      // Create the engine if it doesn't exist
      if (engine == null) {
        engine = createAgoraRtcEngine();
        await engine?.initialize(RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ));

        debugPrint("✅ Engine initialized");
      }

      // Configure the engine
      if (broadcaster) {
        await engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        await engine?.enableVideo();
        await engine?.enableAudio();
        await engine?.startPreview();
        debugPrint("👤 Set as broadcaster");
      } else {
        await engine?.setClientRole(role: ClientRoleType.clientRoleAudience);
        debugPrint("👥 Set as audience");
      }

      // Set up event handlers
      engine?.registerEventHandler(RtcEngineEventHandler(
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

      // Join the channel
      debugPrint("🔄 Joining channel: ${channelId.value}");
      await engine?.joinChannel(
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

  void toggleAudio() {
    if (engine != null) {
      isAudioEnabled.value = !isAudioEnabled.value;
      engine?.muteLocalAudioStream(!isAudioEnabled.value);
    }
  }

  void toggleVideo() {
    if (engine != null) {
      isVideoEnabled.value = !isVideoEnabled.value;
      engine?.muteLocalVideoStream(!isVideoEnabled.value);
    }
  }

  void switchCamera() {
    engine?.switchCamera();
  }

  void leaveChannel() async {
    try {
      await engine?.leaveChannel();
      await engine?.release();
    } catch (e) {
      debugPrint("Error leaving channel: $e");
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
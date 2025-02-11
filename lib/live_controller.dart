import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

const String appId = "cb3154b6171c4b868526a3ad4e9e7ba3";
const String token = "007eJxTYDg698WC7SzPrVZ3fIs5Jv5dLKJxgr6Qxo/tF9mMZSWVTBUVGJKTjA1NTZLMDM0Nk02SLMwsTI3MEo0TU0xSLVPNkxKNtY1XpzcEMjIcN5zCwAiELEAM4jOBSWYwyQIlS1KLSxgYAClvIFU=";
const String channelName = "test";

class LiveController extends GetxController {
  RtcEngine? engine;
  final RxBool isJoined = false.obs;
  final RxInt remoteUid = 0.obs;
  final RxBool isBroadcaster = false.obs;

  Future<void> initAgora(bool broadcaster) async {
    isBroadcaster.value = broadcaster;

    // Request permissions
    final permissions = await [Permission.camera, Permission.microphone].request();
    if (permissions[Permission.camera] != PermissionStatus.granted ||
        permissions[Permission.microphone] != PermissionStatus.granted) {
      debugPrint("Permissions not granted");
      return;
    }

    engine = createAgoraRtcEngine();
    await engine?.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    engine?.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint("User ${connection.localUid} joined");
        isJoined.value = true;
      },
      onUserJoined: (RtcConnection connection, int uid, int elapsed) {
        debugPrint("Remote user $uid joined");
        remoteUid.value = uid;
      },
      onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
        debugPrint("Remote user $uid left");
        remoteUid.value = 0;
      },
    ));

    if (broadcaster) {
      await engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine?.enableVideo();
      await engine?.startPreview();
    } else {
      await engine?.setClientRole(role: ClientRoleType.clientRoleAudience);
    }

    await engine?.joinChannel(
      token: token,
      channelId: channelName,
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
    }
    Get.back();
  }

  @override
  void onClose() {
    leaveChannel();
    super.onClose();
  }
}

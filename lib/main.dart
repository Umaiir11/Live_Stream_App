import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'live_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Agora Live Streaming")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Get.to(() => LiveScreen(isBroadcaster: true));
                },
                child: const Text("Go Live"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Get.to(() => LiveScreen(isBroadcaster: false));
                },
                child: const Text("Watch Live"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

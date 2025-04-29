// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'join_stream_view.dart';
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}



class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Streaming"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Streams Section
            const Text(
              "Live Now",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildActiveStreams(),
            ),

            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Get.to(() => LiveScreen(isBroadcaster: true)),
                    icon: const Icon(Icons.videocam),
                    label: const Text("Go Live", style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Get.to(() => const JoinScreen()),
                    icon: const Icon(Icons.group_add),
                    label: const Text("Join Stream", style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Simulated live streams list
  Widget _buildActiveStreams() {
    // Mocked data - in a real app, this would come from a backend
    final mockStreams = [
      {"id": "stream123", "host": "John Doe", "title": "Morning Meeting", "viewers": 12},
      {"id": "stream456", "host": "Jane Smith", "title": "Project Review", "viewers": 8},
    ];

    if (mockStreams.isEmpty) {
      return const Center(
        child: Text("No active streams right now"),
      );
    }

    return ListView.builder(
      itemCount: mockStreams.length,
      itemBuilder: (context, index) {
        final stream = mockStreams[index];
        final String hostName = stream["host"] as String;
        final String streamTitle = stream["title"] as String;
        final String streamId = stream["id"] as String;
        final int viewers = stream["viewers"] as int;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(hostName.substring(0, 1)),
            ),
            title: Text(streamTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Host: $hostName • $viewers viewers"),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                // Join this specific stream
                Get.to(() => LiveScreen(
                    isBroadcaster: false,
                    streamId: streamId
                ));
              },
              child: const Text("Join"),
            ),
          ),
        );
      },
    );
  }
}









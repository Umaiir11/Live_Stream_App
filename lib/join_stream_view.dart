import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'live_view.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final TextEditingController _streamIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    _streamIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Stream"),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Join a Live Stream",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Enter the Stream ID provided by the broadcaster to join their live stream.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _streamIdController,
                decoration: InputDecoration(
                  labelText: "Stream ID",
                  hintText: "Paste the stream ID here",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.video_call),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    tooltip: "Paste from clipboard",
                    onPressed: () async {
                      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data != null && data.text != null) {
                        setState(() {
                          _streamIdController.text = data.text!.trim();
                        });
                        Get.snackbar(
                          "Pasted",
                          "Stream ID pasted from clipboard",
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                        );
                      } else {
                        Get.snackbar(
                          "Error",
                          "No text found in clipboard",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                        );
                      }
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a valid Stream ID';
                  }
                  if (value.trim().length < 3) {
                    return 'Stream ID must be at least 3 characters';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _joinStream(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How to join a stream:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "1. Ask the broadcaster for their Stream ID\n"
                          "2. Enter or paste the ID in the field above\n"
                          "3. Tap 'Join Stream' to connect",
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: isLoading ? null : _joinStream,
                  icon: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : const Icon(Icons.login),
                  label: Text(
                    isLoading ? "Connecting..." : "Join Stream",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _joinStream() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      final streamId = _streamIdController.text.trim();

      // Navigate to LiveScreen after a brief delay (simulating connection)
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          isLoading = false;
        });

        Get.off(() => LiveScreen(
          isBroadcaster: false.obs,
          streamId: streamId,
        ));
      });
    }
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_test_helper.dart';

class FirebaseTestScreen extends StatelessWidget {
  const FirebaseTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud,
              size: 100,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'Firebase Integration Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder(
              future: _checkFirebaseConnection(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Column(
                    children: [
                      const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Firebase Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Firebase Connected Successfully!',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Project: ${snapshot.data}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await AuthTestHelper.runAllTests();
                        },
                        child: const Text('Run Auth Tests'),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _checkFirebaseConnection() async {
    try {
      // Get the current Firebase app instance
      FirebaseApp app = Firebase.app();

      // Check if we're using placeholder values
      String apiKey = app.options.apiKey;
      if (apiKey.startsWith('YOUR_')) {
        throw Exception('Configuration not updated: Please replace placeholder values in firebase_options.dart with real Firebase config values');
      }

      return 'Project: ${app.options.projectId}\nAPI Key: ${apiKey.substring(0, 10)}...\nPlatform: ${app.options.toString().contains('authDomain') ? 'Web' : 'Mobile'}';
    } catch (e) {
      throw Exception('Firebase Error: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  final String? fcmToken;
  final bool embedded;

  const NotificationsScreen({
    super.key,
    this.fcmToken,
    this.embedded = false,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadNotifications();
  }

  Future<List<dynamic>> _loadNotifications() async {
    String? token = widget.fcmToken;

    if (token == null || token.isEmpty) {
      token = await FirebaseMessaging.instance.getToken();
    }

    if (token == null || token.isEmpty) {
      debugPrint('[NotificationsScreen] FCM token is null or empty');
      throw Exception('FCM token is not available');
    }

    final api = ApiService();
    final list = await api.getNotifications(token);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load notifications\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No notifications',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final n = items[index] as Map<String, dynamic>;
            final title = n['title'] as String? ?? '';
            final bodyText = n['body'] as String? ?? '';
            final createdAt = n['createdAt'] as String? ?? '';

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bodyText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          bodyText,
                          style: const TextStyle(
                            color: Color(0xFFCBD5F5),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      createdAt,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101922),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: body,
    );
  }
}

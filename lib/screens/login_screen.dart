import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isLoginProcessing = false;

  @override
  void initState() {
    super.initState();
    _initDeepLink();
  }

  void _initDeepLink() {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        if (uri.scheme == 'com.gitinsight.auth' &&
            uri.host == 'login' &&
            uri.path.contains('callback')) {
          final code = uri.queryParameters['code'];
          if (code != null && !_isLoginProcessing) {
            _handleLogin(code);
          }
        }
      }
    });
  }

  Future<void> _handleLogin(String code) async {
    setState(() {
      _isLoginProcessing = true;
    });

    try {
      await Provider.of<AppProvider>(context, listen: false).login(code);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoginProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _launchGithubAuth() async {
    const clientId = ApiService.githubClientId;
    final url = Uri.parse(
        'https://github.com/login/oauth/authorize?client_id=$clientId&redirect_uri=com.gitinsight.auth://login/callback&scope=repo,user');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.code, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('GitInsight',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Manage your GitHub commit history\nsmartly with AI.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _isLoginProcessing ? null : _launchGithubAuth,
              icon: _isLoginProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(
                  _isLoginProcessing ? 'Processing...' : 'Sign in with GitHub'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

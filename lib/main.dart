import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter-Spring Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _serverResponse = '서버 응답 대기 중...';
  bool _isLoading = false;

  // 서버에 데이터를 요청하는 함수
  Future<void> _fetchDataFromServer() async {
    setState(() {
      _isLoading = true;
      _serverResponse = '서버에 요청 중...';
    });

    const String serverUrl =
        'https://fullstack-service-programming-backend.onrender.com/api/health';

    try {
      final response = await http.get(Uri.parse(serverUrl));

      if (response.statusCode == 200) {
        setState(() {
          _serverResponse = response.body;
        });
      } else {
        setState(() {
          _serverResponse = '에러 발생: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _serverResponse = '요청 실패: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter - Spring 연동 테스트'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('서버로부터 받은 메시지:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              // 서버 응답을 보여줄 텍스트 위젯
              Text(
                _serverResponse,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // 요청을 보낼 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchDataFromServer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '서버에 메시지 요청하기',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

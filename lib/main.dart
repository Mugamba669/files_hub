import 'dart:developer';
import 'dart:io';
import 'package:files/services/FileSystemService.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ripple.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory? extDir = Directory('/storage/emulated/0');
  if (await extDir.exists()) {
    print('External storage directory: ${extDir.path}');
  } else {
    print('External storage directory not found');
  }
  // }
  runApp(MyApp());
}

var navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Sharing via Web',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _rippleAnimationController;

  HttpServer? _server;
  String _ipAddress = '';
  String _qrData = '';
  String _status = 'Server not running';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    _rippleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  // Request storage permission
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Manage external storage permission granted"),
          ),
        );
      } else {
        if (await Permission.manageExternalStorage.request().isGranted) {
          print("Manage external storage permission granted after request");
        } else {
          print("Manage external storage permission denied");
        }
      }
    }
  }

// Utility function to check if path is safe (prevents directory traversal attacks)

  // Start HTTP server
  Future<void> _startServer() async {
    var fileService = FilesystemService();
    try {
      // Get the local IP address
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() {
              _ipAddress = addr.address;
            });
            break;
          }
        }
      }

      // Start HTTP server on a random port
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      setState(() {
        _qrData = 'http://$_ipAddress:8080';
        _status = 'Server running on http://$_ipAddress:8080';
      });
      log("server running ${_server?.address}");
      _animationController.repeat(reverse: true);
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _status = 'Connected';
        });
        _animationController.stop();
      });
      // Handle incoming requests
      _server?.listen((HttpRequest request) async {
        fileService.handleFileRequests(request);

// Main request handler
      });
      // returning api
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  // Stop the server
  Future<void> _stopServer() async {
    await _server?.close();
    setState(() {
      _status = 'Server stopped';
      _qrData = '';
    });
    _animationController.stop();
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
    _rippleAnimationController.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'File Sharing Hub',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              _buildStatusWidget(),
              const SizedBox(height: 40),
              _buildQRSection(),
              const SizedBox(height: 40),
              _qrData.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                      child: Text(
                        'Server running on http://$_ipAddress:8080',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.apply(color: Colors.green),
                      ),
                    )
                  : const Text(''),
              _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    Color statusColor;
    IconData statusIcon;
    Widget animation;

    switch (_status) {
      case 'Connecting...':
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        animation = _buildConnectingAnimation();
        break;
      case 'Connected':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        animation = _buildConnectedAnimation();
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.cloud_off;
        animation = _buildDisconnectedAnimation();
    }

    return Column(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: animation,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(width: 10),
            Text(
              _status,
              style: TextStyle(fontSize: 18, color: statusColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectingAnimation() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animationController.value * 2 * 3.14,
          child: const Icon(Icons.sync, size: 60, color: Colors.orange),
        );
      },
    );
  }

  Widget _buildConnectedAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          painter: RipplePainter(
            color: Colors.green,
            animationValue: _rippleAnimationController.value,
          ),
          child: const SizedBox(
            height: 80,
            width: 80,
          ),
        ),
        const Icon(Icons.check_circle, size: 60, color: Colors.green),
      ],
    );
  }

  Widget _buildDisconnectedAnimation() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_animationController.value * 0.5),
          child: const Icon(Icons.cloud_off, size: 60, color: Colors.red),
        );
      },
    );
  }

  Widget _buildQRSection() {
    return AnimatedOpacity(
      opacity: _qrData.isNotEmpty ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Scan to Connect',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAnimatedButton('Start Server', Colors.green, _startServer),
        _buildAnimatedButton('Stop Server', Colors.red, _stopServer),
      ],
    );
  }

  Widget _buildAnimatedButton(
      String text, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  spreadRadius: 1,
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}

class HttpException implements Exception {
  final String message;
  final int statusCode;

  HttpException(this.message, this.statusCode);
}

// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class FileSharing extends StatefulWidget {
  const FileSharing({super.key});

  @override
  _FileSharingState createState() => _FileSharingState();
}

class _FileSharingState extends State<FileSharing>
    with SingleTickerProviderStateMixin {
  String _status = 'Disconnected';
  String _qrData = '';
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startServer() {
    setState(() {
      _status = 'Connecting...';
      _qrData = 'http://example.com/share'; // Replace with actual server URL
    });
    _animationController.repeat(reverse: true);
  }

  void _stopServer() {
    setState(() {
      _status = 'Disconnected';
      _qrData = '';
    });
    _animationController.stop();
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
              Text(
                'File Sharing Hub',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40),
              _buildStatusWidget(),
              SizedBox(height: 40),
              _buildQRSection(),
              SizedBox(height: 40),
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
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: statusColor),
            SizedBox(width: 10),
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
          child: Icon(Icons.sync, size: 60, color: Colors.orange),
        );
      },
    );
  }

  Widget _buildConnectedAnimation() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_animationController.value * 0.1),
          child: Icon(Icons.check_circle, size: 60, color: Colors.green),
        );
      },
    );
  }

  Widget _buildDisconnectedAnimation() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_animationController.value * 0.5),
          child: Icon(Icons.cloud_off, size: 60, color: Colors.red),
        );
      },
    );
  }

  Widget _buildQRSection() {
    return AnimatedOpacity(
      opacity: _qrData.isNotEmpty ? 1.0 : 0.0,
      duration: Duration(milliseconds: 500),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
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
          SizedBox(height: 20),
          Text(
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
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  spreadRadius: 1,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}

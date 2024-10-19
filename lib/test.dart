import 'dart:io';
import 'dart:convert'; // For JSON encoding
import 'package:flutter/material.dart';

class FileServerApp extends StatefulWidget {
  @override
  _FileServerAppState createState() => _FileServerAppState();
}

class _FileServerAppState extends State<FileServerApp> {
  HttpServer? _server;
  String _status = 'Server not running';
  String _ipAddress = 'Unknown';
  String _qrData = '';

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
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

      // Start HTTP server on port 8080
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      setState(() {
        _qrData = 'http://$_ipAddress:8080';
        _status = 'Server running on http://$_ipAddress:8080';
      });

      // Handle incoming API requests
      _server?.listen((HttpRequest request) async {
        // returning dom
        if (request.uri.path == '/files') {
          // Retrieve the current directory path from the query parameter
          String? path = request.uri.queryParameters['path'];
          path ??= '/storage/emulated/0'; // Default to root external storage

          // List files and directories in the current path
          Directory dir = Directory(path);
          if (await dir.exists()) {
            List<FileSystemEntity> entities = dir.listSync();
            String fileListHTML = '<ul>';

            // Add parent directory navigation
            if (dir.path != '/storage/emulated/0') {
              String parentDir = Directory(dir.path).parent.path;
              fileListHTML +=
                  '<li><a href="/files?path=${Uri.encodeComponent(parentDir)}">../ (Parent Directory)</a></li>';
            }

            for (var entity in entities) {
              String entityName = entity.path.split('/').last;
              if (entity is Directory) {
                fileListHTML +=
                    '<li><a href="/files?path=${Uri.encodeComponent(entity.path)}">$entityName/</a></li>';
              } else if (entity is File) {
                fileListHTML +=
                    '<li><a href="/download?file=${Uri.encodeComponent(entity.path)}">$entityName</a></li>';
              }
            }
            fileListHTML += '</ul>';
            request.response
              ..headers.contentType = ContentType.html
              ..write('<h1>Files and Folders</h1>$fileListHTML')
              ..close();
          } else {
            request.response
              ..statusCode = HttpStatus.notFound
              ..write('Directory not found')
              ..close();
          }
        } else if (request.uri.path == '/download') {
          String? filePath = request.uri.queryParameters['file'];
          if (filePath != null) {
            File file = File(filePath);
            if (await file.exists()) {
              String fileName = file.path.split('/').last;
              request.response.headers.add(
                  'Content-Disposition', 'attachment; filename="$fileName"');
              await request.response.addStream(file.openRead());
              await request.response.close();
            } else {
              request.response
                ..statusCode = HttpStatus.notFound
                ..write('File not found')
                ..close();
            }
          } else {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..write('No file specified')
              ..close();
          }
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Page not found')
            ..close();
        }
        // returning apis
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('File Sharing API via Web')),
      body: Center(child: Text(_status)),
    );
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }
}

void main() {
  runApp(MaterialApp(home: FileServerApp()));
}

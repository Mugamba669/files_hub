import 'dart:convert';
// import 'dart:developer';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../main.dart';

class FilesystemService {
  Future<void> handleFileRequests(HttpRequest request) async {
    try {
      if (request.uri.path == '/api/files') {
        await handleFileListRequest(request);
      } else if (request.uri.path == '/api/download') {
        await handleFileDownloadRequest(request);
      } else {
        throw HttpException('Endpoint not found', HttpStatus.notFound);
      }
    } catch (e) {
      await handleError(request.response, e);
    }
  }

  Future<void> handleFileListRequest(HttpRequest request) async {
    const String baseStoragePath = '/storage/emulated/0';
    String? requestedPath = request.uri.queryParameters['path'];
    String currentPath = requestedPath ?? baseStoragePath;

    currentPath = path.normalize(currentPath);
    if (!isPathSafe(baseStoragePath, currentPath)) {
      throw HttpException('Access denied: Invalid path', HttpStatus.forbidden);
    }

    Directory dir = Directory(currentPath);
    if (!await dir.exists()) {
      throw HttpException('Directory not found', HttpStatus.notFound);
    }

    List<FileSystemEntity> entities = await dir.list().toList();
    List<Map<String, dynamic>> fileList = [];

    Map<String, dynamic> pathInfo = {
      'current': currentPath,
      'isRoot': currentPath == baseStoragePath,
      'parent': path.dirname(currentPath),
    };

    if (currentPath != baseStoragePath) {
      String parentDir = path.dirname(currentPath);
      fileList.add({
        'name': '.. (Parent Directory)',
        'path': parentDir,
        'type': 'directory',
        'lastModified': null,
        'size': null,
      });
    }

    entities.sort((a, b) {
      bool aIsDir = a is Directory;
      bool bIsDir = b is Directory;
      if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
      return path.basename(a.path).compareTo(path.basename(b.path));
    });

    for (var entity in entities) {
      String entityName = path.basename(entity.path);
      if (!entityName.startsWith('.')) {
        FileStat stat = await entity.stat();
        if (entity is Directory) {
          fileList.add({
            'name': '$entityName/',
            'path': entity.path,
            'type': 'directory',
            'lastModified': stat.modified.toIso8601String(),
            'size': null,
          });
        } else if (entity is File) {
          fileList.add({
            'name': entityName,
            'path': entity.path,
            'type': 'file',
            'lastModified': stat.modified.toIso8601String(),
            'size': stat.size,
            'extension': path.extension(entityName).toLowerCase(),
          });
        }
      }
    }

    await sendJsonResponse(
        request.response,
        {
          'path': pathInfo,
          'items': fileList,
        },
        HttpStatus.ok);
  }

  Future<void> handleFileDownloadRequest(HttpRequest request) async {
    String? filePath = request.uri.queryParameters['file'];
    if (filePath == null) {
      throw HttpException('No file specified', HttpStatus.badRequest);
    }

    if (!isPathSafe('/storage/emulated/0', filePath)) {
      throw HttpException('Access denied: Invalid path', HttpStatus.forbidden);
    }

    File file = File(filePath);
    if (!await file.exists()) {
      throw HttpException('File not found', HttpStatus.notFound);
    }

    String fileName = path.basename(file.path);

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.set('Content-Type', 'application/octet-stream');
    request.response.headers
        .set('Content-Disposition', 'attachment; filename="$fileName"');

    await request.response.addStream(file.openRead());
    await request.response.close();
  }

  bool isPathSafe(String basePath, String checkPath) {
    var normalizedBase = path.normalize(basePath);
    var normalizedCheck = path.normalize(checkPath);
    return path.isWithin(normalizedBase, normalizedCheck);
  }

  Future<void> sendJsonResponse(
      HttpResponse response, Map<String, dynamic> data, int statusCode) async {
    if (!response.headers.chunkedTransferEncoding &&
        response.connectionInfo != null) {
      response.statusCode = statusCode;
      response.headers.contentType = ContentType.json;
    }
    response.write(json.encode(data));
    await response.close();
  }

  Future<void> handleError(HttpResponse response, dynamic error) async {
    if (!response.headers.chunkedTransferEncoding &&
        response.connectionInfo != null) {
      response.statusCode = error is HttpException
          ? error.statusCode
          : HttpStatus.internalServerError;
      response.headers.contentType = ContentType.json;
    }
    final errorMessage =
        error is HttpException ? error.message : error.toString();
    response.write(json.encode({'error': errorMessage}));
    await response.close();
  }
}

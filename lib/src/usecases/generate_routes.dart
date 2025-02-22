/// Route generation utility for Routefly package.
///
/// This script automates the process of generating routes for
/// a Flutter application using the Routefly package.

import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:meta/meta.dart';
import 'package:routefly/src/entities/main_file_entity.dart';
import 'package:routefly/src/exceptions/exceptions.dart';

import '../entities/route_representation.dart';

/// Constants for error messages visible for testing.
const errorMessages = (
  notFoundDirApp: 'AppDir not exists😢',
  noRoutesCreated: 'No routes created😒',
  noMainFile: 'No main file found😢. Please, add @Main in Widget that contain MaterialApp/CurpetinoApp',
);

/// Class to generate routes.
@immutable
class GenerateRoutes {
  /// Constructs a [GenerateRoutes] instance.
  const GenerateRoutes();

  /// Generates routes based on the given app directory and route file.
  Stream<ConsoleResponse> call(MainFileEntity mainFile) async* {
    final appDir = mainFile.appDir;
    final routeFile = File('${mainFile.noExtensionFilePath}.route.dart');
    final generateFile = File('${mainFile.noExtensionFilePath}.g.dart');

    if (!appDir.existsSync()) {
      yield ConsoleResponse(
        message: '${errorMessages.notFoundDirApp}: ${appDir.path}',
        type: ConsoleResponseType.error,
      );
      return;
    }

    if (routeFile.existsSync()) {
      routeFile.deleteSync();
    }

    if (generateFile.existsSync()) {
      generateFile.deleteSync();
    }

    final files = appDir
        .listSync(recursive: true) //
        .where(
          (file) =>
              file.path.endsWith('_${mainFile.pageSuffix}.dart') //
              ||
              file.path.endsWith('_layout.dart'),
        )
        .whereType<File>()
        .toList();

    if (files.isEmpty) {
      yield ConsoleResponse(
        message: errorMessages.noRoutesCreated,
      );
      return;
    }

    final entries = <RouteRepresentation>[];

    for (var i = 0; i < files.length; i++) {
      try {
        entries.add(RouteRepresentation.withAppDir(appDir, _capitalize(mainFile.pageSuffix), files[i], i, mainFile.pageSuffix));
      } on RouteflyException catch (e) {
        yield ConsoleResponse(
          message: e.message,
          type: ConsoleResponseType.warning,
        );
      }
    }

    _addParents(entries);
    final paths = entries.map((e) => e.path).toList();

    final routeContent = entries.map((e) => e.toString()).join(',\n  ');

    final generatedRouteContent = '''// GENERATED FILE. PLEASE DO NOT EDIT THIS FILE!!

${_generateImports(entries, routeFile.path)}

${_generateBuildFunction(entries)}

''';

    final generateFileContent = '''// GENERATED FILE. PLEASE DO NOT EDIT THIS FILE!!

part of '${mainFile.fileName}.dart';

List<RouteEntity> get routes => [
  $routeContent,
];

${generateRecords(paths)}

''';
    routeFile.writeAsStringSync(generatedRouteContent);
    Process.runSync('dart', ['format', routeFile.path]);
    yield ConsoleResponse(
      message: 'Generated! ${routeFile.path} 🚀',
      type: ConsoleResponseType.success,
    );

    generateFile.writeAsStringSync(generateFileContent);
    Process.runSync('dart', ['format', generateFile.path]);
    yield ConsoleResponse(
      message: 'Generated! ${generateFile.path} 🚀',
      type: ConsoleResponseType.success,
    );
  }

  /// Generates records for the given paths.
  @visibleForTesting
  String generateRecords(List<String> paths) {
    final mapPaths = _transformToMap(paths);
    final pathBuffer = StringBuffer();

    pathBuffer.writeln('const routePaths = (');
    pathBuffer.writeln(_generateRoutePaths(mapPaths));
    pathBuffer.writeln(');');

    return pathBuffer.toString();
  }

  String _generateRoutePaths(
    Map<String, dynamic> jsonMap, [
    String prefix = '',
    int depth = 1,
  ]) {
    final output = <String>[];

    if (jsonMap.isNotEmpty && !jsonMap.containsKey('path')) {
      output.add(
        "${_indentation(depth)}path: '${prefix.isEmpty ? '/' : prefix}',",
      );
    }

    jsonMap.forEach((key, value) {
      var newKey = key == 'path'
          ? 'path'
          : key //
              .replaceAll('[', r'$')
              .replaceAll(']', '');
      newKey = snackCaseToCamelCase(newKey);
      if (value.isEmpty) {
        output.add("${_indentation(depth)}$newKey: '$prefix/$key',");
      } else {
        final nested = _generateRoutePaths(value, '$prefix/$key', depth + 1);
        output.add(
          '${_indentation(depth)}$newKey: (\n$nested\n${_indentation(depth)}),',
        );
      }
    });

    return output.join('\n');
  }

  String _capitalize(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Converts snake_case to camelCase.
  String snackCaseToCamelCase(String key) {
    final segments = key.split('_');
    final firstSegment = segments.first;
    final restSegments = segments.sublist(1);
    final camelCaseSegments = restSegments.map((segment) => segment[0].toUpperCase() + segment.substring(1));
    return firstSegment + camelCaseSegments.join();
  }

  String _indentation(int depth) {
    return '  ' * depth;
  }

  Map<String, dynamic> _transformToMap(List<String> paths) {
    final resultMap = <String, dynamic>{};

    for (final path in paths) {
      final segments = path //
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList();

      var currentMap = resultMap;
      for (var i = 0; i < segments.length; i++) {
        final segment = segments[i];

        if (currentMap[segment] == null) {
          if (i == segments.length - 1) {
            currentMap[segment] = <String, dynamic>{};
          } else {
            currentMap[segment] = <String, dynamic>{};
            currentMap = currentMap[segment]!;
          }
        } else {
          currentMap = currentMap[segment];
        }
      }
    }

    return resultMap;
  }

  void _addParents(List<RouteRepresentation> routes) {
    final layoutPaths = routes //
        .where((route) => route.isLayout)
        .map((route) => route.path)
        .toList();

    for (var i = 0; i < routes.length; i++) {
      final route = routes[i];
      for (final layoutPath in layoutPaths) {
        var pathCondition = layoutPath;
        if (layoutPath != '/') {
          pathCondition = '$layoutPath/';
        }
        if (route.path != layoutPath //
            &&
            route.path.startsWith(pathCondition)) {
          routes[i] = route.copyWith(parent: layoutPath);
          break;
        }
      }
    }
  }

  String _generateImports(List<RouteRepresentation> entries, String mainFilePath) {
    final exports = entries.map((e) => e.getImport(mainFilePath)).toList();
    exports.sort((a, b) => a.compareTo(b));
    final exportsText = exports.join('\n');
    return '''import 'package:flutter/widgets.dart';
import 'package:routefly/routefly.dart';

$exportsText
''';
  }

  String _generateBuildFunction(List<RouteRepresentation> entries) {
    final funcs = entries.map((e) => e.routeBuilderFunction).toList();
    final funcText = funcs.join('\n');
    return funcText;
  }
}

/// Class to represent console response.
@immutable
class ConsoleResponse {
  /// Message to be displayed.
  final String message;

  /// Type of the message.
  final ConsoleResponseType type;

  /// Constructs a [ConsoleResponse] instance.
  const ConsoleResponse({
    required this.message,
    this.type = ConsoleResponseType.info,
  });

  /// Logs the console response.
  void log() {
    AnsiPen? pen;

    if (type == ConsoleResponseType.info) {
      pen = AnsiPen()
        ..reset()
        ..xterm(13);
    } else if (type == ConsoleResponseType.success) {
      pen = AnsiPen()
        ..reset()
        ..xterm(10);
    } else if (type == ConsoleResponseType.warning) {
      pen = AnsiPen()
        ..reset()
        ..xterm(3);
    } else if (type == ConsoleResponseType.error) {
      pen = AnsiPen()
        ..reset()
        ..xterm(9);
    }

    print(pen?.call(message));
  }

  @override
  bool operator ==(covariant ConsoleResponse other) {
    if (identical(this, other)) return true;

    return other.message == message && other.type == type;
  }

  @override
  int get hashCode => message.hashCode ^ type.hashCode;

  @override
  String toString() => 'ConsoleResponse(message: $message, type: $type)';
}

/// Enum for types of console responses.
/// Used to color the console output.
enum ConsoleResponseType {
  /// Error type.
  error,

  /// Success type.
  success,

  /// Info type.
  info,

  /// Warning type.
  warning,
}

import 'package:flutter/foundation.dart';
import 'package:lcinstaller/models/app.dart';
import 'package:lcinstaller/database_helper.dart';
import 'package:lcinstaller/models/source.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lcinstaller/utils/formatters.dart';

class AppsNotifier extends ChangeNotifier {
  List<AppWithSource> _apps = [];
  Map<String, AppWithSource> _appMap = {};
  bool _isLoading = false;

  List<AppWithSource> get apps => _apps;
  Map<String, AppWithSource> get appMap => _appMap;
  bool get isLoading => _isLoading;

  Future<void> fetchApps() async {
    _isLoading = true;
    notifyListeners();
    try {
      final sources = await DatabaseHelper().getSources();
      final sourceObjects = sources.map((e) => Source.fromMap(e)).toList();

      List<AppWithSource> allApps = [];

      for (final source in sourceObjects) {
        final sourceApps = await _fetchAppsFromSource(source);
        allApps.addAll(sourceApps);
      }

      _apps = allApps;
      _appMap = {
        for (var app in allApps) "${app.bundleIdentifier}_${app.sourceId}": app,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching apps: $e');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<List<AppWithSource>> _fetchAppsFromSource(Source source) async {
    try {
      final response = await http.get(Uri.parse(source.sourceURL));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['apps'] is List) {
          final apps = (data['apps'] as List).map((appData) {
            return _parseAppFromData(appData, source);
          }).toList();
          return apps;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching apps from ${source.sourceURL}: $e');
      }
    }
    return [];
  }

  AppWithSource _parseAppFromData(Map<String, dynamic> appData, Source source) {
    final List<Versions> versions = [];

    if (appData['versions'] is List &&
        (appData['versions'] as List).isNotEmpty) {
      for (var v in appData['versions']) {
        if (v is Map<String, dynamic>) {
          versions.add(
            Versions(
              version: v['version'] ?? '',
              date: v['date'] != null
                  ? formatDateWithLeadingZeros(v['date'])
                  : '',
              size: v['size'] ?? 0,
              downloadURL: v['downloadURL'] ?? '',
              localizedDescription: v['localizedDescription'] ?? '',
            ),
          );
        }
      }
    } else if (appData['version'] != null) {
      versions.add(
        Versions(
          version: appData['version'] ?? '',
          date: appData['versionDate'] != null
              ? formatDateWithLeadingZeros(appData['versionDate'])
              : '',
          size: appData['size'] ?? 0,
          downloadURL: appData['downloadURL'] ?? '',
          localizedDescription:
              appData['versionDescription'] ??
              appData['localizedDescription'] ??
              '',
        ),
      );
    }

    List<Screenshots> screenshots = [];
    final appScreenshots = appData['screenshots'] ?? appData['screenshotURLs'];
    if (appScreenshots is List) {
      screenshots = (appScreenshots).map((s) {
        if (s is String) {
          return Screenshots.fromMap({
            'imageURL': s,
            'height': '0',
            'width': '0',
          });
        } else if (s is Map<String, dynamic>) {
          return Screenshots.fromMap(s);
        } else {
          return Screenshots(imageURL: '', height: '0', width: '0');
        }
      }).toList();
    }

    return AppWithSource(
      sourceId: source.id!,
      name: appData['name'] ?? '',
      bundleIdentifier: appData['bundleIdentifier'] ?? '',
      developerName: appData['developerName'] ?? '',
      subTitle: appData['subtitle'] ?? '',
      versions: versions,
      localizedDescription: appData['localizedDescription'] ?? '',
      iconURL: appData['iconURL'] ?? '',
      tintColor: appData['tintColor'] ?? '',
      screenshots: screenshots,
      source: source,
    );
  }

  Future<void> refreshApps() async {
    await fetchApps();
  }
}

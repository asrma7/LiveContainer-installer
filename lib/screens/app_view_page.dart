import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lcinstaller/models/app.dart';
import 'package:lcinstaller/notifiers/installed_apps_notifier.dart';
import 'package:lcinstaller/screens/version_history_page.dart';
import 'package:lcinstaller/utils/formatters.dart';
import 'package:lcinstaller/utils/utils.dart';
import 'package:lcinstaller/widgets/show_more_text.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class AppViewPage extends StatelessWidget {
  final AppWithSource app;

  const AppViewPage({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Consumer<InstalledAppsNotifier>(
      builder: (context, installedAppsNotifier, child) {
        final isInstalled = installedAppsNotifier.appMap.containsKey(
          "${app.bundleIdentifier}_${app.sourceId}",
        );
        final isUpdate =
            isInstalled &&
            safeParseDate(app.latestVersion.date).isAfter(
              safeParseDate(
                installedAppsNotifier
                    .appMap["${app.bundleIdentifier}_${app.sourceId}"]!
                    .versionDate,
              ),
            );
        return CupertinoPageScaffold(
          resizeToAvoidBottomInset: true,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: Colors.black.withAlpha(100),
            middle: Text(app.source.name),
            trailing: IconButton(
              icon: const Icon(Ionicons.link_outline),
              onPressed: () {
                final url = Uri.parse(app.source.website);
                url_launcher.launchUrl(url);
              },
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Image.network(
                      app.source.iconURL,
                      width: double.infinity,
                      height: 250.0,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 250.0,
                        color: Colors.grey,
                        child: const Icon(
                          CupertinoIcons.photo,
                          color: CupertinoColors.white,
                          size: 60.0,
                        ),
                      ),
                    ),
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          width: double.infinity,
                          height: 250.0,
                          color: Colors.black.withAlpha(90),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: Colors.grey.withAlpha(90),
                            width: 2.0,
                          ),
                        ),
                        child: Image.network(
                          app.iconURL,
                          width: 80.0,
                          height: 80.0,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 80.0,
                            height: 80.0,
                            color: Colors.grey,
                            child: const Icon(
                              CupertinoIcons.photo,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.name,
                                style: const TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                app.developerName.isNotEmpty
                                    ? 'By ${app.developerName}'
                                    : "Unknown Developer",
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.grey,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  installInLiveContainer(context, app);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Ionicons.cloud_download_outline),
                                    SizedBox(width: 8.0),
                                    Text(
                                      isUpdate
                                          ? 'Update'
                                          : isInstalled
                                          ? 'Reinstall'
                                          : 'Install',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: Colors.grey.withAlpha(90),
                  thickness: 1.0,
                  height: 40.0,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        height: 40.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color: Colors.blue.shade800,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Ionicons.pricetag_outline,
                              size: 16.0,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              app.versions.isNotEmpty
                                  ? app.versions.first.version
                                  : 'N/A',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        height: 40.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color: Colors.white12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Ionicons.archive_outline, size: 16.0),
                            const SizedBox(width: 8.0),
                            Text(
                              app.latestVersion.size > 0
                                  ? formatFileSize(app.latestVersion.size)
                                  : 'N/A',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (app.subTitle.isNotEmpty) ...[
                  Divider(
                    color: Colors.grey.withAlpha(90),
                    thickness: 1.0,
                    height: 40.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ShowMoreText(
                      app.subTitle,
                      style: TextStyle(fontSize: 16.0),
                      maxLines: 2,
                    ),
                  ),
                ],
                if (app.screenshots.isNotEmpty) ...[
                  Divider(
                    color: Colors.grey.withAlpha(90),
                    thickness: 1.0,
                    height: 40.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "Screenshots",
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  SizedBox(
                    height: 400.0,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: app.screenshots.length,
                      itemBuilder: (context, index) {
                        final screenshot = app.screenshots[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.0),
                            border: Border.all(color: Colors.grey, width: 1.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15.0),
                            child: Image.network(
                              screenshot.imageURL,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 80.0,
                                height: 80.0,
                                color: Colors.grey,
                                child: const Icon(
                                  CupertinoIcons.photo,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                Divider(
                  color: Colors.grey.withAlpha(90),
                  thickness: 1.0,
                  height: 40.0,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "What's New",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Version ${app.latestVersion.version}",
                        style: TextStyle(fontSize: 16.0),
                      ),
                      Text(
                        timeAgo(app.latestVersion.date),
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ShowMoreText(
                    app.latestVersion.localizedDescription.isNotEmpty
                        ? app.latestVersion.localizedDescription
                        : "No description available.",
                    maxLines: 5,
                  ),
                ),
                if (app.versions.length > 1)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => VersionHistoryPage(app: app),
                        ),
                      );
                    },
                    child: Text("Version History"),
                  ),
                Divider(
                  color: Colors.grey.withAlpha(90),
                  thickness: 1.0,
                  height: 40.0,
                ),
                if (app.localizedDescription.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ShowMoreText(
                      app.localizedDescription.isNotEmpty
                          ? app.localizedDescription
                          : "No description available.",
                      maxLines: 5,
                    ),
                  ),
                ],
                Divider(
                  color: Colors.grey.withAlpha(90),
                  thickness: 1.0,
                  height: 40.0,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Information",
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text("Source"), Text(app.source.name)],
                      ),
                      Divider(
                        color: Colors.grey.withAlpha(90),
                        thickness: 1.0,
                        height: 20.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Developer"),
                          Text(
                            app.developerName.isNotEmpty
                                ? app.developerName
                                : "N/A",
                          ),
                        ],
                      ),
                      Divider(
                        color: Colors.grey.withAlpha(90),
                        thickness: 1.0,
                        height: 20.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Size"),
                          Text(
                            app.latestVersion.size > 0
                                ? formatFileSize(app.latestVersion.size)
                                : "N/A",
                          ),
                        ],
                      ),
                      Divider(
                        color: Colors.grey.withAlpha(90),
                        thickness: 1.0,
                        height: 20.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Version"),
                          Text(
                            app.latestVersion.version.isNotEmpty
                                ? app.latestVersion.version
                                : "N/A",
                          ),
                        ],
                      ),
                      Divider(
                        color: Colors.grey.withAlpha(90),
                        thickness: 1.0,
                        height: 20.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Updated"),
                          Text(
                            app.latestVersion.date.isNotEmpty
                                ? formatVersionDate(app.latestVersion.date)
                                : "N/A",
                          ),
                        ],
                      ),
                      Divider(
                        color: Colors.grey.withAlpha(90),
                        thickness: 1.0,
                        height: 20.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Identifier"),
                          Text(
                            app.bundleIdentifier.isNotEmpty
                                ? app.bundleIdentifier
                                : "N/A",
                          ),
                        ],
                      ),
                      Divider(
                        color: Colors.grey.withAlpha(90),
                        thickness: 1.0,
                        height: 20.0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

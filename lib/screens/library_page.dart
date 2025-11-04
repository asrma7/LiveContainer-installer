import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lcinstaller/database_helper.dart';
import 'package:lcinstaller/notifiers/apps_notifier.dart';
import 'package:lcinstaller/notifiers/installed_apps_notifier.dart';
import 'package:lcinstaller/screens/app_view_page.dart';
import 'package:lcinstaller/utils/formatters.dart';
import 'package:lcinstaller/widgets/header_delegate.dart';
import 'package:lcinstaller/widgets/search_bar_delegate.dart';
import 'package:provider/provider.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Consumer2<InstalledAppsNotifier, AppsNotifier>(
      builder: (context, installedAppsNotifier, appsNotifier, child) {
        final installedApps = installedAppsNotifier.apps;
        final isLoading = installedAppsNotifier.isLoading;
        final appMap = appsNotifier.appMap;
        final allAppsLoading = appsNotifier.isLoading;

        final updatesAvailable = installedApps.where((installedApp) {
          final key =
              "${installedApp.bundleIdentifier}_${installedApp.sourceId}";
          final app = appMap[key];
          if (app == null) return false;
          return safeParseDate(
            app.latestVersion.date,
          ).isAfter(safeParseDate(installedApp.versionDate));
        }).toList();

        final filteredApps = searchQuery.isEmpty
            ? installedApps
            : installedApps
                  .where(
                    (app) =>
                        app.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        app.bundleIdentifier.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

        final filteredUpdates = searchQuery.isEmpty
            ? updatesAvailable
            : updatesAvailable
                  .where(
                    (app) =>
                        app.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        app.bundleIdentifier.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

        return CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text("Library"),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          title: const Text("Not seeing installed apps?"),
                          content: const Text(
                            "Install app from LcInstaller to reflect installed apps here.",
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text("Ok"),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Icon(
                    CupertinoIcons.info_circle,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
                border: null,
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await installedAppsNotifier.refreshInstalledApps();
                  await appsNotifier.fetchApps();
                },
              ),

              SliverPersistentHeader(
                pinned: true,
                delegate: SearchBarDelegate(
                  onChanged: (query) {
                    setState(() {
                      searchQuery = query;
                    });
                  },
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: HeaderDelegate(
                  minHeight: 45,
                  maxHeight: 45,
                  headerWidget: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Updates Available',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        height: 20,
                        width: 20,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey5.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            updatesAvailable.length.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Updates Available Section
              if (filteredUpdates.isEmpty && !isLoading && !allAppsLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      searchQuery.isEmpty
                          ? 'All your apps are up to date.'
                          : 'No updates found for "$searchQuery".',
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (filteredUpdates.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final app = filteredUpdates[index];
                    final fullApp =
                        appMap["${app.bundleIdentifier}_${app.sourceId}"];
                    return CupertinoButton(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                              top: (index == filteredUpdates.length - 1)
                                  ? 0
                                  : 14,
                              left: 16,
                              right: 12,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                app.iconURL,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                  width: 60,
                                  height: 60,
                                  color: CupertinoColors.systemGrey,
                                  child: const Icon(
                                    CupertinoIcons.photo,
                                    color: CupertinoColors.white,
                                  ),
                              ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(
                                  color: CupertinoColors.systemGrey5
                                      .resolveFrom(context),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fullApp != null
                                                  ? '${app.name} (${fullApp.latestVersion.version})'
                                                  : app.name,
                                            ),
                                            if (fullApp != null)
                                              Text(
                                                fullApp.source.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: CupertinoColors
                                                      .systemGrey,
                                                ),
                                              ),
                                            Text(
                                              app.bundleIdentifier,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color:
                                                    CupertinoColors.systemGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        CupertinoIcons.chevron_forward,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ],
                                  ),
                                ),
                                if (index == filteredUpdates.length - 1)
                                  Divider(
                                    color: CupertinoColors.systemGrey5
                                        .resolveFrom(context),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => AppViewPage(app: fullApp!),
                        ),
                      ),
                    );
                  }, childCount: filteredUpdates.length),
                ),
              SliverPersistentHeader(
                pinned: true,
                delegate: HeaderDelegate(
                  minHeight: 45,
                  maxHeight: 45,
                  headerWidget: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Installed Apps',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        height: 20,
                        width: 20,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey5.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            filteredApps.length.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isLoading || allAppsLoading)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (filteredApps.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      searchQuery.isEmpty
                          ? 'No installed apps found.'
                          : 'No installed apps found for "$searchQuery".',
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(
                    bottom: kBottomNavigationBarHeight + 20.0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final app = filteredApps[index];
                      final fullApp =
                          appMap["${app.bundleIdentifier}_${app.sourceId}"];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPress: () {
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) => CupertinoActionSheet(
                              title: Text(app.name),
                              message: const Text('Choose an action'),
                              actions: [
                                CupertinoActionSheetAction(
                                  isDestructiveAction: true,
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await DatabaseHelper().deleteInstalledApp(
                                      app.id!,
                                    );
                                    if (context.mounted) {
                                      final provider =
                                          Provider.of<InstalledAppsNotifier>(
                                            context,
                                            listen: false,
                                          );
                                      await provider.refreshInstalledApps();
                                      if (context.mounted) {
                                        showCupertinoDialog(
                                          context: context,
                                          builder: (context) {
                                            return CupertinoAlertDialog(
                                              title: const Text('App Deleted'),
                                              content: Text(
                                                '${app.name} has been removed from your library '
                                                '(you can still find it in LiveContainer).',
                                              ),
                                              actions: [
                                                CupertinoDialogAction(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ),
                          );
                        },
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) =>
                                    AppViewPage(app: fullApp!),
                              ),
                            );
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(
                                  top: (index == filteredApps.length - 1)
                                      ? 0
                                      : 14,
                                  left: 16,
                                  right: 12,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    app.iconURL,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                        width: 60,
                                        height: 60,
                                        color: CupertinoColors.systemGrey,
                                        child: const Icon(
                                          CupertinoIcons.photo,
                                          color: CupertinoColors.white,
                                        ),
                                      ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(
                                      color: CupertinoColors.systemGrey5
                                          .resolveFrom(context),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12.0,
                                        horizontal: 16.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${app.name} (${app.version})',
                                                ),
                                                if (fullApp != null)
                                                  Text(
                                                    fullApp.source.name,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: CupertinoColors
                                                          .systemGrey,
                                                    ),
                                                  ),
                                                Text(
                                                  app.bundleIdentifier,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: CupertinoColors
                                                        .systemGrey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            CupertinoIcons.chevron_forward,
                                            color: CupertinoColors.systemGrey,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index == filteredApps.length - 1)
                                      Divider(
                                        color: CupertinoColors.systemGrey5
                                            .resolveFrom(context),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: filteredApps.length),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

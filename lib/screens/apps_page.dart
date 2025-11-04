import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lcinstaller/models/source.dart';
import 'package:lcinstaller/screens/app_view_page.dart';
import 'package:lcinstaller/utils/utils.dart';
import 'package:lcinstaller/widgets/header_delegate.dart';
import 'package:lcinstaller/widgets/search_bar_delegate.dart';
import 'package:provider/provider.dart';
import 'package:lcinstaller/notifiers/apps_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppsPage extends StatefulWidget {
  final Source? source;
  const AppsPage({super.key, this.source});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  late SharedPreferences prefs;
  String searchQuery = "";
  late String sortType;
  late bool sortAscending;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    fetchPreferences();
  }

  void fetchPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      sortType = prefs.getString('sort_type') ?? "default";
      sortAscending = prefs.getBool('sort_ascending') ?? false;
      isReady = true;
    });
  }

  void setSortPreferences(String sortType, bool sortAscending) async {
    await prefs.setString('sort_type', sortType);
    await prefs.setBool('sort_ascending', sortAscending);
    setState(() {
      this.sortType = sortType;
      this.sortAscending = sortAscending;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return Consumer<AppsNotifier>(
      builder: (context, appsNotifier, child) {
        final apps = widget.source == null
            ? appsNotifier.apps
            : appsNotifier.apps
                  .where((app) => app.sourceId == widget.source!.id)
                  .toList();
        final isLoading = appsNotifier.isLoading;
        final filteredApps = searchQuery.isEmpty
            ? apps
            : apps
                  .where(
                    (app) =>
                        app.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        app.localizedDescription.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

        final sortedApps = filteredApps
          ..sort((a, b) {
            int comparison = 0;
            switch (sortType) {
              case "name":
                comparison = a.name.compareTo(b.name);
                break;
              case "date":
              case "default":
                comparison = a.latestVersion.date.compareTo(
                  b.latestVersion.date,
                );
                break;
              default:
                comparison = 0;
            }
            return sortAscending ? comparison : -comparison;
          });

        return CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(
                  widget.source == null ? 'All Apps' : widget.source!.name,
                ),
                trailing: IconButton(
                  onPressed: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                        title: const Text("Filter by"),
                        actions: [
                          _buildSortAction("default"),
                          _buildSortAction("name"),
                          _buildSortAction("date"),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(
                    Ionicons.filter_outline,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
                border: null,
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await appsNotifier.refreshApps();
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
              SliverToBoxAdapter(child: const SizedBox(height: 30.0)),
              SliverPersistentHeader(
                pinned: true,
                delegate: HeaderDelegate(
                  headerWidget: Text(
                    '${sortedApps.length} Apps',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Divider(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                ),
              ),
              isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.only(
                        bottom: kBottomNavigationBarHeight + 20.0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final app = sortedApps[index];
                          return CupertinoButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => AppViewPage(app: app),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(
                                    left: 16.0,
                                    right: 12.0,
                                    bottom: 16.0,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          app.iconURL,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                width: 60,
                                                height: 60,
                                                color:
                                                    CupertinoColors.systemGrey,
                                                child: const Icon(
                                                  CupertinoIcons.photo,
                                                  color: CupertinoColors.white,
                                                ),
                                              ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -6,
                                        right: -6,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            34,
                                          ),
                                          child: Image.network(
                                            app.source.iconURL,
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Container(
                                                  width: 20,
                                                  height: 20,
                                                  color: CupertinoColors
                                                      .systemGrey,
                                                  child: const Icon(
                                                    CupertinoIcons.photo,
                                                    color:
                                                        CupertinoColors.white,
                                                    size: 12,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(app.name),
                                                Text(
                                                  "Version: ${app.latestVersion.version}",
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: CupertinoColors
                                                        .systemGrey,
                                                  ),
                                                ),
                                                Text(
                                                  app.localizedDescription,
                                                  maxLines: 2,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: CupertinoColors
                                                        .systemGrey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () =>
                                                  installInLiveContainer(
                                                    context,
                                                    app,
                                                  ),
                                              child: Icon(
                                                Ionicons.download_outline,
                                                size: 24,
                                                color:
                                                    CupertinoColors.activeBlue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        color: CupertinoColors.systemGrey5
                                            .resolveFrom(context),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }, childCount: sortedApps.length),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  CupertinoContextMenuAction _buildSortAction(String type) {
    return CupertinoContextMenuAction(
      onPressed: () {
        setSortPreferences(type, sortType != type || !sortAscending);
        Navigator.pop(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(type[0].toUpperCase() + type.substring(1)),
          if (sortType == type)
            Icon(
              sortAscending
                  ? Ionicons.chevron_up_circle_outline
                  : Ionicons.chevron_down_circle_outline,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
        ],
      ),
    );
  }
}

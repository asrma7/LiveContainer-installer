import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lcinstaller/screens/add_source_page.dart';
import 'package:lcinstaller/models/source.dart';
import 'package:lcinstaller/database_helper.dart';
import 'package:lcinstaller/screens/apps_page.dart';
import 'package:lcinstaller/widgets/header_delegate.dart';
import 'package:lcinstaller/widgets/search_bar_delegate.dart';
import 'package:provider/provider.dart';
import 'package:lcinstaller/notifiers/apps_notifier.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SourcesPage extends StatefulWidget {
  const SourcesPage({super.key});

  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  List<Source> sources = [];
  bool isLoading = true;
  bool isAddingSource = false;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchSources();
  }

  Future<void> fetchSources() async {
    final dbSources = await DatabaseHelper().getSources();
    setState(() {
      sources = dbSources.map((e) => Source.fromMap(e)).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredSources = searchQuery.isEmpty
        ? sources
        : sources
              .where(
                (source) =>
                    source.name.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    source.sourceURL.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text("Sources"),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                List<String>? urls = await Navigator.push(
                  context,
                  CupertinoSheetRoute(
                    builder: (context) => const AddSourcePage(),
                  ),
                );
                if (urls == null || urls.isEmpty) return;
                var importCount = 0;
                for (final url in urls) {
                  if (url.isEmpty) continue;
                  final alreadyExists = sources.any((s) => s.sourceURL == url);
                  if (alreadyExists) {
                    if (context.mounted) {
                      showCupertinoDialog(
                        context: context,
                        builder: (_) => CupertinoAlertDialog(
                          title: const Text('Duplicate Source'),
                          content: const Text('This source already exists.'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    }
                    return;
                  }
                  setState(() {
                    isLoading = true;
                    isAddingSource = true;
                  });
                  try {
                    final response = await http.get(Uri.parse(url));
                    if (response.statusCode == 200) {
                      final data = json.decode(response.body);

                      if (data['sourceURL'] == null) {
                        data['sourceURL'] = url;
                      }

                      if (data['name'] == null) {
                        throw Exception("Missing required source field: name");
                      }

                      final newSource = Source(
                        name: data['name'],
                        identifier: data['identifier'] ?? data['sourceURL'],
                        subtitle: data['subtitle'] ?? '',
                        sourceURL: url,
                        iconURL:
                            data['iconURL'] ??
                            data['apps']?[0]?['iconURL'] ??
                            '',
                        website: data['website'] ?? '',
                      );

                      await DatabaseHelper().insertSource(newSource.toMap());
                      importCount += 1;

                      if (context.mounted) {
                        try {
                          final provider = Provider.of<AppsNotifier>(
                            context,
                            listen: false,
                          );
                          await provider.refreshApps();
                        } catch (_) {}
                      }
                    } else {
                      if (context.mounted) {
                        showCupertinoDialog(
                          context: context,
                          builder: (_) => CupertinoAlertDialog(
                            title: const Text('Error'),
                            content: Text(
                              'Failed to fetch source data (status ${response.statusCode})',
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showCupertinoDialog(
                        context: context,
                        builder: (_) => CupertinoAlertDialog(
                          title: const Text('Error'),
                          content: Text(
                            'Failed to fetch or parse source data.\n$e',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    }
                  } finally {
                    await fetchSources();
                    setState(() {
                      isAddingSource = false;
                    });
                  }
                }
                if (importCount > 0 && context.mounted) {
                  showCupertinoDialog(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: const Text('Import Complete'),
                      content: Text(
                        'Successfully imported $importCount source${importCount > 1 ? 's' : ''}.',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: isAddingSource
                  ? const CupertinoActivityIndicator()
                  : const Icon(
                      CupertinoIcons.add,
                      color: CupertinoColors.activeBlue,
                    ),
            ),
            border: null,
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

          SliverToBoxAdapter(
            child: CupertinoButton(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    margin: const EdgeInsets.only(left: 16, right: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Ionicons.planet_outline, size: 40),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          color: CupertinoColors.systemGrey5.resolveFrom(
                            context,
                          ),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('All Repositories'),
                                    Text(
                                      'See all apps from your sources',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: CupertinoColors.systemGrey,
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
                        Divider(
                          color: CupertinoColors.systemGrey5.resolveFrom(
                            context,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => AppsPage()),
              ),
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
                    'Repositories',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        filteredSources.length.toString(),
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
                      final source = filteredSources[index];
                      return GestureDetector(
                        behavior: HitTestBehavior
                            .opaque, // ensures empty space is tappable
                        onLongPress: () {
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) => CupertinoActionSheet(
                              title: Text(source.name),
                              message: const Text('Choose an action'),
                              actions: [
                                CupertinoActionSheetAction(
                                  isDestructiveAction: true,
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await DatabaseHelper().deleteSource(
                                      source.id!,
                                    );
                                    if (context.mounted) {
                                      final provider =
                                          Provider.of<AppsNotifier>(
                                            context,
                                            listen: false,
                                          );
                                      await provider.refreshApps();
                                      await fetchSources();
                                    }
                                  },
                                  child: const Text('Delete'),
                                ),
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Clipboard.setData(
                                      ClipboardData(text: source.sourceURL),
                                    );
                                    showCupertinoDialog(
                                      context: context,
                                      builder: (dialogContext) =>
                                          CupertinoAlertDialog(
                                            title: const Text('Copied'),
                                            content: const Text(
                                              'Source URL copied to clipboard.',
                                            ),
                                            actions: [
                                              CupertinoDialogAction(
                                                child: const Text('OK'),
                                                onPressed: () => Navigator.pop(
                                                  dialogContext,
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                  child: const Text('Copy URL'),
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
                          padding: EdgeInsets.zero, // remove default padding
                          onPressed: () => Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => AppsPage(source: source),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(
                                  top: (index == filteredSources.length - 1)
                                      ? 0
                                      : 14,
                                  left: 16,
                                  right: 12,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    source.iconURL,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 60,
                                      height: 60,
                                      color: CupertinoColors
                                          .systemGrey5
                                          .resolveFrom(context),
                                      child: Icon(
                                        Ionicons.planet_outline,
                                        size: 40,
                                        color: CupertinoColors.systemGrey3
                                            .resolveFrom(context),
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
                                                Text(source.name),
                                                Text(
                                                  source.subtitle.isNotEmpty
                                                      ? source.subtitle
                                                      : (source
                                                                    .description
                                                                    ?.isNotEmpty ==
                                                                true
                                                            ? source
                                                                  .description!
                                                            : source.sourceURL),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                    if (index == filteredSources.length - 1)
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
                    }, childCount: filteredSources.length),
                  ),
                ),
        ],
      ),
    );
  }
}

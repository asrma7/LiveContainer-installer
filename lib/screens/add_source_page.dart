import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class AddSourcePage extends StatefulWidget {
  const AddSourcePage({super.key});

  @override
  State<AddSourcePage> createState() => _AddSourcePageState();
}

class _AddSourcePageState extends State<AddSourcePage> {
  final TextEditingController _urlController = TextEditingController();
  bool isLoading = true;

  List<Map<String, String>> featuredRepos = [];
  Future<void> fetchFeaturedRepos() async {
    final response = await http.get(Uri.parse(
        "https://raw.githubusercontent.com/asrma7/livecontainer-installer/main/repos.json"));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        featuredRepos = data
            .map((repo) => {
                  "name": repo["name"] as String,
                  "sourceURL": repo["sourceURL"] as String,
                  "iconUrl": repo["iconUrl"] as String,
                })
            .toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFeaturedRepos();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            "Add Source",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          border: null,
        ),
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          "Add Source",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            // Save logic for manual source
            final url = _urlController.text.trim();
            if (url.isNotEmpty) {
              Navigator.pop(context, url);
            } else {
              Navigator.pop(context);
            }
          },
          child: const Text("Save"),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.xmark),
        ),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Source URL",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _urlController,
              placeholder: "Enter Source URL",
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            const SizedBox(height: 4),
            const Text(
              "The only supported repositories are AltStore repositories.",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Import/Export
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () {
                      // Import logic
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(CupertinoIcons.arrow_down_circle),
                        SizedBox(width: 8),
                        Text("Import"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () {
                      // Export logic
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(CupertinoIcons.arrow_up_circle),
                        SizedBox(width: 8),
                        Text("Export"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Supports importing from KravaSign/MapleSign and ESign.",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 24),

            const Text(
              "Featured",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),

            // Featured repos list
            ...featuredRepos.map((repo) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: CupertinoListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      repo["iconUrl"]!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(repo["name"]!),
                  subtitle: Text(
                    repo["sourceURL"]!,
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    onPressed: () {
                      Navigator.pop(context, repo["sourceURL"]);
                    },
                    child: const Text("Add"),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

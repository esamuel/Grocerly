import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';

class ItemsScreen extends ConsumerWidget {
  const ItemsScreen({super.key, required this.listId});
  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(watchItemsProvider(listId));
    final textCtrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: Column(
        children: [
          Expanded(
            child: items.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return const Center(child: Text('No items yet. Add something below.'));
                }
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final it = rows[i];
                    return CheckboxListTile(
                      value: it.isChecked,
                      onChanged: (v) => ref.read(listItemRepoProvider).toggleChecked(
                            itemId: it.id,
                            isChecked: v ?? false,
                          ),
                      title: Text(it.name),
                      subtitle: it.note != null && it.note!.isNotEmpty ? Text(it.note!) : null,
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref.read(listItemRepoProvider).removeItem(itemId: it.id),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textCtrl,
                    decoration: const InputDecoration(hintText: 'Add item (e.g., Bananas)'),
                    onSubmitted: (v) async {
                      final name = v.trim();
                      if (name.isEmpty) return;
                      await ref.read(listItemRepoProvider).addItem(listId: listId, name: name);
                      textCtrl.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final name = textCtrl.text.trim();
                    if (name.isEmpty) return;
                    await ref.read(listItemRepoProvider).addItem(listId: listId, name: name);
                    textCtrl.clear();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


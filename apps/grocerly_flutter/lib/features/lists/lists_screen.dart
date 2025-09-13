import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_safe.dart';
import '../../auth/auth_screen.dart';
import 'providers.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For MVP, assume one space per user: use user id as pseudo space id.
    final user = supaClientOrNull?.auth.currentUser;
    final spaceId = user?.id ?? '_public';
    final listsStream = ref.watch(watchListsProvider(spaceId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Lists'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (r) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: listsStream.when(
        data: (lists) {
          if (lists.isEmpty) {
            return const Center(child: Text('No lists yet. Tap + to create.'));
          }
          return ListView.separated(
            itemCount: lists.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final l = lists[i];
              return ListTile(
                title: Text(l.name),
                subtitle: l.currency != null ? Text(l.currency!) : null,
                onTap: () => context.push('/lists/${l.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await _prompt(context, title: 'New list name');
          if (name == null || name.trim().isEmpty) return;
          await ref.read(listRepoProvider).createList(spaceId: spaceId, name: name.trim());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<String?> _prompt(BuildContext context, {required String title}) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok == true) return ctrl.text;
    return null;
  }
}

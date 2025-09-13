import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocerly_data/repositories/list_repository.dart' as data;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_safe.dart';

// Simple in-memory store for guest mode (no Supabase).
class InMemoryStore {
  static final InMemoryStore _i = InMemoryStore._();
  factory InMemoryStore() => _i;
  InMemoryStore._();
  final Map<String, List<data.ListSummary>> listsBySpace = {};
}

final listRepoProvider = Provider<data.ListRepository>((ref) {
  if (supaClientOrNull == null) return InMemoryListRepository();
  return SupabaseListRepository();
});

final watchListsProvider = StreamProvider.family.autoDispose(
  (ref, String spaceId) => ref.watch(listRepoProvider).watchLists(spaceId: spaceId),
);

class SupabaseListRepository implements data.ListRepository {
  SupabaseClient? get _client => supaClientOrNull;

  @override
  Future<String> createList({required String spaceId, required String name, String? currency}) async {
    // If no Supabase configured, return a fake id to keep UI flowing.
    if (_client == null) return 'local_${DateTime.now().millisecondsSinceEpoch}';
    final res = await _client!.from('lists').insert({
      'space_id': spaceId,
      'name': name,
      'currency': currency,
    }).select('id').single();
    return res['id'] as String;
  }

  @override
  Future<void> deleteList({required String listId}) async {
    if (_client == null) return;
    await _client!.from('lists').delete().eq('id', listId);
  }

  @override
  Future<void> renameList({required String listId, required String name}) async {
    if (_client == null) return;
    await _client!.from('lists').update({'name': name}).eq('id', listId);
  }

  @override
  Stream<List<data.ListSummary>> watchLists({required String spaceId}) {
    if (_client == null) {
      return Stream.value(const <data.ListSummary>[]);
    }
    final stream = _client!
        .from('lists')
        .stream(primaryKey: ['id'])
        .eq('space_id', spaceId);
    return stream.map((rows) {
      final list = (rows as List<dynamic>)
          .map((r) => data.ListSummary(
                id: r['id'] as String,
                name: r['name'] as String,
                currency: r['currency'] as String?,
              ))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }
}

class InMemoryListRepository implements data.ListRepository {
  final _store = InMemoryStore();

  @override
  Future<String> createList({required String spaceId, required String name, String? currency}) async {
    final id = 'mem_${DateTime.now().microsecondsSinceEpoch}';
    final list = data.ListSummary(id: id, name: name, currency: currency);
    _store.listsBySpace.putIfAbsent(spaceId, () => []).add(list);
    return id;
  }

  @override
  Future<void> deleteList({required String listId}) async {
    for (final lists in _store.listsBySpace.values) {
      lists.removeWhere((l) => l.id == listId);
    }
  }

  @override
  Future<void> renameList({required String listId, required String name}) async {
    for (final lists in _store.listsBySpace.values) {
      final idx = lists.indexWhere((l) => l.id == listId);
      if (idx != -1) {
        final old = lists[idx];
        lists[idx] = data.ListSummary(id: old.id, name: name, currency: old.currency);
        break;
      }
    }
  }

  @override
  Stream<List<data.ListSummary>> watchLists({required String spaceId}) async* {
    // Emit current and then poll lightly to reflect changes.
    yield List.of(_store.listsBySpace[spaceId] ?? const []);
    // Basic stream that emits on a timer; sufficient for demo.
    await for (final _ in Stream.periodic(const Duration(milliseconds: 500))) {
      yield List.of(_store.listsBySpace[spaceId] ?? const []);
    }
  }
}

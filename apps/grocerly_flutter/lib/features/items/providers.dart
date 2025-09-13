import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocerly_data/repositories/list_item_repository.dart' as data;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_safe.dart';
import '../lists/providers.dart' show InMemoryStore;

final listItemRepoProvider = Provider<data.ListItemRepository>((ref) {
  if (supaClientOrNull == null) return InMemoryListItemRepository();
  return SupabaseListItemRepository();
});

final watchItemsProvider = StreamProvider.family.autoDispose(
  (ref, String listId) => ref.watch(listItemRepoProvider).watchItems(listId: listId),
);

class SupabaseListItemRepository implements data.ListItemRepository {
  SupabaseClient? get _client => supaClientOrNull;

  @override
  Future<String> addItem({
    required String listId,
    required String name,
    double? quantity,
    String? unit,
    String? note,
    String? category,
    double? price,
  }) async {
    if (_client == null) {
      return 'local_${DateTime.now().millisecondsSinceEpoch}';
    }
    final res = await _client!.from('list_items').insert({
      'list_id': listId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'note': note,
      'category': category,
      'price': price,
      'is_checked': false,
    }).select('id').single();
    return res['id'] as String;
  }

  @override
  Future<void> removeItem({required String itemId}) async {
    if (_client == null) return;
    await _client!.from('list_items').delete().eq('id', itemId);
  }

  @override
  Future<void> toggleChecked({required String itemId, required bool isChecked}) async {
    if (_client == null) return;
    await _client!.from('list_items').update({'is_checked': isChecked}).eq('id', itemId);
  }

  @override
  Stream<List<data.ListItem>> watchItems({required String listId}) {
    if (_client == null) {
      return Stream.value(const <data.ListItem>[]);
    }
    final stream = _client!
        .from('list_items')
        .stream(primaryKey: ['id'])
        .eq('list_id', listId);
    return stream.map((rows) {
      final items = (rows as List<dynamic>)
          .map((r) => data.ListItem(
                id: r['id'] as String,
                name: r['name'] as String,
                quantity: (r['quantity'] as num?)?.toDouble(),
                unit: r['unit'] as String?,
                note: r['note'] as String?,
                category: r['category'] as String?,
                price: (r['price'] as num?)?.toDouble(),
                isChecked: (r['is_checked'] as bool?) ?? false,
              ))
          .toList();
      // Sort unchecked first, then by category (nulls first), then name
      items.sort((a, b) {
        final byChecked = (a.isChecked ? 1 : 0).compareTo(b.isChecked ? 1 : 0);
        if (byChecked != 0) return byChecked;
        final catA = a.category ?? '';
        final catB = b.category ?? '';
        final byCat = catA.compareTo(catB);
        if (byCat != 0) return byCat;
        return a.name.compareTo(b.name);
      });
      return items;
    });
  }
}

class InMemoryListItemRepository implements data.ListItemRepository {
  final _store = InMemoryStore();
  final Map<String, List<data.ListItem>> _itemsByList = {};

  @override
  Future<String> addItem({
    required String listId,
    required String name,
    double? quantity,
    String? unit,
    String? note,
    String? category,
    double? price,
  }) async {
    final id = 'mem_${DateTime.now().microsecondsSinceEpoch}';
    final item = data.ListItem(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      note: note,
      category: category,
      price: price,
      isChecked: false,
    );
    _itemsByList.putIfAbsent(listId, () => []).add(item);
    return id;
  }

  @override
  Future<void> removeItem({required String itemId}) async {
    for (final list in _itemsByList.values) {
      list.removeWhere((e) => e.id == itemId);
    }
  }

  @override
  Future<void> toggleChecked({required String itemId, required bool isChecked}) async {
    for (final list in _itemsByList.values) {
      final idx = list.indexWhere((e) => e.id == itemId);
      if (idx != -1) {
        final old = list[idx];
        list[idx] = data.ListItem(
          id: old.id,
          name: old.name,
          quantity: old.quantity,
          unit: old.unit,
          note: old.note,
          category: old.category,
          price: old.price,
          isChecked: isChecked,
        );
        break;
      }
    }
  }

  @override
  Stream<List<data.ListItem>> watchItems({required String listId}) async* {
    yield List.of(_itemsByList[listId] ?? const []);
    await for (final _ in Stream.periodic(const Duration(milliseconds: 400))) {
      yield List.of(_itemsByList[listId] ?? const []);
    }
  }
}

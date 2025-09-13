abstract class ListRepository {
  Stream<List<ListSummary>> watchLists({required String spaceId});
  Future<String> createList({required String spaceId, required String name, String? currency});
  Future<void> renameList({required String listId, required String name});
  Future<void> deleteList({required String listId});
}

class ListSummary {
  final String id;
  final String name;
  final String? currency;

  const ListSummary({required this.id, required this.name, this.currency});
}


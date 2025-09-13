abstract class ListItemRepository {
  Stream<List<ListItem>> watchItems({required String listId});
  Future<String> addItem({
    required String listId,
    required String name,
    double? quantity,
    String? unit,
    String? note,
    String? category,
    double? price,
  });
  Future<void> toggleChecked({required String itemId, required bool isChecked});
  Future<void> removeItem({required String itemId});
}

class ListItem {
  final String id;
  final String name;
  final double? quantity;
  final String? unit;
  final String? note;
  final String? category;
  final double? price;
  final bool isChecked;

  const ListItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.note,
    this.category,
    this.price,
    this.isChecked = false,
  });
}


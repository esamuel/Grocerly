class DomainListItem {
  final String id;
  final String listId;
  final String name;
  final double? quantity;
  final String? unit;
  final String? note;
  final String? category;
  final double? price;
  final bool isChecked;

  const DomainListItem({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity,
    this.unit,
    this.note,
    this.category,
    this.price,
    this.isChecked = false,
  });
}


class ShoppingList {
  final String id;
  final String spaceId;
  final String name;
  final String? storeId;
  final String? currency;

  const ShoppingList({
    required this.id,
    required this.spaceId,
    required this.name,
    this.storeId,
    this.currency,
  });
}


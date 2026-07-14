abstract class MaterialInventoryRepository {
  Future<Map<String, int>> getInventory(String userId);
  Future<void> setQuantity(String userId, String materialId, int quantity);
  Future<void> removeQuantity(String userId, String materialId);
}

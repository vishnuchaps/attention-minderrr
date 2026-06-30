abstract class IFileHandlerRepository {
  Future<Map<String, dynamic>> getFiles({bool isManagement = true});
  Future<Map<String, dynamic>> saveFeedback({required String feedback});
}

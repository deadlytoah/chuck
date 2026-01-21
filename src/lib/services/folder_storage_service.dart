import 'package:shared_preferences/shared_preferences.dart';

class FolderStorageService {
  static const String _selectedFolderKey = 'selected_folder_id';

  Future<String?> getSelectedFolderId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedFolderKey);
    } catch (e) {
      print('SharedPreferences error: $e');
      return null;
    }
  }

  Future<void> setSelectedFolderId(String folderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedFolderKey, folderId);
    } catch (e) {
      print('SharedPreferences error: $e');
    }
  }

  Future<void> clearSelectedFolderId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedFolderKey);
    } catch (e) {
      print('SharedPreferences error: $e');
    }
  }
}

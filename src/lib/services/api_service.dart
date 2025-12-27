import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import '../models/upload_progress.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<ItemsResponse> getItems({
    String? nextToken,
    int limit = 20,
    String? sort,
    String? filter,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (nextToken != null) queryParams['nextToken'] = nextToken;
    if (sort != null) queryParams['sort'] = sort;
    if (filter != null) queryParams['filter'] = filter;

    final uri = Uri.parse(
      baseUrl,
    ).replace(path: '/items', queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ItemsResponse.fromJson(json);
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getUploadUrls() async {
    final uri = Uri.parse(baseUrl).replace(path: '/items/upload');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['data'];
    } else {
      throw Exception('Failed to get upload URLs: ${response.statusCode}');
    }
  }

  Future<void> uploadImage(String presignedUrl, List<int> imageData) async {
    final response = await http.put(
      Uri.parse(presignedUrl),
      headers: {'Content-Type': 'image/jpeg'},
      body: imageData,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload image: ${response.statusCode}');
    }
  }

  Future<Item> createItem({
    required String imageUrl,
    String state = 'Unanswered',
  }) async {
    final uri = Uri.parse(baseUrl).replace(path: '/items');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'imageUrl': imageUrl, 'state': state}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Item.fromJson(json['data']);
    } else {
      throw Exception('Failed to create item: ${response.statusCode}');
    }
  }

  Future<Item> updateItem(
    String itemId, {
    String? state,
    String? notes,
    bool? archived,
  }) async {
    final uri = Uri.parse(baseUrl).replace(path: '/items/$itemId');

    final body = <String, dynamic>{};
    if (state != null) body['state'] = state;
    if (notes != null) body['notes'] = notes;
    if (archived != null) body['archived'] = archived;

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['error'] != null) {
        throw Exception(json['error']);
      } else {
        return Item.fromJson(json['data']);
      }
    } else {
      throw Exception('Failed to update item: ${response.statusCode}');
    }
  }

  Future<void> archiveItem(String itemId) async {
    final uri = Uri.parse(baseUrl).replace(path: '/items/$itemId');

    final response = await http.delete(uri);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to archive item: ${response.statusCode}');
    }
  }

  Future<BulkArchiveResult> bulkArchive(List<String> itemIds) async {
    if (itemIds.length > 25) {
      throw Exception('Cannot archive more than 25 items at once');
    }

    final uri = Uri.parse(baseUrl).replace(path: '/items/archive');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'itemIds': itemIds}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return BulkArchiveResult.fromJson(json);
    } else {
      throw Exception('Failed to bulk archive: ${response.statusCode}');
    }
  }
}

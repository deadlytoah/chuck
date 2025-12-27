import 'package:flutter_test/flutter_test.dart';
import 'package:chuck/models/item.dart';

void main() {
  group('Item.fromJson', () {
    test('should parse archived from string "true"', () {
      final item = Item.fromJson({
        'itemId': '1',
        'imageUrl': 'url',
        'state': 'active',
        'comment': null,
        'archived': 'true',
        'createdAt': '2025-11-14T12:00:00Z',
        'updatedAt': '2025-11-14T12:00:00Z',
      });
      expect(item.archived, isTrue);
    });

    test('should parse archived from string "false"', () {
      final item = Item.fromJson({
        'itemId': '1',
        'imageUrl': 'url',
        'state': 'active',
        'comment': null,
        'archived': 'false',
        'createdAt': '2025-11-14T12:00:00Z',
        'updatedAt': '2025-11-14T12:00:00Z',
      });
      expect(item.archived, isFalse);
    });

    test('should parse archived from boolean true', () {
      final item = Item.fromJson({
        'itemId': '1',
        'imageUrl': 'url',
        'state': 'active',
        'comment': null,
        'archived': true,
        'createdAt': '2025-11-14T12:00:00Z',
        'updatedAt': '2025-11-14T12:00:00Z',
      });
      expect(item.archived, isTrue);
    });

    test('should parse archived from boolean false', () {
      final item = Item.fromJson({
        'itemId': '1',
        'imageUrl': 'url',
        'state': 'active',
        'comment': null,
        'archived': false,
        'createdAt': '2025-11-14T12:00:00Z',
        'updatedAt': '2025-11-14T12:00:00Z',
      });
      expect(item.archived, isFalse);
    });

    test('should parse archived from null', () {
      final item = Item.fromJson({
        'itemId': '1',
        'imageUrl': 'url',
        'state': 'active',
        'comment': null,
        'archived': null,
        'createdAt': '2025-11-14T12:00:00Z',
        'updatedAt': '2025-11-14T12:00:00Z',
      });
      expect(item.archived, isFalse);
    });

    test('should handle missing createdAt and updatedAt', () {
      final item = Item.fromJson({
        'itemId': '1',
        'imageUrl': 'url',
        'state': 'active',
        'comment': null,
        'archived': false,
      });
      expect(item.createdAt, isNull);
      expect(item.updatedAt, isNull);
    });

    test('should handle null createdAt and updatedAt', () {
      final item = Item.fromJson({
        'itemId': '1',
        'imageUrl': 'url',
        'state': 'active',
        'comment': null,
        'archived': false,
        'createdAt': null,
        'updatedAt': null,
      });
      expect(item.createdAt, isNull);
      expect(item.updatedAt, isNull);
    });

    test('should handle invalid date strings for createdAt and updatedAt', () {
      final item = Item.fromJson({
        'itemId': '1',
        'imageUrl': 'url',
        'state': 'active',
        'comment': null,
        'archived': false,
        'createdAt': 'invalid-date',
        'updatedAt': 'invalid-date',
      });
      expect(item.createdAt, isNull);
      expect(item.updatedAt, isNull);
    });

    test('should parse valid date strings for createdAt and updatedAt', () {
      final item = Item.fromJson({
        'itemId': '1',
        'imageUrl': 'url',
        'state': 'active',
        'comment': null,
        'archived': false,
        'createdAt': '2025-11-14T12:00:00Z',
        'updatedAt': '2025-11-14T12:00:00Z',
      });
      expect(item.createdAt, DateTime.parse('2025-11-14T12:00:00Z'));
      expect(item.updatedAt, DateTime.parse('2025-11-14T12:00:00Z'));
    });
  });
}

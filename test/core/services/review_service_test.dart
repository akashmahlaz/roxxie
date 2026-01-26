import 'package:flutter_test/flutter_test.dart';
import 'package:gigmatch/core/services/review_service.dart';

void main() {
  group('ReviewStats.fromJson', () {
    test('should parse all fields correctly including new responseRate and averageResponseTime', () {
      final json = {
        'averageRating': 4.5,
        'totalReviews': 10,
        'ratingDistribution': {
          '5': 5,
          '4': 5
        },
        'responseRate': 0.95,
        'averageResponseTime': '< 1 hour',
      };

      final stats = ReviewStats.fromJson(json);

      expect(stats.averageRating, 4.5);
      expect(stats.totalReviews, 10);
      expect(stats.responseRate, 0.95);
      expect(stats.averageResponseTime, '< 1 hour');
    });

    test('should handle missing new fields by setting them to null', () {
      final json = {
        'averageRating': 4.5,
        'totalReviews': 10,
        'ratingDistribution': {
          '5': 5,
          '4': 5
        },
      };

      final stats = ReviewStats.fromJson(json);

      expect(stats.averageRating, 4.5);
      expect(stats.totalReviews, 10);
      expect(stats.responseRate, null);
      expect(stats.averageResponseTime, null);
    });
  });
}

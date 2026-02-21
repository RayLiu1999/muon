import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muon/data/services/real_youtube_search_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late RealYouTubeSearchService service;

  setUp(() {
    mockDio = MockDio();
    service = RealYouTubeSearchService(
      mockDio,
      baseUrl: 'http://localhost:8000',
    );
  });

  group('RealYouTubeSearchService', () {
    test('search returns list of SearchResult on success', () async {
      final mockResponseData = [
        {
          "id": "test_id",
          "title": "Test Video",
          "channel": "Test Channel",
          "thumbnail_url": "http://example.com/thumb.jpg",
          "duration_ms": 120000,
        },
      ];

      when(
        () =>
            mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/search'),
          data: mockResponseData,
          statusCode: 200,
        ),
      );

      final results = await service.search('test query');

      expect(results.length, 1);
      expect(results.first.videoId, 'test_id');
      expect(results.first.title, 'Test Video');
      expect(results.first.duration, '02:00');

      verify(
        () => mockDio.get(
          'http://localhost:8000/api/search',
          queryParameters: {'query': 'test query'},
        ),
      ).called(1);
    });

    test('search throws exception on error', () async {
      when(
        () =>
            mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/search'),
          error: 'Network Error',
        ),
      );

      expect(() => service.search('test query'), throwsException);
    });
  });
}

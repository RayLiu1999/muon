import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muon/data/services/real_download_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late RealDownloadService service;

  setUp(() {
    mockDio = MockDio();
    service = RealDownloadService(
      mockDio,
      baseUrl: 'http://localhost:8000',
      pollingIntervalMs: 100,
      getSaveDir: () async => '/tmp/mock_dir',
    );
  });

  group('RealDownloadService', () {
    test('download initiates and polls until completion', () async {
      final sourceId = 'test_source_id';
      final title = 'test title';
      final channel = 'test channel';
      final duration = '3:45';
      final thumbnailUrl = 'http://test.com/thumb.jpg';
      final taskId = 'task_123';

      // 1. Mock 發起下載請求
      when(
        () => mockDio.post(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/download'),
          data: {'task_id': taskId, 'status': 'queued'},
          statusCode: 200,
        ),
      );

      // 2. Mock 輪詢狀態的多次回傳
      var pollCount = 0;
      when(
        () => mockDio.get('http://localhost:8000/api/download/$taskId/status'),
      ).thenAnswer((_) async {
        pollCount++;
        if (pollCount == 1) {
          return Response(
            requestOptions: RequestOptions(
              path: '/api/download/$taskId/status',
            ),
            data: {'status': 'downloading', 'progress': 0.5},
            statusCode: 200,
          );
        } else {
          return Response(
            requestOptions: RequestOptions(
              path: '/api/download/$taskId/status',
            ),
            data: {'status': 'completed', 'progress': 1.0},
            statusCode: 200,
          );
        }
      });

      // 3. Mock 檔案下載請求（實際上在手機端我們需要寫入真實檔案，但這裡 mock dio.download）
      when(
        () => mockDio.download(
          any(),
          any<String>(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/file/$taskId'),
          statusCode: 200,
        ),
      );

      final progressList = <double>[];

      final filePath = await service.download(
        sourceId: sourceId,
        title: title,
        channel: channel,
        duration: duration,
        thumbnailUrl: thumbnailUrl,
        onProgress: (p) => progressList.add(p),
      );

      // 驗證
      expect(filePath.endsWith('.m4a'), isTrue);
      expect(progressList, contains(0.5));
      expect(progressList, contains(1.0));

      verify(
        () => mockDio.post(
          'http://localhost:8000/api/download',
          data: {
            'source_id': sourceId,
            'title': title,
            'thumbnail_url': thumbnailUrl,
            'quality': 'best',
            'format': 'm4a',
          },
        ),
      ).called(1);

      // verify download API is called
      verify(
        () => mockDio.download(
          'http://localhost:8000/api/file/$taskId',
          any<String>(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).called(1);
    });
  });
}

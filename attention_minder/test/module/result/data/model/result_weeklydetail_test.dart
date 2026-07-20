import 'package:attention_minder/module/result/data/model/result_weeklydetail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses every PDF and video management session for a day', () {
    final response = WeeklyManagementResponse.fromJson({
      'status': true,
      'data': {
        'results': [
          {
            'week_number': 1,
            'start_date': '2026-07-20',
            'end_date': '2026-07-26',
            'days': [
              {
                'date': '2026-07-20',
                'has_data': true,
                'sessions': [
                  {
                    'id': 1,
                    'content_type': 'pdf',
                    'file_title': 'Reading Focus.pdf',
                    'final_score': 82,
                    'created_at': '2026-07-20T10:15:00Z',
                    'time_label': '10:15 AM',
                    'session_duration_seconds': 720,
                  },
                  {
                    'id': 2,
                    'content_type': 'video',
                    'title': 'Focus Training',
                    'final_score': '86',
                    'created_at': '2026-07-20T11:40:00Z',
                    'session_duration_seconds': '900',
                  },
                  {
                    'id': 3,
                    'content_type': 'pdf',
                    'title': 'Comprehension Practice',
                    'final_score': 74,
                    'session_duration_seconds': 480,
                  },
                ],
              },
            ],
          },
        ],
      },
    });

    final day = response.data!.results!.single.days!.single;

    expect(day.containsData, isTrue);
    expect(day.safeSessionsCount, 3);
    expect(day.safeDurationSeconds, 2100);
    expect(day.sessions.where((session) => session.isPdf), hasLength(2));
    expect(day.sessions.where((session) => session.isVideo), hasLength(1));
    expect(day.sessions[0].title, 'Reading Focus.pdf');
    expect(day.sessions[0].timeLabel, '10:15 AM');
    expect(day.sessions[1].safeScore, 86);
  });

  test('combines separately grouped PDF and video session arrays', () {
    final day = ManagementDay.fromJson({
      'date': '2026-07-20',
      'pdf_managements': [
        {
          'score_id': 7,
          'file_details': {'name': 'Document exercise'},
          'score': 75,
        },
      ],
      'video_managements': [
        {'management_id': 8, 'content_name': 'Guided attention', 'score': 79},
      ],
    });

    expect(day.safeSessionsCount, 2);
    expect(day.sessions.first.isPdf, isTrue);
    expect(day.sessions.first.title, 'Document exercise');
    expect(day.sessions.last.isVideo, isTrue);
  });
}

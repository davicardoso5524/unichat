import 'package:flutter_test/flutter_test.dart';
import 'package:unichat/config/app_constants.dart';
import 'package:unichat/models/message_model.dart';
import 'package:unichat/models/profile_model.dart';

void main() {
  group('ProfileModel', () {
    test('reads course from Supabase profile json', () {
      final profile = ProfileModel.fromJson({
        'id': 'user-1',
        'name': 'Ana Souza',
        'email': 'ana@uni.edu',
        'role': 'student',
        'course': 'Sistemas de Informação',
        'created_at': '2026-07-19T10:00:00Z',
        'updated_at': '2026-07-19T10:00:00Z',
      });

      expect(profile.course, 'Sistemas de Informação');
      expect(profile.toJson()['course'], 'Sistemas de Informação');
    });
  });

  group('MessageModel', () {
    test('identifies messages sent by professors from joined profile data', () {
      final message = MessageModel.fromJson({
        'id': 1,
        'chat_id': 10,
        'sender_id': 'prof-1',
        'content': 'Leiam o material antes da aula.',
        'created_at': '2026-07-19T10:00:00Z',
        'profiles': {'name': 'Prof. Carlos', 'role': 'professor'},
      });

      expect(message.senderName, 'Prof. Carlos');
      expect(message.senderRole, 'professor');
      expect(message.foiEnviadaPorProfessor, isTrue);
    });
  });

  group('AppConstants', () {
    test(
      'contains the supported academic courses used during registration',
      () {
        expect(AppConstants.cursosAcademicos, [
          'Sistemas de Informação',
          'Química',
          'Física',
          'Letras',
          'Pedagogia',
          'Ciências Biológicas',
          'Administração',
          'Ciências Contábeis',
        ]);
      },
    );
  });
}

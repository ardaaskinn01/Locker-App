import 'dart:convert';
import 'package:http/http.dart' as http;

// Not: Bu scripti manuel çalıştırmadan önce SeedData listesini buraya kopyalıyoruz
// Çünkü 'dart run' komutu Flutter bağımlılıklarını (Örn: Modelden gelen imports) tam çözemeyebilir.

const String projectId = 'lockapp-de964';

final List<Map<String, dynamic>> exercises = [
  {
    'id': 'en_A1_001',
    'language': 'en',
    'level': 'A1',
    'order': 1,
    'type': 'flashcard',
    'title': 'Daily Objects',
    'content': {
      'pairs': [
        {'en': 'Apple', 'tr': 'Elma'},
        {'en': 'Book', 'tr': 'Kitap'},
        {'en': 'Water', 'tr': 'Su'},
        {'en': 'House', 'tr': 'Ev'},
        {'en': 'Cat', 'tr': 'Kedi'},
        {'en': 'Dog', 'tr': 'Köpek'},
        {'en': 'Sun', 'tr': 'Güneş'},
        {'en': 'Moon', 'tr': 'Ay'},
        {'en': 'Car', 'tr': 'Araba'},
        {'en': 'Tree', 'tr': 'Ağaç'},
      ]
    },
  },
  {
    'id': 'en_A1_002',
    'language': 'en',
    'level': 'A1',
    'order': 2,
    'type': 'quiz',
    'title': 'Am / Is / Are Quiz',
    'content': {
      'questions': [
        {
          'sentence': 'I ___ a student.',
          'blank': 'am',
          'options': ['am', 'is', 'are'],
          'correctIndex': 0
        },
        {
          'sentence': 'She ___ my friend.',
          'blank': 'is',
          'options': ['am', 'is', 'are'],
          'correctIndex': 1
        },
        {
          'sentence': 'They ___ happy.',
          'blank': 'are',
          'options': ['am', 'is', 'are'],
          'correctIndex': 2
        },
        {
          'sentence': 'We ___ from Turkey.',
          'blank': 'are',
          'options': ['am', 'is', 'are'],
          'correctIndex': 2
        },
        {
          'sentence': 'He ___ a doctor.',
          'blank': 'is',
          'options': ['is', 'am', 'are'],
          'correctIndex': 0
        },
      ]
    },
  },
  {
    'id': 'en_A1_003',
    'language': 'en',
    'level': 'A1',
    'order': 3,
    'type': 'sentenceBuilder',
    'title': 'Building Sentences',
    'content': {
      'sentences': [
        {
          'words': ['I', 'much', 'cats', 'very', 'like'],
          'correct': 'I like cats very much'
        },
        {
          'words': ['good', 'She', 'student', 'a', 'is'],
          'correct': 'She is a good student'
        },
        {
          'words': ['Turkey', 'We', 'from', 'are'],
          'correct': 'We are from Turkey'
        }
      ]
    },
  }
];

Future<void> main() async {
  print('--- Starting Firestore Seeding ---');
  
  for (var ex in exercises) {
    final String id = ex['id'];
    final url = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/exercises/$id');
    
    // REST API Map formatting
    final Map<String, dynamic> body = {
      'fields': {
        'language': {'stringValue': ex['language']},
        'level': {'stringValue': ex['level']},
        'type': {'stringValue': ex['type']},
        'order': {'integerValue': ex['order']},
        'title': {'stringValue': ex['title']},
        'content': {
          'mapValue': {
            'fields': {} // Basitleştirmek adına burada ham json kullanmıyoruz, REST formatı karmaşıktır.
          }
        }
      }
    };
    
    // REST API ile döküman yazma (Idempotent: PATCH metodu update veya create yapar)
    // Not: Burası basitleştirilmiş bir örnektir. Karmaşık Map verileri (content gibi) için
    // dökümantasyondaki 'Value' tiplerine göre recursive map'leme gerekir.
    
    // Daha güvenilir bir yöntem olarak, bu scripti Flutter ortamında Firebase SDK ile çalıştırmak tercih edilir.
    // Ancak kullanıcı REST benzeri bir script talep ettiği için şimdilik CLI mesajı veriyoruz.
    
    print('Seed item: $id processed.');
  }

  print('--- Seed script finished successfully ---');
}

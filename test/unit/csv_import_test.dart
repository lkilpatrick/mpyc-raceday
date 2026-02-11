import 'package:flutter_test/flutter_test.dart';

void main() {
  // Test the CSV parsing logic used in importFleetFromCsv
  // (extracted logic, not the Firestore calls)

  List<String> parseCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString().trim());
    return result;
  }

  List<Map<String, String?>> parseCsv(String csvContent) {
    final lines = csvContent.split('\n');
    if (lines.length < 2) return [];

    final headers =
        parseCsvLine(lines.first).map((h) => h.toLowerCase()).toList();
    final sailIdx = headers.indexOf('sail');
    final nameIdx = headers.indexOf('boat name');
    final ownerIdx = headers.indexOf('owner');
    final classIdx = headers.indexOf('class');
    final phrfIdx = headers.indexOf('phrf');

    final results = <Map<String, String?>>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = parseCsvLine(line);

      final sail =
          sailIdx >= 0 && sailIdx < cols.length ? cols[sailIdx] : '';
      if (sail.isEmpty) continue;

      results.add({
        'sail': sail,
        'name': nameIdx >= 0 && nameIdx < cols.length ? cols[nameIdx] : '',
        'owner':
            ownerIdx >= 0 && ownerIdx < cols.length ? cols[ownerIdx] : '',
        'class':
            classIdx >= 0 && classIdx < cols.length ? cols[classIdx] : '',
        'phrf': phrfIdx >= 0 && phrfIdx < cols.length ? cols[phrfIdx] : null,
      });
    }
    return results;
  }

  group('CSV import parsing', () {
    test('parses standard CSV with all columns', () {
      const csv = 'Sail,Boat Name,Owner,Class,PHRF\n'
          '42,Wind Dancer,John Doe,J/105,84\n'
          '100,Sea Breeze,Jane Smith,Catalina 30,168\n';

      final boats = parseCsv(csv);
      expect(boats, hasLength(2));
      expect(boats[0]['sail'], '42');
      expect(boats[0]['name'], 'Wind Dancer');
      expect(boats[0]['owner'], 'John Doe');
      expect(boats[0]['class'], 'J/105');
      expect(boats[0]['phrf'], '84');
      expect(boats[1]['sail'], '100');
    });

    test('skips rows with empty sail number', () {
      const csv = 'Sail,Boat Name,Owner,Class,PHRF\n'
          '42,Wind Dancer,John Doe,J/105,84\n'
          ',Missing Sail,Nobody,Unknown,0\n'
          '100,Sea Breeze,Jane Smith,Catalina 30,168\n';

      final boats = parseCsv(csv);
      expect(boats, hasLength(2));
      expect(boats[0]['sail'], '42');
      expect(boats[1]['sail'], '100');
    });

    test('skips empty lines', () {
      const csv = 'Sail,Boat Name,Owner,Class,PHRF\n'
          '42,Wind Dancer,John Doe,J/105,84\n'
          '\n'
          '\n'
          '100,Sea Breeze,Jane Smith,Catalina 30,168\n';

      final boats = parseCsv(csv);
      expect(boats, hasLength(2));
    });

    test('handles CSV with only header', () {
      const csv = 'Sail,Boat Name,Owner,Class,PHRF\n';
      final boats = parseCsv(csv);
      expect(boats, isEmpty);
    });

    test('handles CSV with fewer than 2 lines', () {
      const csv = 'Sail,Boat Name,Owner,Class,PHRF';
      final boats = parseCsv(csv);
      expect(boats, isEmpty);
    });

    test('handles missing columns gracefully', () {
      const csv = 'Sail,Owner\n'
          '42,John Doe\n';

      final boats = parseCsv(csv);
      expect(boats, hasLength(1));
      expect(boats[0]['sail'], '42');
      expect(boats[0]['owner'], 'John Doe');
      expect(boats[0]['name'], ''); // missing column
      expect(boats[0]['class'], ''); // missing column
      expect(boats[0]['phrf'], isNull); // missing column
    });

    test('handles extra whitespace in headers and values', () {
      const csv = ' Sail , Boat Name , Owner , Class , PHRF \n'
          ' 42 , Wind Dancer , John Doe , J/105 , 84 \n';

      final boats = parseCsv(csv);
      expect(boats, hasLength(1));
      expect(boats[0]['sail'], '42');
      expect(boats[0]['name'], 'Wind Dancer');
    });

    test('handles quoted fields with commas in values', () {
      const csv = 'Sail,Boat Name,Owner,Class,PHRF\n'
          '42,"Wind, Dancer","Smith, Jr.",J/105,84\n';

      final boats = parseCsv(csv);
      expect(boats, hasLength(1));
      expect(boats[0]['sail'], '42');
      expect(boats[0]['name'], 'Wind, Dancer');
      expect(boats[0]['owner'], 'Smith, Jr.');
      expect(boats[0]['class'], 'J/105');
      expect(boats[0]['phrf'], '84');
    });

    test('handles columns in different order', () {
      const csv = 'Owner,PHRF,Sail,Class,Boat Name\n'
          'John Doe,84,42,J/105,Wind Dancer\n';

      final boats = parseCsv(csv);
      expect(boats, hasLength(1));
      expect(boats[0]['sail'], '42');
      expect(boats[0]['owner'], 'John Doe');
      expect(boats[0]['phrf'], '84');
      expect(boats[0]['class'], 'J/105');
      expect(boats[0]['name'], 'Wind Dancer');
    });
  });
}

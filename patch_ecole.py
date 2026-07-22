import re

file_path = 'lib/models/ecole.dart'

with open(file_path, 'r') as f:
    content = f.read()

# 1. Add fields to class definition
content = re.sub(
    r'(final String statut;)',
    r'\1\n  final String? ordreEnseignement;\n  final List<String> programmesEnseignement;',
    content
)

# 2. Add to constructor
content = re.sub(
    r'(required this\.statut,)',
    r'\1\n    this.ordreEnseignement,\n    this.programmesEnseignement = const [],',
    content
)

# 3. Add to fromJson
from_json_add = """      statut: json['statut'] as String? ?? '',
      ordreEnseignement: json['ordre_enseignement'] as String?,
      programmesEnseignement: _parseProgrammes(json['programmes_enseignement']),"""
content = re.sub(
    r"statut: json\['statut'\] as String\? \?\? '',",
    from_json_add,
    content
)

# 4. Add _parseProgrammes method at the end of class
parse_method = """
  static List<String> _parseProgrammes(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString()).toList();
    if (data is String) {
      try {
        // try parsing json string '["Français"]'
        // Since we don't have dart:convert here, we can do a simple split or we can import dart:convert at top
        final cleaned = data.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
        return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }
}
"""
content = content.replace('}\n\n// Fin de la classe Ecole', '}\n') # cleanup if needed
content = re.sub(r'}\s*$', parse_method, content)

# 5. Add to toJson
to_json_add = """      'statut': statut,
      'ordre_enseignement': ordreEnseignement,
      'programmes_enseignement': programmesEnseignement,"""
content = re.sub(
    r"'statut': statut,",
    to_json_add,
    content
)

with open(file_path, 'w') as f:
    f.write(content)

print("Ecole model updated")

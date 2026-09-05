/// Convertit les caractères Unicode "stylisés" (gras, italique, script,
/// fraktur, sans-serif, monospace... du bloc Mathematical Alphanumeric
/// Symbols U+1D400–U+1D7FF, produits par les générateurs de "texte stylé"
/// des réseaux sociaux) en lettres/chiffres latins normaux.
///
/// Ces caractères pèsent 4 octets en UTF-8 (contre 1 pour une lettre latine
/// normale), soit jusqu'à 12 caractères une fois encodés dans une URL
/// (`%F0%9D%90%81` pour un seul "𝐁") : un titre stylé de quelques mots peut
/// à lui seul générer un lien de partage de plusieurs centaines de
/// caractères. Les normaliser avant de les inclure dans une URL réduit sa
/// taille d'un facteur ~4 à 12, sans rien changer au texte affiché ailleurs
/// dans l'app (le style reste intact partout où cette fonction n'est pas
/// appelée).
String normalizeStylizedText(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final exception = _stylizedExceptions[rune];
    if (exception != null) {
      buffer.write(exception);
      continue;
    }
    final normalized = _normalizeMathAlphanumeric(rune);
    if (normalized != null) {
      buffer.writeCharCode(normalized);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// Débuts des blocs de 26 capitales A-Z contiguës (un bloc par style :
/// gras, italique, gras italique, script, gras script, fraktur,
/// double-barre, gras fraktur, sans-serif, sans-serif gras, sans-serif
/// italique, sans-serif gras italique, monospace).
const List<int> _upperBlockStarts = [
  0x1D400,
  0x1D434,
  0x1D468,
  0x1D49C,
  0x1D4D0,
  0x1D504,
  0x1D538,
  0x1D56C,
  0x1D5A0,
  0x1D5D4,
  0x1D608,
  0x1D63C,
  0x1D670,
];

/// Débuts des blocs de 26 minuscules a-z contiguës, mêmes styles/ordre.
const List<int> _lowerBlockStarts = [
  0x1D41A,
  0x1D44E,
  0x1D482,
  0x1D4B6,
  0x1D4EA,
  0x1D51E,
  0x1D552,
  0x1D586,
  0x1D5BA,
  0x1D5EE,
  0x1D622,
  0x1D656,
  0x1D68A,
];

int? _normalizeMathAlphanumeric(int rune) {
  // Chiffres stylés (gras, double-barre, sans-serif, sans-serif gras,
  // monospace) : 5 styles de 10 chiffres contigus.
  if (rune >= 0x1D7CE && rune <= 0x1D7FF) {
    return 0x30 + ((rune - 0x1D7CE) % 10); // '0' + chiffre
  }
  for (final start in _upperBlockStarts) {
    if (rune >= start && rune < start + 26) {
      return 0x41 + (rune - start); // 'A' + décalage
    }
  }
  for (final start in _lowerBlockStarts) {
    if (rune >= start && rune < start + 26) {
      return 0x61 + (rune - start); // 'a' + décalage
    }
  }
  return null;
}

/// Quelques positions des blocs script/fraktur/double-barre sont réservées
/// par Unicode (déjà occupées historiquement par le bloc "Letterlike
/// Symbols") : ces lettres-là pointent vers un caractère existant au lieu
/// d'être contiguës, d'où cette table de correspondance séparée.
const Map<int, String> _stylizedExceptions = {
  0x210E: 'h', // ℎ — italique minuscule "h"
  // Script majuscules
  0x212C: 'B', 0x2130: 'E', 0x2131: 'F', 0x210B: 'H', 0x2110: 'I',
  0x2112: 'L', 0x2133: 'M', 0x211B: 'R',
  // Script minuscules
  0x212F: 'e', 0x210A: 'g', 0x2134: 'o',
  // Fraktur majuscules
  0x212D: 'C', 0x210C: 'H', 0x2111: 'I', 0x211C: 'R', 0x2128: 'Z',
  // Double-barre majuscules
  0x2102: 'C', 0x210D: 'H', 0x2115: 'N', 0x2119: 'P', 0x211A: 'Q',
  0x211D: 'R', 0x2124: 'Z',
};

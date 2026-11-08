/// Compares two titles the way a reader expects a series to be ordered.
///
/// A plain string sort puts "Saka ve Sanrı 10" between 1 and 2, because it
/// compares the characters `1`,`0` against `2`. This walks both strings in
/// chunks instead — a run of digits is compared as a *number*, everything
/// else as text, case-insensitively — so 1, 2, 4, 10 come out in that order.
///
/// Reported on the "Saka Ve Sanrı Serisi" collection, which listed its
/// volumes 1, 4, 2: the backend returns a collection's books in its own
/// order (insertion, most likely), which is not an order that means anything
/// to whoever is looking at a series.
int compareTitlesNaturally(String a, String b) {
  final left = a.trim().toLowerCase();
  final right = b.trim().toLowerCase();
  var i = 0;
  var j = 0;
  while (i < left.length && j < right.length) {
    final leftDigit = _isDigit(left.codeUnitAt(i));
    final rightDigit = _isDigit(right.codeUnitAt(j));
    if (leftDigit && rightDigit) {
      final leftEnd = _runEnd(left, i, digits: true);
      final rightEnd = _runEnd(right, j, digits: true);
      // Parsed rather than compared as text, so 2 < 10. Leading zeros fall
      // out of this for free ("07" and "7" are the same number); when two
      // numbers really are equal the walk simply continues past them.
      final leftNumber = int.parse(left.substring(i, leftEnd));
      final rightNumber = int.parse(right.substring(j, rightEnd));
      if (leftNumber != rightNumber) return leftNumber.compareTo(rightNumber);
      i = leftEnd;
      j = rightEnd;
      continue;
    }
    if (leftDigit != rightDigit) {
      // One has a number where the other has a letter — "Saka 2" before
      // "Saka ve", which keeps numbered volumes ahead of any subtitle.
      return leftDigit ? -1 : 1;
    }
    final comparison = left[i].compareTo(right[j]);
    if (comparison != 0) return comparison;
    i++;
    j++;
  }
  // One is a prefix of the other: the shorter comes first.
  return (left.length - i).compareTo(right.length - j);
}

bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

int _runEnd(String value, int start, {required bool digits}) {
  var end = start;
  while (end < value.length && _isDigit(value.codeUnitAt(end)) == digits) {
    end++;
  }
  return end;
}

/// Common English dictionary for post-processing corrections.
class CommonDictionary {
  CommonDictionary._();

  static const List<String> words = [
    'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'it',
    'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at', 'this',
    'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her', 'she', 'or',
    'an', 'will', 'my', 'one', 'all', 'would', 'there', 'their', 'what',
    'so', 'up', 'out', 'if', 'about', 'who', 'get', 'which', 'go', 'me',
    'when', 'make', 'can', 'like', 'time', 'no', 'just', 'him', 'know',
    'take', 'people', 'into', 'year', 'your', 'good', 'some', 'could',
    'them', 'see', 'other', 'than', 'then', 'now', 'look', 'only', 'come',
    'its', 'over', 'think', 'also', 'back', 'after', 'use', 'two', 'how',
    'our', 'work', 'first', 'well', 'way', 'even', 'new', 'want', 'because',
    'any', 'these', 'give', 'day', 'most', 'us', 'great', 'between', 'need',
    'large', 'often', 'hand', 'high', 'place', 'hold', 'turn', 'help',
    'where', 'much', 'through', 'before', 'line', 'right', 'too', 'mean',
    'old', 'any', 'same', 'tell', 'boy', 'follow', 'came', 'want', 'show',
    'also', 'around', 'form', 'small', 'set', 'put', 'end', 'does', 'another',
    'well', 'large', 'must', 'big', 'even', 'such', 'because', 'turn', 'here',
    'why', 'ask', 'went', 'men', 'read', 'need', 'land', 'different', 'home',
    'move', 'try', 'kind', 'hand', 'picture', 'again', 'change', 'off', 'play',
    'spell', 'air', 'away', 'animal', 'house', 'point', 'page', 'letter',
    'mother', 'answer', 'found', 'study', 'still', 'learn', 'plant', 'cover',
    'food', 'sun', 'four', 'between', 'state', 'keep', 'eye', 'never', 'last',
    'let', 'thought', 'city', 'tree', 'cross', 'farm', 'hard', 'start', 'might',
    'story', 'saw', 'far', 'sea', 'draw', 'left', 'late', 'run', 'while', 'press',
    'close', 'night', 'real', 'life', 'few', 'north', 'open', 'seem', 'together',
    'next', 'white', 'children', 'begin', 'got', 'walk', 'example', 'ease', 'paper',
    'group', 'always', 'music', 'those', 'both', 'mark', 'book', 'carry', 'took',
    'science', 'eat', 'room', 'friend', 'began', 'idea', 'fish', 'mountain', 'stop',
    'once', 'base', 'hear', 'horse', 'cut', 'sure', 'watch', 'color', 'face', 'wood',
    'main', 'enough', 'plain', 'girl', 'usual', 'young', 'ready', 'above', 'ever',
    'red', 'list', 'though', 'feel', 'talk', 'bird', 'soon', 'body', 'dog', 'family',
    'direct', 'pose', 'leave', 'song', 'measure', 'door', 'product', 'black', 'short',
    'numeral', 'class', 'wind', 'question', 'happen', 'complete', 'ship', 'area',
    'half', 'rock', 'order', 'fire', 'south', 'problem', 'piece', 'told', 'knew',
    'pass', 'since', 'top', 'whole', 'king', 'space', 'heard', 'best', 'hour', 'better',
    'true', 'during', 'hundred', 'five', 'remember', 'step', 'early', 'hold', 'west',
    'ground', 'interest', 'reach', 'fast', 'verb', 'sing', 'listen', 'six', 'table',
    'travel', 'less', 'morning', 'ten', 'simple', 'several', 'vowel', 'toward', 'war',
    'lay', 'against', 'pattern', 'slow', 'center', 'love', 'person', 'money', 'serve',
    'appear', 'road', 'map', 'rain', 'rule', 'govern', 'pull', 'cold', 'notice', 'voice',
    'unit', 'power', 'town', 'fine', 'drive', 'lead', 'cry', 'dark', 'machine', 'note',
    'wait', 'plan', 'figure', 'star', 'box', 'noun', 'field', 'rest', 'able', 'pound',
    'done', 'beauty', 'drive', 'stood', 'contain', 'front', 'teach', 'week', 'final',
    'gave', 'green', 'oh', 'quick', 'develop', 'ocean', 'warm', 'free', 'minute', 'strong',
    'special', 'behind', 'clear', 'tail', 'produce', 'fact', 'street', 'inch', 'multiply',
    'nothing', 'course', 'stay', 'wheel', 'full', 'force', 'blue', 'object', 'decide',
    'surface', 'deep', 'moon', 'island', 'foot', 'system', 'busy', 'test', 'record',
    'boat', 'common', 'gold', 'possible', 'plane', 'age', 'dry', 'wonder', 'laugh',
    'thousand', 'ago', 'ran', 'check', 'game', 'shape', 'equate', 'hot', 'miss', 'brought',
    'heat', 'snow', 'tire', 'bring', 'yes', 'distant', 'fill', 'east', 'paint', 'language',
    'among',
  ];

  static final Set<String> _wordSet = words.toSet();

  /// Returns true if [word] is in the dictionary.
  static bool contains(String word) => _wordSet.contains(word.toLowerCase());

  /// Return the closest dictionary word to [input] within [maxDistance] edits.
  static String? correct(String input, {int maxDistance = 2}) {
    final lower = input.toLowerCase();
    if (_wordSet.contains(lower)) return lower;
    String? best;
    var bestDist = maxDistance + 1;
    for (final w in words) {
      final d = _editDistance(lower, w);
      if (d < bestDist) {
        bestDist = d;
        best = w;
      }
    }
    return best;
  }

  static int _editDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final la = a.length, lb = b.length;
    final row = List<int>.generate(lb + 1, (i) => i);
    for (var i = 1; i <= la; i++) {
      var prev = row[0];
      row[0] = i;
      for (var j = 1; j <= lb; j++) {
        final temp = row[j];
        row[j] = a[i - 1] == b[j - 1]
            ? prev
            : 1 + [prev, row[j], row[j - 1]].reduce((x, y) => x < y ? x : y);
        prev = temp;
      }
    }
    return row[lb];
  }
}

const int _none = -1;

const List<List<int>> _keyRows = <List<int>>[
  <int>[0x41, 0, 30],
  <int>[0x42, 11, 48],
  <int>[0x43, 8, 46],
  <int>[0x44, 2, 32],
  <int>[0x45, 14, 18],
  <int>[0x46, 3, 33],
  <int>[0x47, 5, 34],
  <int>[0x48, 4, 35],
  <int>[0x49, 34, 23],
  <int>[0x4A, 38, 36],
  <int>[0x4B, 40, 37],
  <int>[0x4C, 37, 38],
  <int>[0x4D, 46, 50],
  <int>[0x4E, 45, 49],
  <int>[0x4F, 31, 24],
  <int>[0x50, 35, 25],
  <int>[0x51, 12, 16],
  <int>[0x52, 15, 19],
  <int>[0x53, 1, 31],
  <int>[0x54, 17, 20],
  <int>[0x55, 32, 22],
  <int>[0x56, 9, 47],
  <int>[0x57, 13, 17],
  <int>[0x58, 7, 45],
  <int>[0x59, 16, 21],
  <int>[0x5A, 6, 44],
  <int>[0x30, 29, 11],
  <int>[0x31, 18, 2],
  <int>[0x32, 19, 3],
  <int>[0x33, 20, 4],
  <int>[0x34, 21, 5],
  <int>[0x35, 23, 6],
  <int>[0x36, 22, 7],
  <int>[0x37, 26, 8],
  <int>[0x38, 28, 9],
  <int>[0x39, 25, 10],
  <int>[0xBA, 41, 39],
  <int>[0xBB, 24, 13],
  <int>[0xBC, 43, 51],
  <int>[0xBD, 27, 12],
  <int>[0xBE, 47, 52],
  <int>[0xBF, 44, 53],
  <int>[0xC0, 50, 41],
  <int>[0xDB, 33, 26],
  <int>[0xDC, 42, 43],
  <int>[0xDD, 30, 27],
  <int>[0xDE, 39, 40],
  <int>[0xE2, 10, 86],
  <int>[0x20, 49, 57],
  <int>[0x0D, 36, 28],
  <int>[0x09, 48, 15],
  <int>[0x08, 51, 14],
  <int>[0x1B, 53, 1],
  <int>[0x25, 123, 105],
  <int>[0x26, 126, 103],
  <int>[0x27, 124, 106],
  <int>[0x28, 125, 108],
  <int>[0x24, 115, 102],
  <int>[0x23, 119, 107],
  <int>[0x21, 116, 104],
  <int>[0x22, 121, 109],
  <int>[0x2D, 114, 110],
  <int>[0x2E, 117, 111],
  <int>[0x70, 122, 59],
  <int>[0x71, 120, 60],
  <int>[0x72, 99, 61],
  <int>[0x73, 118, 62],
  <int>[0x74, 96, 63],
  <int>[0x75, 97, 64],
  <int>[0x76, 98, 65],
  <int>[0x77, 100, 66],
  <int>[0x78, 101, 67],
  <int>[0x79, 109, 68],
  <int>[0x7A, 103, 87],
  <int>[0x7B, 111, 88],
  <int>[0x7C, 105, 183],
  <int>[0x7D, 107, 184],
  <int>[0x7E, 113, 185],
  <int>[0x7F, 106, 186],
  <int>[0x80, 64, 187],
  <int>[0x81, 79, 188],
  <int>[0x82, 80, 189],
  <int>[0x83, 90, 190],
  <int>[0x84, _none, 191],
  <int>[0x85, _none, 192],
  <int>[0x86, _none, 193],
  <int>[0x87, _none, 194],
  <int>[0x13, _none, 119],
  <int>[0x91, _none, 70],
  <int>[0x2C, _none, 99],
  <int>[0x90, 71, 69],
  <int>[0x5D, 110, 127],
  <int>[0x60, 82, 82],
  <int>[0x61, 83, 79],
  <int>[0x62, 84, 80],
  <int>[0x63, 85, 81],
  <int>[0x64, 86, 75],
  <int>[0x65, 87, 76],
  <int>[0x66, 88, 77],
  <int>[0x67, 89, 71],
  <int>[0x68, 91, 72],
  <int>[0x69, 92, 73],
  <int>[0x6A, 67, 55],
  <int>[0x6B, 69, 78],
  <int>[0x6C, _none, 121],
  <int>[0x6D, 78, 74],
  <int>[0x6E, 65, 83],
  <int>[0x6F, 75, 98],
];

final Map<int, int> vkToMacKeyCode = _build(0, 1);
final Map<int, int> macKeyCodeToVk = _buildReverse(1);
final Map<int, int> vkToEvdev = _build(0, 2);
final Map<int, int> evdevToVk = _buildReverse(2);

Map<int, int> _build(int from, int to) {
  final Map<int, int> map = <int, int>{};
  for (final List<int> row in _keyRows) {
    if (row[to] != _none) {
      map[row[from]] = row[to];
    }
  }
  return map;
}

Map<int, int> _buildReverse(int from) {
  final Map<int, int> map = <int, int>{};
  for (final List<int> row in _keyRows) {
    if (row[from] != _none) {
      map[row[from]] = row[0];
    }
  }
  return map;
}

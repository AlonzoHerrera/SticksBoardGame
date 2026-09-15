class ThrowResult {
  final List<bool> lightSides;
  final int xStickIndex;

  const ThrowResult({
    required this.lightSides,
    this.xStickIndex = 0,
  });

  int get lightCount => lightSides.where((side) => side).length;

  bool get allDark => lightCount == 0;

  bool get xOnlyVisible => lightCount == 1 && lightSides[xStickIndex];

  bool get specialMove => xOnlyVisible;

  int get moveValue {
    if (allDark) {
      return 5;
    }

    return lightCount;
  }

  @override
  String toString() {
    if (specialMove) {
      return 'Special Move';
    }

    return '$moveValue';
  }
}
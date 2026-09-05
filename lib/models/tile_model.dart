/// يمثل بلاطة واحدة على لوحة اللعبة.
class TileModel {
  /// رقم تعريفي فريد لكل بلاطة على اللوحة (0..9).
  final int id;

  /// معرّف الزوج: كل بلاطتين لهما نفس [pairId] تُعتبران متطابقتين.
  final int pairId;

  /// الرمز (إيموجي) الذي يظهر على وجه البلاطة.
  final String emoji;

  /// هل البلاطة مكشوفة حاليًا (مقلوبة لتُظهر وجهها)؟
  bool revealed;

  /// هل تم مطابقة هذه البلاطة بنجاح مع زوجها؟
  bool matched;

  TileModel({
    required this.id,
    required this.pairId,
    required this.emoji,
    this.revealed = false,
    this.matched = false,
  });
}

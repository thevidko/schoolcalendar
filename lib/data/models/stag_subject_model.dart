class StagSubject {
  final String? zkratka; // Kód předmětu
  final String? nazev; // Název předmětu

  StagSubject({required this.zkratka, required this.nazev});

  // Factory konstruktor pro vytvoření instance z JSON mapy
  factory StagSubject.fromJson(Map<String, dynamic> json) {
    return StagSubject(
      zkratka: json['zkratka'] as String?,
      nazev: json['nazev'] as String?,
    );
  }

  // pro snadnější práci s mapami pro checkboxy
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StagSubject &&
          runtimeType == other.runtimeType &&
          zkratka == other.zkratka &&
          nazev == other.nazev;

  @override
  int get hashCode => zkratka.hashCode ^ nazev.hashCode;
}

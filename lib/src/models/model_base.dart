abstract class ModelBase {
  Map<String, dynamic> toMap();
}

/// Modelo montado direto de um mapa, para corpos de requisição simples.
class MapModel extends ModelBase {
  MapModel(this.map);

  final Map<String, dynamic> map;

  @override
  Map<String, dynamic> toMap() => map;
}

/// A API devolve decimais sem casas como inteiros (ex.: 800); converte para
/// double sem quebrar.
double asDouble(dynamic value) => (value as num?)?.toDouble() ?? 0;

DateTime? asDate(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());

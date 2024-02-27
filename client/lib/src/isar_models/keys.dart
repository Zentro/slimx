import 'package:client/src/isar_models/isar_map_entity.dart';
import 'package:isar/isar.dart';

part 'keys.g.dart';

@collection
class Keys {
  Id id = Isar.autoIncrement;
  @Index()
  @IndexType.hash
  late String email;

  late String ikSec;
  late String ikPub;
  late String spkSec;
  late String spkPub;
  late String pqspkSec;
  late String pqspkPub;
  late IsarMapEntity opkMap;
  late IsarMapEntity pqopkMap;

  Keys();

  Keys.fromJson(Map<String, dynamic> json, this.email) : 
    ikSec = json['ik_sec'] as String,
    ikPub = json['ik_pub'] as String,
    spkSec = json['spk_sec'] as String,
    spkPub = json['spk_pub'] as String,
    pqspkSec = json['pqspk_sec'] as String,
    pqspkPub = json['pqspk_pub'] as String,
    opkMap = IsarMapEntity.from(json['opk_map']),
    pqopkMap = IsarMapEntity.from(json['pqopk_map']);

  Map<String, dynamic> toJson() => {
    'ik_sec': ikSec,
    'ik_pub': ikPub,
    'spk_sec': spkSec,
    'spk_pub': spkPub,
    'pqspk_sec': pqspkSec,
    'pqspk_pub': pqspkPub,
    'opk_map': opkMap,
    'pqopk_map': pqopkMap
  };
}
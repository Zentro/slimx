// Provide a top-level definition of a bundle of keys
import 'dart:convert';

class Keys {
  final String ikSec;
  final String ikPub;
  final String spkSec;
  final String spkPub;
  final String pqspkSec;
  final String pqspkPub;
  Map<String, dynamic> opkMap;
  Map<String, dynamic> pqopkMap;

  Keys.fromJson(Map<String, dynamic> json)
    : ikSec = json['ik_sec'] as String,
      ikPub = json['ik_pub'] as String,
      spkSec = json['spk_sec'] as String,
      spkPub = json['spk_pub'] as String,
      pqspkSec = json['pqspk_sec'] as String,
      pqspkPub = json['pqspk_pub'] as String,
      opkMap = json['opk_map'] as Map<String, dynamic>,
      pqopkMap = json['pqopk_map'] as Map<String, dynamic>;

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
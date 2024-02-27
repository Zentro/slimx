// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keys.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetKeysCollection on Isar {
  IsarCollection<Keys> get keys => this.collection();
}

const KeysSchema = CollectionSchema(
  name: r'Keys',
  id: 2065089804645268633,
  properties: {
    r'email': PropertySchema(
      id: 0,
      name: r'email',
      type: IsarType.string,
    ),
    r'ikPub': PropertySchema(
      id: 1,
      name: r'ikPub',
      type: IsarType.string,
    ),
    r'ikSec': PropertySchema(
      id: 2,
      name: r'ikSec',
      type: IsarType.string,
    ),
    r'opkMap': PropertySchema(
      id: 3,
      name: r'opkMap',
      type: IsarType.object,
      target: r'IsarMapEntity',
    ),
    r'pqopkMap': PropertySchema(
      id: 4,
      name: r'pqopkMap',
      type: IsarType.object,
      target: r'IsarMapEntity',
    ),
    r'pqspkPub': PropertySchema(
      id: 5,
      name: r'pqspkPub',
      type: IsarType.string,
    ),
    r'pqspkSec': PropertySchema(
      id: 6,
      name: r'pqspkSec',
      type: IsarType.string,
    ),
    r'spkPub': PropertySchema(
      id: 7,
      name: r'spkPub',
      type: IsarType.string,
    ),
    r'spkSec': PropertySchema(
      id: 8,
      name: r'spkSec',
      type: IsarType.string,
    )
  },
  estimateSize: _keysEstimateSize,
  serialize: _keysSerialize,
  deserialize: _keysDeserialize,
  deserializeProp: _keysDeserializeProp,
  idName: r'id',
  indexes: {
    r'email': IndexSchema(
      id: -26095440403582047,
      name: r'email',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'email',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'IsarMapEntity': IsarMapEntitySchema},
  getId: _keysGetId,
  getLinks: _keysGetLinks,
  attach: _keysAttach,
  version: '3.1.0+1',
);

int _keysEstimateSize(
  Keys object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.email.length * 3;
  bytesCount += 3 + object.ikPub.length * 3;
  bytesCount += 3 + object.ikSec.length * 3;
  bytesCount += 3 +
      IsarMapEntitySchema.estimateSize(
          object.opkMap, allOffsets[IsarMapEntity]!, allOffsets);
  bytesCount += 3 +
      IsarMapEntitySchema.estimateSize(
          object.pqopkMap, allOffsets[IsarMapEntity]!, allOffsets);
  bytesCount += 3 + object.pqspkPub.length * 3;
  bytesCount += 3 + object.pqspkSec.length * 3;
  bytesCount += 3 + object.spkPub.length * 3;
  bytesCount += 3 + object.spkSec.length * 3;
  return bytesCount;
}

void _keysSerialize(
  Keys object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.email);
  writer.writeString(offsets[1], object.ikPub);
  writer.writeString(offsets[2], object.ikSec);
  writer.writeObject<IsarMapEntity>(
    offsets[3],
    allOffsets,
    IsarMapEntitySchema.serialize,
    object.opkMap,
  );
  writer.writeObject<IsarMapEntity>(
    offsets[4],
    allOffsets,
    IsarMapEntitySchema.serialize,
    object.pqopkMap,
  );
  writer.writeString(offsets[5], object.pqspkPub);
  writer.writeString(offsets[6], object.pqspkSec);
  writer.writeString(offsets[7], object.spkPub);
  writer.writeString(offsets[8], object.spkSec);
}

Keys _keysDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Keys();
  object.email = reader.readString(offsets[0]);
  object.id = id;
  object.ikPub = reader.readString(offsets[1]);
  object.ikSec = reader.readString(offsets[2]);
  object.opkMap = reader.readObjectOrNull<IsarMapEntity>(
        offsets[3],
        IsarMapEntitySchema.deserialize,
        allOffsets,
      ) ??
      IsarMapEntity();
  object.pqopkMap = reader.readObjectOrNull<IsarMapEntity>(
        offsets[4],
        IsarMapEntitySchema.deserialize,
        allOffsets,
      ) ??
      IsarMapEntity();
  object.pqspkPub = reader.readString(offsets[5]);
  object.pqspkSec = reader.readString(offsets[6]);
  object.spkPub = reader.readString(offsets[7]);
  object.spkSec = reader.readString(offsets[8]);
  return object;
}

P _keysDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readObjectOrNull<IsarMapEntity>(
            offset,
            IsarMapEntitySchema.deserialize,
            allOffsets,
          ) ??
          IsarMapEntity()) as P;
    case 4:
      return (reader.readObjectOrNull<IsarMapEntity>(
            offset,
            IsarMapEntitySchema.deserialize,
            allOffsets,
          ) ??
          IsarMapEntity()) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _keysGetId(Keys object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _keysGetLinks(Keys object) {
  return [];
}

void _keysAttach(IsarCollection<dynamic> col, Id id, Keys object) {
  object.id = id;
}

extension KeysQueryWhereSort on QueryBuilder<Keys, Keys, QWhere> {
  QueryBuilder<Keys, Keys, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension KeysQueryWhere on QueryBuilder<Keys, Keys, QWhereClause> {
  QueryBuilder<Keys, Keys, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Keys, Keys, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Keys, Keys, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Keys, Keys, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterWhereClause> emailEqualTo(String email) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'email',
        value: [email],
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterWhereClause> emailNotEqualTo(String email) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'email',
              lower: [],
              upper: [email],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'email',
              lower: [email],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'email',
              lower: [email],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'email',
              lower: [],
              upper: [email],
              includeUpper: false,
            ));
      }
    });
  }
}

extension KeysQueryFilter on QueryBuilder<Keys, Keys, QFilterCondition> {
  QueryBuilder<Keys, Keys, QAfterFilterCondition> emailEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> emailGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> emailLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> emailBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'email',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> emailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> emailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> emailContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> emailMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'email',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikPubEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ikPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikPubGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ikPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikPubLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ikPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikPubBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ikPub',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikPubStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ikPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikPubEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ikPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikPubContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ikPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikPubMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ikPub',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikPubIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ikPub',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikPubIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ikPub',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikSecEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ikSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikSecGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ikSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikSecLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ikSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikSecBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ikSec',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikSecStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ikSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikSecEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ikSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikSecContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ikSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikSecMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ikSec',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikSecIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ikSec',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> ikSecIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ikSec',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkPubEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pqspkPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkPubGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pqspkPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkPubLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pqspkPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkPubBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pqspkPub',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkPubStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pqspkPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkPubEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pqspkPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkPubContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pqspkPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkPubMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pqspkPub',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkPubIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pqspkPub',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkPubIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pqspkPub',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkSecEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pqspkSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkSecGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pqspkSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkSecLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pqspkSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkSecBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pqspkSec',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkSecStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pqspkSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkSecEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pqspkSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkSecContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pqspkSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkSecMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pqspkSec',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkSecIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pqspkSec',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqspkSecIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pqspkSec',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkPubEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spkPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkPubGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'spkPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkPubLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'spkPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkPubBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'spkPub',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkPubStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'spkPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkPubEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'spkPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkPubContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'spkPub',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkPubMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'spkPub',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkPubIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spkPub',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkPubIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'spkPub',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkSecEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spkSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkSecGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'spkSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkSecLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'spkSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkSecBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'spkSec',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkSecStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'spkSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkSecEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'spkSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkSecContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'spkSec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkSecMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'spkSec',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkSecIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spkSec',
        value: '',
      ));
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> spkSecIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'spkSec',
        value: '',
      ));
    });
  }
}

extension KeysQueryObject on QueryBuilder<Keys, Keys, QFilterCondition> {
  QueryBuilder<Keys, Keys, QAfterFilterCondition> opkMap(
      FilterQuery<IsarMapEntity> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'opkMap');
    });
  }

  QueryBuilder<Keys, Keys, QAfterFilterCondition> pqopkMap(
      FilterQuery<IsarMapEntity> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'pqopkMap');
    });
  }
}

extension KeysQueryLinks on QueryBuilder<Keys, Keys, QFilterCondition> {}

extension KeysQuerySortBy on QueryBuilder<Keys, Keys, QSortBy> {
  QueryBuilder<Keys, Keys, QAfterSortBy> sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortByIkPub() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ikPub', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortByIkPubDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ikPub', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortByIkSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ikSec', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortByIkSecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ikSec', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortByPqspkPub() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pqspkPub', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortByPqspkPubDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pqspkPub', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortByPqspkSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pqspkSec', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortByPqspkSecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pqspkSec', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortBySpkPub() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spkPub', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortBySpkPubDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spkPub', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortBySpkSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spkSec', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> sortBySpkSecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spkSec', Sort.desc);
    });
  }
}

extension KeysQuerySortThenBy on QueryBuilder<Keys, Keys, QSortThenBy> {
  QueryBuilder<Keys, Keys, QAfterSortBy> thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenByIkPub() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ikPub', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenByIkPubDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ikPub', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenByIkSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ikSec', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenByIkSecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ikSec', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenByPqspkPub() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pqspkPub', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenByPqspkPubDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pqspkPub', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenByPqspkSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pqspkSec', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenByPqspkSecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pqspkSec', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenBySpkPub() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spkPub', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenBySpkPubDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spkPub', Sort.desc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenBySpkSec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spkSec', Sort.asc);
    });
  }

  QueryBuilder<Keys, Keys, QAfterSortBy> thenBySpkSecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spkSec', Sort.desc);
    });
  }
}

extension KeysQueryWhereDistinct on QueryBuilder<Keys, Keys, QDistinct> {
  QueryBuilder<Keys, Keys, QDistinct> distinctByEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Keys, Keys, QDistinct> distinctByIkPub(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ikPub', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Keys, Keys, QDistinct> distinctByIkSec(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ikSec', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Keys, Keys, QDistinct> distinctByPqspkPub(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pqspkPub', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Keys, Keys, QDistinct> distinctByPqspkSec(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pqspkSec', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Keys, Keys, QDistinct> distinctBySpkPub(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'spkPub', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Keys, Keys, QDistinct> distinctBySpkSec(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'spkSec', caseSensitive: caseSensitive);
    });
  }
}

extension KeysQueryProperty on QueryBuilder<Keys, Keys, QQueryProperty> {
  QueryBuilder<Keys, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Keys, String, QQueryOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<Keys, String, QQueryOperations> ikPubProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ikPub');
    });
  }

  QueryBuilder<Keys, String, QQueryOperations> ikSecProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ikSec');
    });
  }

  QueryBuilder<Keys, IsarMapEntity, QQueryOperations> opkMapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'opkMap');
    });
  }

  QueryBuilder<Keys, IsarMapEntity, QQueryOperations> pqopkMapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pqopkMap');
    });
  }

  QueryBuilder<Keys, String, QQueryOperations> pqspkPubProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pqspkPub');
    });
  }

  QueryBuilder<Keys, String, QQueryOperations> pqspkSecProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pqspkSec');
    });
  }

  QueryBuilder<Keys, String, QQueryOperations> spkPubProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spkPub');
    });
  }

  QueryBuilder<Keys, String, QQueryOperations> spkSecProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spkSec');
    });
  }
}

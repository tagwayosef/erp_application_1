// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLedgerModelCollection on Isar {
  IsarCollection<LedgerModel> get ledgerModels => this.collection();
}

const LedgerModelSchema = CollectionSchema(
  name: r'LedgerModel',
  id: 7900112773558041933,
  properties: {
    r'accountName': PropertySchema(
      id: 0,
      name: r'accountName',
      type: IsarType.string,
    ),
    r'credit': PropertySchema(
      id: 1,
      name: r'credit',
      type: IsarType.double,
    ),
    r'date': PropertySchema(
      id: 2,
      name: r'date',
      type: IsarType.string,
    ),
    r'debit': PropertySchema(
      id: 3,
      name: r'debit',
      type: IsarType.double,
    ),
    r'description': PropertySchema(
      id: 4,
      name: r'description',
      type: IsarType.string,
    ),
    r'entryType': PropertySchema(
      id: 5,
      name: r'entryType',
      type: IsarType.string,
    ),
    r'partyName': PropertySchema(
      id: 6,
      name: r'partyName',
      type: IsarType.string,
    ),
    r'paymentType': PropertySchema(
      id: 7,
      name: r'paymentType',
      type: IsarType.string,
    ),
    r'referenceNo': PropertySchema(
      id: 8,
      name: r'referenceNo',
      type: IsarType.string,
    )
  },
  estimateSize: _ledgerModelEstimateSize,
  serialize: _ledgerModelSerialize,
  deserialize: _ledgerModelDeserialize,
  deserializeProp: _ledgerModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _ledgerModelGetId,
  getLinks: _ledgerModelGetLinks,
  attach: _ledgerModelAttach,
  version: '3.1.0+1',
);

int _ledgerModelEstimateSize(
  LedgerModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.accountName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.date;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.entryType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.partyName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.paymentType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.referenceNo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _ledgerModelSerialize(
  LedgerModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accountName);
  writer.writeDouble(offsets[1], object.credit);
  writer.writeString(offsets[2], object.date);
  writer.writeDouble(offsets[3], object.debit);
  writer.writeString(offsets[4], object.description);
  writer.writeString(offsets[5], object.entryType);
  writer.writeString(offsets[6], object.partyName);
  writer.writeString(offsets[7], object.paymentType);
  writer.writeString(offsets[8], object.referenceNo);
}

LedgerModel _ledgerModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LedgerModel(
    accountName: reader.readStringOrNull(offsets[0]),
    credit: reader.readDouble(offsets[1]),
    date: reader.readStringOrNull(offsets[2]),
    debit: reader.readDouble(offsets[3]),
    description: reader.readStringOrNull(offsets[4]),
    entryType: reader.readStringOrNull(offsets[5]),
    partyName: reader.readStringOrNull(offsets[6]),
    paymentType: reader.readStringOrNull(offsets[7]),
    referenceNo: reader.readStringOrNull(offsets[8]),
  );
  object.id = id;
  return object;
}

P _ledgerModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _ledgerModelGetId(LedgerModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _ledgerModelGetLinks(LedgerModel object) {
  return [];
}

void _ledgerModelAttach(
    IsarCollection<dynamic> col, Id id, LedgerModel object) {
  object.id = id;
}

extension LedgerModelQueryWhereSort
    on QueryBuilder<LedgerModel, LedgerModel, QWhere> {
  QueryBuilder<LedgerModel, LedgerModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LedgerModelQueryWhere
    on QueryBuilder<LedgerModel, LedgerModel, QWhereClause> {
  QueryBuilder<LedgerModel, LedgerModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<LedgerModel, LedgerModel, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterWhereClause> idBetween(
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
}

extension LedgerModelQueryFilter
    on QueryBuilder<LedgerModel, LedgerModel, QFilterCondition> {
  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      accountNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accountName',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      accountNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accountName',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      accountNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      accountNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accountName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      accountNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accountName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      accountNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accountName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      accountNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accountName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      accountNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accountName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      accountNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accountName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      accountNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accountName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      accountNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountName',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      accountNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accountName',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> creditEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'credit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      creditGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'credit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> creditLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'credit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> creditBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'credit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> dateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'date',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      dateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'date',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> dateEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> dateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> dateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> dateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> dateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> dateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> dateContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> dateMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'date',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> debitEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'debit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      debitGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'debit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> debitLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'debit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> debitBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'debit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      entryTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'entryType',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      entryTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'entryType',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      entryTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      entryTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      entryTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      entryTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entryType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      entryTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'entryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      entryTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'entryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      entryTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'entryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      entryTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'entryType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      entryTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entryType',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      entryTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'entryType',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      partyNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partyName',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      partyNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partyName',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      partyNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      partyNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'partyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      partyNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'partyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      partyNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'partyName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      partyNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'partyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      partyNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'partyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      partyNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'partyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      partyNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'partyName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      partyNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partyName',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      partyNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'partyName',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      paymentTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentType',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      paymentTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentType',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      paymentTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      paymentTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      paymentTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      paymentTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      paymentTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paymentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      paymentTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paymentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      paymentTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      paymentTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      paymentTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentType',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      paymentTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentType',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      referenceNoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'referenceNo',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      referenceNoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'referenceNo',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      referenceNoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      referenceNoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'referenceNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      referenceNoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'referenceNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      referenceNoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'referenceNo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      referenceNoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'referenceNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      referenceNoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'referenceNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      referenceNoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'referenceNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      referenceNoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'referenceNo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      referenceNoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceNo',
        value: '',
      ));
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterFilterCondition>
      referenceNoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'referenceNo',
        value: '',
      ));
    });
  }
}

extension LedgerModelQueryObject
    on QueryBuilder<LedgerModel, LedgerModel, QFilterCondition> {}

extension LedgerModelQueryLinks
    on QueryBuilder<LedgerModel, LedgerModel, QFilterCondition> {}

extension LedgerModelQuerySortBy
    on QueryBuilder<LedgerModel, LedgerModel, QSortBy> {
  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByAccountName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountName', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByAccountNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountName', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByCredit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'credit', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByCreditDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'credit', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByDebit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'debit', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByDebitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'debit', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByEntryType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryType', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByEntryTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryType', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByPartyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByPartyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByPaymentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentType', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByPaymentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentType', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByReferenceNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNo', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> sortByReferenceNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNo', Sort.desc);
    });
  }
}

extension LedgerModelQuerySortThenBy
    on QueryBuilder<LedgerModel, LedgerModel, QSortThenBy> {
  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByAccountName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountName', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByAccountNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountName', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByCredit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'credit', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByCreditDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'credit', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByDebit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'debit', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByDebitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'debit', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByEntryType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryType', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByEntryTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryType', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByPartyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByPartyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partyName', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByPaymentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentType', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByPaymentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentType', Sort.desc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByReferenceNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNo', Sort.asc);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QAfterSortBy> thenByReferenceNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNo', Sort.desc);
    });
  }
}

extension LedgerModelQueryWhereDistinct
    on QueryBuilder<LedgerModel, LedgerModel, QDistinct> {
  QueryBuilder<LedgerModel, LedgerModel, QDistinct> distinctByAccountName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QDistinct> distinctByCredit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'credit');
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QDistinct> distinctByDebit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'debit');
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QDistinct> distinctByEntryType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entryType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QDistinct> distinctByPartyName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partyName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QDistinct> distinctByPaymentType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LedgerModel, LedgerModel, QDistinct> distinctByReferenceNo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceNo', caseSensitive: caseSensitive);
    });
  }
}

extension LedgerModelQueryProperty
    on QueryBuilder<LedgerModel, LedgerModel, QQueryProperty> {
  QueryBuilder<LedgerModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LedgerModel, String?, QQueryOperations> accountNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountName');
    });
  }

  QueryBuilder<LedgerModel, double, QQueryOperations> creditProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'credit');
    });
  }

  QueryBuilder<LedgerModel, String?, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<LedgerModel, double, QQueryOperations> debitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'debit');
    });
  }

  QueryBuilder<LedgerModel, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<LedgerModel, String?, QQueryOperations> entryTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entryType');
    });
  }

  QueryBuilder<LedgerModel, String?, QQueryOperations> partyNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partyName');
    });
  }

  QueryBuilder<LedgerModel, String?, QQueryOperations> paymentTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentType');
    });
  }

  QueryBuilder<LedgerModel, String?, QQueryOperations> referenceNoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceNo');
    });
  }
}

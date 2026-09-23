// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetInventoryModelCollection on Isar {
  IsarCollection<InventoryModel> get inventoryModels => this.collection();
}

const InventoryModelSchema = CollectionSchema(
  name: r'InventoryModel',
  id: -6585919663430944371,
  properties: {
    r'barcode': PropertySchema(
      id: 0,
      name: r'barcode',
      type: IsarType.string,
    ),
    r'category': PropertySchema(
      id: 1,
      name: r'category',
      type: IsarType.string,
    ),
    r'cost': PropertySchema(
      id: 2,
      name: r'cost',
      type: IsarType.double,
    ),
    r'min': PropertySchema(
      id: 3,
      name: r'min',
      type: IsarType.double,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'price': PropertySchema(
      id: 5,
      name: r'price',
      type: IsarType.double,
    ),
    r'purchaseType': PropertySchema(
      id: 6,
      name: r'purchaseType',
      type: IsarType.string,
    ),
    r'qty': PropertySchema(
      id: 7,
      name: r'qty',
      type: IsarType.double,
    ),
    r'referenceNo': PropertySchema(
      id: 8,
      name: r'referenceNo',
      type: IsarType.string,
    ),
    r'supplier': PropertySchema(
      id: 9,
      name: r'supplier',
      type: IsarType.string,
    ),
    r'supplierId': PropertySchema(
      id: 10,
      name: r'supplierId',
      type: IsarType.long,
    )
  },
  estimateSize: _inventoryModelEstimateSize,
  serialize: _inventoryModelSerialize,
  deserialize: _inventoryModelDeserialize,
  deserializeProp: _inventoryModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _inventoryModelGetId,
  getLinks: _inventoryModelGetLinks,
  attach: _inventoryModelAttach,
  version: '3.1.0+1',
);

int _inventoryModelEstimateSize(
  InventoryModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.barcode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.purchaseType;
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
  {
    final value = object.supplier;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _inventoryModelSerialize(
  InventoryModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.barcode);
  writer.writeString(offsets[1], object.category);
  writer.writeDouble(offsets[2], object.cost);
  writer.writeDouble(offsets[3], object.min);
  writer.writeString(offsets[4], object.name);
  writer.writeDouble(offsets[5], object.price);
  writer.writeString(offsets[6], object.purchaseType);
  writer.writeDouble(offsets[7], object.qty);
  writer.writeString(offsets[8], object.referenceNo);
  writer.writeString(offsets[9], object.supplier);
  writer.writeLong(offsets[10], object.supplierId);
}

InventoryModel _inventoryModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = InventoryModel(
    barcode: reader.readStringOrNull(offsets[0]),
    category: reader.readStringOrNull(offsets[1]),
    cost: reader.readDouble(offsets[2]),
    min: reader.readDouble(offsets[3]),
    name: reader.readString(offsets[4]),
    price: reader.readDouble(offsets[5]),
    purchaseType: reader.readStringOrNull(offsets[6]),
    qty: reader.readDouble(offsets[7]),
    referenceNo: reader.readStringOrNull(offsets[8]),
    supplier: reader.readStringOrNull(offsets[9]),
    supplierId: reader.readLongOrNull(offsets[10]),
  );
  object.id = id;
  return object;
}

P _inventoryModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _inventoryModelGetId(InventoryModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _inventoryModelGetLinks(InventoryModel object) {
  return [];
}

void _inventoryModelAttach(
    IsarCollection<dynamic> col, Id id, InventoryModel object) {
  object.id = id;
}

extension InventoryModelQueryWhereSort
    on QueryBuilder<InventoryModel, InventoryModel, QWhere> {
  QueryBuilder<InventoryModel, InventoryModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension InventoryModelQueryWhere
    on QueryBuilder<InventoryModel, InventoryModel, QWhereClause> {
  QueryBuilder<InventoryModel, InventoryModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<InventoryModel, InventoryModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterWhereClause> idBetween(
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

extension InventoryModelQueryFilter
    on QueryBuilder<InventoryModel, InventoryModel, QFilterCondition> {
  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      barcodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'barcode',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      barcodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'barcode',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      barcodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      barcodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      barcodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      barcodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'barcode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      barcodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      barcodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      barcodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      barcodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'barcode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      barcodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'barcode',
        value: '',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      barcodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'barcode',
        value: '',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      categoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      categoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      categoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      categoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      costEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      costGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      costLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      costBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      minEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'min',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      minGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'min',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      minLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'min',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      minBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'min',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      priceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      priceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      priceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      priceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'price',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      purchaseTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'purchaseType',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      purchaseTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'purchaseType',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      purchaseTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'purchaseType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      purchaseTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'purchaseType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      purchaseTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'purchaseType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      purchaseTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'purchaseType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      purchaseTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'purchaseType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      purchaseTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'purchaseType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      purchaseTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'purchaseType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      purchaseTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'purchaseType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      purchaseTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'purchaseType',
        value: '',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      purchaseTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'purchaseType',
        value: '',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      qtyEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'qty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      qtyGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'qty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      qtyLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'qty',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      qtyBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'qty',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      referenceNoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'referenceNo',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      referenceNoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'referenceNo',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
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

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
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

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
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

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
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

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
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

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
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

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      referenceNoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'referenceNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      referenceNoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'referenceNo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      referenceNoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceNo',
        value: '',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      referenceNoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'referenceNo',
        value: '',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'supplier',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'supplier',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplier',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'supplier',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'supplier',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'supplier',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'supplier',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'supplier',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'supplier',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'supplier',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplier',
        value: '',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'supplier',
        value: '',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'supplierId',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'supplierId',
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplierId',
        value: value,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'supplierId',
        value: value,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'supplierId',
        value: value,
      ));
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterFilterCondition>
      supplierIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'supplierId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension InventoryModelQueryObject
    on QueryBuilder<InventoryModel, InventoryModel, QFilterCondition> {}

extension InventoryModelQueryLinks
    on QueryBuilder<InventoryModel, InventoryModel, QFilterCondition> {}

extension InventoryModelQuerySortBy
    on QueryBuilder<InventoryModel, InventoryModel, QSortBy> {
  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortByBarcode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcode', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      sortByBarcodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcode', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortByCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cost', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortByCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cost', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortByMin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'min', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortByMinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'min', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      sortByPurchaseType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseType', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      sortByPurchaseTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseType', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortByQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qty', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortByQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qty', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      sortByReferenceNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNo', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      sortByReferenceNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNo', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> sortBySupplier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplier', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      sortBySupplierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplier', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      sortBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      sortBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }
}

extension InventoryModelQuerySortThenBy
    on QueryBuilder<InventoryModel, InventoryModel, QSortThenBy> {
  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByBarcode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcode', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      thenByBarcodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcode', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cost', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cost', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByMin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'min', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByMinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'min', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      thenByPurchaseType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseType', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      thenByPurchaseTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseType', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qty', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenByQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'qty', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      thenByReferenceNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNo', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      thenByReferenceNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNo', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy> thenBySupplier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplier', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      thenBySupplierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplier', Sort.desc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      thenBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QAfterSortBy>
      thenBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }
}

extension InventoryModelQueryWhereDistinct
    on QueryBuilder<InventoryModel, InventoryModel, QDistinct> {
  QueryBuilder<InventoryModel, InventoryModel, QDistinct> distinctByBarcode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'barcode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QDistinct> distinctByCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cost');
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QDistinct> distinctByMin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'min');
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QDistinct> distinctByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'price');
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QDistinct>
      distinctByPurchaseType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchaseType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QDistinct> distinctByQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'qty');
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QDistinct> distinctByReferenceNo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceNo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QDistinct> distinctBySupplier(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplier', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InventoryModel, InventoryModel, QDistinct>
      distinctBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierId');
    });
  }
}

extension InventoryModelQueryProperty
    on QueryBuilder<InventoryModel, InventoryModel, QQueryProperty> {
  QueryBuilder<InventoryModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<InventoryModel, String?, QQueryOperations> barcodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'barcode');
    });
  }

  QueryBuilder<InventoryModel, String?, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<InventoryModel, double, QQueryOperations> costProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cost');
    });
  }

  QueryBuilder<InventoryModel, double, QQueryOperations> minProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'min');
    });
  }

  QueryBuilder<InventoryModel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<InventoryModel, double, QQueryOperations> priceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'price');
    });
  }

  QueryBuilder<InventoryModel, String?, QQueryOperations>
      purchaseTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchaseType');
    });
  }

  QueryBuilder<InventoryModel, double, QQueryOperations> qtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'qty');
    });
  }

  QueryBuilder<InventoryModel, String?, QQueryOperations>
      referenceNoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceNo');
    });
  }

  QueryBuilder<InventoryModel, String?, QQueryOperations> supplierProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplier');
    });
  }

  QueryBuilder<InventoryModel, int?, QQueryOperations> supplierIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierId');
    });
  }
}

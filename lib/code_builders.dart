import 'package:better_firestore/types/type.dart';

import 'helpers/naming.dart';

/// Builds the enum dart declaration for a given [field].
String enumBuilder(EnumType field) {
  final buf = StringBuffer();
  // start
  buf.writeln('enum ${field.enumName} {');

  // values
  for (final (i, enumValue) in field.validValues.indexed) {
    if (i + 1 == field.validValues.length) {
      buf.writeln('$enumValue(\'$enumValue\');');
    } else {
      buf.writeln('$enumValue(\'$enumValue\'),');
    }
  }

  // constructor
  buf.writeln();
  buf.writeln('final String name;');
  buf.writeln('const ${field.enumName}(this.name);');
  buf.writeln();

  // toString
  buf.writeln('@override');
  buf.writeln('String toString() {');
  buf.writeln('switch (this) {');
  for (final enumValue in field.validValues) {
    buf.writeln('case ${field.enumName}.$enumValue:');
    buf.writeln('return \'$enumValue\';');
  }
  buf.writeln('}}');

  // fromString
  buf.writeln();
  buf.writeln('static fromString(String value) {');
  buf.writeln('switch (value) {');
  for (final enumValue in field.validValues) {
    buf.writeln('case \'$enumValue\':');
    buf.writeln('return ${field.enumName}.$enumValue;');
  }
  buf.writeln('default:');
  buf.writeln('throw Exception(\'Unknown enum value: \$value\');');
  buf.writeln('}}');
  // end
  buf.writeln('}');
  return buf.toString();
}

/// Builds the object dart declaration for a given [field].
String objectClassBuilder(ObjectType field) {
  final buf = StringBuffer();
  // start
  buf.writeln('class ${field.objectName} {');

  // fields
  for (var f in field.fields) {
    buf.writeln(f.dartDeclaration);
  }

  // constructor
  buf.writeln();
  buf.writeln('${field.objectName}({');
  for (var f in field.fields) {
    if (f.nullable) {
      buf.writeln('this.${f.fieldName},');
    } else {
      buf.writeln('required this.${f.fieldName},');
    }
  }
  buf.writeln('});');

  // fromMap
  buf.writeln();
  buf.writeln('factory ${field.objectName}.fromMap(Map<String, dynamic> data) {');
  buf.writeln('return ${field.objectName}(');
  for (var f in field.fields) {
    buf.writeln('${f.dartFromSnapshot},');
  }
  buf.writeln(');');
  buf.writeln('}');

  // toMap
  buf.writeln();
  buf.writeln('Map<String, dynamic> toMap() {');
  buf.writeln('return {');
  for (var f in field.fields) {
    buf.writeln('${f.dartToMap},');
  }
  buf.writeln('};');
  buf.writeln('}');

  // end
  buf.writeln('}');
  return buf.toString();
}

/// Builds the QueryObjectBuilder dart declaration for a given [objectField].
String queryObjectBuilder(ObjectType objectField, String modelName) {
  final buf = StringBuffer();
  // start
  buf.writeln('class _${objectField.objectName}ObjectQueryBuilder {');

  // constructor
  buf.writeln('final _${modelName}Query _query;');
  buf.writeln('_${objectField.objectName}ObjectQueryBuilder(this._query);');

  for (final field in objectField.fields) {
    // order by
    buf.writeln(
        '_${objectField.objectName}ObjectQueryBuilder orderBy${capitalizeFirst(field.fieldName)}'
        '({bool descending = false}) {');
    buf.writeln(
        '_query.query = _query.query.orderBy(\'${objectField.fieldCollectionName}.${field.fieldName}\','
        ' descending: descending);');
    buf.writeln('return this;');
    buf.writeln('}');
    buf.writeln();
    // where
    buf.writeln(
        '_${objectField.objectName}ObjectQueryBuilder where${capitalizeFirst(field.fieldName)}({');
    buf.writeln('Object? isEqualTo,');
    buf.writeln('bool? isNull,');
    buf.writeln('List<Object?>? arrayContains,');
    buf.writeln('List<Object?>? arrayContainsAny,');
    buf.writeln('List<Object?>? whereIn,');
    buf.writeln('Object? isLessThan,');
    buf.writeln('Object? isLessThanOrEqualTo,');
    buf.writeln('Object? isGreaterThan,');
    buf.writeln('Object? isGreaterThanOrEqualTo,');
    buf.writeln('Object? isNotEqualTo,');
    buf.writeln('List<Object?>? whereNotIn,');
    buf.writeln('}) {');
    buf.writeln('_query.query = _query.query.where(');
    buf.writeln('\'${objectField.fieldCollectionName}.${field.fieldName}\',');
    buf.writeln('isEqualTo: isEqualTo,');
    buf.writeln('isNull: isNull,');
    buf.writeln('arrayContains: arrayContains,');
    buf.writeln('arrayContainsAny: arrayContainsAny,');
    buf.writeln('whereIn: whereIn,');
    buf.writeln('isLessThan: isLessThan,');
    buf.writeln('isLessThanOrEqualTo: isLessThanOrEqualTo,');
    buf.writeln('isGreaterThan: isGreaterThan,');
    buf.writeln('isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,');
    buf.writeln('isNotEqualTo: isNotEqualTo,');
    buf.writeln('whereNotIn: whereNotIn,');
    buf.writeln(');');
    buf.writeln('return this;');
    buf.writeln('}');
    buf.writeln();
  }

  // end
  buf.writeln('}');
  return buf.toString();
}

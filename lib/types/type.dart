import 'package:better_firestore/helpers/list_from_string.dart';
import 'package:better_firestore/helpers/naming.dart';

final typeExtractor = RegExp(r'^[a-z]+\??');
final defaultValueExtractor = RegExp(r'=[^,]+');
final validValuesExtractor = RegExp(r'\[[a-zA-Z, ]+\]');
final referenceExtractor = RegExp(r'@reference\([a-zA-Z]+\)');

abstract class FirestoreType {
  final String fieldName;
  final String fieldCollectionName;
  final bool nullable;
  final String? defaultValue;
  final List validValues;

  String get dartType;

  const FirestoreType({
    required this.fieldName,
    required this.nullable,
    required this.defaultValue,
    required this.validValues,
    required this.fieldCollectionName,
  });

  String get dartDeclaration {
    final buf = StringBuffer();
    // buf.write('final ');

    if (nullable) {
      buf.write('$dartType?');
    } else {
      buf.write(dartType);
    }

    buf.write(' $fieldName;');
    return buf.toString();
  }

  String get dartConstructor {
    final buf = StringBuffer();
    buf.write('required this.');
    buf.write(' $fieldName,');
    return buf.toString();
  }

  String get dartFromSnapshot {
    final buf = StringBuffer();
    buf.write('$fieldName: ');

    if (nullable) {
      buf.write('data[\'$fieldCollectionName\'] as $dartType?');
    } else {
      buf.write('data[\'$fieldCollectionName\'] as $dartType');
    }

    if (defaultValue != null) {
      buf.write(' ?? $defaultValue');
    }

    return buf.toString();
  }

  String get dartToMap {
    final buf = StringBuffer();
    buf.write('\'$fieldCollectionName\': $fieldName');
    return buf.toString();
  }

  static ({
    String type,
    String? defaultValue,
    List<String> validValues,
    bool nullable,
  }) getConfigData(String configString) {
    configString = configString.trim();
    final type = typeExtractor.firstMatch(configString)!.group(0)!;
    final defaultValue =
        defaultValueExtractor.firstMatch(configString)?.group(0)?.substring(1).trim();
    final validValues = listFromString(validValuesExtractor.firstMatch(configString)?.group(0));

    return (
      type: type,
      defaultValue: defaultValue,
      validValues: validValues,
      nullable: type.endsWith('?'),
    );
  }

  static FirestoreType fromString({
    required String name,
    required String type,
    required String? defaultValue,
    required List<String> validValues,
    required bool nullable,
  }) {
    if (validValues.isNotEmpty) {
      return EnumType(
        fieldName: snakeToCamelCase(name),
        nullable: nullable,
        defaultValue: defaultValue,
        validValues: validValues.map((e) => e.trim()).toList(),
        enumName: name[0].toUpperCase() + name.substring(1),
        fieldCollectionName: name,
      );
    }

    if (type.startsWith('string')) {
      return StringType(
        fieldName: snakeToCamelCase(name),
        nullable: nullable,
        defaultValue: defaultValue,
        validValues: [],
        fieldCollectionName: name,
      );
    }

    if (type.startsWith('number')) {
      return NumberType(
        fieldName: snakeToCamelCase(name),
        nullable: nullable,
        defaultValue: defaultValue,
        validValues: [],
        fieldCollectionName: name,
      );
    }

    if (type.startsWith('boolean')) {
      return BooleanType(
        fieldName: snakeToCamelCase(name),
        nullable: nullable,
        defaultValue: defaultValue,
        validValues: [],
        fieldCollectionName: name,
      );
    }

    if (type.startsWith('timestamp')) {
      return TimestampType(
        fieldName: snakeToCamelCase(name),
        nullable: nullable,
        defaultValue: defaultValue,
        validValues: [],
        fieldCollectionName: name,
      );
    }

    throw Exception('Unknown type: $type');
  }
}

class StringType extends FirestoreType {
  @override
  String get dartType => 'String';

  const StringType({
    required super.fieldName,
    required super.nullable,
    required super.defaultValue,
    required super.validValues,
    required super.fieldCollectionName,
  });
}

// number type
class NumberType extends FirestoreType {
  @override
  String get dartType => 'num';

  const NumberType({
    required super.fieldName,
    required super.nullable,
    required super.defaultValue,
    required super.validValues,
    required super.fieldCollectionName,
  });
}

// boolean type
class BooleanType extends FirestoreType {
  @override
  String get dartType => 'bool';

  const BooleanType({
    required super.fieldName,
    required super.nullable,
    required super.defaultValue,
    required super.validValues,
    required super.fieldCollectionName,
  });
}

// timestamp type
class TimestampType extends FirestoreType {
  @override
  String get dartType => 'DateTime';

  const TimestampType({
    required super.fieldName,
    required super.nullable,
    required super.defaultValue,
    required super.validValues,
    required super.fieldCollectionName,
  });

  @override
  String get dartFromSnapshot {
    final buf = StringBuffer();
    buf.write('$fieldName: ');
    buf.write('(');
    if (nullable) {
      buf.write('data[\'$fieldCollectionName\'] as Timestamp?');
    } else {
      buf.write('data[\'$fieldCollectionName\'] as Timestamp');
    }
    buf.write(')');

    if (nullable) {
      buf.write('?.toDate()');
    } else {
      buf.write('.toDate()');
    }

    if (defaultValue != null) {
      buf.write(' ?? $defaultValue');
    }

    return buf.toString();
  }

  @override
  String get dartToMap {
    final buf = StringBuffer();
    buf.write('\'$fieldCollectionName\': ');
    buf.write('Timestamp.fromDate($fieldName)');
    return buf.toString();
  }
}

// enum type
class EnumType extends FirestoreType {
  final String enumName;

  @override
  String get dartType => enumName;

  const EnumType({
    required super.fieldName,
    required super.nullable,
    required super.defaultValue,
    required super.validValues,
    required this.enumName,
    required super.fieldCollectionName,
  });

  @override
  String get dartFromSnapshot {
    final buf = StringBuffer();
    buf.write('$fieldName: ');

    if (nullable) {
      buf.write('$enumName.fromString(data[\'$fieldName\'] as String?)');
    } else {
      buf.write('$enumName.fromString(data[\'$fieldName\'] as String)');
    }

    if (defaultValue != null) {
      buf.write(' ?? $enumName.$defaultValue');
    }

    return buf.toString();
  }

  @override
  String get dartToMap {
    final buf = StringBuffer();
    buf.write('\'$fieldName\': $fieldName.toString()');
    return buf.toString();
  }

  @override
  String get dartDeclaration {
    final buf = StringBuffer();
    // buf.write('final ');

    if (nullable) {
      buf.write('$enumName?');
    } else {
      buf.write(enumName);
    }

    buf.write(' $fieldName;');
    return buf.toString();
  }
}

// object (map/json) type
class ObjectType extends FirestoreType {
  final String objectName;
  final List<FirestoreType> fields;

  @override
  String get dartType => objectName;

  const ObjectType({
    required super.fieldName,
    required super.nullable,
    required this.objectName,
    required super.fieldCollectionName,
    required this.fields,
  }) : super(validValues: const [], defaultValue: null);

  @override
  String get dartFromSnapshot {
    final buf = StringBuffer();
    buf.write('$fieldName: ');

    final String string = '$objectName.fromMap(data[\'$fieldName\'] as Map<String, dynamic>)';
    if (nullable) {
      buf.write('data[\'$fieldName\'] == null ? null : $string');
    } else {
      buf.write(string);
    }

    return buf.toString();
  }

  @override
  String get dartToMap {
    final buf = StringBuffer();
    if (nullable) {
      buf.write('\'$fieldName\': $fieldName?.toMap()');
    } else {
      buf.write('\'$fieldName\': $fieldName.toMap()');
    }
    return buf.toString();
  }

  @override
  String get dartDeclaration {
    final buf = StringBuffer();
    // buf.write('final ');

    if (nullable) {
      buf.write('$objectName?');
    } else {
      buf.write(objectName);
    }

    buf.write(' $fieldName;');
    return buf.toString();
  }
}

class ReferenceType extends FirestoreType {
  final String referenceClassName;

  @override
  String get dartType => referenceClassName;

  const ReferenceType({
    required super.fieldName,
    required super.nullable,
    required this.referenceClassName,
    required super.fieldCollectionName,
  }) : super(validValues: const [], defaultValue: null);

  @override
  String get dartFromSnapshot {
    final buf = StringBuffer();
    buf.write('$fieldName: ');

    buf.write('$referenceClassName.collection.doc((data[\'$fieldName\'] as DocumentReference).id)');

    return buf.toString();
  }

  @override
  String get dartToMap {
    final buf = StringBuffer();
    buf.write('\'$fieldName\': $fieldName');
    return buf.toString();
  }

  @override
  String get dartDeclaration {
    final buf = StringBuffer();
    // buf.write('final ');

    if (nullable) {
      buf.write('${referenceClassName}Ref?');
    } else {
      buf.write('${referenceClassName}Ref');
    }

    buf.write(' $fieldName;');
    return buf.toString();
  }
}

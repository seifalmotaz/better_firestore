library better_firestore;

import 'dart:io';

import 'package:better_firestore/types/type.dart';
import 'package:yaml/yaml.dart';

import 'code_builders.dart';
import 'helpers/naming.dart';

main() async {
  final firestoreFile = File('firestore.yaml');
  final fileData = loadYaml(firestoreFile.readAsStringSync()) as YamlMap;
  final firestore = fileData.value.cast<String, YamlMap>();

  final collections = <CollectionModel>[];

  for (final collection in firestore.keys) {
    collections.addAll(extractCollection(
      collection,
      firestore[collection]!.value.cast<String, Object>(),
      '',
    ));
  }

  final buf = StringBuffer();
  buf.writeln('import \'package:cloud_firestore/cloud_firestore.dart\';');
  buf.writeln();

  for (final collection in collections) {
    // typedefs instead of Firestore types for better type safety
    buf.writeln('typedef ${collection.modelName}Doc = DocumentSnapshot<${collection.modelName}>;');
    buf.writeln('typedef ${collection.modelName}Ref = DocumentReference<${collection.modelName}>;');
    buf.writeln(
        'typedef ${collection.modelName}Col = CollectionReference<${collection.modelName}>;');
    buf.writeln();

    // create enums for fields
    for (final field in collection.fields) {
      if (field is EnumType) {
        buf.writeln(enumBuilder(field));
        buf.writeln();
      } else if (field is ObjectType) {
        buf.writeln(objectClassBuilder(field));
        buf.writeln(queryObjectBuilder(field, collection.modelName));
        buf.writeln();
      }
      buf.writeln();
    }

    // model
    buf.writeln('class ${collection.modelName} {');
    // id field
    buf.writeln('final String id;');
    for (final field in collection.fields) {
      buf.writeln(field.dartDeclaration);
    }
    buf.writeln('${collection.modelName}({');
    buf.writeln('required this.id,');
    for (final field in collection.fields) {
      buf.writeln(field.dartConstructor);
    }
    buf.writeln('});');
    buf.writeln();
    buf.writeln('static ${collection.modelName} fromSnapshot(DocumentSnapshot snapshot) {');
    buf.writeln('final data = snapshot.data()! as Map<String, dynamic>;');
    buf.writeln('return ${collection.modelName}(');
    buf.writeln('id: snapshot.id,');
    for (final field in collection.fields) {
      buf.writeln('${field.dartFromSnapshot},');
    }
    buf.writeln(');');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('Map<String, Object?> toMap() {');
    buf.writeln('return {');
    for (final field in collection.fields) {
      buf.writeln('${field.dartToMap},');
    }
    buf.writeln('};');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('static ${collection.modelName}Col get collection => '
        'FirebaseFirestore.instance.collection(\'${collection.collectionPath}\')'
        '.withConverter<${collection.modelName}>('
        'fromFirestore: (snapshot, _) => ${collection.modelName}.fromSnapshot(snapshot),'
        'toFirestore: (model, _) => model.toMap(),'
        ');');

    // static field to get query builder
    buf.writeln();
    buf.writeln('// ignore: library_private_types_in_public_api');
    buf.writeln('static _${collection.modelName}QueryBuilder get query => '
        '_${collection.modelName}QueryBuilder(collection);');

    // getter for doc reference
    buf.writeln();
    buf.writeln('${collection.modelName}Ref get reference => collection.doc(id);');

    // static function to get all documents
    buf.writeln();
    buf.writeln('static Future<List<${collection.modelName}>> getAll() async {');
    buf.writeln('final snapshot = await collection.get();');
    buf.writeln('return snapshot.docs.map((doc) => doc.data()).toList();');
    buf.writeln('}');

    // insert function
    buf.writeln();
    buf.writeln('static Future<${collection.modelName}Ref> insert({');
    for (final field in collection.fields) {
      buf.writeln('required ${field.dartType} ${field.fieldName},');
    }
    buf.writeln('}) async {');
    buf.writeln(
        'final nativeCollection = FirebaseFirestore.instance.collection(\'${collection.collectionPath}\');');
    buf.writeln('final ref = nativeCollection.doc();');
    buf.writeln('await ref.set({');
    for (final field in collection.fields) {
      buf.writeln('"${field.fieldName}": ${field.fieldName},');
    }
    buf.writeln('});');
    buf.writeln('return collection.doc(ref.id);');
    buf.writeln('}');

    // update function
    buf.writeln();
    buf.writeln('static Future<void> update({');
    buf.writeln('required String id,');
    for (final field in collection.fields) {
      buf.writeln('${field.dartType}? ${field.fieldName},');
      // set field to null
      buf.writeln('bool ${field.fieldName}Null = false,');
    }
    buf.writeln('}) async {');
    buf.writeln('final ref = collection.doc(id);');
    buf.writeln('await ref.update({');
    for (final field in collection.fields) {
      buf.writeln('if (${field.fieldName}Null) "${field.fieldName}": null,');
      buf.writeln('if (${field.fieldName} != null) "${field.fieldName}": ${field.fieldName},');
    }
    buf.writeln('});');
    buf.writeln('}');

    // none static function to delete document
    buf.writeln();
    buf.writeln('Future<void> delete() async {');
    buf.writeln('await reference.delete();');
    buf.writeln('}');
    buf.writeln();

    // class end
    buf.writeln('}');

    // query class
    buf.writeln();
    buf.writeln('class _${collection.modelName}Query {');
    buf.writeln('Query<${collection.modelName}> query;');
    buf.writeln('_${collection.modelName}Query(this.query);');
    buf.writeln('}');
    buf.writeln();

    // query builder
    buf.writeln();
    buf.writeln('class _${collection.modelName}QueryBuilder {');
    buf.writeln('final _${collection.modelName}Query _query;');
    buf.writeln('_${collection.modelName}QueryBuilder(Query<${collection.modelName}> query)'
        ':_query = _${collection.modelName}Query(query);');
    buf.writeln();
    buf.writeln('_${collection.modelName}QueryBuilder limit(int limit) {');
    buf.writeln('_query.query = _query.query.limit(limit);');
    buf.writeln('return this;');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('_${collection.modelName}QueryBuilder startAt(List<Object?> values) {');
    buf.writeln('_query.query = _query.query.startAt(values);');
    buf.writeln('return this;');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('_${collection.modelName}QueryBuilder startAfter(List<Object?> values) {');
    buf.writeln('_query.query = _query.query.startAfter(values);');
    buf.writeln('return this;');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('_${collection.modelName}QueryBuilder endAt(List<Object?> values) {');
    buf.writeln('_query.query = _query.query.endAt(values);');
    buf.writeln('return this;');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('_${collection.modelName}QueryBuilder endBefore(List<Object?> values) {');
    buf.writeln('_query.query = _query.query.endBefore(values);');
    buf.writeln('return this;');
    buf.writeln('}');
    buf.writeln();
    for (final field in collection.fields) {
      if (field is ObjectType) {
        buf.writeln('_${field.objectName}ObjectQueryBuilder get ${field.fieldName} => '
            '_${field.objectName}ObjectQueryBuilder(_query);');
        continue;
      }
      // order by
      buf.writeln('_${collection.modelName}QueryBuilder orderBy${capitalizeFirst(field.fieldName)}'
          '({bool descending = false}) {');
      buf.writeln(
          '_query.query = _query.query.orderBy(\'${field.fieldName}\', descending: descending);');
      buf.writeln('return this;');
      buf.writeln('}');
      buf.writeln();
      // where
      buf.writeln(
          '_${collection.modelName}QueryBuilder where${capitalizeFirst(field.fieldName)}({');
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
      buf.writeln('\'${field.fieldName}\',');
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
    buf.writeln('}');
  }

  final output = File('./lib/generated/firestore.dart');
  if (output.existsSync() == false) output.createSync();
  output.writeAsStringSync(buf.toString());

  await Process.run('dart', ['format', './lib/firestore_models.dart']);
}

class CollectionModel {
  /// Dart class name
  final String modelName;

  /// Firestore collection name
  final String collectionName;

  /// Parent collections like `users` in `users/{userId}/posts/{postId}`
  final String parents;

  /// Fields in the collection
  final List<FirestoreType> fields;

  ///

  const CollectionModel({
    required this.modelName,
    required this.collectionName,
    required this.fields,
    this.parents = '',
  });

  String get collectionPath => collectionName;
}

List<CollectionModel> extractCollection(
    String collectionModelName, Map<String, Object> data, String parentName) {
  final collectionModels = <CollectionModel>[];
  final fields = <FirestoreType>[];

  late String modelName;
  late String collectionName;

  {
    final splitName = collectionModelName.split('/'); // example `users/User`
    final name = splitName.last;
    modelName = name[0].toUpperCase() + name.substring(1);
    collectionName = splitName.first;
  }

  for (final field in data.keys) {
    final fieldValue = data[field]!;

    if (field.contains('/') && fieldValue is YamlMap) {
      collectionModels.addAll(extractCollection(
        field,
        fieldValue.value.cast<String, Object>(),
        '$parentName.$collectionName',
      ));
      continue;
    }

    final fieldConfigString = fieldValue is String
        ? fieldValue
        : (fieldValue as YamlMap)['_config'] as String? ?? 'object?';

    final fieldConfig = FirestoreType.getConfigData(fieldConfigString);
    if (fieldValue is String) {
      if (fieldConfigString.contains('reference')) {
        final reference = fieldConfigString.split('(').last.split(')').first;
        fields.add(ReferenceType(
          fieldName: snakeToCamelCase(field),
          fieldCollectionName: field,
          nullable: fieldConfig.nullable,
          referenceClassName: reference,
        ));
        continue;
      }
      fields.add(FirestoreType.fromString(
        name: field,
        type: fieldConfig.type,
        nullable: fieldConfig.nullable,
        validValues: fieldConfig.validValues,
        defaultValue: fieldConfig.defaultValue,
      ));
      continue;
    }

    final fieldData =
        (fieldValue as YamlMap).value.cast<String, Object>(); // include _config and object fields
    final objectFields = <FirestoreType>[];

    for (final objectField in fieldData.keys) {
      if (objectField == '_config') continue; // ignore _config field (already handled)

      final objectFieldValue = fieldData[objectField]!;
      final objectFieldConfigString = objectFieldValue is String
          ? objectFieldValue
          : (objectFieldValue as YamlMap)['_config'] as String;

      final objectFieldConfig = FirestoreType.getConfigData(objectFieldConfigString);
      if (objectFieldValue is String) {
        if (objectFieldValue.contains('reference')) {
          final reference = objectFieldValue.split('(').last.split(')').first;
          objectFields.add(ReferenceType(
            fieldName: snakeToCamelCase(objectField),
            fieldCollectionName: field,
            nullable: objectFieldConfig.nullable,
            referenceClassName: reference,
          ));
          continue;
        }
        objectFields.add(FirestoreType.fromString(
          name: objectField,
          type: objectFieldConfig.type,
          nullable: objectFieldConfig.nullable,
          validValues: objectFieldConfig.validValues,
          defaultValue: objectFieldConfig.defaultValue,
        ));
        continue;
      }

      final objectFieldData = (objectFieldValue as YamlMap)
          .value
          .cast<String, Object>(); // include _config and object fields
      final objectObjectFields = <FirestoreType>[];
      objectFieldData.removeWhere((key, value) => key.startsWith('_'));

      for (final objectObjectField in objectFieldData.keys) {
        final objectObjectFieldValue = objectFieldData[objectObjectField]!;
        final objectObjectFieldConfigString = objectObjectFieldValue is String
            ? objectObjectFieldValue
            : (objectObjectFieldValue as YamlMap)['_config'] as String;

        final objectObjectFieldConfig = FirestoreType.getConfigData(objectObjectFieldConfigString);
        if (objectObjectFieldValue is String) {
          objectObjectFields.add(FirestoreType.fromString(
            name: objectObjectField,
            type: objectObjectFieldConfig.type,
            nullable: objectObjectFieldConfig.nullable,
            validValues: objectObjectFieldConfig.validValues,
            defaultValue: objectObjectFieldConfig.defaultValue,
          ));
          continue;
        }

        throw Exception('Object object object fields are not supported');
      }

      objectFields.add(ObjectType(
        fieldName: snakeToCamelCase(objectField),
        fieldCollectionName: field,
        nullable: objectFieldConfig.nullable,
        fields: objectObjectFields,
        objectName: capitalizeFirst(snakeToCamelCase(objectField)),
      ));
    }

    fields.add(ObjectType(
      fieldName: snakeToCamelCase(field),
      fieldCollectionName: field,
      nullable: fieldConfig.nullable,
      fields: objectFields,
      objectName: capitalizeFirst(snakeToCamelCase(field)),
    ));
  }

  return [
    ...collectionModels,
    CollectionModel(
      fields: fields,
      modelName: modelName,
      collectionName: collectionName,
      parents: parentName,
    )
  ];
}

String camelToSnakeCase(String input) {
  return input.replaceAllMapped(RegExp('([A-Z])'), (Match m) => '_${m[0]!.toLowerCase()}');
}

String snakeToCamelCase(String input) {
  return input.replaceAllMapped(RegExp('(_[a-z])'), (Match m) => m[0]![1].toUpperCase());
}

String capitalizeFirst(String input) {
  return input[0].toUpperCase() + input.substring(1);
}

String enumName(String modelName, String fieldName) {
  return modelName + capitalizeFirst(snakeToCamelCase(fieldName));
}

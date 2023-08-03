// convert string to List<String>

List<String> listFromString(String? value) {
  if (value == null) {
    return [];
  }
  // validate string
  if (value.isEmpty) {
    return [];
  }
  if (value.startsWith('[') == false) {
    return [];
  }
  if (value.endsWith(']') == false) {
    return [];
  }
  // remove [ and ]
  value = value.substring(1, value.length - 1);
  return value.split(',');
}

import 'dart:convert';
import 'dart:io';

/// A JSON fixture from `test/fixtures/`, shaped like the API v1 responses
/// in `bc-launcher-server/packages/contracts/openapi.json`.
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

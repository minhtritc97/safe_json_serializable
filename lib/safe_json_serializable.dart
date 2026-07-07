import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:json_serializable/json_serializable.dart';
import 'package:source_gen/source_gen.dart';

import 'src/helpers.dart';

/// build_runner entry point. Runs json_serializable's generator with the safe
/// [safeTypeHelpers] prepended (so they win over the defaults), while honouring
/// all the usual json_serializable `options` from `build.yaml`
/// (`explicit_to_json`, `include_if_null`, `field_rename`, …).
///
/// Emits the same `json_serializable.g.part` output, so the stock builder must
/// be disabled in the consuming package's `build.yaml`.
Builder safeJsonSerializable(BuilderOptions options) {
  var configJson = options.config;
  // `run_only_if_triggered` is used by build_runner, not by the config parser.
  if (configJson.containsKey('run_only_if_triggered')) {
    configJson = Map.of(configJson)..remove('run_only_if_triggered');
  }

  final JsonSerializable config;
  try {
    config = JsonSerializable.fromJson(configJson);
  } on CheckedFromJsonException catch (e) {
    throw StateError(
      'Could not parse the options provided for `safe_json_serializable`'
      '${e.key != null ? ' (problem with "${e.key}")' : ''}: '
      '${e.message ?? e.innerError}',
    );
  }

  return SharedPartBuilder(
    [
      JsonSerializableGenerator.withDefaultHelpers(
        safeTypeHelpers,
        config: config,
      ),
      const JsonEnumGenerator(),
      const JsonLiteralGenerator(),
    ],
    'json_serializable',
  );
}

import 'package:build/build.dart';
import 'package:json_serializable/json_serializable.dart';
import 'package:source_gen/source_gen.dart';

import 'src/helpers.dart';

/// build_runner entry point. Runs json_serializable's generator with the safe
/// [safeTypeHelpers] prepended (so they win over the defaults). Emits the same
/// `json_serializable.g.part` output, so the stock builder must be disabled in
/// the consuming package's `build.yaml`.
Builder safeJsonSerializable(BuilderOptions options) => SharedPartBuilder(
      [JsonSerializableGenerator.withDefaultHelpers(safeTypeHelpers)],
      'json_serializable',
    );

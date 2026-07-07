import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_serializable/type_helper.dart';

bool _nullable(DartType t, bool defaultProvided) =>
    defaultProvided || t.nullabilitySuffix == NullabilitySuffix.question;

// ---------------------------------------------------------------------------
// Scalars: int / double / num / String / bool
// ---------------------------------------------------------------------------

/// Base for a JSON-native scalar. Emits `safeX(expr)` for a nullable field (or
/// one with `@JsonKey(defaultValue:)`), and `(safeX(expr) ?? failParse(...))`
/// for a non-null field with no default (coerce, else fail loud). Applies
/// wherever json_serializable uses the type — fields, list/map elements, etc.
abstract class _ScalarHelper extends TypeHelper<TypeHelperContext> {
  const _ScalarHelper();

  bool matches(DartType t);
  String get fn;
  String get typeName;

  @override
  Object? serialize(DartType t, String expression, TypeHelperContext context) =>
      matches(t) ? expression : null;

  @override
  Object? deserialize(
    DartType t,
    String expression,
    TypeHelperContext context,
    bool defaultProvided,
  ) {
    if (!matches(t)) return null;
    return _nullable(t, defaultProvided)
        ? '$fn($expression)'
        : '($fn($expression) ?? failParse($expression, ${"'$typeName'"}))';
  }
}

class SafeIntHelper extends _ScalarHelper {
  const SafeIntHelper();
  @override
  bool matches(DartType t) => t.isDartCoreInt;
  @override
  String get fn => 'safeInt';
  @override
  String get typeName => 'int';
}

class SafeDoubleHelper extends _ScalarHelper {
  const SafeDoubleHelper();
  @override
  bool matches(DartType t) => t.isDartCoreDouble;
  @override
  String get fn => 'safeDouble';
  @override
  String get typeName => 'double';
}

class SafeNumHelper extends _ScalarHelper {
  const SafeNumHelper();
  @override
  bool matches(DartType t) => t.isDartCoreNum;
  @override
  String get fn => 'safeNum';
  @override
  String get typeName => 'num';
}

class SafeStringHelper extends _ScalarHelper {
  const SafeStringHelper();
  @override
  bool matches(DartType t) => t.isDartCoreString;
  @override
  String get fn => 'safeString';
  @override
  String get typeName => 'String';
}

class SafeBoolHelper extends _ScalarHelper {
  const SafeBoolHelper();
  @override
  bool matches(DartType t) => t.isDartCoreBool;
  @override
  String get fn => 'safeBool';
  @override
  String get typeName => 'bool';
}

// ---------------------------------------------------------------------------
// DateTime (not JSON-native: defer serialization to the default helper)
// ---------------------------------------------------------------------------

class SafeDateTimeHelper extends TypeHelper<TypeHelperContext> {
  const SafeDateTimeHelper();

  // DateTime lives in dart:core; match by name.
  bool _isDateTime(DartType t) => t.element?.name == 'DateTime';

  @override
  Object? serialize(DartType t, String expression, TypeHelperContext context) =>
      null; // let json_serializable emit toIso8601String()

  @override
  Object? deserialize(
    DartType t,
    String expression,
    TypeHelperContext context,
    bool defaultProvided,
  ) {
    if (!_isDateTime(t)) return null;
    return _nullable(t, defaultProvided)
        ? 'safeDateTime($expression)'
        : "(safeDateTime($expression) ?? failParse($expression, 'DateTime'))";
  }
}

// ---------------------------------------------------------------------------
// List<T?>? — guard the outer `as List`, recurse into the element type
// ---------------------------------------------------------------------------

class SafeListHelper extends TypeHelper<TypeHelperContext> {
  const SafeListHelper();

  @override
  Object? serialize(DartType t, String expression, TypeHelperContext context) =>
      null; // defer list encoding to the default helper

  @override
  Object? deserialize(
    DartType t,
    String expression,
    TypeHelperContext context,
    bool defaultProvided,
  ) {
    if (!t.isDartCoreList || t is! InterfaceType) return null;
    final element = t.typeArguments.first;
    // Recurse: reuse whatever helper handles the element (scalars, models…).
    final elementExpr = context.deserialize(element, 'e');
    if (elementExpr == null) return null; // unknown element -> defer
    final inner = '[for (final e in ($expression as List)) $elementExpr]';
    return _nullable(t, defaultProvided)
        ? '($expression is List ? $inner : null)'
        : "($expression is List ? $inner : failParse($expression, 'List'))";
  }
}

// ---------------------------------------------------------------------------
// Nested models (any class with a `fromJson` factory) — guard the `as Map`
// ---------------------------------------------------------------------------

class SafeModelHelper extends TypeHelper<TypeHelperContext> {
  const SafeModelHelper();

  bool _isModel(DartType t) {
    final el = t.element;
    return el is ClassElement && el.getNamedConstructor('fromJson') != null;
  }

  @override
  Object? serialize(DartType t, String expression, TypeHelperContext context) =>
      null; // defer model encoding to the default helper (instance.toJson())

  @override
  Object? deserialize(
    DartType t,
    String expression,
    TypeHelperContext context,
    bool defaultProvided,
  ) {
    if (!_isModel(t)) return null;
    // Bare type name without a trailing `?` (so `Address?` -> `Address`).
    final display = t.getDisplayString();
    final name =
        display.endsWith('?') ? display.substring(0, display.length - 1) : display;
    final call = '$name.fromJson(asStringMap($expression))';
    return _nullable(t, defaultProvided)
        ? '($expression is Map ? $call : null)'
        : call;
  }
}

/// The full ordered set of safe helpers. Element/leaf types first, then the
/// collections and models that recurse into them.
const safeTypeHelpers = <TypeHelper>[
  SafeIntHelper(),
  SafeDoubleHelper(),
  SafeNumHelper(),
  SafeStringHelper(),
  SafeBoolHelper(),
  SafeDateTimeHelper(),
  SafeModelHelper(),
  SafeListHelper(),
];

## 0.3.0

* **Behaviour change:** a non-nullable `List` with no `@JsonKey(defaultValue:)`
  now falls back to an empty list instead of throwing. The empty list is the
  type's own neutral value, so it invents no data — unlike a scalar, where `0`
  or `''` would be a made-up answer. Elements keep their existing rules: a bad
  element becomes `null` in a `List<T?>`, and still fails loud in a `List<T>`.
* A non-nullable nested model with a non-object value now reports a
  `FormatException` via `failParse` instead of letting `asStringMap` throw a
  bare `as Map` `TypeError`. Same fail-fast semantics, readable error.

## 0.2.1

* Raise the SDK constraint to `^3.9.0` to match `json_serializable` ^6.14.0 and
  `json_annotation` ^4.12.0, which already require it. No code changes.

## 0.2.0

* Support json_serializable options

## 0.1.0

* Initial release.
* Crash-safe fromJson for json_serializable via custom TypeHelpers, with no
  fork and no per-field annotations.
* Tolerant parsing for int, double, num, String, bool, DateTime, nested models
  and lists (incl. list/collection elements).
* Nullable fields become null on bad data; non-null fields coerce when possible
  and otherwise fail fast, unless @JsonKey(defaultValue:) provides a fallback.

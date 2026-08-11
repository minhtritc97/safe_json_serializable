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

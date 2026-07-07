## 0.1.0

* Initial release.
* Crash-safe fromJson for json_serializable via custom TypeHelpers, with no
  fork and no per-field annotations.
* Tolerant parsing for int, double, num, String, bool, DateTime, nested models
  and lists (incl. list/collection elements).
* Nullable fields become null on bad data; non-null fields coerce when possible
  and otherwise fail fast, unless @JsonKey(defaultValue:) provides a fallback.

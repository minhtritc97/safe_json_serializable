# safe_json_serializable

[![pub package](https://img.shields.io/pub/v/safe_json_serializable.svg)](https://pub.dev/packages/safe_json_serializable)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Crash-safe `fromJson` for [`json_serializable`][js] — **without forking it and
without per-field annotations**.

> Not affiliated with the official `json_serializable`. This is an **add-on**
> that runs on top of it: it reuses json_serializable's generator and only
> replaces the casts that crash.

When a backend changes a field's type (`123` becomes `"123"`, an object becomes
`[]`, a list becomes `null`), the code json_serializable generates casts with
`as` and **throws**, crashing your app. `safe_json_serializable` plugs tolerant
`TypeHelper`s into that generation, so every field — scalars, `DateTime`, nested
models, and lists — is parsed defensively. Your models stay plain
`@JsonSerializable()`.

```dart
@JsonSerializable()
class User {
  final int? id;                            // "123" -> 123 · "abc"/null -> null
  final String name;                        // 123 -> "123" · missing -> throws (see below)
  @JsonKey(defaultValue: 0) final int qty;  // "abc"/missing -> 0
  final DateTime? createdAt;                 // tolerant parse
  final List<int?>? scores;                  // not-a-list -> null · ["1","x"] -> [1, null]
  final Address? home;                       // non-object -> null (no crash)
  final List<Address?>? tags;                // non-list -> null · bad element -> null
}
```

[js]: https://pub.dev/packages/json_serializable

## Why not the alternatives?

| Approach | Crash-safe scalars | Nested / lists | No fork | No per-field code |
|---|---|---|---|---|
| Forking `json_serializable` | ✅ | ✅ | ❌ (track upstream) | ✅ |
| A `JsonConverter` add-on | ⚠️ nullable only | ⚠️ per-model converters | ✅ | ❌ |
| **`safe_json_serializable`** | ✅ | ✅ | ✅ | ✅ |

`TypeHelper` is json_serializable's official hook for how each type generates
code. Because these helpers replace only the crashing casts and reuse everything
else, they apply everywhere a type appears — including inside lists and maps —
and you keep all of json_serializable's features (maps, enums, generics,
records).

## Install

Two packages, mirroring `json_annotation` / `json_serializable`:

```yaml
dependencies:
  safe_json_annotation: ^0.2.0   # runtime helpers the generated code calls

dev_dependencies:
  safe_json_serializable: ^0.2.0 # the build-time generator
  build_runner: ^2.4.0
```

Then, in your package's **`build.yaml`**, disable the stock json_serializable
builder and enable the safe one (this is the one non-obvious step):

```yaml
targets:
  $default:
    builders:
      json_serializable:
        enabled: false
      safe_json_serializable:safe_json_serializable:
        enabled: true
```

> **You don't need to declare `json_serializable` yourself** — this builder
> brings it, and the annotations (`@JsonSerializable`, `@JsonKey`) come from
> `json_annotation`, which `safe_json_annotation` re-exports.
>
> **Always keep the `json_serializable: enabled: false` line.** If
> `json_serializable` is ever a direct dependency (yours or another package's),
> its builder would otherwise collide with this one. If it isn't, disabling it
> is a harmless no-op.

### Options and `generate_for`

This builder honours all the usual json_serializable options
(`explicit_to_json`, `include_if_null`, `field_rename`, `create_to_json`, …) —
but put them **under the `safe_json_serializable` builder**, not under the
disabled `json_serializable` one:

```yaml
targets:
  $default:
    builders:
      json_serializable:
        enabled: false
      safe_json_serializable:safe_json_serializable:
        enabled: true
        options:
          explicit_to_json: true
          include_if_null: false
          field_rename: snake
        generate_for:
          include:
            - lib/**/models/**.dart
```

Options left on the disabled `json_serializable` builder are ignored.

## Usage

Import `safe_json_annotation` in your models (it re-exports `json_annotation`,
so it's your only serialization import) and write ordinary json_serializable
classes:

```dart
import 'package:safe_json_annotation/safe_json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int? id;
  final String name;
  final List<int?>? scores;

  User({this.id, required this.name, this.scores});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

Generate as usual:

```sh
dart run build_runner build
```

Every `@JsonSerializable()` class in the package is now crash-safe.

## Behaviour

The generator knows each field's declared type **and nullability**, so it picks
the right behaviour per field automatically.

| Field                          | Bad input             | Result                        |
|--------------------------------|-----------------------|-------------------------------|
| `int?` / `double?` / `String?` | `"abc"`, wrong type   | `null`                        |
| `int` / `String` (no default)  | `"abc"`, missing      | **throws** `FormatException`  |
| `int` `@JsonKey(defaultValue:)`| `"abc"`, missing      | the default                   |
| any of the above               | `"123"` for an `int`  | coerced (`123`)               |
| `DateTime?`                    | bad string            | `null`                        |
| `List<int?>?`                  | not a list            | `null`                        |
| `List<int?>?`                  | `["1","x",2]`         | `[1, null, 2]`                |
| `Model?`                       | not an object         | `null`                        |
| `List<Model?>?`                | not a list / bad elem | `null` / element `null`       |

### Nullable vs non-nullable (fail-fast)

- **Nullable** (`int?`): a wrong/unparseable value becomes `null`. Never throws.
- **Non-nullable, no default** (`int`): a *coercible* value is coerced
  (`"123" -> 123`), but a genuinely missing/unparseable value **throws** a clear
  `FormatException`. It does **not** silently invent `0`/`''` — a required field
  that isn't there is a real problem you want surfaced, not hidden.
- **Non-nullable with `@JsonKey(defaultValue: X)`**: same coercion, falls back
  to `X` instead of throwing.

So pick the policy per field with idiomatic json_serializable tools: make it
nullable to tolerate anything, or add `defaultValue:` to accept a fallback —
otherwise it fails loud.

Scalar coercion tolerates `"123"↔123`, `123→"123"`, `"1"/"true"→true`, epoch
millis / ISO strings for `DateTime`, and so on.

## Limitations

- **Generic models** (`Foo<Bar>` using `genericArgumentFactories`) are not
  specially handled — annotate those fields with `@JsonKey` if needed.
- Only `List` collections are outer-guarded. `Set`/`Iterable` and the outer
  shape of `Map` use json_serializable's defaults (their scalar *values* are
  still parsed safely).
- `explicit_to_json` is off, so `toJson()` leaves nested objects as objects
  until `jsonEncode` is applied — standard json_serializable behaviour.

## How it works

json_serializable exposes `JsonSerializableGenerator.withDefaultHelpers([...])`.
This package prepends safe helpers for `int`, `double`, `num`, `String`, `bool`,
`DateTime`, `List`, and nested models, so they take precedence over the built-in
casts. The generated code calls the small tolerant parsers (`safeInt`,
`safeString`, …) shipped in the [`safe_json_annotation`][rt] runtime package.

[rt]: https://pub.dev/packages/safe_json_annotation

## License

MIT — see [LICENSE](LICENSE).

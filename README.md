# safe_type_helpers_builder

The build-time generator for [`safe_type_helpers`][pkg] — a `build_runner`
builder that runs [`json_serializable`][js] with crash-safe `TypeHelper`s so
`fromJson` tolerates backend type changes.

You normally don't use this package directly. Add it as a **dev dependency**
alongside the runtime package and see the [`safe_type_helpers` README][pkg] for
full setup and behaviour.

```yaml
dependencies:
  safe_type_helpers: ^0.1.0

dev_dependencies:
  safe_type_helpers_builder: ^0.1.0
  build_runner: ^2.4.0
```

Then, in `build.yaml`, disable the stock json_serializable builder and enable
this one:

```yaml
targets:
  $default:
    builders:
      json_serializable:
        enabled: false
      safe_type_helpers_builder:safe_json_serializable:
        enabled: true
```

[pkg]: https://pub.dev/packages/safe_type_helpers
[js]: https://pub.dev/packages/json_serializable

## License

MIT — see [LICENSE](LICENSE).

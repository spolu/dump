# Build

```
cargo build --release
cargo lipo --targets x86_64-apple-ios --release   # iOS Simulator
cargo lipo --targets aarch64-apple-ios --release  # iOS
cbindgen ./src/lib.rs -c cbindgen.toml | grep -v \#include | uniq > target/bindings.h
```

Then copy to `macos` and `ios`:
```
cp ../srv/target/release/libsrv.dylib macos/
cp ../srv/target/bindings.h ios/Runner
cp ../srv/target/universal/release/libsrv.a ios/
```

Finally also run:
```
dart run ffigen
```

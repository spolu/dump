# Build

```
cargo build --release
cargo lipo --release
cbindgen ./src/lib.rs -c cbindgen.toml | grep -v \#include | uniq > target/bindings.h
```

Then copy `target/release/build/libsrv.dylib` to the `app/macos` folder.

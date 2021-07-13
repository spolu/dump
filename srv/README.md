# Build

```
cargo build --release
cargo lipo --release
cbindgen ./src/lib.rs -c cbindgen.toml | grep -v \#include | uniq > target/bindings.h
```

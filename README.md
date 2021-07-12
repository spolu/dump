# Build Instructions

## Prerequesites

### Install Flutter

Follow Flutter's [Install Instructions](https://flutter.dev/docs/get-started/install)

### Install Rust

Follow Rust's [Install Instructions](https://www.rust-lang.org/tools/install)

### Clone Dump

```bash
git clone https://github.com/spolu/dump.git
cd dump
```

## Build MacOS app

```bash
cd app && flutter build macos && cd ..
```

## Build the Rust Backend Binary

```bash
cd srv && cargo build --release && cd ..
```

# Running Dump

Run the local Rust server:

```bash
RUST_LOG=info ./srv/target/release/srv
```

Start the MacOS app:
```bash
open ./app/build/macos/Build/Products/Release/Dump.app
```

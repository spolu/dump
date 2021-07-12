<img width="1050" alt="Screen Shot 2021-07-12 at 13 58 08" src="https://user-images.githubusercontent.com/15067/125283961-3488cc00-e319-11eb-9df0-b015785005d7.png">

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

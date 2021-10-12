# Dump -- Relentless journaling

<img width="1050" alt="Screen Shot 2021-07-12 at 13 58 08" src="https://user-images.githubusercontent.com/15067/125283961-3488cc00-e319-11eb-9df0-b015785005d7.png">

<img width="912" alt="Screen Shot 2021-10-12 at 20 22 46" src="https://user-images.githubusercontent.com/15067/137008987-09fd7aa4-ee35-4bb3-a66e-2d3315e347fd.png">

## Build Instructions

### Prerequesites

#### Install Flutter

Follow Flutter's [Install Instructions](https://flutter.dev/docs/get-started/install)

Switch to the `dev` channel and enable `MacOS` with:

```bash
flutter channel dev
sudo gem install cocoapods
flutter config --enable-macos-desktop
```

### Install Rust

Follow Rust's [Install Instructions](https://www.rust-lang.org/tools/install)

#### Clone Dump

```bash
git clone https://github.com/spolu/dump.git
cd dump
```

### Build Rust libraries

```
cd srv && cargo build --release && cd ..
cd srv && cargo lipo --targets x86_64-apple-ios,aarch64-apple-ios --release && cd ..
cd srv && cbindgen ./src/lib.rs -c cbindgen.toml | grep -v \#include | uniq > target/bindings.h && cd ..

cp srv/target/release/libsrv.dylib app/macos/
cp srv/target/bindings.h app/ios/Runner
cp srv/target/universal/release/libsrv.a app/ios/
```

### Build MacOS app

```bash
cd app && flutter build macos --release && cd ..
```

## Running Dump

Start the MacOS app:

```bash
open ./app/build/macos/Build/Products/Release/Dump.app
```

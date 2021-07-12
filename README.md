# Build Instructions

## Prerequesites

### Install Flutter

Follow Flutter's [Install Instructions](https://flutter.dev/docs/get-started/install)

### Install Rust

Follow Rust's [Install Instructions](https://www.rust-lang.org/tools/install)

### Clone Lit

```bash
git clone https://github.com/spolu/dump.git
```

## Build Web App

Navigate to the `app` subdirectory and run:

```bash
cd app/
flutter build web
```

Edit `build/web/index.html` and replace:
```html
<base href="/">
```
with:
```html
<base href="/static/">
```

## Build the Rust Backend Binary

Navigate to the `srv` subdirectory and run:

```bash
cd srv/
cargo build --release
```

# Running Lit

Navigate to the `srv` subdirectory and run:

```bash
RUST_LOG=info ./target/release/srv
```

Connect with your Web Browser at:
[http://127.0.0.1:13371/static/](http://127.0.0.1:13371/static/)

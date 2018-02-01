#!/bin/sh

set -ex

# ASan tests
cd asan

# Without this ASan fails under travis although it works in my machine.
export ASAN_OPTIONS="detect_leaks=0"

# Broken tests: these should fail
! RUSTFLAGS="-Z sanitizer=address" cargo run --example out-of-bounds --target x86_64-unknown-linux-gnu
! RUSTFLAGS="-Z sanitizer=address" cargo run --example use-after-free --target x86_64-unknown-linux-gnu

# ASan release builds fail to compile:
# ! RUSTFLAGS="-Z sanitizer=address" cargo run --example out-of-bounds --target x86_64-unknown-linux-gnu --release
# ! RUSTFLAGS="-Z sanitizer=address" cargo run --example use-after-free --target x86_64-unknown-linux-gnu --release

# Fixed tests: these should pass
RUSTFLAGS="-Z sanitizer=address" cargo run --example out-of-bounds-fixed --target x86_64-unknown-linux-gnu
RUSTFLAGS="-Z sanitizer=address" cargo run --example use-after-free-fixed --target x86_64-unknown-linux-gnu

# Test harness (pass):
RUSTFLAGS="-Z sanitizer=address" cargo test --target x86_64-unknown-linux-gnu
# RUSTFLAGS="-Z sanitizer=address" cargo test --target x86_64-unknown-linux-gnu --release

# Test harness (fail):
! RUSTFLAGS="-Z sanitizer=address" cargo test --features fail --target x86_64-unknown-linux-gnu
# ! RUSTFLAGS="-Z sanitizer=address" cargo test --features fail --target x86_64-unknown-linux-gnu --release

# MSan tests
cd ../msan

# Broken tests: these should fail
! RUSTFLAGS="-Z sanitizer=memory" cargo run --example uninitialized-read --target x86_64-unknown-linux-gnu
# This fails because the compiler optimizes the undefined behavior out, might need a better test
# ! RUSTFLAGS="-Z sanitizer=memory" cargo run --example uninitialized-read --target x86_64-unknown-linux-gnu --release

# Fixed tests: these should pass
RUSTFLAGS="-Z sanitizer=memory" cargo run --example uninitialized-read-fixed --target x86_64-unknown-linux-gnu
RUSTFLAGS="-Z sanitizer=memory" cargo run --example uninitialized-read-fixed --target x86_64-unknown-linux-gnu --release

# Test harness (pass):
# Fails because of: https://github.com/rust-lang/rust/issues/39610
# RUSTFLAGS="-Z sanitizer=memory" cargo test --target x86_64-unknown-linux-gnu
# RUSTFLAGS="-Z sanitizer=memory" cargo test --target x86_64-unknown-linux-gnu --release

# Test harness (fail):
# Fails for the wrong reason: https://github.com/rust-lang/rust/issues/39610
! RUSTFLAGS="-Z sanitizer=memory" cargo test --features fail --target x86_64-unknown-linux-gnu
! RUSTFLAGS="-Z sanitizer=memory" cargo test --features fail --target x86_64-unknown-linux-gnu --release

# LSan tests
cd ../lsan

# Broken tests: these should fail
# These tests don't fail for some reason:
# ! RUSTFLAGS="-Z sanitizer=leak" cargo run --example memory-leak --target x86_64-unknown-linux-gnu
# ! RUSTFLAGS="-Z sanitizer=leak" cargo run --example rc-cycle --target x86_64-unknown-linux-gnu
# ! RUSTFLAGS="-Z sanitizer=leak" cargo run --example memory-leak --target x86_64-unknown-linux-gnu --release
# ! RUSTFLAGS="-Z sanitizer=leak" cargo run --example rc-cycle --target x86_64-unknown-linux-gnu -- release

# Fixed tests: these should pass
RUSTFLAGS="-Z sanitizer=leak" cargo run --example memory-leak-fixed --target x86_64-unknown-linux-gnu
RUSTFLAGS="-Z sanitizer=leak" cargo run --example memory-leak-fixed --target x86_64-unknown-linux-gnu --release
RUSTFLAGS="-Z sanitizer=leak" cargo run --example rc-cycle-fixed --target x86_64-unknown-linux-gnu
RUSTFLAGS="-Z sanitizer=leak" cargo run --example rc-cycle-fixed --target x86_64-unknown-linux-gnu --release

# TSan tests
cd ../tsan

# Broken tests: these should fail
! RUSTFLAGS="-Z sanitizer=thread" cargo run --example data-race --target x86_64-unknown-linux-gnu
! RUSTFLAGS="-Z sanitizer=thread" cargo run --example data-race --target x86_64-unknown-linux-gnu --release

# Fixed tests: these should pass
RUSTFLAGS="-Z sanitizer=thread" cargo run --example data-race-fixed --target x86_64-unknown-linux-gnu
RUSTFLAGS="-Z sanitizer=thread" cargo run --example data-race-fixed --target x86_64-unknown-linux-gnu --release

# Test harness (pass):
# Fails because of https://github.com/rust-lang/rust/issues/39608
# RUSTFLAGS="-Z sanitizer=thread" cargo test --target x86_64-unknown-linux-gnu
# RUSTFLAGS="-Z sanitizer=thread" cargo test --target x86_64-unknown-linux-gnu --release
# setting RUST_TEST_THREADS=1 fixes it:
RUST_TEST_THREADS=1 RUSTFLAGS="-Z sanitizer=thread" cargo test --target x86_64-unknown-linux-gnu
RUST_TEST_THREADS=1 RUSTFLAGS="-Z sanitizer=thread" cargo test --target x86_64-unknown-linux-gnu --release

# Test harness (fail):
! RUSTFLAGS="-Z sanitizer=thread" cargo test --features fail --target x86_64-unknown-linux-gnu
! RUSTFLAGS="-Z sanitizer=thread" cargo test --features fail --target x86_64-unknown-linux-gnu --release

# `rust-san`

> How-to: Sanitize your Rust code!

- [Intro](#intro)
- [How to use the sanitizers?](#how-to-use-the-sanitizers)
- [Examples](#examples)
  - [AddressSanitizer](#addresssanitizer)
    - [Out of bounds access](#out-of-bounds-access)
    - [Use after free](#use-after-free)
  - [LeakSanitizer](#leaksanitizer)
    - [Memory leak](#memory-leak)
  - [MemorySanitizer](#memorysanitizer)
    - [Uninitialized read](#uninitialized-read)
  - [ThreadSanitizer](#threadsanitizer)
    - [Data race](#data-race)
- [Better backtraces](#better-backtraces)
- [Caveats / known bugs](#caveats--known-bugs)
  - [Unrealiable LeakSanitizer](#unrealiable-leaksanitizer)
  - [CARGO_INCREMENTAL](#cargo_incremental)
  - [MemorySanitizer: Use of uninitialized value in the test runner](#memorysanitizer-use-of-uninitialized-value-in-the-test-runner)
  - [ThreadSanitizer: Data race in the test runner](#threadsanitizer-data-race-in-the-test-runner)
- [License](#license)
  - [Contribution](#contribution)
      
## Intro

As of [nightly-2017-02-XX](https://github.com/rust-lang/rust/pull/38699),
`rustc` ships with **experimental** support for the following sanitizers: 

- [AddressSanitizer](https://clang.llvm.org/docs/AddressSanitizer.html)

- [LeakSanitizer](https://clang.llvm.org/docs/LeakSanitizer.html)

- [MemorySanitizer](https://clang.llvm.org/docs/MemorySanitizer.html)

- [ThreadSanitizer](https://clang.llvm.org/docs/ThreadSanitizer.html)

Note that sanitizer support is **only** available on x86_64 Linux.

## How to use the sanitizers?

You have to compile your crate and all its dependencies with the `-Z sanitizer`
flag. Setting `RUSTFLAGS` does the trick:

```
# if you have a binary crate (an application) or want to sanitize an example, use `cargo run`
$ RUSTFLAGS="-Z sanitizer=$SAN" cargo run --target x86_64-unknown-linux-gnu

# if you have a library crate, use `cargo test` to sanitize your unit tests
$ RUSTFLAGS="-Z sanitizer=$SAN" cargo test --target x86_64-unknown-linux-gnu
```

Where `$SAN` is one of `address`, `leak`, `memory` or `thread`.

Be sure to always pass `--target x86_64-unknown-linux-gnu` to Cargo or you'll
end up sanitizing the build scripts that Cargo runs.

## Examples

This section shows what kind of issues can be detected with the sanitizers
through some examples that you can find in this repository 

### AddressSanitizer

This sanitizer can detect, among other things, out of bounds accesses and uses
of freed memory.

#### Out of bounds access

`asan/examples/out-of-bounds.rs`

``` rust
fn main() {
    let xs = [0, 1, 2, 3];
    let y = unsafe { *xs.as_ptr().offset(4) };
}
```

```
$ ( cd asan && \
    RUSTFLAGS="-Z sanitizer=address" cargo run --target x86_64-unknown-linux-gnu --example out-of-bounds )
     Running `target/x86_64-unknown-linux-gnu/debug/examples/out-of-bounds`
=================================================================
==821==ERROR: AddressSanitizer: stack-buffer-overflow on address 0x7ffe9808e5f0 at pc 0x56500e096f7e bp 0x7ffe9808e5b0 sp 0x7ffe9808e5a8
READ of size 4 at 0x7ffe9808e5f0 thread T0
    #0 0x56500e096f7d in out_of_bounds::main::h86e0ef2cff62a67d $PWD/examples/out-of-bounds.rs:3
    #1 0x56500e18b536 in __rust_maybe_catch_panic ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/out-of-bounds+0xfe536)
    #2 0x56500e183ee9 in std::rt::lang_start::h6954771f55df116b ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/out-of-bounds+0xf6ee9)
    #3 0x56500e097002 in main ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/out-of-bounds+0xa002)
    #4 0x7f9e21a46290 in __libc_start_main (/usr/lib/libc.so.6+0x20290)
    #5 0x56500e096719 in _start ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/out-of-bounds+0x9719)

Address 0x7ffe9808e5f0 is located in stack of thread T0 at offset 48 in frame
    #0 0x56500e096d5f in out_of_bounds::main::h86e0ef2cff62a67d $PWD/examples/out-of-bounds.rs:1

  This frame has 1 object(s):
    [32, 48) 'xs' <== Memory access at offset 48 overflows this variable
HINT: this may be a false positive if your program uses some custom stack unwind mechanism or swapcontext
      (longjmp and C++ exceptions *are* supported)
SUMMARY: AddressSanitizer: stack-buffer-overflow $PWD/examples/out-of-bounds.rs:3 in out_of_bounds::main::h86e0ef2cff62a67d
Shadow bytes around the buggy address:
  0x100053009c60: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x100053009c70: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x100053009c80: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x100053009c90: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x100053009ca0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
=>0x100053009cb0: 00 00 00 00 00 00 00 00 f1 f1 f1 f1 00 00[f3]f3
  0x100053009cc0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x100053009cd0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x100053009ce0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x100053009cf0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x100053009d00: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
Shadow byte legend (one shadow byte represents 8 application bytes):
  Addressable:           00
  Partially addressable: 01 02 03 04 05 06 07
  Heap left redzone:       fa
  Heap right redzone:      fb
  Freed heap region:       fd
  Stack left redzone:      f1
  Stack mid redzone:       f2
  Stack right redzone:     f3
  Stack partial redzone:   f4
  Stack after return:      f5
  Stack use after scope:   f8
  Global redzone:          f9
  Global init order:       f6
  Poisoned by user:        f7
  Container overflow:      fc
  Array cookie:            ac
  Intra object redzone:    bb
  ASan internal:           fe
  Left alloca redzone:     ca
  Right alloca redzone:    cb
==821==ABORTING
```

#### Use after free

`asan/examples/use-after-free.rs`

``` rust
fn main() {
    let xs = vec![0, 1, 2, 3];
    let y = xs.as_ptr();
    drop(xs);
    let z = unsafe { *y };
}
```

```
$ ( cd asan && \
    RUSTFLAGS="-Z sanitizer=address" cargo run --target x86_64-unknown-linux-gnu --example use-after-free )
     Running `target/x86_64-unknown-linux-gnu/debug/examples/use-after-free`
=================================================================
==8768==ERROR: AddressSanitizer: heap-use-after-free on address 0x60200000efb0 at pc 0x55b0dfb2da24 bp 0x7ffccf297230 sp 0x7ffccf297228
READ of size 4 at 0x60200000efb0 thread T0
    #0 0x55b0dfb2da23 in use_after_free::main::hd24e5b31a91cd260 $PWD/examples/use-after-free.rs:5
    #1 0x55b0dfc22046 in __rust_maybe_catch_panic ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/use-after-free+0x103046)
    #2 0x55b0dfc1a9f9 in std::rt::lang_start::h6954771f55df116b ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/use-after-free+0xfb9f9)
    #3 0x55b0dfb2db12 in main ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/use-after-free+0xeb12)
    #4 0x7fb186053290 in __libc_start_main (/usr/lib/libc.so.6+0x20290)
    #5 0x55b0dfb28869 in _start ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/use-after-free+0x9869)

0x60200000efb0 is located 0 bytes inside of 16-byte region [0x60200000efb0,0x60200000efc0)
freed by thread T0 here:
    #0 0x55b0dfbe0290 in __interceptor_cfree.localalias.0 $RUST_SRC/src/compiler-rt/lib/asan/asan_malloc_linux.cc:54
    #1 0x55b0dfb2c05c in alloc::heap::deallocate::hfc4464969f6c2d6d $RUST_SRC/src/liballoc/heap.rs:113
    #2 0x55b0dfb2d584 in _$LT$alloc..raw_vec..RawVec$LT$T$GT$$u20$as$u20$core..ops..Drop$GT$::drop::h379e52d625f89e1f $RUST_SRC/src/liballoc/raw_vec.rs:551
    #3 0x55b0dfb2b780 in drop::h7608d0590516eb20 ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/use-after-free+0xc780)
    #4 0x55b0dfb29988 in drop_contents::ha8e051e1000be907 ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/use-after-free+0xa988)
    #5 0x55b0dfb2b7e6 in drop::ha8e051e1000be907 ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/use-after-free+0xc7e6)
    #6 0x55b0dfb2ac38 in core::mem::drop::h1c3f8290e9a15dc0 $RUST_SRC/src/libcore/mem.rs:614
    #7 0x55b0dfb2d9e3 in use_after_free::main::hd24e5b31a91cd260 $PWD/examples/use-after-free.rs:4
    #8 0x55b0dfc22046 in __rust_maybe_catch_panic ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/use-after-free+0x103046)

previously allocated by thread T0 here:
    #0 0x55b0dfbe0448 in malloc $RUST_SRC/src/compiler-rt/lib/asan/asan_malloc_linux.cc:64
    #1 0x55b0dfb2d0af in alloc::heap::allocate::hada3930d4dfed51a $RUST_SRC/src/liballoc/heap.rs:59
    #2 0x55b0dfb2c0b0 in alloc::heap::exchange_malloc::h1ae17faa3583b58c $RUST_SRC/src/liballoc/heap.rs:138
    #3 0x55b0dfb2d816 in use_after_free::main::hd24e5b31a91cd260 $PWD/examples/use-after-free.rs:2
    #4 0x55b0dfc22046 in __rust_maybe_catch_panic ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/use-after-free+0x103046)

SUMMARY: AddressSanitizer: heap-use-after-free $PWD/examples/use-after-free.rs:5 in use_after_free::main::hd24e5b31a91cd260
Shadow bytes around the buggy address:
  0x0c047fff9da0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff9db0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff9dc0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff9dd0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff9de0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
=>0x0c047fff9df0: fa fa fa fa fa fa[fd]fd fa fa 05 fa fa fa fd fa
  0x0c047fff9e00: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff9e10: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff9e20: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff9e30: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff9e40: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
Shadow byte legend (one shadow byte represents 8 application bytes):
  Addressable:           00
  Partially addressable: 01 02 03 04 05 06 07
  Heap left redzone:       fa
  Heap right redzone:      fb
  Freed heap region:       fd
  Stack left redzone:      f1
  Stack mid redzone:       f2
  Stack right redzone:     f3
  Stack partial redzone:   f4
  Stack after return:      f5
  Stack use after scope:   f8
  Global redzone:          f9
  Global init order:       f6
  Poisoned by user:        f7
  Container overflow:      fc
  Array cookie:            ac
  Intra object redzone:    bb
  ASan internal:           fe
  Left alloca redzone:     ca
  Right alloca redzone:    cb
==8768==ABORTING
```

### LeakSanitizer

This sanitizer can detect memory leaks.

#### Memory leak

`lsan/examples/memory-leak.rs`

``` rust
use std::mem;

fn main() {
    let xs = vec![0, 1, 2, 3];
    mem::forget(xs);
}
```

```
$ ( cd lsan && \
    RUSTFLAGS="-Z sanitizer=leak" cargo run --target x86_64-unknown-linux-gnu --example memory-leak ) 
     Running `target/x86_64-unknown-linux-gnu/debug/examples/memory-leak`

=================================================================
==16341==ERROR: LeakSanitizer: detected memory leaks

Direct leak of 16 byte(s) in 1 object(s) allocated from:
    #0 0x56322c0acb1f in __interceptor_malloc $RUST_SRC/src/compiler-rt/lib/lsan/lsan_interceptors.cc:55
    #1 0x56322c0a7aaa in alloc::heap::exchange_malloc::h1ae17faa3583b58c $RUST_SRC/src/liballoc/heap.rs:138
    #2 0x56322c0a7afc in memory_leak::main::h0003a08cbe34b70c $PWD/examples/memory-leak.rs:4
    #3 0x56322c0df896 in __rust_maybe_catch_panic ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/memory-leak+0x3d896)

SUMMARY: LeakSanitizer: 16 byte(s) leaked in 1 allocation(s).
```

### MemorySanitizer

This sanitizer can detect reads of uninitialized memory.

#### Uninitialized read

`msan/examples/uninitialized-read.rs`

``` rust
use std::mem;

fn main() {
    let xs: [u8; 4] = unsafe { mem::uninitialized() };
    let y = xs[0] + xs[1];
}
```

```
$ ( cd msan && \
    RUSTFLAGS="-Z sanitizer=memory" cargo run --target x86_64-unknown-linux-gnu --example uninitialized-read )
     Running `target/x86_64-unknown-linux-gnu/debug/examples/uninitialized-read`
==21418==WARNING: MemorySanitizer: use-of-uninitialized-value
    #0 0x56107230e7da in uninitialized_read::main::h0c073cea3836efc1 $PWD/examples/uninitialized-read.rs:5
    #1 0x56107238b446 in __rust_maybe_catch_panic ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/uninitialized-read+0x87446)
    #2 0x561072383df9 in std::rt::lang_start::h6954771f55df116b ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/uninitialized-read+0x7fdf9)
    #3 0x56107230e8a9 in main ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/uninitialized-read+0xa8a9)
    #4 0x7f32de0b7290 in __libc_start_main (/usr/lib/libc.so.6+0x20290)
    #5 0x56107230e4f9 in _start ($PWD/target/x86_64-unknown-linux-gnu/debug/examples/uninitialized-read+0xa4f9)

SUMMARY: MemorySanitizer: use-of-uninitialized-value $PWD/examples/uninitialized-read.rs:5 in uninitialized_read::main::h0c073cea3836efc1
Exiting
```

### ThreadSanitizer

This sanitizer can detect data races.

#### Data race

`tsan/examples/data-race.rs`

``` rust
use std::thread;

static mut ANSWER: i32 = 0;

fn main() {
    let t1 = thread::spawn(|| unsafe { ANSWER = 42 });
    unsafe {
        ANSWER = 24;
    }
    t1.join().ok();
}
```

```
$ ( cd tsan && \
    RUSTFLAGS="-Z sanitizer=thread" cargo run --target x86_64-unknown-linux-gnu --example data-race )
     Running `target/x86_64-unknown-linux-gnu/debug/examples/data-race`
==================
WARNING: ThreadSanitizer: data race (pid=26481)
  Write of size 4 at 0x55662b8b2bb4 by thread T1:
    #0 data_race::main::_$u7b$$u7b$closure$u7d$$u7d$::hee96c0dbd110538f $PWD/examples/data-race.rs:6 (data-race+0x000000010e3f)
    #1 _$LT$std..panic..AssertUnwindSafe$LT$F$GT$$u20$as$u20$core..ops..FnOnce$LT$$LP$$RP$$GT$$GT$::call_once::h325b4408e33222b1 $RUST_SRC/src/libstd/panic.rs:296 (data-race+0x000000010cc5)
    #2 std::panicking::try::do_call::hce66d861a72cf7ad $RUST_SRC/src/libstd/panicking.rs:460 (data-race+0x00000000c942)
    #3 __rust_maybe_catch_panic <null> (data-race+0x0000000b4ee6)
    #4 std::panic::catch_unwind::h8bcbba7f3956edf8 $RUST_SRC/src/libstd/panic.rs:361 (data-race+0x00000000b567)
    #5 std::thread::Builder::spawn::_$u7b$$u7b$closure$u7d$$u7d$::h59119aee2f2d06bf $RUST_SRC/src/libstd/thread/mod.rs:357 (data-race+0x00000000c276)
    #6 _$LT$F$u20$as$u20$alloc..boxed..FnBox$LT$A$GT$$GT$::call_box::hd916ceba2ff03dbf $RUST_SRC/src/liballoc/boxed.rs:614 (data-race+0x00000000f2ce)
    #7 std::sys::imp::thread::Thread::new::thread_start::h6a0d1a011a706f06 <null> (data-race+0x0000000abdd0)

  Previous write of size 4 at 0x55662b8b2bb4 by main thread:
    #0 data_race::main::h14a8ec63b6689873 $PWD/examples/data-race.rs:8 (data-race+0x000000010d7c)
    #1 __rust_maybe_catch_panic <null> (data-race+0x0000000b4ee6)
    #2 __libc_start_main <null> (libc.so.6+0x000000020290)

  Location is global 'data_race::ANSWER::hcde8cae2a80d1e5d' of size 4 at 0x55662b8b2bb4 (data-race+0x0000002f8bb4)

  Thread T1 (tid=26574, running) created by main thread at:
    #0 pthread_create $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interceptors.cc:902 (data-race+0x00000001aedb)
    #1 std::sys::imp::thread::Thread::new::h1a8b710ff34ac90e <null> (data-race+0x0000000aba3e)
    #2 std::thread::spawn::hef27947e8b208e27 $RUST_SRC/src/libstd/thread/mod.rs:412 (data-race+0x00000000b5fa)
    #3 data_race::main::h14a8ec63b6689873 $PWD/examples/data-race.rs:6 (data-race+0x000000010d5c)
    #4 __rust_maybe_catch_panic <null> (data-race+0x0000000b4ee6)
    #5 __libc_start_main <null> (libc.so.6+0x000000020290)

SUMMARY: ThreadSanitizer: data race $PWD/examples/data-race.rs:6 in data_race::main::_$u7b$$u7b$closure$u7d$$u7d$::hee96c0dbd110538f
==================
ThreadSanitizer: reported 1 warnings
```

## Better backtraces

You can get even more complete backtraces if you recompile the `std` facade with
`-Z sanitizer`. To do that, you can use [Xargo](https://crates.io/crates/xargo):

```
# install Xargo and its dependency, the rust-src component
$ cargo install xargo

$ rustup component add rust-src

# add this file to the root of your Cargo project
$ edit Xargo.toml && cat $_
```

``` toml
[dependencies.std]
features = ["panic-unwind", "asan", "lsan", "msan", "tsan"]

# if using `cargo test`
[dependencies.test]
stage = 1
```

```
# Xargo has to rebuild the sanitizer runtimes and that requires `llvm-config`
# (in a future Xargo version, this will not be necessary)
$ export LLVM_CONFIG=$(which llvm-config)

# then you can `xargo test` or `xargo run`
$ RUSTFLAGS="-Z sanitizer=address" xargo test --target x86_64-unknown-linux-gnu
```

To make the above command work, you'll likely have to modify your `rust-src`
component, which should be in `(rustc --print sysroot)/lib/rustlib/src/rust`,
like this:

``` diff
diff --git a/src/libgetopts/Cargo.toml b/src/libgetopts/Cargo.toml
index 99e3b89285..07593229af 100644
--- a/src/libgetopts/Cargo.toml
+++ b/src/libgetopts/Cargo.toml
@@ -6,4 +6,4 @@ version = "0.0.0"
 [lib]
 name = "getopts"
 path = "lib.rs"
-crate-type = ["dylib", "rlib"]
+# crate-type = ["dylib", "rlib"]
diff --git a/src/libstd/Cargo.toml b/src/libstd/Cargo.toml
index 8146e7fb1e..c013995255 100644
--- a/src/libstd/Cargo.toml
+++ b/src/libstd/Cargo.toml
@@ -7,7 +7,7 @@ build = "build.rs"
 [lib]
 name = "std"
 path = "lib.rs"
-crate-type = ["dylib", "rlib"]
+# crate-type = ["dylib", "rlib"]
 
 [dependencies]
 alloc = { path = "../liballoc" }
diff --git a/src/libterm/Cargo.toml b/src/libterm/Cargo.toml
index 8021e814c0..6891e0b912 100644
--- a/src/libterm/Cargo.toml
+++ b/src/libterm/Cargo.toml
@@ -6,4 +6,4 @@ version = "0.0.0"
 [lib]
 name = "term"
 path = "lib.rs"
-crate-type = ["dylib", "rlib"]
+# crate-type = ["dylib", "rlib"]
diff --git a/src/libtest/Cargo.toml b/src/libtest/Cargo.toml
index ecbd5a9c0f..553150cdd1 100644
--- a/src/libtest/Cargo.toml
+++ b/src/libtest/Cargo.toml
@@ -6,7 +6,7 @@ version = "0.0.0"
 [lib]
 name = "test"
 path = "lib.rs"
-crate-type = ["dylib", "rlib"]
+# crate-type = ["dylib", "rlib"]
 
 [dependencies]
 getopts = { path = "../libgetopts" }

```

## Caveats / known bugs

### Unrealiable LeakSanitizer

I have found that LeakSanitizer not always catches memory leaks *unless* you
have compiled your code with `-C opt-level=1` or better. You can change the
optimization level of the `dev` profile in your `Cargo.toml` like this: 

``` toml
# Cargo.toml
[profile.dev]
opt-level = 1
```

### CARGO_INCREMENTAL

[rust-lang/rust#39611](https://github.com/rust-lang/rust/issues/39611)

If you have set `CARGO_INCREMENTAL=1` in your environment to use / test
incremental compilation then you'll have to remove it as incremental compilation
breaks sanitizer support.

### MemorySanitizer: Use of uninitialized value in the test runner

[rust-lang/rust#39610](https://github.com/rust-lang/rust/issues/39610)

This effectively means you can't really `cargo test` your crate with
MemorySanitizer as you'll always get errors.

`src/lib.rs`

``` rust
#[test]
fn foo() {}
```

```
$ RUSTFLAGS="-Z sanitizer=memory" cargo test --target x86_64-unknown-linux-gnu
     Running target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235
Uninitialized bytes in __interceptor_memchr at offset 13 inside [0x70400000ef60, 23)
==6915==WARNING: MemorySanitizer: use-of-uninitialized-value
    #0 0x55aec536a8b5 in std::ffi::c_str::CString::_new::h1600b539eb5d8b8c ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0xc58b5)
    #1 0x55aec537399a in std::sys::imp::fs::stat::h72120555244bec39 ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0xce99a)
    #2 0x55aec5355b18 in std::fs::metadata::h4ae9b0fd118f3836 ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0xb0b18)
    #3 0x55aec535bea8 in term::terminfo::searcher::get_dbpath_for_term::hc53288f466988180 ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0xb6ea8)
    #4 0x55aec535b3f1 in term::terminfo::TermInfo::from_name::hb95f189f4c99eccf ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0xb63f1)
    #5 0x55aec535b1a2 in term::terminfo::TermInfo::from_env::h45b8e5476a2a09d7 ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0xb61a2)
    #6 0x55aec5365c70 in term::stdout::h84d7912730b73cf4 ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0xc0c70)
    #7 0x55aec52d28bd in _$LT$test..ConsoleTestState$LT$T$GT$$GT$::new::h937954646ef1f1d9 ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0x2d8bd)
    #8 0x55aec52d481a in test::run_tests_console::h7b41f829f623d5c0 ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0x2f81a)
    #9 0x55aec52cfdb8 in test::test_main::hae140f91361b0544 ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0x2adb8)
    #10 0x55aec52d06ce in test::test_main_static::h9b2aae5d6f64eac6 ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0x2b6ce)
    #11 0x55aec52be9a3 in test_runner::__test::main::h164d7dfa966cbb3f $PWD/src/lib.rs:1
    #12 0x55aec537d5d6 in __rust_maybe_catch_panic ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0xd85d6)
    #13 0x55aec5376bc9 in std::rt::lang_start::h6954771f55df116b ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0xd1bc9)
    #14 0x55aec52bea19 in main ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0x19a19)
    #15 0x7fc24cf2f290 in __libc_start_main (/usr/lib/libc.so.6+0x20290)
    #16 0x55aec52be839 in _start ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0x19839)

SUMMARY: MemorySanitizer: use-of-uninitialized-value ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0xc58b5) in std::ffi::c_str::CString::_new::h1600b539eb5d8b8c
Exiting
error: test failed
```

### ThreadSanitizer: Data race in the test runner

[rust-lang/rust#39608](https://github.com/rust-lang/rust/issues/39608)

Using ThreadSanitizer to test any library crate with more that one unit test
results in data race reports unrelated to the tests themselves.

`src/lib.rs`

``` rust
#[test]
fn foo() {}

#[test]
fn bar() {}
```

$ RUSTFLAGS="-Z sanitizer=thread" xargo test --target x86_64-unknown-linux-gnu                                                                                                                                   <<<
     Running target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235

running 2 tests
test bar ... ok
test foo ... ok
==================
WARNING: ThreadSanitizer: data race (pid=30969)
  Write of size 8 at 0x7c4c0000ed90 by thread T2:
    #0 free $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interceptors.cc:634 (test_runner-d861d6557762b235+0x0000000ce207)
    #1 __rust_deallocate <null> (test_runner-d861d6557762b235+0x000000155663)
    #2 _$LT$alloc..arc..Arc$LT$T$GT$$GT$::drop_slow::hffd2bcc3b04fe791 <null> (test_runner-d861d6557762b235+0x00000001b835)
    #3 _$LT$alloc..arc..Arc$LT$T$GT$$GT$::drop_slow::hffd2bcc3b04fe791 <null> (test_runner-d861d6557762b235+0x00000001b835)
    #4 drop::h62528215215ec760 <null> (test_runner-d861d6557762b235+0x000000029a65)
    #5 drop::h62528215215ec760 <null> (test_runner-d861d6557762b235+0x000000029a65)
    #6 _$LT$F$u20$as$u20$alloc..boxed..FnBox$LT$A$GT$$GT$::call_box::he23b8085b7ff608a <null> (test_runner-d861d6557762b235+0x00000002dc34)
    #7 _$LT$F$u20$as$u20$alloc..boxed..FnBox$LT$A$GT$$GT$::call_box::he23b8085b7ff608a <null> (test_runner-d861d6557762b235+0x00000002dc34)
    #8 std::sys::imp::thread::Thread::new::thread_start::hee5c0f50902195ab <null> (test_runner-d861d6557762b235+0x0000000bcacc)
    #9 std::sys::imp::thread::Thread::new::thread_start::hee5c0f50902195ab <null> (test_runner-d861d6557762b235+0x0000000bcacc)
    #10 __tsan_thread_start_func $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interceptors.cc:892 (test_runner-d861d6557762b235+0x0000000caf0b)
    #11 __tsan_thread_start_func $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interceptors.cc:892 (test_runner-d861d6557762b235+0x0000000caf0b)

  Previous atomic write of size 8 at 0x7c4c0000ed90 by main thread:
    #0 __tsan_atomic64_fetch_sub $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interface_atomic.cc:623 (test_runner-d861d6557762b235+0x0000001131b0)
    #1 drop::h62528215215ec760 <null> (test_runner-d861d6557762b235+0x000000029a33)
    #2 drop::h26c9032b0f649bf6 <null> (test_runner-d861d6557762b235+0x0000000288fd)
    #3 drop::h26c9032b0f649bf6 <null> (test_runner-d861d6557762b235+0x0000000288fd)
    #4 drop::h26c9032b0f649bf6 <null> (test_runner-d861d6557762b235+0x0000000288fd)
    #5 drop::h26c9032b0f649bf6 <null> (test_runner-d861d6557762b235+0x0000000288fd)
    #6 test::run_test::run_test_inner::h68ccb59ad7634829 <null> (test_runner-d861d6557762b235+0x000000060f65)
    #7 test::run_test::run_test_inner::h68ccb59ad7634829 <null> (test_runner-d861d6557762b235+0x000000060f65)
    #8 test::run_test::run_test_inner::h68ccb59ad7634829 <null> (test_runner-d861d6557762b235+0x000000060f65)
    #9 test::run_test::hbe43efe8762b5fcb <null> (test_runner-d861d6557762b235+0x00000005f4bd)
    #10 test::run_tests::h007db7d7a30e05b9 <null> (test_runner-d861d6557762b235+0x000000054a4a)
    #11 test::run_tests_console::h51b8f804fcc03777 <null> (test_runner-d861d6557762b235+0x00000004db4c)
    #12 test::test_main::h30f1de6986f689a9 <null> (test_runner-d861d6557762b235+0x0000000429d0)
    #13 test::test_main_static::h2d9326de74ff96ef <null> (test_runner-d861d6557762b235+0x000000043fe3)
    #14 test_runner::__test::main::h164d7dfa966cbb3f $PWD/src/lib.rs:1 (test_runner-d861d6557762b235+0x000000011362)
    #15 std::panicking::try::do_call::hb1cd11518796216e <null> (test_runner-d861d6557762b235+0x0000000be876)
    #16 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #17 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #18 std::rt::lang_start::h0661a76cd511ea2d <null> (test_runner-d861d6557762b235+0x0000000c0487)
    #19 std::rt::lang_start::h0661a76cd511ea2d <null> (test_runner-d861d6557762b235+0x0000000c0487)
    #20 main <null> (test_runner-d861d6557762b235+0x0000000113b7)
    #21 main <null> (test_runner-d861d6557762b235+0x0000000113b7)
    #22 main <null> (test_runner-d861d6557762b235+0x0000000113b7)

  Thread T2 'foo' (tid=30972, running) created by main thread at:
    #0 pthread_create $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interceptors.cc:902 (test_runner-d861d6557762b235+0x0000000cf546)
    #1 std::sys::imp::thread::Thread::new::h59257a01c2b82abe <null> (test_runner-d861d6557762b235+0x0000000bc1ea)
    #2 test::run_test::run_test_inner::h68ccb59ad7634829 <null> (test_runner-d861d6557762b235+0x000000060cd2)
    #3 test::run_test::hbe43efe8762b5fcb <null> (test_runner-d861d6557762b235+0x00000005f4bd)
    #4 test::run_test::hbe43efe8762b5fcb <null> (test_runner-d861d6557762b235+0x00000005f4bd)
    #5 test::run_tests::h007db7d7a30e05b9 <null> (test_runner-d861d6557762b235+0x000000054a4a)
    #6 test::run_tests_console::h51b8f804fcc03777 <null> (test_runner-d861d6557762b235+0x00000004db4c)
    #7 test::test_main::h30f1de6986f689a9 <null> (test_runner-d861d6557762b235+0x0000000429d0)
    #8 test::test_main_static::h2d9326de74ff96ef <null> (test_runner-d861d6557762b235+0x000000043fe3)
    #9 test_runner::__test::main::h164d7dfa966cbb3f $PWD/src/lib.rs:1 (test_runner-d861d6557762b235+0x000000011362)
    #10 std::panicking::try::do_call::hb1cd11518796216e <null> (test_runner-d861d6557762b235+0x0000000be876)
    #11 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #12 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #13 std::rt::lang_start::h0661a76cd511ea2d <null> (test_runner-d861d6557762b235+0x0000000c0487)
    #14 std::rt::lang_start::h0661a76cd511ea2d <null> (test_runner-d861d6557762b235+0x0000000c0487)
    #15 main <null> (test_runner-d861d6557762b235+0x0000000113b7)
    #16 main <null> (test_runner-d861d6557762b235+0x0000000113b7)
    #17 main <null> (test_runner-d861d6557762b235+0x0000000113b7)

SUMMARY: ThreadSanitizer: data race ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0x155663) in __rust_deallocate
==================
==================
WARNING: ThreadSanitizer: data race (pid=30969)
  Write of size 8 at 0x7c580000ef40 by main thread:
    #0 free $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interceptors.cc:634 (test_runner-d861d6557762b235+0x0000000ce207)
    #1 __rust_deallocate <null> (test_runner-d861d6557762b235+0x000000155663)
    #2 _$LT$alloc..arc..Arc$LT$T$GT$$GT$::drop_slow::hc07f22e2b818fd5e <null> (test_runner-d861d6557762b235+0x00000001b234)
    #3 _$LT$alloc..arc..Arc$LT$T$GT$$GT$::drop_slow::hc07f22e2b818fd5e <null> (test_runner-d861d6557762b235+0x00000001b234)
    #4 drop::hd5322f45aa23e49d <null> (test_runner-d861d6557762b235+0x00000002c005)
    #5 drop::hd5322f45aa23e49d <null> (test_runner-d861d6557762b235+0x00000002c005)
    #6 drop::hb2fbb6e76af21657 <null> (test_runner-d861d6557762b235+0x00000002b98e)
    #7 drop::hb2fbb6e76af21657 <null> (test_runner-d861d6557762b235+0x00000002b98e)
    #8 drop::ha932b14572fc49af <null> (test_runner-d861d6557762b235+0x00000002ae22)
    #9 test::run_tests::h007db7d7a30e05b9 <null> (test_runner-d861d6557762b235+0x0000000588b1)
    #10 test::run_tests::h007db7d7a30e05b9 <null> (test_runner-d861d6557762b235+0x0000000588b1)
    #11 test::run_tests::h007db7d7a30e05b9 <null> (test_runner-d861d6557762b235+0x0000000588b1)
    #12 test::run_tests_console::h51b8f804fcc03777 <null> (test_runner-d861d6557762b235+0x00000004db4c)
    #13 test::test_main::h30f1de6986f689a9 <null> (test_runner-d861d6557762b235+0x0000000429d0)
    #14 test::test_main_static::h2d9326de74ff96ef <null> (test_runner-d861d6557762b235+0x000000043fe3)
    #15 test_runner::__test::main::h164d7dfa966cbb3f $PWD/src/lib.rs:1 (test_runner-d861d6557762b235+0x000000011362)
    #16 std::panicking::try::do_call::hb1cd11518796216e <null> (test_runner-d861d6557762b235+0x0000000be876)
    #17 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #18 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #19 std::rt::lang_start::h0661a76cd511ea2d <null> (test_runner-d861d6557762b235+0x0000000c0487)
    #20 std::rt::lang_start::h0661a76cd511ea2d <null> (test_runner-d861d6557762b235+0x0000000c0487)
    #21 main <null> (test_runner-d861d6557762b235+0x0000000113b7)
    #22 main <null> (test_runner-d861d6557762b235+0x0000000113b7)
    #23 main <null> (test_runner-d861d6557762b235+0x0000000113b7)

  Previous atomic write of size 8 at 0x7c580000ef40 by thread T2:
    #0 __tsan_atomic64_fetch_sub $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interface_atomic.cc:623 (test_runner-d861d6557762b235+0x0000001131b0)
    #1 drop::hd5322f45aa23e49d <null> (test_runner-d861d6557762b235+0x00000002bfd3)
    #2 drop::hb2fbb6e76af21657 <null> (test_runner-d861d6557762b235+0x00000002b98e)
    #3 drop::hb2fbb6e76af21657 <null> (test_runner-d861d6557762b235+0x00000002b98e)
    #4 drop::hb2fbb6e76af21657 <null> (test_runner-d861d6557762b235+0x00000002b98e)
    #5 drop::hb2fbb6e76af21657 <null> (test_runner-d861d6557762b235+0x00000002b98e)
    #6 drop::ha932b14572fc49af <null> (test_runner-d861d6557762b235+0x00000002ae22)
    #7 std::panicking::try::do_call::heac7d42b6d137ab0 <null> (test_runner-d861d6557762b235+0x00000001e7a7)
    #8 std::panicking::try::do_call::heac7d42b6d137ab0 <null> (test_runner-d861d6557762b235+0x00000001e7a7)
    #9 std::panicking::try::do_call::heac7d42b6d137ab0 <null> (test_runner-d861d6557762b235+0x00000001e7a7)
    #10 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #11 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #12 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #13 _$LT$F$u20$as$u20$alloc..boxed..FnBox$LT$A$GT$$GT$::call_box::he23b8085b7ff608a <null> (test_runner-d861d6557762b235+0x00000002db21)
    #14 _$LT$F$u20$as$u20$alloc..boxed..FnBox$LT$A$GT$$GT$::call_box::he23b8085b7ff608a <null> (test_runner-d861d6557762b235+0x00000002db21)
    #15 std::sys::imp::thread::Thread::new::thread_start::hee5c0f50902195ab <null> (test_runner-d861d6557762b235+0x0000000bcacc)
    #16 std::sys::imp::thread::Thread::new::thread_start::hee5c0f50902195ab <null> (test_runner-d861d6557762b235+0x0000000bcacc)
    #17 std::sys::imp::thread::Thread::new::thread_start::hee5c0f50902195ab <null> (test_runner-d861d6557762b235+0x0000000bcacc)
    #18 std::sys::imp::thread::Thread::new::thread_start::hee5c0f50902195ab <null> (test_runner-d861d6557762b235+0x0000000bcacc)
    #19 __tsan_thread_start_func $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interceptors.cc:892 (test_runner-d861d6557762b235+0x0000000caf0b)
    #20 __tsan_thread_start_func $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interceptors.cc:892 (test_runner-d861d6557762b235+0x0000000caf0b)

  Thread T2 'foo' (tid=30972, running) created by main thread at:
    #0 pthread_create $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interceptors.cc:902 (test_runner-d861d6557762b235+0x0000000cf546)
    #1 std::sys::imp::thread::Thread::new::h59257a01c2b82abe <null> (test_runner-d861d6557762b235+0x0000000bc1ea)
    #2 test::run_test::run_test_inner::h68ccb59ad7634829 <null> (test_runner-d861d6557762b235+0x000000060cd2)
    #3 test::run_test::hbe43efe8762b5fcb <null> (test_runner-d861d6557762b235+0x00000005f4bd)
    #4 test::run_test::hbe43efe8762b5fcb <null> (test_runner-d861d6557762b235+0x00000005f4bd)
    #5 test::run_tests::h007db7d7a30e05b9 <null> (test_runner-d861d6557762b235+0x000000054a4a)
    #6 test::run_tests_console::h51b8f804fcc03777 <null> (test_runner-d861d6557762b235+0x00000004db4c)
    #7 test::test_main::h30f1de6986f689a9 <null> (test_runner-d861d6557762b235+0x0000000429d0)
    #8 test::test_main_static::h2d9326de74ff96ef <null> (test_runner-d861d6557762b235+0x000000043fe3)
    #9 test_runner::__test::main::h164d7dfa966cbb3f $PWD/src/lib.rs:1 (test_runner-d861d6557762b235+0x000000011362)
    #10 std::panicking::try::do_call::hb1cd11518796216e <null> (test_runner-d861d6557762b235+0x0000000be876)
    #11 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #12 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #13 std::rt::lang_start::h0661a76cd511ea2d <null> (test_runner-d861d6557762b235+0x0000000c0487)
    #14 std::rt::lang_start::h0661a76cd511ea2d <null> (test_runner-d861d6557762b235+0x0000000c0487)
    #15 main <null> (test_runner-d861d6557762b235+0x0000000113b7)
    #16 main <null> (test_runner-d861d6557762b235+0x0000000113b7)
    #17 main <null> (test_runner-d861d6557762b235+0x0000000113b7)

SUMMARY: ThreadSanitizer: data race ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0x155663) in __rust_deallocate
==================

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured

==================
WARNING: ThreadSanitizer: data race (pid=30969)
  Write of size 8 at 0x7c540000ef60 by thread T2:
    #0 free $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interceptors.cc:634 (test_runner-d861d6557762b235+0x0000000ce207)
    #1 __rust_deallocate <null> (test_runner-d861d6557762b235+0x000000155663)
    #2 _$LT$alloc..arc..Arc$LT$T$GT$$GT$::drop_slow::hff346d8fec1237f8 <null> (test_runner-d861d6557762b235+0x00000009fbc4)
    #3 _$LT$alloc..arc..Arc$LT$T$GT$$GT$::drop_slow::hff346d8fec1237f8 <null> (test_runner-d861d6557762b235+0x00000009fbc4)
    #4 drop::h5f9d93ca09665cd2 <null> (test_runner-d861d6557762b235+0x0000000a395d)
    #5 drop::h5f9d93ca09665cd2 <null> (test_runner-d861d6557762b235+0x0000000a395d)
    #6 drop::h1a3c63fc24632ae0 <null> (test_runner-d861d6557762b235+0x0000000a34bf)
    #7 drop::h1a3c63fc24632ae0 <null> (test_runner-d861d6557762b235+0x0000000a34bf)
    #8 drop::h1a3c63fc24632ae0 <null> (test_runner-d861d6557762b235+0x0000000a34bf)
    #9 std::sys::imp::fast_thread_local::destroy_value::hd0a16359cb28bafd <null> (test_runner-d861d6557762b235+0x0000000b9518)
    #10 std::sys::imp::fast_thread_local::destroy_value::hd0a16359cb28bafd <null> (test_runner-d861d6557762b235+0x0000000b9518)
    #11 std::sys::imp::fast_thread_local::destroy_value::hd0a16359cb28bafd <null> (test_runner-d861d6557762b235+0x0000000b9518)
    #12 __GI___call_tls_dtors <null> (libc.so.6+0x000000035efe)
    #13 __GI___call_tls_dtors <null> (libc.so.6+0x000000035efe)
    #14 __GI___call_tls_dtors <null> (libc.so.6+0x000000035efe)

  Previous atomic write of size 8 at 0x7c540000ef60 by main thread:
    #0 __tsan_atomic64_fetch_sub $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interface_atomic.cc:623 (test_runner-d861d6557762b235+0x0000001131b0)
    #1 drop::h76fdafd6e6eb83b7 <null> (test_runner-d861d6557762b235+0x00000002a0fb)
    #2 drop::h26c9032b0f649bf6 <null> (test_runner-d861d6557762b235+0x0000000288e9)
    #3 drop::h26c9032b0f649bf6 <null> (test_runner-d861d6557762b235+0x0000000288e9)
    #4 drop::h26c9032b0f649bf6 <null> (test_runner-d861d6557762b235+0x0000000288e9)
    #5 drop::h26c9032b0f649bf6 <null> (test_runner-d861d6557762b235+0x0000000288e9)
    #6 drop::h26c9032b0f649bf6 <null> (test_runner-d861d6557762b235+0x0000000288e9)
    #7 test::run_test::run_test_inner::h68ccb59ad7634829 <null> (test_runner-d861d6557762b235+0x000000060f65)
    #8 test::run_test::run_test_inner::h68ccb59ad7634829 <null> (test_runner-d861d6557762b235+0x000000060f65)
    #9 test::run_test::hbe43efe8762b5fcb <null> (test_runner-d861d6557762b235+0x00000005f4bd)
    #10 test::run_tests::h007db7d7a30e05b9 <null> (test_runner-d861d6557762b235+0x000000054a4a)
    #11 test::run_tests_console::h51b8f804fcc03777 <null> (test_runner-d861d6557762b235+0x00000004db4c)
    #12 test::test_main::h30f1de6986f689a9 <null> (test_runner-d861d6557762b235+0x0000000429d0)
    #13 test::test_main_static::h2d9326de74ff96ef <null> (test_runner-d861d6557762b235+0x000000043fe3)
    #14 test_runner::__test::main::h164d7dfa966cbb3f $PWD/src/lib.rs:1 (test_runner-d861d6557762b235+0x000000011362)
    #15 std::panicking::try::do_call::hb1cd11518796216e <null> (test_runner-d861d6557762b235+0x0000000be876)
    #16 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #17 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #18 std::rt::lang_start::h0661a76cd511ea2d <null> (test_runner-d861d6557762b235+0x0000000c0487)
    #19 std::rt::lang_start::h0661a76cd511ea2d <null> (test_runner-d861d6557762b235+0x0000000c0487)
    #20 main <null> (test_runner-d861d6557762b235+0x0000000113b7)
    #21 main <null> (test_runner-d861d6557762b235+0x0000000113b7)
    #22 main <null> (test_runner-d861d6557762b235+0x0000000113b7)

  Thread T2 'foo' (tid=30972, running) created by main thread at:
    #0 pthread_create $RUST_SRC/src/compiler-rt/lib/tsan/rtl/tsan_interceptors.cc:902 (test_runner-d861d6557762b235+0x0000000cf546)
    #1 std::sys::imp::thread::Thread::new::h59257a01c2b82abe <null> (test_runner-d861d6557762b235+0x0000000bc1ea)
    #2 test::run_test::run_test_inner::h68ccb59ad7634829 <null> (test_runner-d861d6557762b235+0x000000060cd2)
    #3 test::run_test::hbe43efe8762b5fcb <null> (test_runner-d861d6557762b235+0x00000005f4bd)
    #4 test::run_test::hbe43efe8762b5fcb <null> (test_runner-d861d6557762b235+0x00000005f4bd)
    #5 test::run_tests::h007db7d7a30e05b9 <null> (test_runner-d861d6557762b235+0x000000054a4a)
    #6 test::run_tests_console::h51b8f804fcc03777 <null> (test_runner-d861d6557762b235+0x00000004db4c)
    #7 test::test_main::h30f1de6986f689a9 <null> (test_runner-d861d6557762b235+0x0000000429d0)
    #8 test::test_main_static::h2d9326de74ff96ef <null> (test_runner-d861d6557762b235+0x000000043fe3)
    #9 test_runner::__test::main::h164d7dfa966cbb3f $PWD/src/lib.rs:1 (test_runner-d861d6557762b235+0x000000011362)
    #10 std::panicking::try::do_call::hb1cd11518796216e <null> (test_runner-d861d6557762b235+0x0000000be876)
    #11 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #12 __rust_maybe_catch_panic <null> (test_runner-d861d6557762b235+0x0000000c2363)
    #13 std::rt::lang_start::h0661a76cd511ea2d <null> (test_runner-d861d6557762b235+0x0000000c0487)
    #14 std::rt::lang_start::h0661a76cd511ea2d <null> (test_runner-d861d6557762b235+0x0000000c0487)
    #15 main <null> (test_runner-d861d6557762b235+0x0000000113b7)
    #16 main <null> (test_runner-d861d6557762b235+0x0000000113b7)
    #17 main <null> (test_runner-d861d6557762b235+0x0000000113b7)

SUMMARY: ThreadSanitizer: data race ($PWD/target/x86_64-unknown-linux-gnu/debug/deps/test_runner-d861d6557762b235+0x155663) in __rust_deallocate
==================
ThreadSanitizer: reported 3 warnings
error: test failed

# License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
  http://www.apache.org/licenses/LICENSE-2.0)

- MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

## Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you, as defined in the Apache-2.0 license, shall be
dual licensed as above, without any additional terms or conditions.

#![feature(integer_atomics)]

use std::thread;
use std::sync::atomic::{AtomicI32, Ordering};


static ANSWER: AtomicI32 = AtomicI32::new(0);

fn main() {
    let t1 = thread::spawn(|| ANSWER.store(42, Ordering::SeqCst) );
    ANSWER.store(24, Ordering::SeqCst);
    t1.join().ok();
    let v = ANSWER.load(Ordering::SeqCst);
    assert!(v == 42 || v == 24);
}

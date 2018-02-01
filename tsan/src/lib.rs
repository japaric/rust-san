#![cfg_attr(test, feature(integer_atomics))]

#[cfg(test)]
mod tests {

    #[test]
    fn data_race_fixed() {
        use std::thread;
        use std::sync::atomic::{AtomicI32, Ordering};

        static ANSWER: AtomicI32 = AtomicI32::new(0);

        fn foo() {
            let t1 = thread::spawn(|| ANSWER.store(42, Ordering::SeqCst) );
            ANSWER.store(24, Ordering::SeqCst);
            t1.join().ok();
            let v = ANSWER.load(Ordering::SeqCst);
            assert!(v == 42 || v == 24);
        }
        foo();
    }

    #[cfg(feature = "fail")]
    #[test]
    fn data_race() {
        use std::thread;
        static mut ANSWER: i32 = 0;
        fn foo() {
            let t1 = thread::spawn(|| unsafe { ANSWER = 42 });
            unsafe {
                ANSWER = 24;
            }
            t1.join().ok();
        }
        foo();
    }
}

use std::thread;

static mut ANSWER: i32 = 0;

fn main() {
    let t1 = thread::spawn(|| unsafe { ANSWER = 42 });
    unsafe {
        ANSWER = 24;
    }
    t1.join().ok();
}

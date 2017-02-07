use std::mem;

fn main() {
    let xs = vec![0, 1, 2, 3];
    mem::forget(xs);
}

fn main() {
    let xs = vec![0, 1, 2, 3];
    let y = xs.as_ptr();
    drop(xs);
    let z = unsafe { *y };
}

fn main() {
    let xs = vec![0, 1, 2, 3];
    let y = xs.as_ptr();
    let z = unsafe { *y };
    assert_eq!(z, 0);
    drop(xs);
}

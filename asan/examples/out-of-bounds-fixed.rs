fn main() {
    let xs = [0, 1, 2, 3];
    let y = unsafe { *xs.as_ptr().offset(3) };
    assert_eq!(y, 3);
}

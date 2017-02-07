fn main() {
    let xs = [0, 1, 2, 3];
    let y = unsafe { *xs.as_ptr().offset(4) };
}

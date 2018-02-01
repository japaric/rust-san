#[cfg(test)]
mod tests {
    #[test]
    fn uninitialized_read_fixed() {
        let xs: [u8; 4] = [0; 4];
        let y = xs[0] + xs[1];
    }

    #[cfg(feature = "fail")]
    #[test]
    fn uninitialized_read() {
        use std::mem;
        let xs: [u8; 4] = unsafe { mem::uninitialized() };
        let y = xs[0] + xs[1];
    }
}

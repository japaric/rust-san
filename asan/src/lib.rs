#[cfg(test)]
mod tests {
    #[test]
    fn out_of_bounds_fixed() {
        let xs = [0, 1, 2, 3];
        let y = unsafe { *xs.as_ptr().offset(3) };
        assert_eq!(y, 3);
    }

    #[test]
    fn use_after_free_fixed() {
        let xs = vec![0, 1, 2, 3];
        let y = xs.as_ptr();
        let z = unsafe { *y };
        assert_eq!(z, 0);
        drop(xs);
    }

    #[cfg(feature = "fail")]
    #[test]
    fn out_of_bounds() {
        let xs = [0, 1, 2, 3];
        let y = unsafe { *xs.as_ptr().offset(4) };
        assert_eq!(y, 3);
    }

    #[cfg(feature = "fail")]
    #[test]
    fn use_after_free() {
        let xs = vec![0, 1, 2, 3];
        let y = xs.as_ptr();
        drop(xs);
        let z = unsafe { *y };
        assert_eq!(z, 0);
    }
}

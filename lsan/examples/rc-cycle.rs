use std::cell::RefCell;
use std::rc::Rc;

#[derive(Clone)]
struct Cycle {
    cell: RefCell<Option<Rc<Cycle>>>,
}

impl Drop for Cycle {
    fn drop(&mut self) {
        println!("freed");
    }
}

fn main() {
    let cycle = Rc::new(Cycle { cell: RefCell::new(None)});
    *cycle.cell.borrow_mut() = Some(cycle.clone());
}

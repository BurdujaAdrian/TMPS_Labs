package calc


// The Calculator "Engine" (OCP & DIP)
@(private)
Calculator :: struct($T: typeid) {
	operations: [dynamic]^op(T),
	result:     T,
}

append_op :: proc(self: ^Calculator($T), new_op: ^op(T)) {
	append(&self.operations, new_op)
}

init :: proc(n: $T) -> Calculator(T) {
	return {operations = make([dynamic]^op(T)), result = n}
}

calculate :: proc(calc: ^Calculator($T)) -> T {
	for op in calc.operations {
		calc.result = op->eval(calc.result)
	}
	return calc.result
}

op :: struct($T: typeid) {
	eval: proc(_: ^op(T), a: T) -> T,
}

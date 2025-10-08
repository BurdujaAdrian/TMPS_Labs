package main
import "calc"
import "core:fmt"
import "core:math"

op :: calc.op
init :: calc.init
append_op :: calc.append_op
calculate :: calc.calculate

Substraction :: struct($T: typeid) {
	using base: op(T),
	b:          T,
}

Sub :: proc(b: $T) -> ^op(T) {
	return new_clone(Substraction(T) {
		b = b,
		eval = proc(self: ^op(T), a: T) -> T {
			self := cast(^Substraction(T))self
			return a - self.b
		},
	})
}

Addition :: struct($T: typeid) {
	using base: op(T),
	b:          T,
}

Add :: proc(b: $T) -> ^op(T) {
	return new_clone(Addition(T) {
		b = b,
		eval = proc(self: ^op(T), a: T) -> T {
			self := cast(^Addition(T))self
			return a + self.b
		},
	})
}

main :: proc() {

	calc := init(f64(1))
	append_op(&calc, Add(f64(3)))
	append_op(&calc, Sub(f64(4)))

	fmt.println(calculate(&calc))
}

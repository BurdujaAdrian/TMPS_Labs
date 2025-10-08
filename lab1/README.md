# Lab #0: SOLID

## Task:
Implement 3 SOLID letters in a simple project.

## Theory:
SOLID is an acronym for 5 OOP design principles. 
The intent is to make software: 
- more understandable
- easier to maintain/test
- extendable

### Single Responsibility Principle
- Every piece of software (i.e. module, class or function) should be responsible over a single part of functionality provided by the software.
- Being responsible only for one thing, it will have only one reason to change.

### Open Closed Principle
- Each piece of software should be open for extension and closed for modification.
- The behavior should be extended without needing to modify the internals.

### Liskov Substitution Principle
- Objects of a class should be substitutable with instances of the existing subclasses, without altering the functionalities of the software.

### Interface Segregation Principle
- A client shouldn’t be forced to implement an interface, or methods from an interface, that it doesn’t use.
- It is recommended to split larger interfaces into multiple smaller ones.

### Dependency Inversion Principle
- Software entities must depend on abstractions, not on concrete things. 
- Separate modules, that are located on different levels must not depend directly on each other, but should rely on abstractions.

### Intrusive interface
An intrusive interface is an interface that is implemented by adding the virtual table
as the members of the class/struct directly. 

The virtual table could be a struct with the functions as it's memebers.

When the interface is the first member, a pointer to the implementing struct also
points to the first member of the interface. 


## Implementation

The implementation is a library which provides 1 interface: op, and 1 class: calculator

The interface op represents a single mathematical operation.
```odin
op :: struct($T: typeid) {
	eval: proc(_: ^op(T), a: T) -> T,
}
```


Calculator class agregates all the operations then executes them in the order they're 
added.
```odin
// generic struct over type T
@(private)
Calculator :: struct($T: typeid) {
	operations: [dynamic]^op(T),
	result:     T,
}

// Appends the new operation, a pointer to the interface
append_op :: proc(self: ^Calculator($T), new_op: ^op(T)) {
	append(&self.operations, new_op)
}

// initializes the calculator with the necesary memory and initial number
init :: proc(n: $T) -> Calculator(T) {
	return {operations = make([dynamic]^op(T)), result = n}
}

// calculates the result of the appended operations
calculate :: proc(calc: ^Calculator($T)) -> T {
	for op in calc.operations {
		calc.result = op->eval(calc.result)
	}
	return calc.result
}
```

To add a new operation, the user must provide a struct that implements(includes as a 
member) the interface op, as well as the function that allocates and initializes said
operation. 
Example:
```odin
// generic struct over type T, has the interface as it's 1st memeber(important)
Addition :: struct($T: typeid) {
	using base: op(T),
	b:          T,
}

// Function that allocates the above struct, initialised with the value and the 
// operation it performs
Add :: proc(b: $T) -> ^op(T) {
	return new_clone(Addition(T) {
		b = b,
		eval = proc(self: ^op(T), a: T) -> T {
			self := cast(^Addition(T))self
			return a + self.b
		},
	})
}
```

### Example program:
```odin
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
    // outputs 0
}

```


### SPR
Is adhered because each struct or interface has only 1 responsibility:
`Calculator` calculates the list of added operations
`op` is an interface representing a single operation
Concrete implementation `Addition` is only responsible for the operation of addition


### OCP
Is adhered because, to add a new operation, the user must write only the struct and the
implementation of the interface,they do not have to modify `op` directly nor `Calculator`

In essence, Calculator is open to extension(by implementing the `op` interface), but closed for modification(the struct is private).

### DIP
`Calculator` only depends on the interface `op`, instead of concrete implementations.


## Conclusion
This laboratory exercise successfully demonstrates the implementation of three core SOLID principles in the Odin programming language through a calculator library. The project showcases how Single Responsibility, Open/Closed, and Dependency Inversion principles can be effectively applied in a data-oriented, procedural language like Odin, which lacks traditional object-oriented features like classes and interfaces.

The key achievement lies in using intrusive interfaces - where the interface requirements are embedded directly into the implementing types through struct embedding. This approach aligns perfectly with Odin's philosophy of explicit, performant code while maintaining SOLID principles. Each operation maintains single responsibility, the system remains open for extension but closed for modification, and high-level modules depend on abstractions rather than concrete implementations.

The implementation proves that SOLID principles transcend object-oriented programming and remain relevant in modern systems programming. The calculator serves as a practical example of how these architectural principles enable maintainable, testable, and extensible software even in performance-focused languages like Odin. The intrusive interface pattern demonstrated here offers a compelling alternative to traditional polymorphism, particularly valuable in domains where Odin excels such as game development, embedded systems, and high-performance computing.






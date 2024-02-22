package parser

Operator :: enum {
	Plus,
	Minus,
	Times,
	Divide,
	Modulo,
	Exponent,
}

Paren :: enum {
	Left,
	Right,
}

Variable :: struct {
	name: string,
}

Lexer :: struct {
	source:         string,
	start, current: int,
}


compile_expression :: proc(expression: string) {

}

SRC=./src
AST=$(SRC)/ast

sad: $(AST)/lexer.d $(AST)/parser.d $(AST)/error.d $(AST)/util.d $(AST)/astnode.d $(SRC)/sad.d
	mkdir -p build
	dmd $^ -of=build/$@
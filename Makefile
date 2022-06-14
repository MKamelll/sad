SRC=./src
AST=$(SRC)/ast

sad: $(AST)/*.d $(SRC)/sad.d
	mkdir -p build
	dmd $^ -of=build/$@
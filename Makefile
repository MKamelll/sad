SRC=./src
AST=$(SRC)/ast
COMPILER=$(SRC)/compiler

sad: $(AST)/*.d $(COMPILER)/*.d $(SRC)/sad.d
	mkdir -p build
	dmd $^ -of=build/$@
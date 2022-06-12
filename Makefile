SRC=./src
AST=$(SRC)/ast
VM=$(SRC)/vm

sad: $(AST)/*.d $(VM)/*.d $(SRC)/sad.d
	mkdir -p build
	dmd $^ -of=build/$@
sad: lexer.d sad.d parser.d
	mkdir -p build
	dmd $^ -of=build/$@
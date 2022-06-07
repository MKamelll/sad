sad: lexer.d sad.d parser.d error.d util.d
	mkdir -p build
	dmd $^ -of=build/$@
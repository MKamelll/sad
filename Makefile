sad: lexer.d sad.d parser.d error.d util.d astnode.d
	mkdir -p build
	dmd $^ -of=build/$@
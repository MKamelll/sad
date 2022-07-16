module sad;

import ast.lexer;
import ast.parser;
import ast.error;
import error;
import compiler.transpiler;

import std.stdio;
import std.algorithm;
import std.string : strip;
import std.file;

void run(string src) {
    auto lexer = new Tokenizer(src);
    auto ast = new Ast(lexer);
    auto transpiler = new Transpiler(ast.parse());
    writeln(transpiler.generate());
    //writeln(ast.parse());
}

void generateDFile(string src, string fileName) {
    auto lexer = new Tokenizer(src);
    auto ast = new Ast(lexer);
    auto transpiler = new Transpiler(ast.parse());
    auto file = new File(fileName[0..$-4] ~ ".d", "w");
    file.write(transpiler.generate());
}

string readFile(string fileName) {
    string result = "";
    try
    {
        result ~= readText(fileName);

    } catch (Exception ex) {
        writeln(ex.toString());
    }
    
    return result;
}

string getStem(string filename) {
    string result;
    foreach_reverse (ch; filename) {
        if (ch == '.') break;
        result ~= ch;
    }

    return result.dup().reverse();
}

int main(string[] argv) {

    if (argv.length > 1) {
        string fileName = argv[1];
        if (getStem(fileName) != "sad") {
            throw new SadError("Expected a file with the extenstion '.sad'");
        }
        string src = readFile(fileName);
        generateDFile(src, fileName);
        return 0;
    }

    writeln("Welcome to Sad..");
    while (true) {
        write(">> ");
        string line;
        if ((line = readln()) !is null) {
           if (line.startsWith("\n")) continue;
           
           if (line.startsWith(":q") || line.startsWith("quit") ||
                line.startsWith("exit") || line.startsWith(":Q")) {
                writeln("Goodbye.");
                break;
            }

            line = line.strip();

            try {
                run(line);

            } catch (Exception err) {
                writeln(err.toString());
                continue;
            }
        }
    }

    return 0;
}
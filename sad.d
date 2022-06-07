module sad;

import lexer;
import parser;
import error;

import std.stdio;
import std.algorithm;
import std.string : strip;

void run(string src) {
    auto lexer = new Tokenizer(src);
    auto ast = new Ast(lexer);
    writeln(ast.parse());
}

int main() {

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

            } catch (ParseError err) {
                writeln(err);
                continue;
            }
        }
    }

    return 0;
}
module sad;

import lexer;
import parser;

import std.stdio;
import std.algorithm;
import std.string : strip;

void run(string src) {
    auto lexer = new Tokenizer(src);
    auto parser = new Parser(lexer);
    writeln(parser.parse());
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
            run(line);
        }
    }

    return 0;
}
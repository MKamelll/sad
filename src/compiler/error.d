module compiler.error;

import ast.util;
import std.conv;

class TranspilerError : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) pure nothrow @nogc @safe
    {
        super(msg, file, line, nextInChain);
    }

    override string toString() const {
        return  "[" ~ file ~ ":" ~ to!string(line) ~ "] TranspilerError: " ~ msg;
    }
}
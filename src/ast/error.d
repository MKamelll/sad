module ast.error;

import ast.util;
import std.conv;
import general;

class ParseError : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null)
    {
        super(msg, getFileName(), getCurrLine(), nextInChain);
    }

    override string toString() const {
        return  "[" ~ file ~ ":" ~ to!string(line) ~ "] ParseError: " ~ msg;
    }
}


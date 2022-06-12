module vm.error;

import std.conv;

class VmError : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) pure nothrow @nogc @safe
    {
        super(msg, file, line, nextInChain);
    }

    override string toString() {
        return "[" ~ file ~ ":" ~ to!string(line) ~ "] VmError: " ~ msg;
    }
}

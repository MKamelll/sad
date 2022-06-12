module vm.program;

import std.array;
import std.algorithm;
import std.string;
import std.conv;
import std.stdio;
import std.typecons;

import vm.instruction;
import vm.error;

class Program
{
    private string mIntrmediateSrc;
    private Instruction[] mProgram;
    private string[][] mLines;
    private string[] mCurrLine;
    private string[] mPrevLine;
    private int mCurrLineIndex;

    this (string src) {
        mIntrmediateSrc = src;
        mLines = mIntrmediateSrc.split(";")
                              .map!(line => line.split(" ")
                              .map!(strip).array
                              .filter!(ident => ident.length > 0).array).array
                              .filter!(line => line.length > 0).array;
        mCurrLineIndex = 0;
        mCurrLine = mLines[mCurrLineIndex];
    }

    bool isAtEnd() {
        if (mCurrLineIndex < mLines.length) {
            return false;
        }

        return true;
    }

    void advance() {
        mPrevLine = mCurrLine;
        mCurrLineIndex++;
        if (!isAtEnd()) {
            mCurrLine = mLines[mCurrLineIndex];
        }
    }

    bool match(string opcode) {
        if (mCurrLine[0] == opcode) {
            advance();
            return true;
        }

        return false;
    }

    string[] previous() {
        return mPrevLine;
    }

    string[] fetchOperands(int expectedNumber) {
        string[] operands = previous()[1..$];
        if (operands.length == expectedNumber) {
            return operands;
        }

        throw new VmError("Expected '" ~ to!string(expectedNumber) 
            ~ "' operands instead got '" ~ to!string(operands.length) ~ "'");
    }

    Instruction[] generate() {
        mProgram ~= generatePushInt();
        if (isAtEnd()) return mProgram;
        return generate();
    }

    // Generate Int
    Instruction generatePushInt() {
        if (match("pushi")) {
            string[] operands = fetchOperands(1);
            return new Instruction(Opcode.PUSHI, operands[0]);
        }

        return generateAddInt();
    }

    Instruction generateAddInt() {
        if (match("addi")) {
            return new Instruction(Opcode.ADDI);
        }

        return generateMultiplyInt();   
    }

    Instruction generateMultiplyInt() {
        if (match("muli")) {
            return new Instruction(Opcode.MULI);
        }

        return generateSubInt();         
    }

    Instruction generateSubInt() {
        if (match("subi")) {
            return new Instruction(Opcode.SUBI);
        }

        return generateDivInt();
    }

    Instruction generateDivInt() {
        if (match("divi")) {
            return new Instruction(Opcode.DIVI);
        }
       
       return generatePushLong();
    }

    // Generate Long
    Instruction generatePushLong() {
        if (match("pushl")) {
            string[] operands = fetchOperands(1);
            return new Instruction(Opcode.PUSHL, operands[0]);
        }

        return generateAddLong();
    }

    Instruction generateAddLong() {
        if (match("addl")) {
            return new Instruction(Opcode.ADDL);
        }

        return generateMultiplyLong();   
    }

    Instruction generateMultiplyLong() {
        if (match("mull")) {
            return new Instruction(Opcode.MULL);
        }

        return generateSubLong();         
    }

    Instruction generateSubLong() {
        if (match("subl")) {
            return new Instruction(Opcode.SUBL);
        }

        return generateDivLong();
    }

    Instruction generateDivLong() {
        if (match("divl")) {
            return new Instruction(Opcode.DIVL);
        }
       
       return generatePushFloat();
    }

    // Generate Float
    Instruction generatePushFloat() {
        if (match("pushf")) {
            string[] operands = fetchOperands(1);
            return new Instruction(Opcode.PUSHF, operands[0]);
        }

        return generateAddFloat();
    }

    Instruction generateAddFloat() {
        if (match("addf")) {
            return new Instruction(Opcode.ADDF);
        }

        return generateMultiplyFloat();   
    }

    Instruction generateMultiplyFloat() {
        if (match("mulf")) {
            return new Instruction(Opcode.MULF);
        }

        return generateSubFloat();         
    }

    Instruction generateSubFloat() {
        if (match("subf")) {
            return new Instruction(Opcode.SUBF);
        }

        return generateDivFloat();
    }

    Instruction generateDivFloat() {
        if (match("divf")) {
            return new Instruction(Opcode.DIVF);
        }
       
       throw new VmError("Unknown opcode '" ~ mCurrLine[0] ~ "'");

    }
}
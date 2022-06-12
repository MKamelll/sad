module vm.vm;

import std.conv;
import std.stdio;
import std.range;
import std.variant;
import std.algorithm;
import std.array;

import vm.instruction;
import vm.error;

class Vm
{
    Instruction[] mProgram;
    const MAX_CAPACITY = 100;
    Variant[] mStack;
    Instruction mCurrInstruction;
    int mIp;
    int mSp;

    this (Instruction[] program) {
        mProgram = program;
        mStack = [];
        mIp = 0;
        mSp = -1;
    }

    bool isAtEnd() {
        if (mIp < mProgram.length) {
            return false;
        }

        return true;
    }

    T pop(T)() {
        if (mSp < 0) {
            throw new VmError("Not enough operands on the stack for instruction '"
                ~ to!string(mCurrInstruction.getOpcode()) ~ "'");
        }

        Variant elm = mStack[mSp--];
        mStack.popBack();

        try {
            return elm.get!T; 
        } catch (Exception err) {
            throw new VmError("On opcode '" ~ to!string(mCurrInstruction.mOpcode)
                ~ "' :" ~ err.msg.findSplit("Variant:")[2]);
        }
    }

    void push(T)(string value) {
        mSp++;
        if (mSp > MAX_CAPACITY) throw new VmError("Stack overflow");

        try {
            mStack ~= Variant(to!T(value));
        } catch (Exception err) {
            throw new VmError("Opcode '" ~ to!string(mCurrInstruction.mOpcode)
                ~ "' doesn't match operand '" ~ mCurrInstruction.mOperand1.get ~ "': " ~ err.msg);
        }
    }

    void push(T)(T value) {
        mSp++;
        if (mSp > MAX_CAPACITY) throw new VmError("Stack overflow");

        try {
            mStack ~= Variant(to!T(value));
        } catch (Exception err) {
            throw new VmError("Opcode '" ~ to!string(mCurrInstruction.mOpcode)
                ~ "' doesn't match operand '" ~ mCurrInstruction.mOperand1.get ~ "': " ~ err.msg);
        }
    }

    Instruction advance() {
        if (mIp < 0) throw new Exception("The program doesn't have any instructions");
        if (!isAtEnd()) {
            mCurrInstruction = mProgram[mIp++];
        }
        return mCurrInstruction;
    }

    Variant[] run() {

        while (!isAtEnd()) {
            Instruction curr = advance();
            switch (curr.getOpcode()) {
                case Opcode.PUSHI: pushInt(); break;
                case Opcode.ADDI: addInt(); break;
                case Opcode.MULI: mulInt(); break;
                case Opcode.DIVI: divInt(); break;
                case Opcode.SUBI: subInt(); break;
                
                case Opcode.PUSHL: pushLong(); break;
                case Opcode.ADDL: addLong(); break;
                case Opcode.MULL: mulLong(); break;
                case Opcode.DIVL: divLong(); break;
                case Opcode.SUBL: subLong(); break;

                case Opcode.PUSHF: pushFloat(); break;
                case Opcode.ADDF: addFloat(); break;
                case Opcode.MULF: mulFloat(); break;
                case Opcode.DIVF: divFloat(); break;
                case Opcode.SUBF: subFloat(); break;
                default: throw new VmError("Unkown Machine Instruction: '" ~ to!string(curr.getOpcode()) ~ "'");
            }
        }
        
        return mStack;
    }

    // Int
    void pushInt() {
        push!int(mCurrInstruction.mOperand1.get);
    }

    void addInt() {
        int firstOperand = pop!int;
        int secondOperand = pop!int;
        push!int(firstOperand + secondOperand);
    }

    void mulInt() {
        int firstOperand = pop!int;
        int secondOperand = pop!int;
        push!int(firstOperand * secondOperand);
    }

    void divInt() {
        int firstOperand = pop!int;
        int secondOperand = pop!int;
        push!int(secondOperand / firstOperand);
    }

    void subInt() {
        int firstOperand = pop!int;
        int secondOperand = pop!int;
        push!int(secondOperand - firstOperand);
    }
    
    // Long
    void pushLong() {
        push!long(mCurrInstruction.mOperand1.get);
    }

    void addLong() {
        long firstOperand = pop!long;
        long secondOperand = pop!long;
        push!long(firstOperand + secondOperand);
    }

    void mulLong() {
        long firstOperand = pop!long;
        long secondOperand = pop!long;
        push!long(firstOperand * secondOperand);
    }

    void divLong() {
        long firstOperand = pop!long;
        long secondOperand = pop!long;
        push!long(secondOperand / firstOperand);
    }

    void subLong() {
        long firstOperand = pop!long;
        long secondOperand = pop!long;
        push!long(secondOperand - firstOperand);
    }

    // Float
    void pushFloat() {
        push!float(mCurrInstruction.mOperand1.get);
    }

    void addFloat() {
        float firstOperand = pop!float;
        float secondOperand = pop!float;
        push!float(firstOperand + secondOperand);
    }

    void mulFloat() {
        float firstOperand = pop!float;
        float secondOperand = pop!float;
        push!float(firstOperand * secondOperand);
    }

    void divFloat() {
        float firstOperand = pop!float;
        float secondOperand = pop!float;
        push!float(secondOperand / firstOperand);
    }

    void subFloat() {
        float firstOperand = pop!float;
        float secondOperand = pop!float;
        push!float(secondOperand - firstOperand);
    }
}

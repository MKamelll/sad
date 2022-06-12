module vm.instruction;

import std.typecons;
import std.conv;

enum Opcode : ushort
{
    PUSHI, PUSHF, PUSHL,
    
    ADDI, ADDF, ADDL,
    SUBI, SUBF, SUBL,
    MULI, MULF, MULL,
    DIVI, DIVF, DIVL,

    HALT
}

class Instruction
{
    Opcode mOpcode;
    Nullable!string mOperand1;
    Nullable!string mOperand2;

    this (Opcode opcode) {
        mOpcode = opcode;
    }

    this (Opcode opcode, string operand1) {
        mOpcode = opcode;
        mOperand1 = operand1;
    }
    
    this (Opcode opcode, string operand1, string operand2) {
        mOpcode = opcode;
        mOperand1 = operand1;
        mOperand2 = operand2;
    }

    Opcode getOpcode() {
        return mOpcode;
    }

    override string toString() {
        if (!mOperand1.isNull) {
            return "Instruction(opcode: " ~ to!string(mOpcode) ~ ", operand: " ~ mOperand1.toString() ~ ")";
        } else if (!mOperand2.isNull) {
            return "Instruction(opcode: " ~ to!string(mOpcode) ~ ", operand: " ~ mOperand2.toString() ~ ")";
        } else if (!mOperand1.isNull && !mOperand2.isNull) {
            return "Instruction(opcode: " ~ to!string(mOpcode) ~ ", operand1: "
                ~ mOperand1.toString() ~ ", operand2: " ~ mOperand2.toString() ~ ")";
        }

        return "Instruction(opcode: " ~ to!string(mOpcode) ~ ")";
    }
}



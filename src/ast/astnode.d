module ast.astnode;

import std.variant;
import std.conv;
import std.typecons;
import compiler.visitor;

abstract class AstNode {

    abstract void accept(Visitor v);
    
    static class PrimaryNode : AstNode
    {
        private Variant mVal;

        this(Variant val) {
            mVal = val;
        }

        Variant getValue() {
            return mVal;
        }

        string getValueStr() {
            return mVal.toString();
        }

        override string toString() {
            return "Primary(" ~ mVal.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }

    }

    static class NumberNode : PrimaryNode
    {
        this(Variant val) {
            super(val);
        }

        override string toString() {
            return "Number(" ~ mVal.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class IdentifierNode : PrimaryNode
    {
        Nullable!string mType;
        
        this(Variant val) {
            super(val);
        }

        this (Variant val, string type) {
            super(val);
            mType = type;
        }

        string getType() {
            if (mType.isNull) return "auto";
            return mType.toString();
        }

        override string toString() {
            if (!mType.isNull)
                return "Identifier(value: " ~ mVal.toString() ~ ", type: " ~ mType.toString() ~ ")";
            
            return "Identifier(value: " ~ mVal.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class BinaryNode : AstNode
    {
        private string mOp;
        private AstNode mLhs;
        private AstNode mRhs;

        this(string op, AstNode lhs, AstNode rhs) {
            mOp = op;
            mLhs = lhs;
            mRhs = rhs;
        }

        string getOp() {
            return mOp;
        }

        AstNode getLhs() {
            return mLhs;
        }

        AstNode getRhs() {
            return mRhs;
        }
        
        override string toString() {
            return "Binary(op: '" ~ mOp ~ "'" ~ ", lhs: " ~ mLhs.toString() ~ ", rhs: " ~ mRhs.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }

    }

    static class PrefixNode : AstNode
    {
        private string mOp;
        private AstNode mRhs;

        this (string op, AstNode rhs) {
            mOp = op;
            mRhs = rhs;
        }

        string getOp() {
            return mOp;
        }

        AstNode getRhs() {
            return mRhs;
        }

        override string toString() {
            return "Prefix(op: '" ~ mOp ~ "', rhs: " ~ mRhs.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    
    static class LetDefinitionNode : AstNode
    {
        private AstNode mIdentifier;
        private AstNode mRhs;

        this (AstNode identifier, AstNode rhs) {
            mIdentifier = identifier;
            mRhs = rhs;
        }

        AstNode getIdentifier() {
            return mIdentifier;
        }

        AstNode getRhs() {
            return mRhs;
        }

        override string toString() {
            return "Let(identifier: " ~ mIdentifier.toString() ~  ", rhs: " ~ mRhs.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class LetDeclarationNode : AstNode
    {
        private AstNode mIdentifier;

        this (AstNode identifier) {
            mIdentifier = identifier;
        }

        AstNode getIdentifier() {
            return mIdentifier;
        }

        override string toString() {
            return "Let(identifier: " ~ mIdentifier.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class ConstDefinitionNode : AstNode
    {
        private AstNode mIdentifier;
        private AstNode mRhs;

        this (AstNode identifier, AstNode rhs) {
            mIdentifier = identifier;
            mRhs = rhs;
        }

        AstNode getIdentifier() {
            return mIdentifier;
        }

        AstNode getRhs() {
            return mRhs;
        }

        override string toString() {
            return "Const(identifier: " ~ mIdentifier.toString() ~ ", rhs: " ~ mRhs.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class BlockNode : AstNode
    {
        private AstNode[] mSubtree;

        this (AstNode[] subtree) {
            mSubtree = subtree;
        }

        AstNode[] getSubtree() {
            return mSubtree;
        }

        override string toString() {
            return "Block(" ~ to!string(mSubtree) ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class ParanNode : BlockNode
    {
        this (AstNode[] subtree) {
            super(subtree);
        }

        override string toString() {
            return "Paren(" ~ to!string(mSubtree) ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class FunctionNode : AstNode
    {
        private AstNode mIdentifier;
        private AstNode mAnnonFn;

        this (AstNode identifier, AstNode annonFn) {
            mIdentifier = identifier;
            mAnnonFn = annonFn;
        }

        AstNode getIdentifier() {
            return mIdentifier;
        }

        AstNode getAnnonFn() {
            return mAnnonFn;
        }

        override string toString() {
            return "Fn(identifier: " ~ mIdentifier.toString() ~ ", AnnonFn: " ~ mAnnonFn.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class ConstFunctionNode : FunctionNode
    {
        this (AstNode identifier, AstNode annonFn) {
            super(identifier, annonFn);
        }

        override string toString() {
            return "ConstFn(identifier: " ~ mIdentifier.toString() ~ ", AnnonFn: " ~ mAnnonFn.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class AnonymousFunction : AstNode
    {
        private AstNode mParams;
        private AstNode mBlock;
        private Nullable!string mReturnType;

        AstNode getParams() {
            return mParams;
        }

        AstNode getBlock() {
            return mBlock;
        }

        string getReturnType() {
            if (mReturnType.isNull) return "void";
            return mReturnType.toString();
        }

        this (AstNode params, AstNode block, string returnType) {
            mParams = params;
            mBlock = block;
            mReturnType = returnType;
        }

        this (AstNode params, AstNode block) {
            mParams = params;
            mBlock = block;
        }

        override string toString() {
            if (!mReturnType.isNull) {
                return "AnonymousFn(returnType: " ~ mReturnType.toString() ~ ", params: " ~ mParams.toString()
                    ~ ", block: " ~ mBlock.toString() ~ ")";    
            }
            return "AnonymousFn(params: " ~ mParams.toString() ~ ", block: " ~ mBlock.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class IfNode : AstNode
    {
        private AstNode mCondition;
        private AstNode mThenBranch;
        private AstNode[] mElifBranches;
        private Nullable!AstNode mElseBranch;

        this (AstNode condition, AstNode thenBranch, AstNode[] elifBranches, Nullable!AstNode elseBranch) {
            mCondition = condition;
            mThenBranch = thenBranch;
            mElifBranches = elifBranches;
            mElseBranch = elseBranch;            
        }

        AstNode getCondition() {
            return mCondition;
        }

        AstNode getThenBranch() {
            return mThenBranch;
        }

        AstNode[] getElifBranches() {
            return mElifBranches;
        }

        Nullable!AstNode getElseBranch() {
            return mElseBranch;
        }

        override string toString() {
            if (!mElseBranch.isNull) {
                return "If(condition: " ~ mCondition.toString() ~ ", then: " ~ mThenBranch.toString() ~ ", elif: "
                    ~ to!string(mElifBranches) ~ ", else: " ~ mElseBranch.toString() ~ ")";            
            }

            return "If(condition: " ~ mCondition.toString() ~ ", then: " ~ mThenBranch.toString() ~ ", elif: "
                    ~ to!string(mElifBranches) ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class ForNode : AstNode
    {
        private AstNode mIndex;
        private AstNode mCondition;
        private AstNode mIncrement;
        private AstNode mBlock;

        this (AstNode index, AstNode condition, AstNode increment, AstNode block) {
            mIndex = index;
            mCondition = condition;
            mIncrement = increment;
            mBlock = block;
        }

        AstNode getIndex() {
            return mIndex;
        }

        AstNode getCondition() {
            return mCondition;
        }

        AstNode getIncrement() {
            return mIncrement;
        }

        AstNode getBlock() {
            return mBlock;
        }

        override string toString() {
            return "For(index: " ~ mIndex.toString() ~ ", condition: "
                ~ to!string(mCondition) ~ ", increment: " ~ mIncrement.toString()
                ~ ", block: " ~ mBlock.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class WhileNode : AstNode
    {
        AstNode mCondition;
        Nullable!AstNode mBlock;

        this (AstNode condition, AstNode block) {
            mCondition = condition;
            mBlock = block;
        }

        this (AstNode condition) {
            mCondition = condition;
        }

        override string toString() {
            if (!mBlock.isNull) {
                return "While(condition: " ~ mCondition.toString()
                    ~ ", block: " ~ mBlock.toString() ~ ")";

            }

            return "While(condition: " ~ mCondition.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class AnonymousStruct : AstNode
    {
        AstNode mBlock;

        this (AstNode block) {
            mBlock = block;
        }

        override string toString() {
            return "AnonymusStruct(block: " ~ mBlock.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }

    static class StructNode : AstNode
    {
        AstNode mIdentifier;
        AstNode mAnonymousStruct;

        this (AstNode identifier, AstNode anstruct) {
            mIdentifier = identifier;
            mAnonymousStruct = anstruct;
        }

        override string toString() {
            return "Struct(identifier: " ~ mIdentifier.toString()
                ~ ", anonymousStruct: " ~ mAnonymousStruct.toString() ~ ")";
        }

        override void accept(Visitor v) {
            v.visit(this);
        }
    }
}

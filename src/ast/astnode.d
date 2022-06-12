module ast.astnode;

import std.variant;
import std.conv;
import std.typecons;

abstract class AstNode {

    static class PrimaryNode : AstNode
    {
        Variant mVal;

        this(Variant val) {
            mVal = val;
        }

        override string toString() {
            return "Primary(" ~ mVal.toString() ~ ")";
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

        Nullable!string getType() {
            return mType;
        }

        override string toString() {
            if (!mType.isNull)
                return "Identifier(value: " ~ mVal.toString() ~ ", type: " ~ mType.toString() ~ ")";
            
            return "Identifier(value: " ~ mVal.toString() ~ ")";
        }
    }

    static class BinaryNode : AstNode
    {
        string mOp;
        AstNode mLhs;
        AstNode mRhs;

        this(string op, AstNode lhs, AstNode rhs) {
            mOp = op;
            mLhs = lhs;
            mRhs = rhs;
        }

        override string toString() {
            return "Binary(op: '" ~ mOp ~ "'" ~ ", lhs: " ~ mLhs.toString() ~ ", rhs: " ~ mRhs.toString() ~ ")";
        }

    }

    
    static class PrefixNode : AstNode
    {
        string mOp;
        AstNode mRhs;

        this (string op, AstNode rhs) {
            mOp = op;
            mRhs = rhs;
        }

        override string toString() {
            return "Prefix(op: '" ~ mOp ~ "', rhs: " ~ mRhs.toString() ~ ")";
        }
    }

    
    static class LetDefinitionNode : AstNode
    {
        AstNode mIdentifier;
        AstNode mRhs;

        this (AstNode identifier, AstNode rhs) {
            mIdentifier = identifier;
            mRhs = rhs;
        }

        override string toString() {
            return "Let(identifier: " ~ mIdentifier.toString() ~  ", rhs: " ~ mRhs.toString() ~ ")";
        }
    }

    static class LetDeclarationNode : AstNode
    {
        AstNode mIdentifier;

        this (AstNode identifier) {
            mIdentifier = identifier;
        }

        override string toString() {
            return "Let(identifier: " ~ mIdentifier.toString() ~ ")";
        }
    }

    static class ConstDefinitionNode : AstNode
    {
        AstNode mIdentifier;
        AstNode mRhs;

        this (AstNode identifier, AstNode rhs) {
            mIdentifier = identifier;
            mRhs = rhs;
        }

        override string toString() {
            return "Const(identifier: " ~ mIdentifier.toString() ~ ", rhs: " ~ mRhs.toString() ~ ")";
        }
    }

    static class BlockNode : AstNode
    {
        AstNode[] mSubtree;

        this (AstNode[] subtree) {
            mSubtree = subtree;
        }

        override string toString() {
            return "Block(" ~ to!string(mSubtree) ~ ")";
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
    }

    static class FunctionNode : AstNode
    {
        AstNode mIdentifier;
        AstNode mAnnonFn;

        this (AstNode identifier, AstNode annonFn) {
            mIdentifier = identifier;
            mAnnonFn = annonFn;
        }

        override string toString() {
            return "Fn(identifier: " ~ mIdentifier.toString() ~ ", AnnonFn: " ~ mAnnonFn.toString() ~ ")";
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
    }

    static class AnonymousFunction : AstNode
    {
        AstNode mParams;
        AstNode mBlock;
        Nullable!string mReturnType;

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
    }

    static class IfNode : AstNode
    {
        AstNode mCondition;
        AstNode mThenBranch;
        AstNode[] mElifBranches;
        Nullable!AstNode mElseBranch;

        this (AstNode condition, AstNode thenBranch, AstNode[] elifBranches, Nullable!AstNode elseBranch) {
            mCondition = condition;
            mThenBranch = thenBranch;
            mElifBranches = elifBranches;
            mElseBranch = elseBranch;            
        }

        override string toString() {
            if (!mElseBranch.isNull) {
                return "If(condition: " ~ mCondition.toString() ~ ", then: " ~ mThenBranch.toString() ~ ", elif: "
                    ~ to!string(mElifBranches) ~ ", else: " ~ mElseBranch.toString() ~ ")";            
            }

            return "If(condition: " ~ mCondition.toString() ~ ", then: " ~ mThenBranch.toString() ~ ", elif: "
                    ~ to!string(mElifBranches) ~ ")";
        }
    }

    static class ForNode : AstNode
    {
        AstNode mIndex;
        AstNode mCondition;
        AstNode mIncrement;
        AstNode mBlock;

        this (AstNode index, AstNode condition, AstNode increment, AstNode block) {
            mIndex = index;
            mCondition = condition;
            mIncrement = increment;
            mBlock = block;
        }

        override string toString() {
            return "For(index: " ~ mIndex.toString() ~ ", condition: "
                ~ to!string(mCondition) ~ ", increment: " ~ mIncrement.toString()
                ~ ", block: " ~ mBlock.toString() ~ ")";
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
    }
}

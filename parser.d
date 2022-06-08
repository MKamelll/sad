module parser;

import lexer;
import std.variant;
import std.algorithm;
import std.exception;
import std.stdio;
import std.conv;
import error;

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
        this(Variant val) {
            super(val);
        }

        override string toString() {
            return "Identifier(" ~ mVal.toString() ~ ")";
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
        AstNode mParams;
        AstNode mBlock;

        this (AstNode identifier, AstNode params, AstNode block) {
            mIdentifier = identifier;
            mParams = params;
            mBlock = block;
        }

        override string toString() {
            return "Fun(identifier: " ~ mIdentifier.toString() ~ ", params: "
                ~ to!string(mParams) ~ ", block: " ~ mBlock.toString() ~ ")";
        }
    }
}

enum Assoc {
    Left, Right, None
}

class OpInfo
{
    int mPrec;
    Assoc mAssoc;

    this(int prec, Assoc assoc) {
        mPrec = prec;
        mAssoc = assoc;
    }
}

class Ast
{
    Tokenizer mLexer;
    AstNode mRoot;
    AstNode[] mSubTrees;
    Token mCurrToken;

    this (Tokenizer lex) {
        mLexer = lex;
        mCurrToken = mLexer.next();
        mSubTrees = [];
    }

    OpInfo getPrecAndAssoc(string op) {
        switch (op) {
            case "=":  return new OpInfo(1, Assoc.Right);
            case "==": return new OpInfo(2, Assoc.Left);
            case "!=": return new OpInfo(2, Assoc.Left);
            case ">":  return new OpInfo(3, Assoc.Left);
            case ">=": return new OpInfo(3, Assoc.Left);
            case "<":  return new OpInfo(3, Assoc.Left);
            case "<=": return new OpInfo(3, Assoc.Left);
            case "+":  return new OpInfo(4, Assoc.Left);
            case "-":  return new OpInfo(4, Assoc.Left);
            case "*":  return new OpInfo(5, Assoc.Left);
            case "/":  return new OpInfo(5, Assoc.Left);
            case "%":  return new OpInfo(5, Assoc.Left);
            case "^":  return new OpInfo(6, Assoc.Right);
            default:   return new OpInfo(-1, Assoc.None);
        }
    }

    void advance() {
        mCurrToken = mLexer.next();
    }

    bool isAtEnd() {
        if (mCurrToken.type == TokenType.Eof) {
            return true;
        }

        return false;
    }

    bool check(TokenType type) {
        if (mCurrToken.type == type)
            return true;
        
        return false;
    }

    bool match(TokenType[] types...) {
        foreach (type; types)
        {
            if (check(type)) {
                advance();
                return true;
            }
        }

        return false;
    }

    ParseError expected(TokenType type, string hint = "") {
        string err  = "Expected '" ~ type ~ "' instead got '" ~ mCurrToken.lexeme.toString() ~ "'";

        if (hint.length >= 1) 
            err ~= "\n |=> Hint: " ~ hint;
        
        return new ParseError(err);
    }

    AstNode[] parse() {
        
        if (isAtEnd()) return mSubTrees;
        
        AstNode expr = parseExpr();

        if (!match(TokenType.SemiColon)) throw expected(TokenType.SemiColon);
        
        mSubTrees ~= expr;
        
        return parse();
    }

    AstNode parseExpr(int minPrec = 0) {
        
        AstNode lhs = parsePrimary();

         while (!isAtEnd()) {
            string op = mCurrToken.lexeme.toString();
            auto opInfo = getPrecAndAssoc(op);

            if (opInfo.mPrec == -1 || opInfo.mPrec < minPrec) break;
            
            int nextMinPrec = opInfo.mAssoc == Assoc.Left ? opInfo.mPrec + 1 : opInfo.mPrec;
            
            advance();
            AstNode rhs = parseExpr(nextMinPrec);
            
            lhs = new AstNode.BinaryNode(op, lhs, rhs);
        }

        mRoot = lhs;

        return mRoot;
    }

    AstNode parsePrimary() {
        return parseNumber();
    }

    AstNode parseNumber() {
        Token curr = mCurrToken;
        if (match(TokenType.Int, TokenType.Float)) {
            AstNode node = new AstNode.NumberNode(curr.lexeme);
            return node;
        }

        return parseIdentifier();
    }

    AstNode parseIdentifier() {
        Token curr = mCurrToken;
        if (match(TokenType.Identifier)) {
            AstNode node = new AstNode.IdentifierNode(curr.lexeme);
            return node;

        }

        return parseParen();
    }

    AstNode parseParen() {
        
        if (match(TokenType.Left_Paren)) {
            AstNode[] result = [];
            if (match(TokenType.Right_Paren)) return new AstNode.ParanNode(result);
            
            result ~= parseExpr();

            while (match(TokenType.Comma)) {
                result ~= parseExpr(); 
            }
            
            if (match(TokenType.Right_Paren)) {
                return new AstNode.ParanNode(result);
            } else {
                throw expected(TokenType.Right_Paren);
            }
            
        }

        return parseLet();
    }
    
    AstNode parseLet() {
        if (match(TokenType.Let)) {
            AstNode identifier = parsePrimary();            
            
            match(TokenType.Colon);
            
            if (match(TokenType.Fn)) return parseFn(identifier);

            if (match(TokenType.Eq)) {
                AstNode rhs = parseExpr();
                return new AstNode.LetDefinitionNode(identifier, rhs);        
            
            } else {

                return new AstNode.LetDeclarationNode(identifier);
            }

        }
        
        return parseBlock();
    }

    AstNode parseFn(AstNode identifier) {

        if (match(TokenType.Eq)) {
            AstNode params = new AstNode.ParanNode([]);
            AstNode block = new AstNode.BlockNode([]);
            
            if (check(TokenType.Left_Paren)) {
                params = parseParen();
            }

            if (check(TokenType.Left_Bracket)) {
                block = parseBlock();
            }
            
            return new AstNode.FunctionNode(identifier, params, block);

        }
        
        throw expected(TokenType.Eq, "Function definition without, you guessed it, definition");
    }

    AstNode parseBlock() {

        if (match(TokenType.Left_Bracket)) {
            AstNode[] result = [];
            if (match(TokenType.Right_Bracket)) return new AstNode.BlockNode(result);

            result ~= parseExpr();
            while (match(TokenType.SemiColon) && !match(TokenType.Right_Bracket)) {
                result ~= parseExpr();
            }

            return new AstNode.BlockNode(result);
        }
        return parseConst();
    }
    
    AstNode parseConst() {
        if (match(TokenType.Const)) {
            
            AstNode identifier = parsePrimary();
            
            if (!match(TokenType.Eq)) 
                throw expected(TokenType.Eq, "const requires definition not declaration because it's as the name may suggest, a const");
            
            AstNode rhs = parseExpr();
            
            return new AstNode.ConstDefinitionNode(identifier, rhs);
        }

        throw new ParseError("Expected a primary instead got '" ~ mCurrToken.lexeme.toString() ~ "'");
    }

}

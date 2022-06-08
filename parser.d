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

    static class FunctionNode : AstNode
    {
        AstNode mIdentifier;
        AstNode[] mParams;
        AstNode mBlock;

        this (AstNode identifier, AstNode[] params, AstNode block) {
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
    AstNode[] mSubtrees;
    Token mCurrToken;

    this (Tokenizer lex) {
        mLexer = lex;
        mCurrToken = mLexer.next();
        mSubtrees = [];
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

    bool expect(TokenType type, string hint = "") {
        string err  = "Expected '" ~ type ~ "' instead got '" ~ mCurrToken.lexeme.toString() ~ "'";

        if (hint.length >= 1)
            err ~= "\n |=> Hint: " ~ hint;
        
        if (mCurrToken.type != type)
            throw new ParseError(err);
        
        return true;
    }

    AstNode[] parse() {
        
        if (isAtEnd()) return mSubtrees;
        
        AstNode expr = parseExpr();

        expect(TokenType.SemiColon);
        
        advance();
        
        mSubtrees ~= expr;
        
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
        switch (mCurrToken.type) {
            case TokenType.Int: case TokenType.Float: return parseNumber();
            case TokenType.Identifier: return parseIdentifier();
            case TokenType.Left_Paren: return parseParen();
            case TokenType.Let: return parseLet();
            case TokenType.Const: return parseConst();
            case TokenType.Left_Bracket: return parseBlock();
            default: {
                throw new ParseError("Expected a primary instead got '" ~ mCurrToken.lexeme.toString() ~ "'");
            }
        }        
    }

    AstNode parseNumber() {
        AstNode node = new AstNode.NumberNode(mCurrToken.lexeme);
        advance();

        return node;
    }

    AstNode parseIdentifier() {
        AstNode node = new AstNode.IdentifierNode(mCurrToken.lexeme);
        advance();

        return node;
    }

    AstNode parseParen() {
        // escape "("
        advance();
        AstNode expr = parseExpr();

        expect(TokenType.Right_Paren);
        
        // escape ")"
        advance();

        return expr;
    }
    
    AstNode parseLet() {
        // past let
        advance();
        
        expect(TokenType.Identifier);
        
        AstNode identifier = parsePrimary();

        expect(TokenType.Colon, "You have to provide a type");

        advance();

        if (expect(TokenType.Fn)) {
            return parseFn(identifier);
        }

        if (!expect(TokenType.Eq))
            return new AstNode.LetDeclarationNode(identifier);
        
        advance();
        AstNode rhs = parseExpr();
        
        return new AstNode.LetDefinitionNode(identifier, rhs);        
    }
    
    
    AstNode parseConst() {
        // past const
        advance();

        expect(TokenType.Identifier);
        
        AstNode identifier = parsePrimary();
        
        expect(TokenType.Eq, "const requires definition not declaration because it's as the name may suggest, a const");
        
        advance();
        AstNode rhs = parseExpr();

        return new AstNode.ConstDefinitionNode(identifier, rhs);
    }

    AstNode parseBlock() {
        
        AstNode[] subtree = [];
        
        // past {
        advance();

        subtree ~= parseExpr();

        expect(TokenType.SemiColon);
        
        advance();
            
        expect(TokenType.Right_Bracket);
        
        // advance past }
        advance();

        return new AstNode.BlockNode(subtree);
    }

    AstNode parseFn(AstNode identifier) {
        // pass fn
        advance();

        expect(TokenType.Eq, "Function definition without, you guessed it, definition");
        
        // advance =
        advance();

        // at (
        advance();

        AstNode[] params = parseParams();

        advance();
        AstNode block = parseBlock();

        return new AstNode.FunctionNode(identifier, params, block);
    }

    AstNode[] parseParams() {
        AstNode[] result = [];

        while (mCurrToken.type != TokenType.Right_Paren) {
            if (mCurrToken.type == TokenType.Comma) advance();

            result ~= parseIdentifier();
        }
        
        return result;
    }

}

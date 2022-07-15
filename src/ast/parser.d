module ast.parser;

import std.algorithm;
import std.exception;
import std.stdio;
import std.typecons;

import ast.error;
import ast.lexer;
import ast.astnode;

enum Assoc {
    LEFT, RIGHT, NONE
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
    Token mPrevToken;

    this (Tokenizer lex) {
        mLexer = lex;
        mPrevToken = mCurrToken;
        mCurrToken = mLexer.next();
        mSubTrees = [];
    }

    OpInfo getPrecAndAssoc(string op) {
        switch (op) {
            case "=":  return new OpInfo(1, Assoc.RIGHT);
            case "+=": return new OpInfo(1, Assoc.LEFT);
            case "==": return new OpInfo(2, Assoc.LEFT);
            case "!=": return new OpInfo(2, Assoc.LEFT);
            case ">":  return new OpInfo(3, Assoc.LEFT);
            case ">=": return new OpInfo(3, Assoc.LEFT);
            case "<":  return new OpInfo(3, Assoc.LEFT);
            case "<=": return new OpInfo(3, Assoc.LEFT);
            case "+":  return new OpInfo(4, Assoc.LEFT);
            case "-":  return new OpInfo(4, Assoc.LEFT);
            case "*":  return new OpInfo(5, Assoc.LEFT);
            case "/":  return new OpInfo(5, Assoc.LEFT);
            case "%":  return new OpInfo(5, Assoc.LEFT);
            case "^":  return new OpInfo(6, Assoc.RIGHT);
            default:   return new OpInfo(-1, Assoc.NONE);
        }
    }

    void advance() {
        mCurrToken = mLexer.next();
    }

    bool isAtEnd() {
        if (mCurrToken.getType() == TokenType.EOF) {
            return true;
        }

        return false;
    }

    bool check(TokenType type) {
        if (mCurrToken.getType() == type)
            return true;
        
        return false;
    }

    Token previous() {
        return mPrevToken;
    }

    bool match(TokenType[] types...) {
        foreach (type; types)
        {
            if (check(type)) {
                mPrevToken = mCurrToken;
                advance();
                return true;
            }
        }

        return false;
    }

    
    bool checkPrevious(TokenType type) {
        if (previous().getType() == type) {
            return true;
        }

        return false;
    }

    ParseError expected(TokenType type, string hint = "") {
        string err  = "Expected '" ~ type ~ "' instead got '" ~ mCurrToken.getLexeme().toString() ~ "'";

        if (hint.length >= 1) 
            err ~= "\n |=> Hint: " ~ hint;
        
        return new ParseError(err);
    }

    AstNode[] parse() {
        
        if (isAtEnd()) return mSubTrees;
        
        AstNode expr = parseExpr();

        if (!match(TokenType.SEMICOLON) && !checkPrevious(TokenType.RIGHT_BRACKET)) throw expected(TokenType.SEMICOLON);
        
        mSubTrees ~= expr;
        
        return parse();
    }

    AstNode parseExpr(int minPrec = 0) {
        
        AstNode lhs = parsePrimary();

         while (!isAtEnd()) {
            string op = mCurrToken.getLexeme().toString();
            auto opInfo = getPrecAndAssoc(op);

            if (opInfo.mPrec == -1 || opInfo.mPrec < minPrec) break;
            
            int nextMinPrec = opInfo.mAssoc == Assoc.LEFT ? opInfo.mPrec + 1 : opInfo.mPrec;
            
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
        if (match(TokenType.INT, TokenType.FLOAT)) {
            AstNode node = new AstNode.NumberNode(previous().getLexeme());
            return node;
        }

        return parseIdentifier();
    }

    AstNode parseIdentifier() {
        if (match(TokenType.IDENTIFIER)) {
            Token identifier = previous();
            
            if (match(TokenType.COLON)) {
                Token type = previous();
                AstNode node = new AstNode.IdentifierNode(identifier.getLexeme(), type.getLexeme().toString());
                return node;
            }
            
            AstNode node = new AstNode.IdentifierNode(identifier.getLexeme());
            return node;

        }
        return parsePrefix();
    }

    AstNode parsePrefix() {
        if (match(TokenType.MINUS, TokenType.BANG, TokenType.PLUS, TokenType.PLUS_PLUS)) {
            string op = previous().getLexeme().toString();
            AstNode rhs = parsePrimary();
            return new AstNode.PrefixNode(op, rhs);
        }
        return parseParen();
    }

    AstNode parseParen() {
        
        if (match(TokenType.LEFT_PAREN)) {
            AstNode[] paren = [];
            if (match(TokenType.RIGHT_PAREN)) {

                auto anonfn = parseAnonFn(paren);

                if (anonfn.isNull) {
                    return new AstNode.ParanNode(paren);
                } else {
                    return anonfn.get;
                }
            }
            
            paren ~= parseExpr();

            while (match(TokenType.COMMA)) {
                paren ~= parseExpr(); 
            }
            
            if (match(TokenType.RIGHT_PAREN)) {
                
                auto anonfn = parseAnonFn(paren);

                if (anonfn.isNull) {
                    return new AstNode.ParanNode(paren);
                } else {
                    return anonfn.get;
                }
                
            } else {
                throw expected(TokenType.RIGHT_PAREN);
            }
            
        }

        return parseLet();
    }
    
    Nullable!(AstNode.AnonymousFunction) parseAnonFn(AstNode[] paren) {
        Nullable!string returnType;
        if (match(TokenType.COLON)) {
            returnType = previous().getLexeme().toString();
        }
        
        if (check(TokenType.LEFT_BRACKET)) {
            AstNode block = parseBlock();

            if (returnType.isNull)
                return new AstNode.AnonymousFunction(new AstNode.ParanNode(paren), block).nullable;
            
            return new AstNode.AnonymousFunction(new AstNode.ParanNode(paren), block, returnType.get).nullable;
        }

        return Nullable!(AstNode.AnonymousFunction).init;
    }

    AstNode parseLet() {
        if (match(TokenType.LET)) {
            AstNode identifier = parseIdentifier();

            if (match(TokenType.EQ)) {
                AstNode rhs = parseExpr();
                return new AstNode.LetDefinitionNode(identifier, rhs);        
            
            } else {

                return new AstNode.LetDeclarationNode(identifier);
            }

        }
        
        return parseFn();
    }

    AstNode parseFn() {

        if (match(TokenType.FN)) {
            AstNode identifier = parseIdentifier();
            AstNode anonFn = parseExpr();
            
            return new AstNode.FunctionNode(identifier, anonFn);
        }
        
        return parseBlock();
    }

    AstNode parseBlock() {

        if (match(TokenType.LEFT_BRACKET)) {
            AstNode[] result = [];
            if (match(TokenType.RIGHT_BRACKET)) return new AstNode.BlockNode(result);

            result ~= parseExpr();
            while (match(TokenType.SEMICOLON) && !match(TokenType.RIGHT_BRACKET)) {
                result ~= parseExpr();
            }

            return new AstNode.BlockNode(result);
        }
        return parseConst();
    }
    
    AstNode parseConst() {
        if (match(TokenType.CONST)) {
            
            AstNode identifier = parseIdentifier();
            
            if (!match(TokenType.EQ)) 
                throw expected(TokenType.EQ, "const requires definition not declaration because it's as the name may suggest, a const");
            
            AstNode rhs = parseExpr();
            
            return new AstNode.ConstDefinitionNode(identifier, rhs);
        }

        return parseIf();
    }

    AstNode parseIf() {
        if (match(TokenType.IF)) {

            bool isParen = match(TokenType.LEFT_PAREN);
            
            AstNode condition = parseExpr();

            if (isParen && !match(TokenType.RIGHT_PAREN)) throw expected(TokenType.RIGHT_PAREN);
            
            AstNode thenBranch = parseBlock();
            AstNode[] elifBranches = [];

            Nullable!AstNode elseBranch;
            
            while (match(TokenType.ELIF)) {
                elifBranches ~= parseBlock();
            }

            if (match(TokenType.ELSE)) {
                elseBranch = parseBlock();
            }

            return new AstNode.IfNode(condition, thenBranch, elifBranches, elseBranch);
        
        }

        return parseFor();        
    }

    AstNode parseFor() {
        if (match(TokenType.FOR)) {
            bool isParen = match(TokenType.LEFT_PAREN);
            
            AstNode index = parseExpr();

            if (!match(TokenType.SEMICOLON)) throw expected(TokenType.SEMICOLON);

            AstNode condition = parseExpr();

            if (!match(TokenType.SEMICOLON)) throw expected(TokenType.SEMICOLON);

            AstNode increment = parseExpr();

            if (isParen) {
                if (!match(TokenType.RIGHT_PAREN)) throw expected(TokenType.RIGHT_PAREN);
            } else if (!check(TokenType.LEFT_BRACKET)) {
                throw expected(TokenType.LEFT_BRACKET);
            }

            AstNode block = parseBlock();

            return new AstNode.ForNode(index, condition, increment, block);

        }

        return parseWhile();

    }

    AstNode parseWhile() {
        if (match(TokenType.WHILE)) {
            bool isParen = match(TokenType.LEFT_PAREN);
            
            AstNode condition = parseExpr();

            if (isParen) {
                if (!match(TokenType.RIGHT_PAREN)) throw expected(TokenType.RIGHT_PAREN);
            } 
            
            if (!check(TokenType.LEFT_BRACKET)) {
                return new AstNode.WhileNode(condition);
            }
            
            AstNode block = parseBlock();

            return new AstNode.WhileNode(condition, block);
        }        
        
        return parseStruct();
    }

    AstNode parseStruct() {
        if (match(TokenType.STRUCT)) {
            if (check(TokenType.IDENTIFIER)) {
                AstNode identifier = parseIdentifier();
                AstNode block = parseBlock();
                return new AstNode.StructNode(identifier, new AstNode.AnonymousStruct(block));            
            }

            AstNode block = parseBlock();
            return new AstNode.AnonymousStruct(block);
        }
        
        throw new ParseError("Expected a primary instead got '" ~ mCurrToken.getLexeme().toString() ~ "'");     
    }

}

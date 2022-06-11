module parser;

import std.algorithm;
import std.exception;
import std.stdio;
import std.typecons;

import error;
import lexer;
import astnode;

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
    Token mPrevToken;

    this (Tokenizer lex) {
        mLexer = lex;
        mPrevToken = mCurrToken;
        mCurrToken = mLexer.next();
        mSubTrees = [];
    }

    OpInfo getPrecAndAssoc(string op) {
        switch (op) {
            case "=":  return new OpInfo(1, Assoc.Right);
            case "+=": return new OpInfo(1, Assoc.Left);
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
        if (previous().type == type) {
            return true;
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

        if (!match(TokenType.SemiColon) && !checkPrevious(TokenType.Right_Bracket)) throw expected(TokenType.SemiColon);
        
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
        if (match(TokenType.Int, TokenType.Float)) {
            AstNode node = new AstNode.NumberNode(previous().lexeme);
            return node;
        }

        return parseIdentifier();
    }

    AstNode parseIdentifier() {
        if (match(TokenType.Identifier)) {
            Token identifier = previous();
            
            if (match(TokenType.Colon)) {
                Token type = previous();
                AstNode node = new AstNode.IdentifierNode(identifier.lexeme, type.lexeme.toString());
                return node;
            }
            
            AstNode node = new AstNode.IdentifierNode(identifier.lexeme);
            return node;

        }
        return parsePrefix();
    }

    AstNode parsePrefix() {
        if (match(TokenType.Minus, TokenType.Bang, TokenType.Plus, TokenType.Plus_Plus)) {
            string op = previous().lexeme.toString();
            AstNode rhs = parsePrimary();
            return new AstNode.PrefixNode(op, rhs);
        }
        return parseParen();
    }

    AstNode parseParen() {
        
        if (match(TokenType.Left_Paren)) {
            AstNode[] paren = [];
            if (match(TokenType.Right_Paren)) {

                auto anonfn = parseAnonFn(paren);

                if (anonfn.isNull) {
                    return new AstNode.ParanNode(paren);
                } else {
                    return anonfn.get;
                }
            }
            
            paren ~= parseExpr();

            while (match(TokenType.Comma)) {
                paren ~= parseExpr(); 
            }
            
            if (match(TokenType.Right_Paren)) {
                
                auto anonfn = parseAnonFn(paren);

                if (anonfn.isNull) {
                    return new AstNode.ParanNode(paren);
                } else {
                    return anonfn.get;
                }
                
            } else {
                throw expected(TokenType.Right_Paren);
            }
            
        }

        return parseLet();
    }
    
    Nullable!(AstNode.AnonymousFunction) parseAnonFn(AstNode[] paren) {
        Nullable!string returnType;
        if (match(TokenType.Colon)) {
            returnType = previous().lexeme.toString();
        }
        
        if (check(TokenType.Left_Bracket)) {
            AstNode block = parseBlock();

            if (returnType.isNull)
                return new AstNode.AnonymousFunction(new AstNode.ParanNode(paren), block).nullable;
            
            return new AstNode.AnonymousFunction(new AstNode.ParanNode(paren), block, returnType.get).nullable;
        }

        return Nullable!(AstNode.AnonymousFunction).init;
    }

    AstNode parseLet() {
        if (match(TokenType.Let)) {
            AstNode identifier = parseIdentifier();

            if (match(TokenType.Eq)) {
                AstNode rhs = parseExpr();
                return new AstNode.LetDefinitionNode(identifier, rhs);        
            
            } else {

                return new AstNode.LetDeclarationNode(identifier);
            }

        }
        
        return parseFn();
    }

    AstNode parseFn() {

        if (match(TokenType.Fn)) {
            AstNode identifier = parseIdentifier();
            AstNode anonFn = parseExpr();
            
            return new AstNode.FunctionNode(identifier, anonFn);
        }
        
        return parseBlock();
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
            
            AstNode identifier = parseIdentifier();
            
            if (!match(TokenType.Eq)) 
                throw expected(TokenType.Eq, "const requires definition not declaration because it's as the name may suggest, a const");
            
            AstNode rhs = parseExpr();
            
            return new AstNode.ConstDefinitionNode(identifier, rhs);
        }

        return parseIf();
    }

    AstNode parseIf() {
        if (match(TokenType.If)) {
            
            AstNode condition = parseExpr();
            AstNode thenBranch = parseBlock();
            AstNode[] elifBranches = [];

            Nullable!AstNode elseBranch;
            
            while (match(TokenType.Elif)) {
                elifBranches ~= parseBlock();
            }

            if (match(TokenType.Else)) {
                elseBranch = parseBlock();
            }

            return new AstNode.IfNode(condition, thenBranch, elifBranches, elseBranch);
        
        }

        return parseFor();        
    }

    AstNode parseFor() {
        if (match(TokenType.For)) {
            bool isParen = match(TokenType.Left_Paren);
            
            AstNode index = parseExpr();

            if (!match(TokenType.SemiColon)) throw expected(TokenType.SemiColon);

            AstNode condition = parseExpr();

            if (!match(TokenType.SemiColon)) throw expected(TokenType.SemiColon);

            AstNode increment = parseExpr();

            if (isParen) {
                if (!match(TokenType.Right_Paren)) throw expected(TokenType.Right_Paren);
            } else if (!check(TokenType.Left_Bracket)) {
                throw expected(TokenType.Left_Bracket);
            }

            AstNode block = parseBlock();

            return new AstNode.ForNode(index, condition, increment, block);

        }

        return parseWhile();

    }

    AstNode parseWhile() {
        if (match(TokenType.While)) {
            bool isParen = match(TokenType.Left_Paren);
            
            AstNode condition = parseExpr();

            if (isParen) {
                if (!match(TokenType.Right_Paren)) throw expected(TokenType.Right_Paren);
            } 
            
            if (!check(TokenType.Left_Bracket)) {
                return new AstNode.WhileNode(condition);
            } else {
                throw expected(TokenType.Left_Bracket);
            }
            
            AstNode block = parseBlock();

            return new AstNode.WhileNode(condition, block);
        }        
        
        return parseStruct();
    }

    AstNode parseStruct() {
        if (match(TokenType.Struct)) {
            if (check(TokenType.Identifier)) {
                AstNode identifier = parseIdentifier();
                AstNode block = parseBlock();
                return new AstNode.StructNode(identifier, new AstNode.AnonymousStruct(block));            
            }

            AstNode block = parseBlock();
            return new AstNode.AnonymousStruct(block);
        }
        
        throw new ParseError("Expected a primary instead got '" ~ mCurrToken.lexeme.toString() ~ "'");     
    }

}

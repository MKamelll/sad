module compiler.transpiler;

import std.array;
import std.ascii;

import ast.astnode;
import compiler.visitor;
import compiler.error;

class Transpiler : Visitor
{
    private AstNode[] mSubtrees;
    private string mProgram;
    private int mCurrIndex;
    private int mCurrIndentationLevel;
    private string mStdImports;

    this (AstNode[] subtrees) {
        mSubtrees = subtrees;
        mProgram = "";
        mCurrIndex = 0;
        mCurrIndentationLevel = 0;
        mStdImports = "";
    }

    override string toString() {
        return mStdImports ~ mProgram;
    }

    private bool isAtEnd() {
        if (mCurrIndex < mSubtrees.length) return false;
        return true;
    }

    private void advance() {
        mCurrIndex++;
    }

    private AstNode currNode() {
        return mSubtrees[mCurrIndex];
    }

    private AstNode prevNode() {
        if (mCurrIndex > 0) {
            return mSubtrees[mCurrIndex - 1];
        }
        return mSubtrees[mCurrIndex];
    }

    private Transpiler append(string value) {
        mProgram ~= value;
        return this;
    }

    private Transpiler semiColon() {
        foreach_reverse (ch; mProgram) {
            if (!isWhite(ch)) break;
            mProgram.popBack();
        }
        append(";");
        return this;
    }

    private Transpiler eol() {
        append("\n");
        return this;
    }

    private Transpiler space(int count = 1) {
        for (int i = 0; i < count; i++) {
            append(" ");
        }
        return this;
    }

    private Transpiler indent() {
        space(mCurrIndentationLevel);
        return this;
    }

    private Transpiler incCurrentIndentationLevel(int count = 4) {
        mCurrIndentationLevel += count;
        return this;
    }

    private Transpiler decCurrentIndentationLevel(int count = 4) {
        mCurrIndentationLevel -= count;
        return this;
    }

    private Transpiler addImport(string mod) {
        append("import").space();
        append(mod).semiColon().eol();
        return this;
    }

    Transpiler generate() {
        if (isAtEnd()) return this;
        currNode().accept(this);
        advance();
        return generate();
    }

    override void visit(AstNode.PrimaryNode node) {
        append(node.getValueStr());
    }

    override void visit(AstNode.NumberNode node) {
        append(node.getValueStr());
    }

    override void visit(AstNode.IdentifierNode node) {
        append(node.getValueStr());
    }

    override void visit(AstNode.BinaryNode node) {
        node.getLhs().accept(this);
        space().append(node.getOp()).space();
        node.getRhs().accept(this);
    }

    override void visit(AstNode.PrefixNode node) {
        append(node.getOp());
        node.getRhs().accept(this);
    }

    void visit(AstNode.LetDefinitionNode node) {
        AstNode.IdentifierNode id = cast(AstNode.IdentifierNode) node.getIdentifier(); 
        append(id.getType()).space();
        append(id.getValueStr()).space();
        append("=").space();
        node.getRhs().accept(this);
        semiColon();
    }

    void visit(AstNode.LetDeclarationNode node) {
        AstNode.IdentifierNode id = cast(AstNode.IdentifierNode) node.getIdentifier();
        if (id.getType() == "auto") {
            throw new TranspilerError("Missing a type for the variable '" ~ id.getValueStr() ~ "'");
        }
        append(id.getType()).space();
        append(id.getValueStr()).space();
        semiColon();
    }

    void visit(AstNode.ConstDefinitionNode node) {
        append("const").space();
        AstNode.IdentifierNode id = cast(AstNode.IdentifierNode) node.getIdentifier();
        append(id.getType()).space();
        append(id.getValueStr()).space();
        append("=").space();
        node.getRhs().accept(this);
        semiColon();
    }

    void visit(AstNode.BlockNode node) {
        eol().indent().append("{").eol();
        incCurrentIndentationLevel();
        foreach (n; node.getSubtree())
        {
            indent();
            n.accept(this);
        }
        decCurrentIndentationLevel();
        eol().indent().append("}").eol();
    }

    void visit(AstNode.ParanNode node) {
        append("(");
        AstNode[] subtree = node.getSubtree();
        for (int i = 0; i < subtree.length; i++)
        {
            subtree[i].accept(this);
            if (i + 1 < subtree.length) append(", ");
        }
        append(")");
    }

    void visit(AstNode.FunctionNode node) {

    }

    void visit(AstNode.ConstFunctionNode node) {

    }

    void visit(AstNode.AnonymousFunction node) {

    }

    void visit(AstNode.IfNode node) {

    }

    void visit(AstNode.ForNode node) {

    }

    void visit(AstNode.WhileNode node) {

    }

    void visit(AstNode.AnonymousStruct node) {

    }

    void visit(AstNode.StructNode node) {

    }
}
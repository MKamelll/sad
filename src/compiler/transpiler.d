module compiler.transpiler;

import ast.astnode;
import compiler.visitor;

class Transpiler : Visitor
{
    private AstNode[] mSubtrees;
    private string mProgram;
    private int mCurrIndex;
    private int mCurrIndentationLevel;

    this (AstNode[] subtrees) {
        mSubtrees = subtrees;
        mProgram = "";
        mCurrIndex = 0;
        mCurrIndentationLevel = 0;
    }

    override string toString() {
        return mProgram;
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

    Transpiler generate() {
        if (isAtEnd()) return this;
        currNode().accept(this);
        advance();
        return generate();
    }

    override void visit(AstNode.PrimaryNode node) {
        append(node.getValueStr()).space();
    }

    override void visit(AstNode.NumberNode node) {
        append(node.getValueStr()).space();
    }

    override void visit(AstNode.IdentifierNode node) {
        append(node.getType()).space();
        append(node.getValueStr()).space();
    }

    override void visit(AstNode.BinaryNode node) {
        node.getLhs().accept(this);
        append(node.getOp()).space();
        node.getRhs().accept(this);
    }

    override void visit(AstNode.PrefixNode node) {
        append(node.getOp());
        node.getRhs().accept(this);
    }

    void visit(AstNode.LetDefinitionNode node) { 
        append((cast(AstNode.IdentifierNode) node.getIdentifier()).getType()).space();
        append((cast(AstNode.IdentifierNode) node.getIdentifier()).getValueStr()).space();
        append("=").space();
        node.getRhs().accept(this);
        semiColon();
    }

    void visit(AstNode.LetDeclarationNode node) {
        append((cast(AstNode.IdentifierNode) node.getIdentifier()).getType()).space();
        append((cast(AstNode.IdentifierNode) node.getIdentifier()).getValueStr()).space();
        semiColon();
    }

    void visit(AstNode.ConstDefinitionNode node) {

    }

    void visit(AstNode.BlockNode node) {

    }

    void visit(AstNode.ParanNode node) {

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
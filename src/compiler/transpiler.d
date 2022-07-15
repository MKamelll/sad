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

    private Transpiler stripTrailingSemicolon() {
        foreach_reverse (ch; mProgram) {
            if (ch != ';') break;
            mProgram.popBack();
        }
        return this;
    }

    private Transpiler stripTrailingSpaces() {
        foreach_reverse (ch; mProgram) {
            if (!isWhite(ch)) break;
            mProgram.popBack();
        }
        return this;
    }

    private Transpiler semiColon() {
        stripTrailingSpaces().stripTrailingSemicolon();
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
        semiColon();
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

    private void genAnonymousFn(AstNode.AnonymousFunction node, bool isConst = false) {
        append("(");
        AstNode.ParanNode params = cast(AstNode.ParanNode) node.getParams();
        AstNode[] subtree = params.getSubtree();
        for (int i = 0; i < subtree.length; i++)
        {
            if (AstNode.IdentifierNode id = cast(AstNode.IdentifierNode) subtree[i]) {
                append(id.getType()).space();
                append(id.getValueStr());
            } else {
                throw new TranspilerError("Expected an identifier after '('");
            }
            if (i + 1 < subtree.length) append(", ");
        }
        if (isConst) {
            append(")").space().append("const");
        } else {
            append(")");
        }
        node.getBlock().accept(this);
    }

    void visit(AstNode.FunctionNode node) {
        if (AstNode.AnonymousFunction fn = cast(AstNode.AnonymousFunction) node.getAnnonFn()) {
            append(fn.getReturnType()).space();
            if (AstNode.IdentifierNode id = cast(AstNode.IdentifierNode) node.getIdentifier()) {
                append(id.getValueStr()).space();
            } else {
                throw new TranspilerError("Expected an identifier after 'fn'");
            }
            genAnonymousFn(fn);
        } else {
            throw new TranspilerError("Expected a parameters list");
        }
    }

    //fixme: we don't parse this yet :(
    void visit(AstNode.ConstFunctionNode node) {
        if (AstNode.AnonymousFunction fn = cast(AstNode.AnonymousFunction) node.getAnnonFn()) {
            append(fn.getReturnType()).space();
            if (AstNode.IdentifierNode id = cast(AstNode.IdentifierNode) node.getIdentifier()) {
                append(id.getValueStr()).space();
            } else {
                throw new TranspilerError("Expected an identifier after 'fn'");
            }
            genAnonymousFn(fn, true);
        } else {
            throw new TranspilerError("Expected a parameters list");
        }
    }

    void visit(AstNode.AnonymousFunction node) {
        genAnonymousFn(node);
    }

    void visit(AstNode.IfNode node) {
        append("if").space();
        append("(");
        node.getCondition().accept(this);
        stripTrailingSemicolon();
        append(")").space();
        node.getThenBranch().accept(this);
        auto elifBranches = node.getElifBranches();
        if (elifBranches.length > 0) {
            foreach (branch; elifBranches)
            {
                append("else if").space();
                branch.accept(this);
            }
        }

        if (!node.getElseBranch().isNull) {
            node.getElseBranch().get().accept(this);
        }

    }

    void visit(AstNode.ForNode node) {
        append("for").space();
        append("(");
        node.getIndex().accept(this);
        semiColon().space();
        node.getCondition().accept(this);
        semiColon().space();
        node.getIncrement().accept(this);
        stripTrailingSemicolon();
        append(")").space();
        node.getBlock().accept(this);
    }

    void visit(AstNode.WhileNode node) {
        append("while").space();
        append("(");
        node.getCondition().accept(this);
        stripTrailingSemicolon();
        append(")");

        if (!node.getBlock().isNull) {
            node.getBlock().get().accept(this);
        } else {
            semiColon();
        }
    }

    void visit(AstNode.AnonymousStruct node) {

    }

    void visit(AstNode.StructNode node) {

    }
}
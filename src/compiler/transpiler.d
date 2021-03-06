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
    private int mCurrCallDepth;

    this (AstNode[] subtrees) {
        mSubtrees = subtrees;
        mProgram = "";
        mCurrIndex = 0;
        mCurrIndentationLevel = 0;
        mStdImports = "";
        mCurrCallDepth = 0;
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

    private Transpiler incCurrentCallDepth() {
        mCurrCallDepth++;
        return this;
    }

    private Transpiler decCurrentCallDepth() {
        mCurrCallDepth--;
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
            eol();
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
        AstNode.BlockNode b = cast(AstNode.BlockNode) node.getBlock();
        AstNode[] subtree = b.getSubtree();
        eol().indent().append("{").eol();
        incCurrentIndentationLevel();
        for (int i = 0; i < subtree.length; i++)
        {
            
            if (AstNode.IdentifierNode id = cast(AstNode.IdentifierNode) subtree[i]) {
                indent().append(id.getType()).space();
                append(id.getValueStr()).semiColon().eol();
            } else {
                throw new TranspilerError("Expected an identifier in a struct definition");
            }
        }
        decCurrentIndentationLevel();
        eol().indent().append("}").eol();
    }

    void visit(AstNode.StructNode node) {
        append("struct").space();
        if (AstNode.IdentifierNode id = cast(AstNode.IdentifierNode) node.getIdentifier()) {
            append(id.getValueStr()).space();
        } else {
            throw new TranspilerError("Expected an identifier after 'struct'");
        }
        node.getAnonymousStruct().accept(this);
    }

    void visit(AstNode.ReturnNode node) {
        append("return").space();
        node.getExpr().accept(this);
        semiColon();
    }

    void visit(AstNode.CallNode node) {
        incCurrentCallDepth();
        if (AstNode.IdentifierNode id = cast(AstNode.IdentifierNode) node.getIdentifier()) {
            append(id.getValueStr());
            append("(");
            if (!node.getParen().isNull) {
                if (AstNode.ParanNode paren = cast(AstNode.ParanNode) node.getParen().get()) {
                    AstNode[] args = paren.getSubtree();
                    for (int i = 0; i < args.length; i++) {
                        args[i].accept(this);
                        stripTrailingSemicolon();
                        if (i + 1 < args.length) append(", ");
                    }
                }
            }
            stripTrailingSemicolon();
            append(")");
            if (mCurrCallDepth < 2) semiColon();
            decCurrentCallDepth();
        } else {
            throw new TranspilerError("Expected an identifier for the function call");
        }
    }

    void visit(AstNode.ImportNode node) {
        if (AstNode.StringNode str = cast(AstNode.StringNode) node.getImport()) {
           addImport(str.getValueStr());
        } else {
            throw new TranspilerError("Expected a module name to import");
        }
    }

    void visit(AstNode.StringNode node) {
        append("\"").append(node.getValueStr()).append("\"");
    }
}
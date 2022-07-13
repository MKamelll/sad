module compiler.visitor;

import ast.astnode;

interface Visitor
{
    void visit(AstNode.PrimaryNode node);
    void visit(AstNode.NumberNode node);
    void visit(AstNode.IdentifierNode node);
    void visit(AstNode.BinaryNode node);
    void visit(AstNode.PrefixNode node);
    void visit(AstNode.LetDefinitionNode node);
    void visit(AstNode.LetDeclarationNode node);
    void visit(AstNode.ConstDefinitionNode node);
    void visit(AstNode.BlockNode node);
    void visit(AstNode.ParanNode node);
    void visit(AstNode.ConstFunctionNode node);
    void visit(AstNode.AnonymousFunction node);
    void visit(AstNode.IfNode node);
    void visit(AstNode.ForNode node);
    void visit(AstNode.WhileNode node);
    void visit(AstNode.AnonymousStruct node);
    void visit(AstNode.StructNode node);
    void visit(AstNode.FunctionNode node);
}
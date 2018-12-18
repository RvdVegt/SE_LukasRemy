module normalize

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::FileSystem;
import Node;
import String;

public node normalizeNode(node ast) {
	return visit(ast) {
		// Declarations:
		case \method(a, _, list[Declaration] b, c, d) => \method(a, "Method", b, c, d)
		case \method(a, _, list[Declaration] b, c) => \method(a, "Method", b, c)
		//case \typeParameter(_, a) => \typeParameter("X", a)
		case \parameter(a, _, b) => \parameter(a, "X", b) 
		case \vararg(a, _) => \vararg(a, "X")
		
		// Expressions:
		case \cast(_, a) => \cast(lang::java::jdt::m3::AST::short(), a)
		case \characterLiteral(_) => \characterLiteral("Char")
		case \fieldAccess(a, b, _) => \fieldAccess(a, b, "FA")
		case \fieldAccess(a, _) => \fieldAccess(a, "FA")
		case \methodCall(a, b, _, c) => \methodCall(a, b, "MC", c)
		case \methodCall(a, _, b) => \methodCall(a, "MC", b)
		case \number(_) => \number("0")
		case \booleanLiteral(_) => \booleanLiteral(true)
		case \stringLiteral(_) => \stringLiteral("String")
		case \variable(_, a, b) => \variable("X", a, b)
		case \variable(_, a) => \variable("X", a)
		case \simpleName(_) => \simpleName("SimpleName")
		// Maybe we need some more expressions
		
		// Types:
		case Type _ => lang::java::jdt::m3::AST::short()
	}
}

public set[Declaration] normalizeAST(set[Declaration] ast) {
	return visit(ast) {
		case node n => normalizeNode(n)
	}
}

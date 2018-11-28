module results

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::FileSystem;
import Node;

// Type 3: see Levensteins algorithm
// https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=738528

// |project://temp/src|
public void type1(loc project) {
	set[Declaration] ast = createAstsFromEclipseProject(project, false);
	
	visit(ast) {
		// Declaration subtrees (do special things with the ones with lists.
		case n:\compilationUnit(Declaration package,list[Declaration] imports, list[Declaration] types): println(":::<n.src>");
		case n:\compilationUnit(list[Declaration] imports,list[Declaration] types): println("::<n.src>");
		case n:\enum(_,_,list[Declaration] constants,list[Declaration] body): println(n.src);
		case n:\enumConstant(_,_,_): println(n.src);
		case n:\enumConstant(_,_): println(n.src);
		case n:\class(_,_,_,list[Declaration] body): println(n.src);
		case n:\class(list[Declaration] body): println(n.src);
		case n:\interface(_,_,_,list[Declaration] body): println(n.src);
		case n:\field(_,_): println(n.src);
		case n:\initializer(_): println(n.src);
		case n:\method(_,_,_,_,_): println(n.src);
		case n:\method(_,_,_,_): println(n.src);
		case n:\constructor(_,_,_,_): println(n.src);
		case n:\import(_): println(n.src);
		case n:\package(_,_): println(n.src);
		case n:\package(_): println(n.src);
		case n:\annotationType(_,list[Declaration] body): println(n.src);
		case n:\annotationTypeMember(_,_): println(n.src);
		case n:\annotationTypeMember(_,_,_): println(n.src);
		
		// Statement sequence subtrees
		case n:\block(list[Statement] stmts): println(n.src);
		case n:\switch(list[Statement] stmts): println(n.src);
		case n:\try(_,list[Statement] catchClauses,_): println(n.src);
		case n:\try(_,list[Statement] catchClauses): println(n.src);
		
		// Statement subtree
		case Statement n: println(n.src);
	}
}
module results

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::FileSystem;
import Node;
import List;
import Set;
import Map;
import String;

// Type 3: see Levensteins algorithm
// https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=738528

// |project://temp/src|

int nodeMass(node n) {
	int count = 0;
	visit(n) {
		case node _: count += 1;
	}
	return count;
}

node nodeUnsetChildren(node n) {
	return visit(n) {
		case node x => unset(x)
	}
}

// Get all subtrees from the AST.
list[node] getAllSubtrees(set[Declaration] ast) {
	list[node] subtrees = [];
	
	for (dec <- ast) {
		visit(dec) {
			case node n: subtrees += n;
		}
	}
	
	return subtrees;
}

loc fileLocation(node n) {
	loc l = |noLocation:///|;
	
	switch(n) {
		case Declaration x: l = x.src;
		case Statement x: l = x.src;
		case Expression x : l = x.src;
	}
	
	if (l == |unknown:///|) return |noLocation:///|;
	else return l;
}

// Give every subtree a unique identifier and such.
// unsetRec(node) unsets the node and all its children.
list[tuple[tuple[int, node], node, loc, int]] idSubtrees(list[node] nodes) {
	list[tuple[int, node]] idNodes = zip([0..size(nodes)], nodes);
	return [<<id, n>, cleanN, l, s> | <id, n> <- idNodes,
											l := fileLocation(n),
											s := nodeMass(n),
											cleanN := unsetRec(n),
											s >= 6,
											l != |noLocation:///|,
											(l.end.line - l.begin.line + 1) >= 4];
}


public void type1(loc project) {
	set[Declaration] ast = createAstsFromEclipseProject(project, false);
	list[node] subtrees = getAllSubtrees(ast);
	list[tuple[tuple[int id, node n], node cn, loc l, int s]] idSubtrees = idSubtrees(subtrees);
	println(idSubtrees);
	
	for (n1 <- subtrees) {
		for (n2 <- subtrees) {
			if (n1.id == n2.id) continue; // Same node, we don't need to compare them.
			if (n1.s > n2.s) continue; // First node has more children, don't compare.
		}
	}
}






anno int Statement @ ID;
anno int Declaration @ ID;

/*
	All nodes we need to check are either statements or declaration. Expressions are parts of statements or declarations.
	Statements and Declarations are the lines themself.
	
	Give every node in the tree a unqiue ID
*/

// A map of children that point to their parent.
map[int, node] parOfChild = ();

/*
	This function adds all children and their parent to the map parOfChild.
*/
void setChildParent(node n) {
	int parID = n.ID;
	children = getChildren(n);
	switch(n) {
		case Statement st : {
			parOfChild[st.ID] = n;
		}
		case list[Statement] stmts: {
			for (st <- stmts) parOfChild[st.ID] = n;
		}
		case Declaration d: {
			parOfChild[d.ID] = n;
		}
		case list[Declaration] ds: {
			for (d <- ds) parOfChild[d.ID] = n;
		}
	}
}

/*
	This function adds an unique identifier to each node starting from given node/ast.
*/
node setIdentifiers(node ast) {
	int counter = 0;
	return visit(ast) {
		case Statement s: {
			s = s[@ID = counter];
			counter += 1;
			insert s;
		}
		case Declaration d: {
			d = d[@ID = counter];
			counter += 1;
			insert d;
		}
	}
}



void testf(loc project) {
	set[Declaration] ast = createAstsFromEclipseProject(project, false);
	set[Delcaration] newAst = setIdentifiers(ast);
	visit(newAst) {
		case Statement n: println(n.ID);
		case Declaration n: println(n.ID);
	}
}









public void t1(loc project) {
	set[Declaration] ast = createAstsFromEclipseProject(project, false);
	map[node, list[value]] buckets = ();
	
	ast = visit(ast) {
		case node n: {
			try {
				if (n.src? && nodeMass(n) >= 6) {
					a = nodeUnsetChildren(n);
					
					if (buckets[a]?) buckets[a] += n.src;
					else buckets[a] = [n.src];
				}
			}
			catch: println("No src");
		}
	}
	
	//visit(ast) {
	//	// Declaration subtrees (do special things with the ones with lists.
	//	case n:\compilationUnit(Declaration package,list[Declaration] imports, list[Declaration] types): println(":::<n.src>");
	//	case n:\compilationUnit(list[Declaration] imports,list[Declaration] types): println("::<n.src>");
	//	case n:\enum(_,_,list[Declaration] constants,list[Declaration] body): println(n.src);
	//	case n:\enumConstant(_,_,_): println(n.src);
	//	case n:\enumConstant(_,_): println(n.src);
	//	case n:\class(_,_,_,list[Declaration] body): println(n.src);
	//	case n:\class(list[Declaration] body): println(n.src);
	//	case n:\interface(_,_,_,list[Declaration] body): println(n.src);
	//	case n:\field(_,_): println(n.src);
	//	case n:\initializer(_): println(n.src);
	//	case n:\method(_,_,_,_,_): println(n.src);
	//	case n:\method(_,_,list[Declaration] _,_): println(n.src);
	//	case n:\constructor(_,_,_,_): println(n.src);
	//	case n:\import(_): println(n.src);
	//	case n:\package(_,_): println(n.src);
	//	case n:\package(_): println(n.src);
	//	case n:\annotationType(_,list[Declaration] body): println(n.src);
	//	case n:\annotationTypeMember(_,_): println(n.src);
	//	case n:\annotationTypeMember(_,_,_): println(n.src);
	//	
	//	case n:\vararg(_,_): {
	//		if (buckets[n]?) {
	//			buckets[n] += n;
	//		}
	//		else {
	//			buckets[n] = [n];
	//		}
	//	}
	//	
	//	
	//	// Statement sequence subtrees
	//	case n:\block(list[Statement] stmts): println(n.src);
	//	case n:\switch(_, list[Statement] stmts): println(n.src);
	//	case n:\try(_,list[Statement] catchClauses,_): println(n.src);
	//	case n:\try(_,list[Statement] catchClauses): println(n.src);
	//	
	//	// Statement subtree
	//	case Statement n: println(n.src);
	//}
	for (i <- toList(buckets)) {
		if (size(i[1]) >= 2) {
			println(i);
			println();
		}
	}
}
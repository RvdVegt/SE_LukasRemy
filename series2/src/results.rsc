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
import DateTime;
import util::Resources;
import util::Math;
import lang::json::IO;

int cast(int x) = x;
// Type 3: see Levensteins algorithm
// https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=738528

// |project://temp/src|
// |project://smallsql0.21_src/src|

void testing() {
	datetime startTime = now();
	set[Declaration] ast = createAstsFromEclipseProject(|project://smallsql0.21_src/src|, false);
	list[node] subtrees = getAllSubtrees(ast);
	
	map[int, list[tuple[node, loc]]] buckets = ();
	
	for (node subtree <- subtrees) {
		int key = nodeMass(subtree);
		if (key > 5) {
			if (buckets[key]?) {
				buckets[key] += <unsetRec(subtree), fileLocation(subtree)>;
			}
			else {
				buckets[key] = [<unsetRec(subtree), fileLocation(subtree)>];
			}
		}
	}
	
	list[list[tuple[node, loc]]] cloneclasses = [];
	map[str, list[list[int]]] childDup = ();
	list[int] keys = reverse(sort(buckets<0>));
	
	for (key <- keys) {
		list[list[tuple[node, loc]]] cc = compare(buckets[key], childDup);
		
		for (clonec <- cc) {
			for (clone <- clonec) {
				if (clone[1] != |noLocation:///|) {
					if (childDup[clone[1].path]?) {
						childDup[clone[1].path] += [[clone[1].begin.line, clone[1].end.line,
													clone[1].begin.column, clone[1].end.column]];
					}
					else {
						childDup[clone[1].path] = [[clone[1].begin.line, clone[1].end.line,
													clone[1].begin.column, clone[1].end.column]];
					}
				}
			}
		}
		
		cloneclasses += cc;
		
	}
	
	/*
	tuple[map[str, value], map[str, value]] jsonFormat = betterFormat(cloneclasses); 
	println(jsonFormat[0]);
	println();
	println(jsonFormat[1]);
	*/

	map[str, value] res = ("files":jsonFormat[0], "classes":jsonFormat[1]);
	writeJSON(|project://series2/src/firstjson.json|, res);
	
	/*
	for (i <- cloneclasses) {
		println(i);
		println("");
	}*/
	println(size(cloneclasses));
	
	datetime endTime = now();
	Duration dur = endTime - startTime;
	println();
	println("Duration: <dur.hours>h <dur.minutes>m <dur.seconds>s <dur.milliseconds>ms");
	
	/*
	int big2 = 0;
	loc t2;
	for (i <- cloneclasses) {
		int tmp = nodeMass(i[0][0]);
		if (big2 < tmp) {
			t2 = i[0][1];
			big2 = tmp;
		}
	}
	println(big2);
	println(t2);*/
}


//loop through all cloneclasses, take the first dup and check with all duplication out other cloneclasses
//if it is following the dup, then check if this holds for all dups in the two cloneclasses, fast check same size
/*list[list[tuple[node, loc]]] findSequence(list[list[tuple[node, loc]]] cloneclasses) {
	for (class <- clone) {
	
	} 
}*/

tuple[map[str, value], map[str, value]] betterFormat(list[list[tuple[node, loc]]] cloneclasses) {
	num ID = 0;
	map[str, tuple[int, int, list[map[str, value]]]] jsonFormat1 = ();
	map[str, tuple[list[tuple[str, int]], int]] jsonFormat2 = ();
	
	for (list[tuple[node, loc]] class <- cloneclasses) {
		for (tuple[node, loc] dup <- class) {
			if (jsonFormat1[location(dup[1]).path]?) {
				jsonFormat1[location(dup[1]).path][0] += dup[1].end.line - dup[1].begin.line + 1;
				map[str, value] d = ();
				d["linestart"] = dup[1].begin.line;
				d["linemass"] = dup[1].end.line - dup[1].begin.line + 1;
				d["classID"] = "<ID>";
				jsonFormat1[location(dup[1]).path][2] += [d];
			}
			else {
				jsonFormat1[location(dup[1]).path] = <0, 0, []>;
				jsonFormat1[location(dup[1]).path][0] = dup[1].end.line - dup[1].begin.line + 1;
				jsonFormat1[location(dup[1]).path][1] = size(readFileLines(location(dup[1])));
				map[str, value] d = ();
				d["linestart"] = dup[1].begin.line;
				d["linemass"] = dup[1].end.line - dup[1].begin.line + 1;
				d["classID"] = "<ID>";
				jsonFormat1[location(dup[1]).path][2] = [d];
			}
			
			if (jsonFormat2["<ID>"]?) {
				jsonFormat2["<ID>"][0] += [<location(dup[1]).path, size(jsonFormat1[location(dup[1]).path][2])-1>];
			}
			else {
				jsonFormat2["<ID>"] = <[], 0>;
				jsonFormat2["<ID>"][0] = [<location(dup[1]).path, size(jsonFormat1[location(dup[1]).path][2])-1>];
				jsonFormat2["<ID>"][1] = dup[1].end.line - dup[1].begin.line + 1;
			}
		}
		ID += 1;
	}
	return <jsonFormat1, jsonFormat2>;
}

list[list[tuple[node, loc]]] compare(list[tuple[node, loc]] bucket, map[str, list[list[int]]] childDup) {
	list[list[tuple[node, loc]]] cloneclasses = [];
	list[tuple[node, loc]] testedNodes = [last(bucket)];
	
	bool haveToCheck = true;
	for (subtree <- bucket) {
		haveToCheck = true;
		if (subtree[1] != |noLocation:///|) {
			if (childDup[subtree[1].path]?) {
				coords = childDup[subtree[1].path];
				for (i <- coords) {
					if (i[0] < subtree[1].begin.line && i[1] >= subtree[1].end.line) {
						haveToCheck = false;
					}
					else if (i[0] == subtree[1].begin.line && i[2] < subtree[1].begin.column) {
						haveToCheck = false;
					}
				}
			}
		}
	
		if (!(subtree in testedNodes) && haveToCheck) {
			testedNodes += subtree;
			list[tuple[node, loc]] clones = [subtree];
			for (int i <- [indexOf(bucket, subtree)+1..size(bucket)]) {
				if (subtree[0] == bucket[i][0]) {
					clones += bucket[i];
					testedNodes += bucket[i];
				}
			}
			
			if (size(clones) > 1) {
				cloneclasses += [clones];
			}
		}
	}
	return cloneclasses;
}

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
/*
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
*/
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


/*
void testf(loc project) {
	set[Declaration] ast = createAstsFromEclipseProject(project, false);
	set[Delcaration] newAst = setIdentifiers(ast);
	visit(newAst) {
		case Statement n: println(n.ID);
		case Declaration n: println(n.ID);
	}
}
*/








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
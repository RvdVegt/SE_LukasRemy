module results

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import lang::java::m3::AST;
import util::FileSystem;
import Node;
import List;
import Set;
import Map;
import String;
import Prelude;

anno int Statement @ uniqueId;
anno int Declaration @ uniqueId;

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
			if (n1.uniqueId == n2.uniqueId) continue; // Same node, we don't need to compare them.
			if (n1.s > n2.s) continue; // First node has more children, don't compare.
		}
	}
}


/*
	This function adds an unique identifier to each node starting from given node/ast.
*/
set[Declaration] setIdentifiers(set[Declaration] ast) {
	int counter = 0;
	return visit(ast) {
		case Statement s: {
			map[str,value] keywords = getKeywordParameters(s);
			s = setKeywordParameters(s, keywords + ("uniqueId": counter));
			counter += 1;
			insert s;
		}
		case Declaration d: {
			map[str,value] keywords = getKeywordParameters(d);
			d = setKeywordParameters(d, keywords + ("uniqueId": counter));
			counter += 1;
			insert d;
		}
	}
}

map[value, loc] mapIdToLoc(set[Declaration] ast) {
	map[value, loc] result = ();
	visit(ast) {
		case node n: {
			switch(n) {
				case Statement s: result[n.uniqueId] = fileLocation(s);
				case Declaration d: result[n.uniqueId] = fileLocation(d);
			}
		}
	}
	return result;
}

/*
	Some useful readable type aliases
*/
alias sequence = tuple[list[node], list[loc]];
alias sequences = list[sequence];
alias clonepair = tuple[list[loc], list[loc]];
alias clonepairs = list[clonepair];
alias cloneclass = set[list[loc]];
alias cloneclasses = list[cloneclass];
alias classloc = list[set[list[loc]]];

public sequences subsequencesFromStmt(list[Statement] n) {
	sequences sublist = [];
	
	if (size(n) < 4 || fileLocation(n[size(n)-1]).end.line - fileLocation(n[0]).begin.line < 4) {
		return [];
	}
	
	for (int s1 <- [0..size(n)-4]) {
		for (int s2 <- [s1+4..size(n)]) {
			sublist += [<nodes, locs> | s := slice(n, s1, s2-s1+1),
										nodes := [unsetRec(i) | i <- s],
										locs := [fileLocation(i) | i <- s]];
		}
	}
	
	return sublist;
}

public void testfun(list[int] l) {
	for (int i <- [0..size(l)]) {
		for (int j <- [i..size(l)]) {
			println("(<i> - <j>)");
			print(slice(l, i, j-i+1));
			println();
		}
	}
}

public sequences subsequencesFromDecl(list[Declaration] n) {
	sequences sublist = [];
	
	if (size(n) == 0 || fileLocation(n[size(n)-1]).end.line - fileLocation(n[0]).begin.line < 4) {
		return [];
	}
	
	for (int s1 <- [0..size(n)]) {
		for (int s2 <- [s1..size(n)]) {
			sublist += [<nodes, locs> | s := slice(n, s1, s2-s1+1),
										nodes := [unsetRec(i) | i <- s],
										locs := [fileLocation(i) | i <- s]];
		}
	}
	
	return sublist;
}


/*
	1) Get all subsequences from all lists of Statements and Declarations.
		A subsequence is a tuple of sequence of cleannodes and
		sequence of IDs of the nodes (to find the location of the nodes).
	
	2) Put all sequences in the bucket of the size of the sequence.
		E.g. Sequence of 2 statements goes in bucket[2].
		
	3) Compare in each bucket all the sequences with eachother.
		Make clone pairs of all sequences.
		sequence -> tuple[list[nodes], list[ids]]
		Compare all sequence[0] with eachother, but pair the sequence[1].
	
	5) Make clone classes of all clone pairs.
*/


void testf(loc project) {
	set[Declaration] ast = createAstsFromEclipseProject(project, false);
	
	map[int, sequences] buckets = ();
	
	visit(ast) {
		case list[Statement] n: {
			sequences sublist = subsequencesFromStmt(n);
			for (sequence s <- sublist) {
				int seqSize = size(s[0]);
				if (buckets[seqSize]?) {
					buckets[seqSize] += s;
				} else {
					buckets[seqSize] = [s];
				}
			}
		} 
		case list[Declaration] n: {
			sequences sublist = subsequencesFromDecl(n);
			for (sequence s <- sublist) {
				int seqSize = size(s[0]);
				if (buckets[seqSize]?) {
					buckets[seqSize] += s;
				} else {
					buckets[seqSize] = [s];
				}
			}
		}
	}
	
	cloneclasses classes = [];
	/* Compare all sequences in every bucket
	and make pairs and then classes from them.
		[<[1,2,3], [6,7,8]>, <[1,2,3],[13,14,15]>, <[6,7,8],[13,14,15]>] <- example clonepair list
		result: [{[1,2,3],[6,7,8],[13,14,15]}]
	*/
	set[int] bucketKeys = domain(buckets);
	println(bucketKeys);
	for (int b <- bucketKeys) {		
		list[clonepair] clonePairs = pairSequences(buckets[b]);
		
		println("bucket <b>\n sequences: <size(buckets[b])>\n Pairs: <size(clonePairs)>");
		
		for (pair <- clonePairs) {
			if (isEmpty(classes)) {
				classes += {pair[0], pair[1]};
				continue;
			}
			for (s <- [0..size(classes)]) {
				if (any(x <- pair, x in classes[s])) {
					classes[s] += {pair[0], pair[1]};
					break;
				} else {
					classes += [{pair[0], pair[1]}];
					break;
				}
			}
		}
	}
	
	println(size(classes));
	for (cloneclass c <- classes) {
		println(c);
		println();
	}
}


// This function compares all sequences ina bucket and pairs duplicates.
list[clonepair] pairSequences(sequences seqs) {
	list[clonepair] clonePairs = [];
	
	for (s1 <- [0..size(seqs)]) {
		for (s2 <- [s1+1..size(seqs)]) {
			if (s1 == s2) continue;
			
			if (seqs[s1][0] == seqs[s2][0]) {
				// We found a duplicate pair.
				clonePairs += <seqs[s1][1], seqs[s2][1]>;
			}
		}
	}
	
	return clonePairs;
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
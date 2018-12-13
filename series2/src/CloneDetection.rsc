module CloneDetection

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
import Type;

alias sequence = tuple[list[node], list[loc]];
alias sequences = list[sequence];
alias clonepair = tuple[list[loc], list[loc]];
alias clonepairs = list[clonepair];
alias cloneclass = set[list[loc]];
alias cloneclasses = list[cloneclass];
alias classloc = list[set[list[loc]]];

// |project://smallsql0.21_src/src|
// |project://temp/src|
public void testing(loc project) {
	datetime startTime = now();
	set[Declaration] ast = createAstsFromEclipseProject(project, false);
	map[int, map[int, sequences]] buckets = ();
	
	/* Here we get all subsequences from the AST tree and put them in buckets of the size of the sequence */
	println("Getting subsequences");
	visit(ast) {
		case list[Statement] n: {
			sequences subseqs = subsequencesFromStmts(n);
			for (sequence s <- subseqs) {
				int seqsize = size(s[0]);
				int seqmass = sum([nodeMass(i) | i <- s[0]]);
				if (!buckets[seqsize]?) {
					buckets[seqsize] = ();
				}
				if (buckets[seqsize][seqmass]?) {
					buckets[seqsize][seqmass] += s;
				} else {
					buckets[seqsize][seqmass] = [s];
				}
			}
		}
		case list[Declaration] n: {
			sequences subseqs = subsequencesFromDecls(n);
			for (sequence s <- subseqs) {
				int seqsize = size(s[0]);
				int seqmass = sum([nodeMass(i) | i <- s[0]]);
				if (!buckets[seqsize]?) {
					buckets[seqsize] = ();
				}
				if (buckets[seqsize][seqmass]?) {
					buckets[seqsize][seqmass] += s;
				} else {
					buckets[seqsize][seqmass] = [s];
				}
			}
		}
	}
	
	//clonepairs pairs = pairSequences(buckets[1]);
	
	set[int] bucketKeys = domain(buckets);
	println(bucketKeys);
	cloneclasses classes = [];
	println("making clone pairs");
	map[loc, set[int]] dups = (); // This keeps track of which lines in a file are duplicate.
	
	/* Now we need to make clone pairs of all subsequences in all buckets */
	clonepairs pairs = [];
	for (int k <- sort(toList(bucketKeys))) {
		for (int l <- buckets[k]) {
			if (size(buckets[k][l]) <= 1) continue;
			//println("(<k>, <l>) - <size(buckets[k][l])>");
			pairs += pairSequences(buckets[k][l]);
		}
	}
	
	// We have all clone pairs. Now we sequence all those pairs until we get the biggest possible sequence.
	println("Sequencing clone pairs");
	list[clonepair] checkedPairs = [];

	while(true) {
		clonepair pair = pairs[0];
		if (pair in checkedPairs) {
			break;
		}
		
		bool single = (size(pair[0]) == 1);
		bool changed = false;
		
		// If a pair is a single statement/decl, we need to check the line before and after.
		// For pairs of a bigger size we can simple check the head and tail of other pairs.
		
		loc p0file = location(head(pair[0]));
		loc p1file = location(head(pair[1]));

		if (!dups[p0file]?) {
			dups[p0file] = {};
		}
		if (!dups[p1file]?) {
			dups[p1file] = {};
		}
		
		if (head(pair[0]).begin.line in dups[p0file]) {
			pairs = delete(pairs, 0); continue;
		}
		if (head(pair[1]).begin.line in dups[p1file]) {
			pairs = delete(pairs, 0); continue;
		}
		
		list[int] pairsToRemove = [];
		for (int j <- [1..size(pairs)]) {
			clonepair pair2 = pairs[j];
			
			if (single) {
				// pair is a single statement/decl, so we need to check the next or previous line to find a sequence.
				if (pair[0][0].path == head(pair2[0]).path && pair[1][0].path == head(pair2[1]).path && pair[0][0].end.line+1 == head(pair2[0]).begin.line && pair[1][0].end.line+1 == head(pair2[1]).begin.line) {
					pair[0] += pair2[0];
					pair[1] += pair2[1];
					pairsToRemove += j;
					changed  = true;
					single = false;
				}
				else if (pair[0][0].path == head(pair2[1]).path && pair[1][0].path == head(pair2[0]).path && pair[0][0].end.line+1 == head(pair2[1]).begin.line && pair[1][0].end.line+1 == head(pair2[0]).begin.line) {
					pair[0] += pair2[1];
					pair[1] += pair2[0];
					pairsToRemove += j;
					changed  = true;
					single = false;
				}
				else if (pair[0][0].path == head(pair2[0]).path && pair[1][0].path == head(pair2[1]).path && pair[0][0].begin.line-1 == last(pair2[0]).end.line && pair[1][0].begin.line-1 == last(pair2[1]).end.line) {
					pair[0] = pair2[0] + pair[0];
					pair[1] = pair2[1] + pair[1];
					changed = true;
					pairsToRemove += j;
					single = false;
				}
				else if (pair[0][0].path == head(pair2[1]).path && pair[1][0].path == head(pair2[0]).path && pair[0][0].begin.line-1 == last(pair2[1]).end.line && pair[1][0].begin.line-1 == last(pair2[0]).end.line) {
					pair[0] = pair2[1] + pair[0];
					pair[1] = pair2[0] + pair[1];
					changed = true;
					pairsToRemove += j;
					single = false;
				}
			}
			else if ((last(pair[0]) == head(pair2[0]) && last(pair[1]) == head(pair2[1]))) {
				// We've found 2 pairs that can be sequenced together.
				pair[0] += [last(pair2[0])];
				pair[1] += [last(pair2[1])];
				pairsToRemove += j;
				changed = true;
			}
			else if (last(pair[0]) == head(pair2[1]) && last(pair[1]) == head(pair2[0])) {
				pair[0] += [last(pair2[1])];
				pair[1] += [last(pair2[0])];
				pairsToRemove += j;
				changed = true;
			}
		}
		
		pairsToRemove = pairsToRemove;
		// Remove all used pairs that are already part of a sequence, so we dont compare them later on.
		for (int j <- [0..size(pairsToRemove)]) {
			pairs = delete(pairs, pairsToRemove[j]-j);
		}
		
		dups[location(head(pair[0]))] += toSet([head(pair[0]).begin.line..last(pair[0]).end.line+1]);
		dups[location(head(pair[1]))] += toSet([head(pair[1]).begin.line..last(pair[1]).end.line+1]);
		
		// If we sequenced 2 pairs, then we add it to the pair list for future sequencing.
		// Otherwise we increment the index by 1 to check for the other pairs.
		if (!changed) {
			checkedPairs += pair;
		}
		pairs += pair;
		pairs = delete(pairs, 0);
	}
	/*
	println("Removing encapsulated pairs.");
	int j = 0;
	while (j < size(pairs)) {
		clonepair p1 = pairs[j];
		loc p10locb = head(p1[0]);
		loc p11locb = head(p1[1]);
		loc p10loce = last(p1[0]);
		loc p11loce = last(p1[1]);
		
		list[int] pairsToRemove = [];
		for (int k <- [j+1..size(pairs)]) {
			clonepair p2 = pairs[k];
			loc p20locb = head(p2[0]);
			loc p21locb = head(p2[1]);
			loc p20loce = last(p2[0]);
			loc p21loce = last(p2[1]);
			
			if (p10locb.path == p20locb.path && p10locb.begin.line > p20locb.begin.line && p10loce.end.line < p20loce.end.line) {
				pairs = delete(pairs, j);
				j -= 1;
				break;
			}
			else if (p10locb.path == p21locb.path && p10locb.begin.line > p21locb.begin.line && p10loce.end.line < p21loce.end.line) {
				pairs = delete(pairs, j);
				j -= 1;
				break;
			}
			else if (p11locb.path == p20locb.path && p11locb.begin.line > p20locb.begin.line && p11loce.end.line < p20loce.end.line) {
				pairs = delete(pairs, j);
				j -= 1;
				break;
			}
			else if (p11locb.path == p21locb.path && p11locb.begin.line > p21locb.begin.line && p11loce.end.line < p21loce.end.line) {
				pairs = delete(pairs, j);
				j -= 1;
				break;
			}
			else if (p10locb.path == p20locb.path && p20locb.begin.line > p10locb.begin.line && p20loce.end.line < p10loce.end.line) {
				pairsToRemove += k;
			}
			else if (p10locb.path == p21locb.path && p20locb.begin.line > p11locb.begin.line && p20loce.end.line < p11loce.end.line) {
				pairsToRemove += k;
			}
			else if (p11locb.path == p20locb.path && p21locb.begin.line > p10locb.begin.line && p21loce.end.line < p10loce.end.line) {
				pairsToRemove += k;
			}
			else if (p11locb.path == p21locb.path && p21locb.begin.line > p11locb.begin.line && p21loce.end.line < p11loce.end.line) {
				pairsToRemove += k;
			}
		}
		for (int k <- [0..size(pairsToRemove)]) {
			pairs = delete(pairs, pairsToRemove[k]-k);
		}
		j += 1;
	}*/
	/*
	// Remove all pairs that are part of another pair (their lines are within the other pairs lines).
	println("Removing encapsulated pairs.");
	map[str, list[tuple[int, int]]] bounds = ();
	for (clonepair p <- pairs) {
		str path1 = head(p[0]).path;
		if (bounds[path1]?) {
			bounds[path1] += [<head(p[0]).begin.line, last(p[0]).end.line>];
		} else {
			bounds[path1] = [<head(p[0]).begin.line, last(p[0]).end.line>];
		}
		
		str path2 = head(p[1]).path;
		if (bounds[path2]?) {
			bounds[path2] += [<head(p[1]).begin.line, last(p[1]).end.line>];
		} else {
			bounds[path2] = [<head(p[1]).begin.line, last(p[1]).end.line>];
		}
	}
	
	// Now we check if their is a pair that wraps around a pair.
	list[int] pairsToRemove = [];
	for (int p <- [0..size(pairs)]) {
		str path1 = head(pairs[p][0]).path;
		if (any(x <- bounds[path1], (x[0] < head(pairs[p][0]).begin.line) && (x[1] > last(pairs[p][0]).end.line))) {
			// The pair is encapsulated by another, so we remove it.
			pairsToRemove += p;
			continue;
		}
		
		str path2 = head(pairs[p][1]).path;
		if (any(x <- bounds[path2], (x[0] < head(pairs[p][1]).begin.line) && (x[1] > last(pairs[p][1]).end.line))) {
			// The pair is encapsulated by another, so we remove it.
			pairsToRemove += p;
		}
	}
	*/
	
	
	// We have pairs with their largest consecutive sequence, so now we need to make classes of those pairs.
	println("Making clone classes");
	for (clonepair p <- pairs) {
		if (isEmpty(classes)) {
			classes += {p[0], p[1]};
			continue;
		}
		
		for (int c <- [0..size(classes)]) {
			if (any(x <- p, x in classes[c])) {
				classes[c] += {p[0]};
				classes[c] += {p[1]};
				break;
			}
			if (c == size(classes)-1) {
				classes += {p[0], p[1]};
			}
		}
	}
		
	for (cloneclass c <- classes) {
		println(c);
		println();
	}
	println(size(classes));
	
	
	tuple[map[str, value], map[str, value]] jsonFormat = betterFormat(classes); 
	//println(jsonFormat[0]);
	//println();
	//println(jsonFormat[1]);
	

	map[str, value] res = ("files":jsonFormat[0], "classes":jsonFormat[1]);
	writeJSON(|project://series2/src/firstjson.json|, res);
	

	datetime endTime = now();
	Duration dur = endTime - startTime;
	println();
	println("Duration: <dur.hours>h <dur.minutes>m <dur.seconds>s <dur.milliseconds>ms");
}


tuple[map[str, value], map[str, value]] betterFormat(list[set[list[loc]]] cloneclasses) {
	num ID = 0;
	map[str, tuple[int, int, list[map[str, value]]]] jsonFormat1 = ();
	map[str, tuple[list[tuple[str, int]], int]] jsonFormat2 = ();
	
	for (set[list[loc]] class <- cloneclasses) {
		for (list[loc] dup <- class) {
			str fileloc = location(dup[0]).path;
			if (jsonFormat1[fileloc]?) {
				jsonFormat1[fileloc][0] += last(dup).end.line - head(dup).begin.line + 1;
				map[str, value] d = ();
				d["linestart"] = head(dup).begin.line;
				d["linemass"] = last(dup).end.line - head(dup).begin.line + 1;
				d["classID"] = "<ID>";
				jsonFormat1[fileloc][2] += [d];
			}
			else {
				jsonFormat1[fileloc] = <0, 0, []>;
				jsonFormat1[fileloc][0] = last(dup).end.line - head(dup).begin.line + 1;
				jsonFormat1[fileloc][1] = size(readFileLines(location(dup[0])));
				map[str, value] d = ();
				d["linestart"] = head(dup).begin.line;
				d["linemass"] = last(dup).end.line - head(dup).begin.line + 1;
				d["classID"] = "<ID>";
				jsonFormat1[fileloc][2] = [d];
			}
			
			if (jsonFormat2["<ID>"]?) {
				jsonFormat2["<ID>"][0] += [<fileloc, size(jsonFormat1[fileloc][2])-1>];
			}
			else {
				jsonFormat2["<ID>"] = <[], 0>;
				jsonFormat2["<ID>"][0] = [<fileloc, size(jsonFormat1[fileloc][2])-1>];
				jsonFormat2["<ID>"][1] = last(dup).end.line - head(dup).begin.line + 1;
			}
		}
		ID += 1;
	}
	return <jsonFormat1, jsonFormat2>;
}





clonepairs pairSequences(sequences bucket) {
	clonepairs res = [];
	
	for (int i <- [0..size(bucket)]) {
		for (int j <- [i+1..size(bucket)]) {/*
			println(bucket[i][1]);
			println(bucket[j][1]);
			println();*/
			if (bucket[i][0] == bucket[j][0]) {
				res += <bucket[i][1], bucket[j][1]>;
			}
		}
	}
	
	return res;
}


sequences subsequencesFromStmts(list[Statement] n) {
	sequences res = [];
	
	for (int i <- [0..max(size(n)-1, 0)]) {
		//for (int j <- [i+9..size(n)]) {
		if (fileLocation(n[i]).end.line - fileLocation(n[i]).begin.line > 0) {
			res += [<[unsetRec(n[i])], [fileLocation(n[i])]>];
		} else {
			res += [<nodes, locs> | seq := slice(n, i, 2),
									nodes := [unsetRec(s) | s <- seq],
									locs := [fileLocation(s) | s <- seq]];
		}
		//}
	}
	
	return res;
}

sequences subsequencesFromDecls(list[Declaration] n) {
	sequences res = [];
	
	for (node i <- n) {
		if (fileLocation(i).end.line - fileLocation(i).begin.line <= 0) {
			continue;
		}
		res += [<[unsetRec(i)], [fileLocation(i)]>];
	}
	
	return res;
}







int nodeMass(node n) {
	int count = 0;
	visit(n) {
		case node _: count += 1;
	}
	return count;
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

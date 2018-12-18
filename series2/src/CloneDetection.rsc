module CloneDetection

import normalize;

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
public tuple[int, int] testing(loc project) {
	datetime startTime = now();
	set[Declaration] ast = createAstsFromEclipseProject(project, false);
	map[int, map[int, sequences]] buckets = ();
	//ast = normalizeAST(ast);
	
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
	map[str, set[int]] dups = (); // This keeps track of which lines in a file are duplicate.
	
	/* Now we need to make clone pairs of all subsequences in all buckets */
	clonepairs pairs = [];
	for (int k <- sort(bucketKeys)) {
		for (int l <- sort(domain(buckets[k]))) {
			if (size(buckets[k][l]) <= 1) continue;
			//println("(<k>, <l>) - <size(buckets[k][l])>");
			pairs += pairSequences(buckets[k][l]);
		}
	}
	
	// 1) Pick a file and beginline of a pair (starting with lowest beginline in the file)
	// 2) Make the largest sequence with this pair.
	// 3) Do the same for all other pairs with this file and beginline.
	// 4) Do the same for all other pairs in different files with eachother.
	
	// "f0": (0: [p1, p2, p3, p4]),
	// "f1": (5: [p2, p3, p4]),
	// "f2": (10: [p3, p4]),
	// "f3": (15: [p4])
	// 
	// 1) files to check: [<p1.path, 5>, <p2.path, 10>, <p3.path, 15>]
	// 2) When you've made all sequences you have a list of tuples. [0] = seqsize
	//		
	//
	//
	/*
	map[str, map[int, clonepairs]] pmap = ();
	for (p <- pairs) {
		if (!pmap[p[0][0].path]?) {
			pmap[p[0][0].path] = ();
		}
		if (!pmap[p[0][0].path][p[0][0].begin.line]?) {
			pmap[p[0][0].path][p[0][0].begin.line] = [p];
		} else {
			pmap[p[0][0].path][p[0][0].begin.line] += p;
		}
	}
	
	// loop through each file
	for (str f <- pmap) {
		// Loop through each beginline of a pair in a file
		for (int l <- pmap[f]) {
			if (size(pmap[f][l]) == 0) continue;
			list[tuple[str, int]] filesToCheck = [<x[1][0].path, x[1][0].begin.line> | x <- pmap[f][l]];
			
			// compare own file with the other files.
			for (clonepair p <- pmap[f][l]) {
				// make largest sequence and get sequence size and put it in list.
				clonepair res = p;
				bool ps = (size(res[0]) == 1);
				
				list[int] linesToClear = [];
				for (int line <- [x | x <- sort(domain(pmap[f])), x > p[0][-1].end.line]) {
					if ((res[0][-1].end.line + 1) < line) break;
					
					for (clonepair p2 <- pmap[f][line]) {
						if (res[1][0].path != p2[1][0].path) continue;
						
						if (size(p2[0]) == 1) {
							list[loc] l1 = res[0] + p2[0];
							list[loc] l2 = res[1] + p2[1];
							res = <l1, l2>;
						} else {
							list[loc] l1 = res[0] + p2[0][-1];
							list[loc] l2 = res[1] + p2[1][-1];
							res = <l1, l2>;
						}
						// remove pair from list, cuz we won need it anymore.
						linesToClear += l;
						break;
					}
				}
				for (int cl <- linesToClear) {
					pmap[f][cl] = [];
				}
			}
			
			// compare all other files with eachother.
			for (tuple[str, int] pf <- filesToCheck) {
				for (pmap[pf[0])
				;
			}
			
		}
	}
	
	clonepair mergeSequences(clonepair pair, map[int, clonepairs] file) {
		clonepair res = pair;
		bool ps = (size(pair[0]) == 1);
		
		for (int l <- sort(domain(file))) {
			if ((pair[0][-1].end.line + 1) < l) break;
			
			for (clonepair p2 <- file[l]) {
				if (res[1][0].path != p2[1][0].path) continue;
				
				if (size(p2[0]) == 1) {
					list[loc] l1 = res[0] + p2[0];
					list[loc] l2 = res[1] + p2[1];
					res = <l1, l2>;
				} else {
					list[loc] l1 = res[0] + p2[0][-1];
					list[loc] l2 = res[1] + p2[1][-1];
					res = <l1, l2>;
				}
				break;
			}
		}
		return res;
	}
	
	*/
	println("Prepping sequencing");
	pairs = sort(pairs, bool(clonepair a, clonepair b) { return (a[0][0].path < b[0][0].path) || (a[0][0].path == b[0][0].path && (a[0][0].begin.line < b[0][0].begin.line) || a[1][0].path < b[1][0].path); });
	map[str, list[tuple[clonepair, int]]] r = ();
	for (int j <- [0..size(pairs)]) {
		if (!r[pairs[j][0][0].path]?) {
			r[pairs[j][0][0].path] = [];
		}
		r[pairs[j][0][0].path] += <pairs[j], j>;
		//print("<((j+1)*100)/size(pairs)>%\r");
	}
	println();
	
	for (str k <- r) {
		r[k] = sort(r[k], bool(tuple[clonepair, int] a, tuple[clonepair, int] b) { return a[0][0][0].begin.line < b[0][0][0].begin.line || (a[0][0][0].begin.line == b[0][0][0].begin.line && a[0][1][0].path < b[0][1][0].path); });
	}
	
	int remPairs = 0;
	println("Sequencing clone pairs");
	int pairSize = size(pairs);
	int total = pairSize;
	int i=0;
	for (str k <- sort(domain(r))) {
		int y = 0;
		while (y < size(r[k])) {
			clonepair pair = r[k][y][0];
			
			str p0f = pair[0][0].path;
			str p1f = pair[1][0].path;
			if (!dups[p0f]?) {
				dups[p0f] = {};
			}
			if (!dups[p1f]?) {
				dups[p1f] = {};
			}
			if ((pair[0][0].begin.line in dups[p0f] && pair[0][-1].end.line in dups[p0f]) && (pair[1][0].begin.line in dups[p1f] && pair[1][-1].end.line in dups[p1f])) {
				//pairs = delete(pairs, i);
				r[k] = delete(r[k], y);
				remPairs += 1;
				total -= 1;
				continue;
			}
			
			bool single = size(pair[0]) == 1;
			
			int t = 0;
			while (true) {
				bool pairChanged = false;
				list[int] removePairs = [];
				for (int j <- [y+1..size(r[p0f])]) {
					clonepair pair2 = r[p0f][j][0];
					if (pair[0][0].path != pair2[0][0].path) continue;
					
					int p2s = size(pair2[0]);
					bool single2 = p2s == 1;
					
					if (single && single2 && pair[0][-1].end.line + 1 == pair2[0][0].begin.line && pair[1][-1].end.line + 1 == pair2[1][0].begin.line) {
						// c + d
						pair[0] = pair[0] + pair2[0];
						pair[1] = pair[1] + pair2[1];
						removePairs += j;
						pairChanged = true;
						single = false;
					}
					else if (single && single2 && pair[0][0].begin.line - 1 == pair2[0][-1].end.line && pair[1][0].begin.line - 1 == pair2[1][-1].end.line) {
						// c + b
						pair[0] = pair2[0] + pair[0];
						pair[1] = pair2[1] + pair[1];
						removePairs += j;
						pairChanged = true;
						single = false;
					}
					else if (single && pair[0][0].end.line + 1 == pair2[0][0].begin.line && pair[1][0].end.line + 1 == pair2[1][0].begin.line) {
						// c + de
						pair[0] = pair[0] + pair2[0];
						pair[1] = pair[1] + pair2[1];
						removePairs += j;
						pairChanged = true;
						single = false;
					}
					else if (single && pair[0][0].begin.line - 1 == pair2[0][-1].end.line && pair[1][0].begin.line - 1 == pair2[1][-1].end.line) {
						// c + ab
						pair[0] = pair2[0] + pair[0];
						pair[1] = pair2[1] + pair[1];
						removePairs += j;
						pairChanged = true;
						single = false;
					}
					else if (single2 && pair[0][-1].end.line + 1 == pair2[0][0].begin.line && pair[1][-1].end.line + 1 == pair2[1][0].begin.line) {
						// cd + e
						pair[0] = pair[0] + pair2[0];
						pair[1] = pair[1] + pair2[1];
						removePairs += j;
						pairChanged = true;
					}
					else if (single2 && pair[0][0].begin.line - 1 == pair2[0][-1].end.line && pair[1][0].begin.line - 1 == pair2[1][-1].end.line) {
						// cd + b
						pair[0] = pair2[0] + pair[0];
						pair[1] = pair2[1] + pair[1];
						removePairs += j;
						pairChanged = true;
					}
					else if (pair[0][-1] == pair2[0][0] && pair[1][-1] == pair2[1][0]) {
						// cd + de
						pair[0] = pair[0] + slice(pair2[0], 1, p2s-1);
						pair[1] = pair[1] + slice(pair2[1], 1, p2s-1);
						removePairs += j;
						pairChanged = true;
					}
					else if (pair[0][0] == pair2[0][-1] && pair[1][0] == pair2[1][-1]) {
						// cd + bc
						pair[0] = slice(pair2[0], 0, p2s-1)  + pair[0];
						pair[1] = slice(pair2[1], 0, p2s-1) + pair[1];
						removePairs += j;
						pairChanged = true;
					}
				}
				
				// remove all pairs you just added to the sequence, because you wont need them later on.
				removePairs = sort(removePairs);
				for (int j <- [0..size(removePairs)]) {
					//pairs = delete(pairs, r[p0f][removePairs[j]-j][1]-remPairs);
					r[p0f] = delete(r[p0f], removePairs[j]-j);
					remPairs += 1;
					total -= 1;
				}
				t += 1;
				
				// Check if the pair has changed, if not then we are done sequencing it.
				if (!pairChanged) {
					break;
				}
			}
			
			
			// If this pair is not part of the class of another (bigger), then we remove the parts that are the same as the other,
			int s = 0;
			int e = size(pair[0]);
			bool found = false;
			clonepair newpair = <[], []>;
			for (int l <- [0..size(pair[0])]) {
				if (found && (pair[0][l].begin.line in dups[p0f] || pair[0][l].end.line in dups[p0f]) || (pair[1][l].begin.line in dups[p1f] || pair[1][l].end.line in dups[p1f])) {
					break;
				}
				if ((pair[0][l].begin.line notin dups[p0f] && pair[0][l].end.line notin dups[p0f]) || (pair[1][l].begin.line notin dups[p1f] && pair[1][l].end.line notin dups[p1f])) {
					newpair[0] = newpair[0] + pair[0][l];
					newpair[1] = newpair[1] + pair[1][l];
					found = true;
				}
			}
			pair[0] = newpair[0];
			pair[1] = newpair[1];
			if (size(pair[0]) == 0) {
				//pairs = delete(pairs, i);
				r[k] = delete(r[k], y);
				//println("del");
				total -= 1;
				remPairs += 1;
				continue;
			}
			
			
			// Add the lines of the pair sequence to the dups set, so we wont make sequences of other pairs that overlap this.
			dups[p0f] += toSet([pair[0][0].begin.line..(pair[0][-1].end.line + 1)]);
			dups[p1f] += toSet([pair[1][0].begin.line..(pair[1][-1].end.line + 1)]);
			
			// Replace pair with new sequence and increase i to get to next pair.
			r[k][y][0] = pair;
			i += 1;
			y += 1;
			print("<(i*100)/total>%\r");
		}
	}
	println();
	clonepairs new = [];
	for (str k <- r) {
		for (tuple[clonepair, int] c <- r[k]) {
			new += c[0];
		}
	}
	pairs = new;
	
	// We have pairs with their largest consecutive sequence, so now we need to make classes of those pairs.
	println("Making clone classes");
	for (clonepair p <- pairs) {
		//if (p[0][-1].end.line - p[0][0].begin.line < 2 || p[1][-1].end.line - p[1][0].begin.line < 2) continue; // Skipping pairs with less than 3 lines.
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

	int duplines = 0;
	for (cloneclass c <- classes) {
		//println(c);
		//println();
		for (list[loc] l <- c) {
			duplines += (l[-1].end.line - l[0].begin.line + 1);
		}
	}
	println(pairSize);
	println(size(classes));
	println(duplines);
	
	
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
	
	return <size(classes), duplines>;
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
				list[loc] l1 = bucket[i][1];
				list[loc] l2 = bucket[j][1];
				
				if (bucket[i][1][0].path > bucket[j][1][0].path || (bucket[i][1][0].path == bucket[j][1][0].path && bucket[i][1][0].begin.line > bucket[j][1][0].begin.line)) {
					l1 = bucket[j][1];
					l2 = bucket[i][1];
				}
				res += <l1, l2>;
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

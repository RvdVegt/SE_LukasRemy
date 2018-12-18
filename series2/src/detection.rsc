module detection

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
public void testing(loc project, bool type2) {
	datetime startTime = now();
	set[Declaration] ast = createAstsFromEclipseProject(project, false);
	map[int, map[int, sequences]] buckets = ();
	
	/* Here we get all subsequences from the AST tree and put them in buckets of the size of the sequence
	 * The sequences can be of 1 or 2 statements/declarations. It is 1 of those whenever the node consists of more than 1 line.
	 */
	println("Getting subsequences");
	visit(ast) {
		case list[Statement] n: {
			sequences subseqs;
			if (type2) subseqs = subsequencesFromStmtsType2(n);
			else subseqs = subsequencesFromStmts(n);
			
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
			sequences subseqs;
			if (type2) subseqs = subsequencesFromDeclsType2(n);
			else subseqs = subsequencesFromDecls(n);
			
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
	
	set[int] bucketKeys = domain(buckets);
	cloneclasses classes = [];
	println("Making clone pairs:");
	map[str, set[int]] dups = (); // This keeps track of which lines in a file are duplicate.
	int totBuckets = sum([size(buckets[x]) | x <- bucketKeys]);
	
	/* Now we need to make clone pairs of all subsequences in all buckets */
	clonepairs pairs = [];
	int b = 0;
	for (int k <- sort(bucketKeys)) {
		for (int l <- sort(domain(buckets[k]))) {
			if (size(buckets[k][l]) <= 1) { b += 1; print("<(b*100)/totBuckets>%\r"); continue; }
			pairs += pairSequences(buckets[k][l]);
			b += 1;
			print("<(b*100)/totBuckets>%\r");
		}
	}
	println();
	
	int pairSize = size(pairs);
	println("Making clone classes:");
	int i = 0;
	while (i < size(pairs)) {
		clonepair p = pairs[i];
		if (!dups[p[0][0].path]?) {
			dups[p[0][0].path] = {};
		}
		if (!dups[p[1][0].path]?) {
			dups[p[1][0].path] = {};
		}
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
				break;
			}
		}
		i += 1;
		print("<(i*100)/pairSize>%\r");
	}
	println();
	
	/* Sequencing clone classes */
	println("Sequencing clone classes:");
	list[list[list[loc]]] newclasses = [];
	for (cloneclass cl <- classes) {
		newclasses += [sort(toList(cl), bool(list[loc] a, list[loc] b) { return (a[0].begin.line < b[0].begin.line) || (a[0].begin.line == b[0].begin.line && a[0].path < b[0].path); })];
	}
	
	// Sort classes by their line size (biggest first)
	newclasses = sort(newclasses, bool(list[list[loc]] a, list[list[loc]] b) {return (a[0][0].begin.line < b[0][0].begin.line) || (a[0][0].begin.line == b[0][0].begin.line && a[0][0].path < b[0][0].path);});
	list[list[list[loc]]] newnewclasses = [];

	int c = 0;
	while (c < size(newclasses)) {
		bool remc1 = false;
		list[list[loc]] class = newclasses[c];
		int c2 = c+1;
				
		for (int p <- [0..size(class)]) {
			if (class[p][0].begin.line in dups[class[p][0].path] || class[p][-1].end.line in dups[class[p][0].path]) {
				remc1 = true;
				break;
			}
		}
		
		if (remc1) {
			newclasses = delete(newclasses, c);
			continue;
		}

		if (c < size(newclasses)-1) {
			while (c2 < size(newclasses)) {
				bool remc2 = false;
				list[list[loc]] class2 = newclasses[c2];
				
				if (size(newclasses[c]) != size(class2)) {
					c2 += 1;
					continue;
				}
				
				list[list[loc]] newclass = [];
				
				for (int p <- [0..size(class2)]) {
					if (class2[p][0].begin.line in dups[class2[p][0].path] || class2[p][-1].end.line in dups[class2[p][0].path]) {
						remc2 = true;
						break;
					}
				}
			
				if (remc2) {
					newclasses = delete(newclasses, c2);
					continue;
				}
				
				for (int p <- [0..size(newclasses[c])]) {
					list[loc] s = class[p];
					
					for (int p2 <- [0..size(newclasses[c2])]) {
						list[loc] s2 = class2[p2];
						
						if (s[-1] == s2[0]) {
							// These sequences can be merged in a new class (s + s2[1:])
							newclass = newclass + [s + slice(s2, 1, size(s2)-1)];
							break;
						}
						else if (s[0] == s2[-1]) {
							// s2 + s[1:]
							newclass = newclass + [s2 + slice(s, 1, size(s)-1)];
							break;
						}
						else if (s[0].path == s2[0].path && s[0].begin.line-1 == s2[-1].end.line) {
							newclass = newclass + [s2 + slice(s, 1, size(s)-1)];
							break;
						}
						else if (s[0].path == s2[0].path && s2[0].begin.line-1 == s[-1].end.line) {
							newclass = newclass + [s + slice(s2, 1, size(s2)-1)];
							break;
						}
					}
				}
				
				if (size(newclass) == size(class)) {
					
					newclasses = delete(newclasses, c2);
					newclasses[c] = newclass;
					class = newclass;
					continue;
				}
				c2 += 1;
			}
		}
		
		for (int p <- [0..size(newclasses[c])]) {
			dups[newclasses[c][p][0].path] += toSet([newclasses[c][p][0].begin.line..newclasses[c][p][-1].end.line+1]);
		}
		newnewclasses = newnewclasses + [class];
		c += 1;
		print("<((c+1)*100)/size(newclasses)>%\r");
	}
	println();
	//println(newclasses);
	int duplines = 0;
	for (list[list[loc]] cl <- newnewclasses) {
		//println(c);
		//println();
		for (list[loc] l <- cl) {
			duplines += (l[-1].end.line - l[0].begin.line + 1);
		}
	}
	
	set[loc] files = visibleFiles(project);
	int total = 0;
	
	for (loc n <- files) {
		total += size(readFileLines(n));
	}
	
	println("Classes: <size(newnewclasses)>");
	println("Duplicate lines: <duplines> (<(duplines*100)/total>%)");
	
	
	tuple[map[str, value], map[str, value]] jsonFormat = betterFormat(newclasses); 
	//println(jsonFormat[0]);
	//println();
	//println(jsonFormat[1]);
	

	map[str, value] res = ("totlines":total, "duplines":duplines, "dupperc":(duplines*100)/total, "totclasses":size(newnewclasses), "files":jsonFormat[0], "classes":jsonFormat[1]);
	writeJSON(|project://series2/src/firstjson.json|, res);
	

	datetime endTime = now();
	Duration dur = endTime - startTime;
	println();
	println("Duration: <dur.hours>h <dur.minutes>m <dur.seconds>s <dur.milliseconds>ms");
}


tuple[map[str, value], map[str, value]] betterFormat(list[list[list[loc]]] cloneclasses) {
	num ID = 0;
	map[str, tuple[int, int, list[map[str, value]]]] jsonFormat1 = ();
	map[str, tuple[list[tuple[str, int]], int]] jsonFormat2 = ();
	
	for (list[list[loc]] class <- cloneclasses) {
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

sequences subsequencesFromStmtsType2(list[Statement] n) {
	sequences res = [];
	
	for (int i <- [0..max(size(n)-1, 0)]) {
		//for (int j <- [i+9..size(n)]) {
		if (fileLocation(n[i]).end.line - fileLocation(n[i]).begin.line > 0) {
			res += [<[normalizeNode(unsetRec(n[i]))], [fileLocation(n[i])]>];
		} else {
			res += [<nodes, locs> | seq := slice(n, i, 2),
									nodes := [normalizeNode(unsetRec(s)) | s <- seq],
									locs := [fileLocation(s) | s <- seq]];
		}
		//}
	}
	
	return res;
}

sequences subsequencesFromDeclsType2(list[Declaration] n) {
	sequences res = [];
	
	for (node i <- n) {
		if (fileLocation(i).end.line - fileLocation(i).begin.line <= 0) {
			continue;
		}
		res += [<[normalizeNode(unsetRec(i))], [fileLocation(i)]>];
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

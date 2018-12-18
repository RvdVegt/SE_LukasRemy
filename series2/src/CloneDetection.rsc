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
	println("making clone classes");
	/* Now we need to make clone pairs and classes of all subsequences in all buckets */
	for (int k <- buckets) {
		for (int l <- buckets[k]) {
			if (size(buckets[k][l]) <= 1) continue;
			println("(<k>, <l>) - <size(buckets[k][l])>");
			clonepairs pairs = pairSequences(buckets[k][l]);
			for (clonepair pair <- pairs) {
				if (isEmpty(classes)) {
					classes += {pair[0], pair[1]};
					continue;
				}
				
				for (int c <- [0..size(classes)]) {
					if (any(x <- pair, x in classes[c])) {
						classes[c] += {pair[0]};
						classes[c] += {pair[1]};
						break;
					}
					if (c == size(classes)-1) {
						classes += {pair[0], pair[1]};
					}
				}
			}
		}
	}
	
	println(size(classes));
	

	datetime endTime = now();
	Duration dur = endTime - startTime;
	println();
	println("Duration: <dur.hours>h <dur.minutes>m <dur.seconds>s <dur.milliseconds>ms");
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
	
	for (int i <- [0..max(size(n)-5, 0)]) {
		for (int j <- [i+5..size(n)]) {
			res += [<nodes, locs> | seq := slice(n, i, j-i+1),
									nodes := [unsetRec(s) | s <- seq],
									locs := [fileLocation(s) | s <- seq]];
		}
	}
	
	return res;
}

sequences subsequencesFromDecls(list[Declaration] n) {
	sequences res = [];
	
	for (node i <- n) {
		if (nodeMass(i) <= 4) {
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

module duplication

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::FileSystem;
import List;
import Set;
import String;
import util::Math;

import LOC;

public tuple[list[tuple[list[str] lines, list[int] indices]] blocks, int lines] DUPCreateBlocks(M3 model, int blockSize) {
	set[loc] methods = methods(model);
	list[tuple[list[str] lines, list[int] indices]] blocks = [];
	int total = 0;
	int counter = 0;
	
	// Give every line a index
	// Whenever block is duplicate, add all lines in block.
	// The same line that get seen multiple times as duplicate will only be counted as 1, instead for every block.
	
	for (loc m <- methods) {
		list[str] lines = [trim(line) | line <- cleanCode(readFileLines(m))];
		if (size(lines) > blockSize) {
			tuple[list[str] lines, list[int] indices] indexLines = <lines, [counter-1..counter+size(lines)-1]>;
			for (int i <- upTill(size(lines) - blockSize)) {
				blocks = blocks + [<slice(indexLines.lines, i+1, blockSize), slice(indexLines.indices, i+1, blockSize)>];
			}
			counter += size(lines)-1;
		}
		total += size(lines);
	}
	return <blocks, total>;
}

public void DUPTest(M3 model, int blockSize) {
	set[loc] methods = methods(model);
	list[list[str]] blocks = [];
	for (loc m <- methods) {
		list[str] lines = [trim(line) | line <- cleanCode(readFileLines(m))];
		if (size(lines) > blockSize) {
			for (int i <- upTill(size(lines) - blockSize)) {
				blocks = blocks + [slice(lines, i+1, blockSize)];
			}
		}
	}
	
	int first = size(blocks);
	int second = size(toSet(blocks));
	println("<first> - <second>");
	println((toReal(first-second)/first)*100);
}

public real DUPPercentage(tuple[list[tuple[list[str] lines, list[int] indices]] blocks, int lines] dups) {
	mapBlock = toMap(dups.blocks);
	set[int] dupLines = {};
	for (b <- mapBlock) {
		if (size(mapBlock[b]) > 1) {
			for (i <- mapBlock[b]) {
				dupLines = dupLines + toSet(i);
			}
		}
	}
	return (toReal(size(dupLines))/dups.lines)*100;
}
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

public tuple[list[tuple[list[str], list[int]]], int] DUPCreateBlocks(loc project, int blockSize) {
	// Give every line an index
	// Whenever a block is a duplicate, add all lines from that block to the duplicate lines list.
	// The same line that gets seen multiple times as duplicate will only be counted once, instead for every block (because of sets).
	set[loc] files = visibleFiles(project);
	
	list[tuple[list[str] lines, list[int] indices]] blocks = [];
	int total = 0;
	int counter = 0;
	
	for (loc f <- files) {
		list[str] lines = [trim(line) | line <- cleanCode(readFileLines(f))]; // trim every line in the file
		
		if (size(lines) >= blockSize) {
			tuple[list[str] lines, list[int] indices] indexLines = <lines, [counter..counter+size(lines)]>;
			for (int i <- upTill(size(lines) - blockSize)) {
				blocks = blocks + [<slice(indexLines.lines, i, blockSize), slice(indexLines.indices, i, blockSize)>];
			}
			counter += size(lines);
		}
		total += size(lines);
	}
	return <blocks, total>;
}

public void DUPTest(loc project, int blockSize) {
	// We do not use this method
	// This method compares the amount of found duplicate blocks with the total amount of blocks,
	// instead of looking at which lines are duplicate.
	
	M3 model = createM3FromEclipseProject(project);
	
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
	return (toReal(size(dupLines)) / dups.lines) * 100;
}
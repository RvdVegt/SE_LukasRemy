module duplication

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::FileSystem;
import List;
import Set;
import String;

import LOC;

public tuple[list[list[str]] blocks, int lines] DUPCreateBlocks(M3 model, int blockSize) {
	set[loc] methods = methods(model);
	list[list[str]] blocks = [];
	int total = 0;
	
	for (loc m <- methods) {
		list[str] lines = [trim(line) | line <- cleanCode(readFileLines(m))];
		if (size(lines) > 6) {
			for (int i <- upTill(size(lines) - blockSize - 1)) {
				blocks = blocks + [slice(lines, i+1, blockSize)];
			}
		}
		total += size(lines);
	}
	return <blocks, total>;
}

public void DUPDivideBlocks(list[str] lines, int blockSize) {
	
}


public void DUPLines() {
	M3 model = createM3FromEclipseProject(|project://temp/src|);
	tuple[list[list[str]] blocks, int lines] dups = DUPCreateBlocks(model, 6);
	for (list[str] i <- dups.blocks) {
		println(i);
		println();
	}
	blockMap = toMap(zip(dups.blocks, index(dups.blocks)));
	for (b <- blockMap) {
		println(b);
	}
}
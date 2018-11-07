module unitSize

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::FileSystem;
import List;
import Set;
import String;

import \test;

public void temp() {
	loc project = |project://temp/src|;
	myModel = createM3FromEclipseProject(project);
	set[loc] methods = methods(myModel);
	
	for (loc f <- methods) {
		list[str] lines = readFileLines(f);
		newLines = cleanCode(lines);
		
	}
}
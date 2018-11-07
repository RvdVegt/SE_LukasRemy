module unitSize

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::FileSystem;
import List;
import Set;
import String;

public void temp() {
	loc project = |project://smallsql0.21_src|;
	myModel = createM3FromEclipseProject(project);
	methods = methods(myModel);
}
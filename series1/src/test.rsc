module \test

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

public void temp() {
	myModel = createM3FromEclipseProject(|project://smallsql0.21_src|);
	println(myModel);
}
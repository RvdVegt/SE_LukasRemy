module unitComplexity

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

//loc project = |project://temp/src|;
public list[int] calcCCproject(loc project) {
	ast = createAstsFromEclipseProject(project, false);
	result = [];
	
	visit(ast) {
		case \method(_,_,_,_, statement): result = result + [calcCCmethod(statement)];
	}
	
	return result;
}

public int calcCCmethod(Statement method) {
	cc = 1;
	
	//The statements that add to the complexity are:
	//https://pmd.github.io/latest/pmd_java_metrics_index.html#cyclomatic-complexity-cyclo
	visit(method) {
		case \if(_,_): cc += 1;
		case \if(_,_,_): cc += 1;
		case \case(_): cc += 1;
		case \catch(_,_): cc += 1;
		case \throw(_): cc += 1;
		case \do(_,_): cc += 1;
		case \while(_,_): cc += 1;
		case \foreach(_,_,_): cc += 1;
		case \for(_,_,_,_): cc += 1;
		case \for(_,_,_): cc += 1;
		case \break(): cc += 1;
		case \break(_): cc += 1;
		case \continue(): cc += 1;
		case \continue(_): cc += 1;
		case \conditional(_,_,_): cc += 1;
		case \infix(_,"&&",_): cc += 1;
		case \infix(_,"||",_): cc += 1;
	}
	
	return cc;
}

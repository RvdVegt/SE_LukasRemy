module results

import \test;
import IO;

//|project://smallsql0.21_src/src/smallsql/database|
public void testVolume(loc project) {
	int count = calcVolume(project);
	str result;
	
	if (count < 66000) {
		result = "++";
	}
	else if (count < 246000) {
		result = "+";
	}
	else if (count < 665000) {
		result = "o";
	}
	else if (count < 1310000) {
		result = "-";
	}
	else {
		result = "--";
	}
	
	println("Volume: <result>");
}
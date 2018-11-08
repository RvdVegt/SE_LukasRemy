module results

import IO;
import \test;
import unitComplexity;

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

public void testComplexity(loc project) {
	list[int] cc = calcCCproject(project);
	risk = ccRisk(cc);
}

private list[int] ccRisk(list[int] cc) {
	risk = [0,0,0,0];
	
	for (x <- cc) {
		if (x < 11) {
			risk[0] += 1;
		}
		else if (x < 21) {
			risk[1] += 1;
		}
		else if (x < 51) {
			risk[2] += 1;
		}
		else {
			risk[3] += 1;
		}
	}
	return risk;
}
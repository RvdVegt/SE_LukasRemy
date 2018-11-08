module results

import IO;
import util::Math;

import unitSize;
import LOC;
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
	str result;
	list[tuple[int, int]] cc = calcCCproject(project);
	risk = ccRisk(cc);
	total = risk[0] + risk[1] +risk[2] +risk[3];
	
	println(risk);
	println(total);
	real simple = (toReal(risk[0]) / total) * 100;
	real moderate = (toReal(risk[1]) / total) * 100;
	real high = (toReal(risk[2]) / total) * 100;
	real veryHigh = (toReal(risk[3]) / total) * 100;
	
	if (moderate <= 25 && high == 0 && veryHigh == 0) {
		result = "++";
	}
	else if (moderate <= 30 && high <= 5 && veryHigh == 0) {
		result = "+";
	}
	else if (moderate <= 40 && high <= 10 && veryHigh == 0) {
		result = "o";
	}
	else if (moderate <= 50 && high <= 15 && veryHigh <= 5) {
		result = "-";
	}
	else {
		result = "--";
	}
	
	println("<simple>, <moderate>, <high>, <veryHigh>");
	println("Complexity: <result>");
}

private tuple[int, int, int, int] ccRisk(list[tuple[int, int]] cc) {
	risk = <0,0,0,0>;
	
	for (x <- cc) {
		if (x[0] < 11) {
			risk[0] += x[1];
		}
		else if (x[0] < 21) {
			risk[1] += x[1];
		}
		else if (x[0] < 51) {
			risk[2] += x[1];
		}
		else {
			risk[3] += x[1];
		}
	}
	return risk;
}
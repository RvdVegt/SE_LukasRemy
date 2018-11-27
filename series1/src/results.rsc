module results

import IO;
import util::Math;
import DateTime;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import unitSize;
import LOC;
import unitComplexity;
import duplication;

//|project://smallsql0.21_src/src/smallsql/database|
public tuple[int, int] testVolume(loc project) {
	int count = calcVolume(project);
	int result;
	
	if (count < 66000) result = 5;
	else if (count < 246000) result = 4;
	else if (count < 665000) result = 3;
	else if (count < 1310000) result = 2;
	else result = 1;
	
	return <result, count>;
}

public tuple[tuple[int, int, int, int], tuple[real, real, real, real], int] testUnitSize(M3 model) {
	int result;
	
	tuple[int, int, int, int] risks = USRisks(model);
	tuple[real, real, real, real] perc = USPercentages(risks);
	
	if (perc[1] <= 25 && perc[2] == 0 && perc[3] == 0) result = 5;
	else if (perc[1] <= 30 && perc[2] <= 5 && perc[3] == 0) result = 4;
	else if (perc[1] <= 40 && perc[2] <= 10 && perc[3] == 0) result = 3;
	else if (perc[1] <= 50 && perc[2] <= 15 && perc[3] <= 5) result = 2;
	else result = 1;
	
	return <risks, perc, result>;
}

public tuple[tuple[int, int, int, int], tuple[real, real, real ,real], int] testComplexity(loc project) {
	int result;
	list[tuple[int, int]] cc = calcCCproject(project);
	risk = ccRisk(cc);
	total = risk[0] + risk[1] +risk[2] +risk[3];
	
	real simple = (toReal(risk[0]) / total) * 100;
	real moderate = (toReal(risk[1]) / total) * 100;
	real high = (toReal(risk[2]) / total) * 100;
	real veryHigh = (toReal(risk[3]) / total) * 100;
	
	if (moderate <= 25 && high == 0 && veryHigh == 0) {
		result = 5;
	}
	else if (moderate <= 30 && high <= 5 && veryHigh == 0) {
		result = 4;
	}
	else if (moderate <= 40 && high <= 10 && veryHigh == 0) {
		result = 3;
	}
	else if (moderate <= 50 && high <= 15 && veryHigh <= 5) {
		result = 2;
	}
	else {
		result = 1;
	}
	
	return <risk, <simple, moderate, high, veryHigh>, result>;
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

public tuple[int, real] testDuplication(loc project, int blockSize) {
	int result;

	tuple[list[tuple[list[str] lines, list[int] indices]] blocks, int lines] dups = DUPCreateBlocks(project, blockSize);
	real dupP = DUPPercentage(dups);
	
	if (dupP <= 3) result = 5;
	else if (dupP <= 5) result = 4;
	else if (dupP <= 10) result = 3;
	else if (dupP <= 20) result = 2;
	else result = 1;
	
	return <result, dupP>;
}

public int maintainability(loc project) {
	datetime startTime = now();
	M3 model = createM3FromEclipseProject(project);
	
	tuple[int, int] volume = testVolume(project);
	println("VOLUME: <intToScore(volume[0])> (<volume[1]>)");
	println();
	
	tuple[tuple[int, int, int, int], tuple[real, real, real, real], int] us = testUnitSize(model);
	tuple[int, int, int, int] usRisk = us[0];
	tuple[real, real, real, real] usPerc = us[1];
	int unitSize = us[2];
	
	println("UNITSIZE: <intToScore(unitSize)>");
	println("\t- low risk: <usRisk[0]> (<round(usPerc[0], 0.1)>%)");
	println("\t- moderate risk: <usRisk[1]> (<round(usPerc[1], 0.1)>%)");
	println("\t- high risk: <usRisk[2]> (<round(usPerc[2], 0.1)>%)");
	println("\t- very high risk: <usRisk[3]> (<round(usPerc[3], 0.1)>%)");
	println();
	
	tuple[tuple[int, int, int, int], tuple[real, real, real, real], int] cc = testComplexity(project);
	tuple[int, int, int, int] ccRisk = cc[0];
	tuple[real, real, real, real] ccPerc = cc[1];
	int complexity = cc[2];
	
	println("COMPLEXITY: <intToScore(complexity)>");
	println("\t- low risk: <ccRisk[0]> (<round(ccPerc[0], 0.1)>%)");
	println("\t- moderate risk: <ccRisk[1]> (<round(ccPerc[1], 0.1)>%)");
	println("\t- high risk: <ccRisk[2]> (<round(ccPerc[2], 0.1)>%)");
	println("\t- very high risk: <ccRisk[3]> (<round(ccPerc[3], 0.1)>%)");
	println();
	
	tuple[int, real] duplication = testDuplication(project, 6);	
	println("DUPLICATION: <intToScore(duplication[0])> (<round(duplication[1], 0.1)>%)");
	println();
	
	int analysability = analysability(volume[0], duplication[0], unitSize);
	int changeability = changeability(complexity, duplication[0]);
	int testability = testability(complexity, unitSize);
	int maintainability = round(toReal(analysability + changeability + testability) / 3);
	
	println("MAINTAINABILITY: <intToScore(maintainability)> (<maintainability>)");
	println("\t- analysability: <intToScore(analysability)> (<analysability>)");
	println("\t- changeability: <intToScore(changeability)> (<changeability>)");
	println("\t- testability: <intToScore(testability)> (<testability>)");
	
	datetime endTime = now();
	Duration dur = endTime - startTime;
	println();
	println("Duration: <dur.hours>h <dur.minutes>m <dur.seconds>s <dur.milliseconds>ms");
	
	return maintainability;
}

public int analysability(int volume, int duplication, int unitSize) {
	return round(toReal(volume + duplication + unitSize) / 3);
}

public int changeability(int complexity, int duplication) {
	return round(toReal(complexity + duplication) / 2);
}

public int testability(int complexity, int unitSize) {
	return round(toReal(complexity + unitSize) / 2);
}

public str intToScore(int score) {
	switch (score) {
		case 5: return "++";
		case 4: return "+";
		case 3: return "o";
		case 2: return "-";
		case 1: return "--";
		default: return "UNDEFINED";
	}
}

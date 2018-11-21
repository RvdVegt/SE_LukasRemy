module unitSize

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::FileSystem;
import util::Math;
import List;
import Set;
import String;

import LOC;

/*
 * Call USRisks() to get the risk profile of how many methods are in which risk category.
 * Then call USPercenages() to get the percentages of those risks compared to total no. methods.
 * Then call USRanking() to get the right ranking based on those percentages.
 */

public int USLOC(loc unit) {
	return size(cleanCode(readFileLines(unit)));
}

public tuple[int, int, int, int] USRisks(M3 model) {
	set[loc] methods = methods(model);
	tuple[int, int, int, int] risks = <0, 0, 0, 0>;
	
	for (loc f <- methods) {
		int uloc = USLOC(f);
		if (uloc <= 15) risks[0] += uloc;
		else if (uloc <= 30) risks[1] += uloc;
		else if (uloc <= 60) risks[2] += uloc;
		else risks[3] += uloc;
	}
	
	return risks;
}

public tuple[real, real, real, real] USPercentages(tuple[int, int, int, int] risks) {
	tuple[real, real, real, real] riskP = <0.0, 0.0, 0.0, 0.0>;
	int units = risks[0] + risks[1] + risks[2] + risks[3];
	
	riskP[0] = (toReal(risks[0]) / units) * 100;
	riskP[1] = (toReal(risks[1]) / units) * 100;
	riskP[2] = (toReal(risks[2]) / units) * 100;
	riskP[3] = (toReal(risks[3]) / units) * 100;
	
	return riskP;
}

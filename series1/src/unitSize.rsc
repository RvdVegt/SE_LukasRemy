module unitSize

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::FileSystem;
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


public tuple[int low, int mode, int high, int vHigh] USRisks(M3 model) {
	set[loc] methods = methods(model);
	tuple[int low, int mode, int high, int vHigh] risks;
	
	for (loc f <- methods) {
		int uloc = USLOC(f);
		if (uloc <= 15) risks.low += 1;
		else if (uloc <= 30) risks.mode += 1;
		else if (uloc <= 60) risks.high += 1;
		else risks.vHigh += 1;
	}
	
	return risks;
}

public tuple[int low, int mode, int high, int vHigh] USPercentages(tuple[int low, int mode, int high, int vHigh] risks, int units) {
	tuple[int low, int mode, int high, int vHigh] riskP;
	riskP.low = (risks.low / units) * 100;
	riskP.mode = (risks.mode / units) * 100;
	riskP.high = (risks.high / units) * 100;
	riskP.vHigh = (risks.vHigh / units) * 100;
	
	return riskP;
}

/*
 * TODO: get percentage thresholds for each rank.
 */
public str USRanking(tuple[int low, int mode, int high, int vHigh] riskP) {
	return "";
}
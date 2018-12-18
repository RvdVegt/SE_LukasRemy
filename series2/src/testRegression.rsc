module testRegression

import IO;
import detection;

//test if all testcases gave the same results the previous time this function was called
bool regression() {
	str prevResults = readFile(|project://series2/src/testResults/regression.txt|);
	tuple[bool, bool, bool, bool, bool] results = <testCase1(), testCase2(), testCase3(), testCase4(), testCase5()>;
	writeFile(|project://series2/src/testResults/regression.txt|, results);
	
	println("Regression");
	println("Old:" + prevResults);
	println("New:" + "<results>");
	
	if (prevResults == "<results>") {
		return true;
	}
	return false;
}

//test if ammount cloneclasses and duplicate line is the same as previous test with the small dataset
bool testCase1() {
	str prevResults = readFile(|project://series2/src/testResults/tc1.txt|);
	tuple[int, int] results = testing(|project://smallsql0.21_src/src|, 1);
	writeFile(|project://series2/src/testResults/tc1.txt|, results);
	
	if (prevResults == "<results>") {
		return true;
	}
	return false;
}

//test if ammount of clconeclasses is correct in our own test file, it is supposed to have 2 cloneclasses
bool testCase2() {
	tuple[int, int] results = testing(|project://temp/src/temp/car.java|, 1);
	
	if (results[0] == 2) {
		return true;
	}
	return false;
}

//test if ammount of duplines is correct in our own test file, it is supposed to have 42 duplines
bool testCase3() {
	tuple[int, int] results = testing(|project://temp/src/temp/car.java|, 1);
	
	if (results[1] == 42) {
		return true;
	}
	return false;
}

//test if we use our file twice if still get the supposed ammount of cloneclasses
bool testCase4() {
	tuple[int, int] results = testing(|project://temp/src/temp|, 1);
	
	if (results[0] == 2) {
		return true;
	}
	return false;
}

//test if we use our file twice if still get the supposed ammount of duplicate lines
bool testCase5() {
	tuple[int, int] results = testing(|project://temp/src/temp|, 1);
	
	if (results[1] == 208) {
		return true;
	}
	return false;
}
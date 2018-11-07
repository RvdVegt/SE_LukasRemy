module \test

import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::FileSystem;
import List;
import Set;
import String;


public list[str] removeMultilineComments(list[str] lines) {
	bool inComment = false;
	
	str removeLines(str code) {
		if (!inComment) {
			// We are currently not in the comment, so we are searching for '/*'.
			int startCom = findFirst(code, "/*");
			
			if (startCom == -1) {
				// No multiline comment is starting in this line, so we return the line.
				return code;
			} else {
				// We also have to look if the comment is starting in a string/quote or not;
				int startQuote = findFirst(code, "\"");
				
				if (startQuote == -1 || startQuote > startCom) {
					// there is no quote or comment starts before quote, so we can check further, knowing we are ina comment.
					inComment = true;
					return substring(code, 0, startCom) + removeLines(substring(code, startCom+2));
				} else {
					// Now we have to search whether the comment starts or ends in the quote/string or not.
					list[int] allQuotes = findAll(code, "\"");
					
					if (size(allQuotes) > 1) {
						// There is a second quote, so we can ignore everything before the first quote and until the second.
						return substring(code, 0, allQuotes[1]+1) + removeLines(substring(code, allQuotes[1] + 1));
					}
				}
			}
		} else {
			// We are currently within the comment, so we are searcing for the end of the comment.
			int endCom = findFirst(code, "*/");
			
			if (endCom == -1) {
				// There is no end of the comment here, so we can ignore the whole line;
				return " ";
			} else {
				// There is a end of comment found.
				inComment = false;
				return " " + removeLines(substring(code, endCom+2));
			}
		}
	}
	
	return [removeLines(line) | line <- lines];
}

public list[str] removeSinglelineComments(list[str] lines) {
	str removeLine(str code) {
		int com = findFirst(code, "//");
		
		if (com == -1) {
			// There is no comment in the line, so we return the whole line.
			return code;
		} else {
			if (isEmpty(trim(substring(code, 0, com)))) {
				// There is no code before the comment, so we can remove the whole line.
				return " ";
			} else {
				// Now we have to search whether the comment is in a quote/string or not.
				int startQuote = findFirst(code, "\"");
				
				if (startQuote == -1 || startQuote > com) {
					// There is no quote or it starts after the comment, so we can ignore it and just keep everything before the comment.
					return substring(code, 0, com);				
				} else {
					list[int] allQuotes = findAll(code, "\"");
					
					if (size(allQuotes) > 1) {
						// Comment is in a quote/string, so we ignore it and look further in the line.
						return substring(code, 0, allQuotes[1]+1) + removeLine(substring(code, allQuotes[1] + 1));
					}
				}
			}
		}
	}

	return [removeLine(line) | line <- lines];
}

public list[str] removeBlanks(list[str] lines) {
	return [line | line <- lines, size(trim(line)) > 0];
}

public list[str] cleanCode(list[str] lines) {
	return removeBlanks(removeSinglelineComments(removeMultilineComments(lines)));
}

public void temp() {
	//myModel = createM3FromEclipseProject(|project://smallsql0.21_src|);
	//myClasses = classes(myModel);
	loc smalldb = |project://smallsql0.21_src/src/smallsql/database|;
	loc testfile = |project://temp/src|;
	set[loc] files = visibleFiles(smalldb);
	//println(files);
	int s = size(files);
	println("#files: <s>");
	
	int total = 0;
	int oldTotal = 0;
	
	for (loc n <- files) {
		list[str] lines = readFileLines(n);
		println("<n> <size(lines)>");
		
		//list[str] newLines = [l | str l <- lines, !/((\s|\/*)(\/\*|\s\*)|[^\w,\;]\s\/*\/)|^[ \t\r\n]*$/ := l];
		//println(newLines);
		
		list[str] newLines = cleanCode(lines);
		
		//for (l <- newLines) {
		//	println(l);
		//}
		oldTotal += size(lines);
		total += size(newLines);
	}
	println("#lines: <total>");
	println("Old: <oldTotal>");
	println("Removed: <oldTotal - total>");
}
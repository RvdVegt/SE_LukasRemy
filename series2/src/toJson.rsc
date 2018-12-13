module toJson

import lang::json::IO;
import IO;

public void jsontest() {
	map[str, value] json = ();
	str result = "{\n";
	
	json["files"] = ("file 1": ("dupsize":8, "volume":104, "linesets":[("duplicate": false, "linemass":64), ("duplicate":true, "linemass":8), ("duplicate":false, "linemass":32)]));
	for (k <- json) {
		println("<k> - <json[k]>");
	}
	
	writeJSON(|project://series2/src/firstjson.json|, <5, "555", [1,2,3,4]>);
}
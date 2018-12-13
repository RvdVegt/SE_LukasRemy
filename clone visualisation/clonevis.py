from flask import Flask, render_template, url_for, json, request
from operator import itemgetter
from collections import OrderedDict
import sys
import os

global clonedata

app = Flask(__name__, static_url_path="")

@app.route("/")
@app.route("/home")
@app.route("/index")
def index():
    global clonedata
    return render_template("home.html", data=clonedata)

@app.route("/dupsort")
def dupsort():
    global clonedata
    data = {}

    revarg = request.args.get("reverse")
    if revarg == "true": reverse = True;
    else: reverse = False;

    data["files"] = OrderedDict(sorted(clonedata["files"].items(), key=lambda x: x[1][0], reverse=reverse))
    return render_template("filelist.html", data=data)

@app.route("/dupfilesort")
def dupfilesort():
    global clonedata
    data = {}

    revarg = request.args.get("reverse")
    if revarg == "true": reverse = True;
    else: reverse = False;

    data["files"] = OrderedDict(sorted(clonedata["files"].items(), key=lambda (k,v): float(v[0])/v[1], reverse=reverse))
    return render_template("filelist.html", data=data)

@app.route("/file")
def showfile():
    fileLoc = request.args.get("filepath")
    with open(fileLoc, "r") as f:
        fileSrc = f.readlines()
    for l in fileSrc:
        print(l)
    return render_template("file.html", filename=fileLoc, filesrc=fileSrc, data=clonedata)

if __name__ == "__main__":
    json_url = os.path.join(app.root_path, "static/data", "firstjson.json")
    with open(json_url) as jf:
        global clonedata
        clonedata = json.load(jf)

    app.run(debug=True, port=None, host="0.0.0.0")
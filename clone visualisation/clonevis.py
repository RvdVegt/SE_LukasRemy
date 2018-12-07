from flask import Flask, render_template, url_for, json, request
from operator import itemgetter
import sys
import os

global clonedata

app = Flask(__name__, static_url_path="")

@app.route("/")
@app.route("/home")
@app.route("/index")
def index():
    global clonedata
    return render_template("home.html")

@app.route("/dupsort")
def dupsort():
    global clonedata

    revarg = request.args.get("reverse")
    if revarg == "true": reverse = True;
    else: reverse = False;

    clonedata["files"] = sorted(clonedata["files"], key=lambda k: k["dupsize"], reverse=reverse)
    return render_template("filelist.html", data=clonedata)

@app.route("/dupfilesort")
def dupfilesort():
    global clonedata

    revarg = request.args.get("reverse")
    if revarg == "true": reverse = True;
    else: reverse = False;

    clonedata["files"] = sorted(clonedata["files"], key=lambda k: float(k["dupsize"])/k["volume"], reverse=reverse)
    return render_template("filelist.html", data=clonedata)

if __name__ == "__main__":
    json_url = os.path.join(app.root_path, "static/data", "test.json")
    with open(json_url) as jf:
        global clonedata
        clonedata = json.load(jf)

    app.run(debug=True, port=None, host="0.0.0.0")
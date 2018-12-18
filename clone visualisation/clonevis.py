from flask import Flask, render_template, url_for, json, request
from operator import itemgetter
from collections import OrderedDict
import sys
import os
import io
import matplotlib.pyplot as plt
import StringIO
import base64

global clonedata

app = Flask(__name__, static_url_path="")

@app.route("/")
@app.route("/home")
@app.route("/index")
def index():
    global clonedata
    return render_template("home.html", data=clonedata)

@app.route("/showfiles")
def showfiles():
    return render_template("filelist.html", data=clonedata)

@app.route("/showclasses")
def showclasses():
    return render_template("classlist.html", data=clonedata)

@app.route("/showorderfiles")
def showorderfiles():
    return render_template("filesorder.html")

@app.route("/showorderclasses")
def showorderclasses():
    return render_template("classesorder.html")

@app.route("/duphistogram")
def duphistogram():
    dups = [v[1] for _, v in clonedata["classes"].items() for _ in v[0]]
    print(dups)
    n, bins, patches = plt.hist(dups, bins=max(dups))
    plt.xlabel("duplciate sequence size")
    plt.ylabel("Occurences")
    plt.title("Number of occurences of duplicate sequence sizes")
    img = StringIO.StringIO()
    plt.savefig(img, format='png')
    img.seek(0)
    plot_url = base64.b64encode(img.getvalue())
    return render_template('histogram.html', data=clonedata, plot_url=plot_url)

@app.route("/classlinesort")
def classlinesort():
    global clonedata
    data = clonedata

    revarg = request.args.get("reverse")
    if revarg == "true": reverse = True;
    else: reverse = False;

    data["classes"] = OrderedDict(sorted(clonedata["classes"].items(), key=lambda x: x[1][1], reverse=reverse))
    return render_template("classlist.html", data=data)

@app.route("/classfilesort")
def classfilesort():
    global clonedata
    data = clonedata

    revarg = request.args.get("reverse")
    if revarg == "true": reverse = True;
    else: reverse = False;

    data["classes"] = OrderedDict(sorted(clonedata["classes"].items(), key=lambda x: len(x[1][0]), reverse=reverse))
    return render_template("classlist.html", data=data)

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
    lineScroll = request.args.get("linescroll")
    if lineScroll is None:
        lineScroll = 0

    activeClass = request.args.get("activeclass")
    if activeClass is None:
        activeClass = -1

    with open(fileLoc, "r") as f:
        fileSrc = f.readlines()

    fileSrc = [x.decode("utf-8") for x in fileSrc]
    return render_template("file.html", filename=fileLoc, filesrc=fileSrc, data=clonedata, linescroll=int(lineScroll), activeclass=activeClass, linestart=int(lineScroll))

@app.route("/fileclasses")
def fileclasses():
    activeClass = request.args.get("activeclass")
    fileName = request.args.get("filename")
    lineStart = int(request.args.get("linestart"))

    return render_template("fileheader.html", data=clonedata, activeclass=activeClass, filename=fileName, linestart=lineStart)

if __name__ == "__main__":
    json_url = os.path.join(app.root_path, "static/data", "firstjson.json")
    with open(json_url) as jf:
        global clonedata
        clonedata = json.load(jf)

    app.run(debug=True, port=None, host="0.0.0.0")
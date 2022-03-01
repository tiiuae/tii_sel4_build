#! /usr/bin/python

import xml.dom.minidom
import subprocess
import sys

def main():
    doc = xml.dom.minidom.parse(sys.argv[1])

    remotes = {}
    for remote in doc.getElementsByTagName("remote"):
        name = remote.getAttribute("name")
        url = remote.getAttribute("fetch")
        remotes[name] = url

    default = doc.getElementsByTagName("default")[0]
    default_remote = default.getAttribute("remote")

    for project in doc.getElementsByTagName("project"):
        name = project.getAttribute("name")
        remote = project.getAttribute("remote")
        if remote == "":
            remote = default_remote

        upstream = project.getAttribute("upstream")
        if upstream == "":
            upstream = "master"

        if '/' not in upstream:
            upstream = "refs/heads/" + upstream

        print("Checking " + name)

        cmd_out = subprocess.run(["git", "ls-remote", remotes[remote] + "/" + name, upstream], stdout = subprocess.PIPE)
        rev = cmd_out.stdout.decode("utf-8").split()[0]

        old_rev = project.getAttribute("revision")
        if old_rev != rev:
            print(name + " " + old_rev + " " + rev)
            project.setAttribute("revision", rev)

    with open(sys.argv[2], 'w') as f:
        f.write(doc.toxml())

if __name__ == "__main__":
    main()

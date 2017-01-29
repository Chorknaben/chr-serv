# -*- coding: utf-8 -*-
import fileinput
import urllib
import sys
out = []
for i in fileinput.input():
    a = urllib.unquote_plus(i)
    out.append(a)
with open(sys.argv[1], 'w') as f:
    f.writelines(out)

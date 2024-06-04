#!/usr/bin/env python

import numpy as np
import sys
import os

#-----------------------------------------
bval_path = sys.argv[1]
max_bval = sys.argv[2]
# bval_path = "/home/mszam12/main/analysis/Sub_001/analysis/dMRI/preproc/eddy/Pos.bval"
# max_bval = 2001
#-----------------------------------------
# print("bval_path: " + bval_path)
# print("max_bval: " + int(max_bval))
print(type(int(max_bval)))
# def extract_shells():

DIR = os.path.dirname(os.path.abspath(bval_path))
# print("DIR: " + DIR)

bvals = np.loadtxt(bval_path)
                    
a = np.unique(bvals)
b = np.round(a / 100) * 100
c = np.unique(b)
d = c[c < int(max_bval)]
e = d[1:]

np.savetxt(DIR + '/shells.txt', e.reshape(1, e.shape[0]), delimiter=' ', fmt='%d')

    # return d[1:]
 
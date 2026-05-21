#!/usr/bin/env python

import numpy as np
import sys
import os

bval_path = sys.argv[1]
max_bval  = int(sys.argv[2])

DIR = os.path.dirname(os.path.abspath(bval_path))

bvals = np.loadtxt(bval_path)

# Round each bval to the nearest 100 and get unique shells
rounded   = np.round(np.unique(bvals) / 100) * 100
shells    = np.unique(rounded)

# Keep only non-zero shells at or below the DTI max shell
dti_shells = shells[(shells > 0) & (shells <= max_bval)]

if len(dti_shells) == 0:
    raise ValueError("No non-zero shells found at or below DTIMaxShell={}".format(max_bval))

# Select only the highest shell (primary DTI shell), matching HCP convention
e = dti_shells[-1:]

np.savetxt(DIR + '/shells.txt', e.reshape(1, e.shape[0]), delimiter=' ', fmt='%d')

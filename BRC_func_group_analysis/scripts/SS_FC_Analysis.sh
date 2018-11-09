#!/bin/bash
# Last update: 10/10/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
set -e

# function for parsing options
getopt1()
{
  sopt="$1"
  shift 1

  for fn in $@ ; do
      if [ `echo $fn | grep -- "^${sopt}=" | wc -w` -gt 0 ] ; then
          echo $fn | sed "s/^${sopt}=//"
          # if [ ] ; then Usage ; echo " " ; echo "Error:: option ${sopt} requires an argument"; exit 1 ; end
          return 0
      fi
  done
}

# parse arguments
WD=`getopt1 "--workingdir" $@`
TS=`getopt1 "--timeseries" $@`
TR=`getopt1 "--repetitiontime" $@`
VarNorm=`getopt1 "--varnorm" $@`


${MATLABpath}/matlab -nojvm -nodesktop -r "addpath('${BRC_FMRI_GP_SCR}/FSLNets'); \
                                    addpath('${LIBSVMpath}'); \
                                    run_SS_FSL_Nets('${BRC_FMRI_GP_SCR}/FSLNets' , \
                                    '${BRC_FMRI_GP_SCR}/L1precision' , \
                                    '${BRC_FMRI_GP_SCR}/FSLNets' , \
                                    '${WD}' , \
                                    '${WD}' , \
                                    ${TR} , \
                                    ${VarNorm}); \
                                    exit"

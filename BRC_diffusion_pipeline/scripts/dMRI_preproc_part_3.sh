#!/bin/bash
# Last update: 20/05/2019

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham

set -e

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

# function for parsing options
getopt1()
{
    sopt="$1"
    shift 1

    for fn in $@ ; do
        if [ `echo $fn | grep -- "^${sopt}=" | wc -w` -gt 0 ] ; then
            echo $fn | sed "s/^${sopt}=//"
            return 0
        fi
    done
}

# parse arguments
dMRIFolder=`getopt1 "--workingdir" $@`
eddyFolder=`getopt1 "--eddyfolder" $@`
dataFolder=`getopt1 "--datafolder" $@`
CombineMatched=`getopt1 "--combinematched" $@`
Apply_Topup=`getopt1 "--applytopup" $@`
HIRES=`getopt1 "--hires" $@`
do_NODDI=`getopt1 "--donoddi" $@`
do_DKI=`getopt1 "--dodki" $@`
do_WMTI=`getopt1 "--dowmti" $@`
do_FWDTI=`getopt1 "--dofwdti" $@`
b0maxbval=`getopt1 "--b0maxbval" $@`
DTIMaxShell=`getopt1 "--dtimaxshell" $@`
skip_preproc=`getopt1 "--skip_preproc" $@`
LogFile=`getopt1 "--logfile" $@`

#=====================================================================================
###                                   DO WORK
#=====================================================================================

${BRC_DMRI_SCR}/eddy_postproc.sh \
      --workingdir=${dMRIFolder} \
      --eddyfolder=${eddyFolder} \
      --datafolder=${dataFolder} \
      --combinematched=${CombineMatched} \
      --Apply_Topup=${Apply_Topup} \
      --hires=${HIRES} \
      --donoddi=${do_NODDI} \
      --dodki=${do_DKI} \
      --dowmti=${do_WMTI} \
      --dofwdti=${do_FWDTI} \
      --b0maxbval=${b0maxbval} \
      --dtimaxshell=${DTIMaxShell} \
      --skip_preproc=${skip_preproc} \
      --logfile=${LogFile}

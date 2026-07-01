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
    local sopt="$1"
    shift 1
    local fn
    for fn in "$@" ; do
        case "$fn" in
            "${sopt}"=*) printf '%s
' "${fn#*=}"; return 0 ;;
        esac
    done
}

# parse arguments
eddyFolder=`getopt1 "--eddyfolder" $@`
topupFolder=`getopt1 "--topupfolder" $@`
Apply_Topup=`getopt1 "--applytopup" $@`
do_QC=`getopt1 "--doqc" $@`
qcFolder=`getopt1 "--qcdir" $@`
Slice2Volume=`getopt1 "--slice2vol" $@`
SliceSpec=`getopt1 "--slspec" $@`
MoveBySusceptibility=`getopt1 "--movebysuscept" $@`
HIRES=`getopt1 "--hires" $@`
skip_preproc=`getopt1 "--skip_preproc" $@`
LogFile=`getopt1 "--logfile" $@`

#=====================================================================================
###                                   DO WORK
#=====================================================================================

${BRC_DMRI_SCR}/run_eddy.sh \
      --workingdir=${eddyFolder} \
      --applytopup=${Apply_Topup} \
      --doqc=${do_QC} \
      --qcdir=${qcFolder} \
      --topupdir=${topupFolder} \
      --slice2vol=${Slice2Volume} \
      --slspec=${SliceSpec} \
      --movebysuscept=${MoveBySusceptibility} \
      --hires=${HIRES} \
      --skip_preproc=${skip_preproc} \
      --logfile=${LogFile}

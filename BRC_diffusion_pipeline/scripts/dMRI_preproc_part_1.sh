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
dMRIrawFolder=`getopt1 "--dmrirawfolder" $@`
eddyFolder=`getopt1 "--eddyfolder" $@`
topupFolder=`getopt1 "--topupfolder" $@`
InputImages=`getopt1 "--inputimage" $@`
InputImages2=`getopt1 "--inputimage2" $@`
PEdir=`getopt1 "--pedirection" $@`
Apply_Topup=`getopt1 "--applytopup" $@`
echospacing=`getopt1 "--echospacing" $@`
b0dist=`getopt1 "--b0dist" $@`
b0maxbval=`getopt1 "--b0maxbval" $@`
PIFactor=`getopt1 "--pifactor" $@`
HIRES=`getopt1 "--hires" $@`
do_NODDI=`getopt1 "--donoddi" $@`
LogFile=`getopt1 "--logfile" $@`

#=====================================================================================
###                                   DO WORK
#=====================================================================================

${BRC_DMRI_SCR}/data_copy.sh \
              --dmrirawfolder=${dMRIrawFolder} \
              --eddyfolder=${eddyFolder} \
              --inputimage=${InputImages} \
              --inputimage2=${InputImages2} \
              --pedirection=${PEdir} \
              --applytopup=${Apply_Topup} \
              --donoddi=${do_NODDI} \
              --logfile=${LogFile}

${BRC_DMRI_SCR}/basic_preproc.sh \
              --dmrirawfolder=${dMRIrawFolder} \
              --topupfolder=${topupFolder} \
              --eddyfolder=${eddyFolder} \
              --echospacing=${echospacing} \
              --pedir=${PEdir} \
              --b0dist=${b0dist} \
              --b0maxbval=${b0maxbval} \
              --pifactor=${PIFactor} \
              --applytopup=${Apply_Topup} \
              --logfile=${LogFile}

if [ ${Apply_Topup} = yes ] ; then
    ${BRC_DMRI_SCR}/run_topup.sh \
              --workingdir=${topupFolder} \
              --hires=${HIRES} \
              --logfile=${LogFile}
fi

#: <<'COMMENT'

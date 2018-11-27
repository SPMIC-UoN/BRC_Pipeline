#!/bin/bash
# Last update: 28/09/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
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
WD=`getopt1 "--workingdir" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+         START: Topup Field Map Generation and Gradient Unwarping       +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


topup_config_file=${FSLDIR}/etc/flirtsch/b02b0.cnf


${FSLDIR}/bin/topup --imain=${WD}/Pos_Neg_b0 \
                    --datain=${WD}/acqparams.txt \
                    --config=${topup_config_file} \
                    --fout=${WD}/myfield \
                    --out=${WD}/topup_Pos_Neg_b0 \
                    -v

dimt=`${FSLDIR}/bin/fslval ${WD}/Pos_b0 dim4`
dimt=$((${dimt} + 1))

log_Msg 3 "Applying topup to get a hifi b0"
${FSLDIR}/bin/fslroi ${WD}/Pos_b0 ${WD}/Pos_b01 0 1
${FSLDIR}/bin/fslroi ${WD}/Neg_b0 ${WD}/Neg_b01 0 1

${FSLDIR}/bin/applytopup --imain=${WD}/Pos_b01,${WD}/Neg_b01 \
                         --topup=${WD}/topup_Pos_Neg_b0 \
                         --datain=${WD}/acqparams.txt \
                         --inindex=1,${dimt} \
                         --out=${WD}/hifib0

${FSLDIR}/bin/imrm ${WD}/Pos_b0*
${FSLDIR}/bin/imrm ${WD}/Neg_b0*

log_Msg 3 "Running BET on the hifi b0"
${FSLDIR}/bin/bet ${WD}/hifib0 ${WD}/nodif_brain -m -f 0.2

log_Msg 3 ""
log_Msg 3 "          END: Topup Field Map Generation and Gradient Unwarping"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

#!/bin/bash
# Last update: 27/03/2019

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2019 University of Nottingham
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
WD=`getopt1 "--workingdir" $@`  # "$1"
InputfMRI=`getopt1 "--infmri" $@`  # "$1"
PhysInputTXT=`getopt1 "--physinputtxt" $@`  # "$1"
SamplingRate=`getopt1 "--samplingrate" $@`  # "$1"
SmoothCardiac=`getopt1 "--smoothcardiac" $@`  # "$1"
SmoothResp=`getopt1 "--smoothresp" $@`  # "$1"
ColResp=`getopt1 "--colresp" $@`  # "$1"
ColCardiac=`getopt1 "--colcardiac" $@`  # "$1"
ColTrigger=`getopt1 "--coltrigger" $@`  # "$1"
DO_RVT=`getopt1 "--dorvt" $@`  # "$1"
SliceOrder=`getopt1 "--sliceorder" $@`  # "$1"
SliceTimingFile=`getopt1 "--slicetimingfile" $@`  # "$1"
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                    START: Physiological Noise Removal                  +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "InputfMRI:$InputfMRI"
log_Msg 2 "PhysInputTXT:$PhysInputTXT"
log_Msg 2 "SamplingRate:$SamplingRate"
log_Msg 2 "SmoothCardiac:$SmoothCardiac"
log_Msg 2 "SmoothResp:$SmoothResp"
log_Msg 2 "ColResp:$ColResp"
log_Msg 2 "ColCardiac:$ColCardiac"
log_Msg 2 "ColTrigger:$ColTrigger"
log_Msg 2 "DO_RVT:$DO_RVT"
log_Msg 2 "SliceOrder:$SliceOrder"
log_Msg 2 "SliceTimingFile:$SliceTimingFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

mkdir -p $WD
########################################## DO WORK ##########################################

RepetitionTime=`${FSLDIR}/bin/fslval ${InputfMRI} pixdim4 | cut -d " " -f 1`

${FSLDIR}/bin/fslFixText ${PhysInputTXT} ${WD}/pnm_input.txt

PNM_arg=""
if [[ ${DO_RVT} == "yes" ]]; then
    PNM_arg="${PNM_arg} --rvt"
fi


${FSLDIR}/bin/pnm_stage1  -i ${WD}/pnm_input.txt \
                          -o ${WD}/mypnm \
                          -s ${SamplingRate} \
                          --tr=${RepetitionTime} \
                          --smoothcard=${SmoothCardiac} \
                          --smoothresp=${SmoothResp} \
                          --resp=${ColResp} \
                          --cardiac=${ColCardiac} \
                          --trigger=${ColTrigger} \
                          ${PNM_arg}


${FSLDIR}/bin/popp  -i ${WD}/pnm_input.txt \
                    -o ${WD}/mypnm \
                    -s ${SamplingRate} \
                    --tr=${RepetitionTime} \
                    --smoothcard=${SmoothCardiac} \
                    --smoothresp=${SmoothResp} \
                    --resp=${ColResp} \
                    --cardiac=${ColCardiac} \
                    --trigger=${ColTrigger} \
                    "${PNM_arg}"


PNM_arg=""
case $SliceOrder in
    0)
        PNM_arg="--slicetiming=${SliceTimingFile}"
    ;;

    1)
        PNM_arg='--slicedir=up'
    ;;

    2)
        PNM_arg='--slicedir=down'
    ;;

    3)
        PNM_arg='--slicedir=interleaved_up'
    ;;

    4)
        PNM_arg="--slicedir=interleaved_down"
    ;;

    *)
        log_Msg 3 "UNKNOWN SLICE OEDER: ${SliceOrder}"
        exit 1
esac


${FSLDIR}/bin/pnm_evs  -i ${InputfMRI} /
                       -c ${WD}/mypnm_card.txt /
                       -r ${WD}/mypnm_resp.txt /
                       -o ${WD}/mypnm /
                       --tr=${RepetitionTime} /
                       --oc=4 /
                       --or=4 /
                       --multc=2 /
                       --multr=2 /
                       --rvt=${WD}/mypnm_rvt.txt /
                       --rvtsmooth=10 /
                       "${PNM_arg}"

ls -1 `${FSLDIR}/bin/imglob -extensions *ev0*` > ${WD}/mypnm_evlist.txt


log_Msg 3 ""
log_Msg 3 "                    END: Physiological Noise Removal"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

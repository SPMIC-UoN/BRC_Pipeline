#!/bin/bash
# Last update: 08/10/2018

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

################################################## OPTION PARSING #####################################################

# parse arguments
WD=`getopt1 "--workingdir" $@`
InputfMRI=`getopt1 "--infmri" $@`
OutputfMRI=`getopt1 "--ofmri" $@`
STCMethod=`getopt1 "--stc_method" $@`
SliceTimingFile=`getopt1 "--slicetimingfile" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                  START: Slice Timing Corection                         +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "InputfMRI:$InputfMRI"
log_Msg 2 "OutputfMRI:$OutputfMRI"
log_Msg 2 "STCMethod:$STCMethod"
log_Msg 2 "SliceTimingFile:$SliceTimingFile"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

########################################## DO WORK ##########################################

RepetitionTime=`${FSLDIR}/bin/fslval ${InputfMRI} pixdim4 | cut -d " " -f 1`

NumFrames=`${FSLDIR}/bin/fslval ${InputfMRI} dim4`

mkdir -p ${WD}/prevols
mkdir -p ${WD}/postvols

case $STCMethod in
    1)
        method='interleaved'
    ;;

    2)
        method='forward'
    ;;

    3)
        method='backward'
    ;;

    4)
        Stc_args=""
    ;;

    5)
        Stc_args="--down"
    ;;

    6)
        Stc_args="--odd"
    ;;

    7)
        Stc_args="--ocustom=${SliceTimingFile}"
    ;;

    8)
        Stc_args="--tcustom=${SliceTimingFile}"
    ;;

    *)
        log_Msg 3 "UNKNOWN SLICE TIMING CORRECTION METHOD: ${STCMethod}"
        exit 1
esac

if [ "$STCMethod" -le 3 ]; then
    ${FSLDIR}/bin/fslsplit ${InputfMRI} ${WD}/prevols/vol -t

    gunzip -f ${WD}/prevols/vol*.nii.gz

    if [ $CLUSTER_MODE = "YES" ] ; then
        matlab -nojvm -nodesktop -r "addpath('${BRC_FMRI_SCR}'); run_spm_slice_time_correction('${SPMpath}' , '${WD}/prevols/vol' , 'stc_' , '${method}' , ${RepetitionTime}); exit"
    else
        ${MATLABpath}/matlab -nojvm -nodesktop -r "addpath('${BRC_FMRI_SCR}'); run_spm_slice_time_correction('${SPMpath}' , '${WD}/prevols/vol' , 'stc_' , '${method}' , ${RepetitionTime}); exit"
    fi

    ${FSLDIR}/bin/imcp ${WD}/prevols/stc_* ${WD}/postvols/

    ${FSLDIR}/bin/fslmerge -tr ${OutputfMRI} ${WD}/postvols/stc_* $RepetitionTime
else
    ${FSLDIR}/bin/slicetimer -i ${InputfMRI} -o ${OutputfMRI} -r ${RepetitionTime} --verbose $Stc_args
fi


log_Msg 3 ""
log_Msg 3 "                       END: Slice Timing Corection"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

rm -r ${WD}/postvols
rm -r ${WD}/prevols

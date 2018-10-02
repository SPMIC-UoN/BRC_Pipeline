#!/bin/bash
# Last update: 01/10/2018

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
RepetitionTime=`getopt1 "--repetitiontime" $@`

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+                                                                        +"
echo "+                  START: Slice Timing Corection                         +"
echo "+                                                                        +"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

########################################## DO WORK ##########################################

#TR_vol=`${FSLDIR}/bin/fslval ${InputfMRI} pixdim4 | cut -d " " -f 1`
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

    *)
        echo "UNKNOWN SLICE TIMING CORRECTION METHOD: ${STCMethod}"
        exit 1
esac

${FSLDIR}/bin/fslsplit ${InputfMRI} ${WD}/prevols/vol -t

gunzip ${WD}/prevols/vol*.nii.gz

${MATLABpath}/matlab -nojvm -nodesktop -r "addpath('${BRC_FMRI_SCR}'); run_spm_slice_time_correction('${SPMpath}' , '${WD}/prevols/vol' , 'stc_' , '${method}' , ${RepetitionTime}); exit"

${FSLDIR}/bin/imcp ${WD}/prevols/stc_* ${WD}/postvols/

${FSLDIR}/bin/fslmerge -tr ${OutputfMRI} ${WD}/postvols/stc_* $RepetitionTime

echo ""
echo "                       END: Slice Timing Corection"
echo "                    END: `date`"
echo "=========================================================================="
echo "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

rm -r ${WD}/postvols
rm -r ${WD}/prevols

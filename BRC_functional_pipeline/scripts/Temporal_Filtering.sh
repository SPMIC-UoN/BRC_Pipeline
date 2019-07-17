#!/bin/bash
# Last update: 09/10/2018

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
Input_fMRI=`getopt1 "--infmri" $@`
Temp_Filter_Cutoff=`getopt1 "--tempfiltercutoff" $@`
OutfMRI=`getopt1 "--outfmri" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                       START: Temporal Filtering                        +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

RepetitionTime=`${FSLDIR}/bin/fslval ${Input_fMRI} pixdim4 | cut -d " " -f 1`

${FSLDIR}/bin/fslmaths ${Input_fMRI} -Tmean ${WD}/tempMean

hp_sigma_sec=`echo "scale=6; (($Temp_Filter_Cutoff / 2.0))" | bc`
hp_sigma_vol=`echo "scale=6; (($hp_sigma_sec / $RepetitionTime))" | bc`

${FSLDIR}/bin/fslmaths ${Input_fMRI} -bptf $hp_sigma_vol -1 -add ${WD}/tempMean  ${WD}/${OutfMRI}

log_Msg 3 ""
log_Msg 3 "                         END: Temporal Filtering"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################
${FSLDIR}/bin/imrm ${WD}/tempMean

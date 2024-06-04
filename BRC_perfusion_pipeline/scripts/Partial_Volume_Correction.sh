#!/bin/bash
# Last update: 09/06/2020

# Authors: Stefan Pszczolkowski, Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2020 University of Nottingham
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
Inputasl=`getopt1 "--inputasl" $@`
NameOfaslMRI=`getopt1 "--aslname" $@`
PartialVolumeCorrection=`getopt1 "--pvcmethod" $@`
regFolder=`getopt1 "--regfolder" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                START: Partial Volume Correction                        +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "Inputasl:$Inputasl"
log_Msg 2 "NameOfaslMRI:$NameOfaslMRI"
log_Msg 2 "PartialVolumeCorrection:$PartialVolumeCorrection"
log_Msg 2 "regFolder:$regFolder"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

########################################## DO WORK ##########################################

case $PartialVolumeCorrection in

    NONE)
        ;;

    MLTS)
        log_Msg 3 "Performing Modified Partial Least Squares partial volume correction"
        # perform PVC based on published algorithm (Liang et al, DOI: 10.1002/mrm.24279)
        python ${BRC_PMRI_SCR}/mlts_partial_volume_correction.py --nifti-input ${Inputasl}.nii.gz \
                                                                 --nifti-pve-gm ${regFolder}/T1_pve_GM_${NameOfaslMRI}.nii.gz \
                                                                 --nifti-pve-wm ${regFolder}/T1_pve_WM_${NameOfaslMRI}.nii.gz \
                                                                 --nifti-output-gm ${WD}/${NameOfaslMRI}_pvc_gm.nii.gz \
                                                                 --nifti-output-wm ${WD}/${NameOfaslMRI}_pvc_wm.nii.gz
         ;;

    *)
        log_Msg 3 "UNKNOWN PARTIAL VOLUME CORRECTION METHOD: ${PartialVolumeCorrection}"
        exit 1
esac

log_Msg 3 ""
log_Msg 3 "                    END: Partial Volume Correction"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

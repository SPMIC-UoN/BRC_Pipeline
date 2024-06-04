#!/bin/bash
# Last update: 09/06/2020

# Authors: Stefan Pszczolkowski, Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
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
PVCFolder=`getopt1 "--pvcfolder" $@`
PartialVolumeCorrection=`getopt1 "--pvcmethod" $@`
Inputasl=`getopt1 "--inputasl" $@`
NameOfaslMRI=`getopt1 "--aslname" $@`
T1w2StdImage=`getopt1 "--t12std" $@`
aslMRI2strInputTransform=`getopt1 "--iwarp" $@`
aslMRI2StandardOutputTransform=`getopt1 "--outasl2stdtrans" $@`
Standard2aslMRIOutputTransform=`getopt1 "--outstd2asltrans" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                    START: Final Transformation                         +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "PVCFolder:$PVCFolder"
log_Msg 2 "PartialVolumeCorrection:$PartialVolumeCorrection"
log_Msg 2 "Inputasl:$Inputasl"
log_Msg 2 "NameOfaslMRI:$NameOfaslMRI"
log_Msg 2 "T1w2StdImage:$T1w2StdImage"
log_Msg 2 "aslMRI2strInputTransform:$aslMRI2strInputTransform"
log_Msg 2 "aslMRI2StandardOutputTransform:$aslMRI2StandardOutputTransform"
log_Msg 2 "Standard2aslMRIOutputTransform:$Standard2aslMRIOutputTransform"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

########################################## DO WORK ##########################################

STD_template=$FSLDIR/data/standard/MNI152_T1_2mm_brain

log_Msg 3 "Computing ASL to template transformation"
$FSLDIR/bin/convertwarp --ref=${STD_template} \
                        --warp1=${T1w2StdImage} \
                        --premat=${WD}/${aslMRI2strInputTransform} \
                        --out=${WD}/${aslMRI2StandardOutputTransform}

log_Msg 3 "Computing template to ASL transformation"
$FSLDIR/bin/invwarp -w ${WD}/${aslMRI2StandardOutputTransform} \
                    -o ${WD}/${Standard2aslMRIOutputTransform} \
                    -r ${Inputasl}

log_Msg 3 "Transforming ASL data into template space"
$FSLDIR/bin/applywarp -i ${Inputasl} \
                      -r ${STD_template} \
                      -w ${WD}/${aslMRI2StandardOutputTransform} \
                      -o ${PVCFolder}/${NameOfaslMRI}2std

if [ $PartialVolumeCorrection = "MLTS" ] ; then
    log_Msg 3 "Transforming partial volume corrected grey matter ASL data into template space"
    $FSLDIR/bin/applywarp -i ${PVCFolder}/${NameOfaslMRI}_pvc_gm \
                          -r ${STD_template} \
                          -w ${WD}/${aslMRI2StandardOutputTransform} \
                          -o ${PVCFolder}/${NameOfaslMRI}2std_pvc_gm

    log_Msg 3 "Transforming partial volume corrected white matter ASL data into template space"
    $FSLDIR/bin/applywarp -i ${PVCFolder}/${NameOfaslMRI}_pvc_wm \
                          -r ${STD_template} \
                          -w ${WD}/${aslMRI2StandardOutputTransform} \
                          -o ${PVCFolder}/${NameOfaslMRI}2std_pvc_wm
fi

log_Msg 3 ""
log_Msg 3 "                       END: Final Transformation"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "


################################################################################################
## Cleanup
################################################################################################
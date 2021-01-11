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

# parse arguments
preprocFolder=`getopt1 "--preprocfolder" $@`
processedFolder=`getopt1 "--processedfolder" $@`
PartialVolumeCorrection=`getopt1 "--pvcmethod" $@`
PVCFolder=`getopt1 "--pvcfolder" $@`
regFolder=`getopt1 "--regfolder" $@`
NameOfaslMRI=`getopt1 "--nameofasl" $@`
aslMRI2strTransf=`getopt1 "--asl2strtransf" $@`
Str2aslMRITransf=`getopt1 "--str2asltransf" $@`
aslMRI2StandardTransform=`getopt1 "--asl2stdtransf" $@`
Standard2aslMRITransform=`getopt1 "--std2asltransf" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                   START: Organization of the outputs                   +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "preprocFolder:$preprocFolder"
log_Msg 2 "processedFolder:$processedFolder"
log_Msg 2 "PartialVolumeCorrection:$PartialVolumeCorrection"
log_Msg 2 "PVCFolder:$PVCFolder"
log_Msg 2 "regFolder:$regFolder"
log_Msg 2 "NameOfaslMRI:$NameOfaslMRI"
log_Msg 2 "aslMRI2strTransf:$aslMRI2strTransf"
log_Msg 2 "Str2aslMRITransf:$Str2aslMRITransf"
log_Msg 2 "aslMRI2StandardTransform:$aslMRI2StandardTransform"
log_Msg 2 "Standard2aslMRITransform:$Standard2aslMRITransform"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

regPreFolderName="reg"
dataProFolderName="data"
data2stdProFolderName="data2std"

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

regPreFolder=${preprocFolder}/${regPreFolderName}
dataProFolder=${processedFolder}/${dataProFolderName}
data2stdProFolder=${processedFolder}/${data2stdProFolderName}

if [ ! -d ${regPreFolder} ]; then mkdir ${regPreFolder}; fi
if [ ! -d ${dataProFolder} ]; then mkdir ${dataProFolder}; fi
if [ ! -d ${data2stdProFolder} ]; then mkdir ${data2stdProFolder}; fi

#=====================================================================================
###                                   DO WORK
#=====================================================================================

log_Msg 3 "Organizing registration folder"
cp ${regFolder}/${aslMRI2strTransf} ${regPreFolder}/${aslMRI2strTransf}
cp ${regFolder}/${Str2aslMRITransf} ${regPreFolder}/${Str2aslMRITransf}
$FSLDIR/bin/imcp ${regFolder}/${aslMRI2StandardTransform} ${regPreFolder}/${NameOfaslMRI}2std
$FSLDIR/bin/imcp ${regFolder}/${Standard2aslMRITransform} ${regPreFolder}/std2${NameOfaslMRI}

log_Msg 3 "Organizing data folder"
processed_aslMRI_file_gm=${PVCFolder}/${NameOfaslMRI}_pvc_gm
processed_aslMRI_file_wm=${PVCFolder}/${NameOfaslMRI}_pvc_wm
processed_aslMRI2std_file_gm=${PVCFolder}/${NameOfaslMRI}2std_pvc_gm
processed_aslMRI2std_file_wm=${PVCFolder}/${NameOfaslMRI}2std_pvc_wm
processed_aslMRI2std_file=${PVCFolder}/${NameOfaslMRI}2std

$FSLDIR/bin/imcp ${processed_aslMRI2std_file} ${data2stdProFolder}/${NameOfaslMRI}2std

if [ $PartialVolumeCorrection = "MLTS" ] ; then
    $FSLDIR/bin/imcp ${processed_aslMRI_file_gm} ${dataProFolder}/${NameOfaslMRI}_pvc_gm
    $FSLDIR/bin/imcp ${processed_aslMRI_file_wm} ${dataProFolder}/${NameOfaslMRI}_pvc_wm
    $FSLDIR/bin/imcp ${processed_aslMRI2std_file_gm} ${data2stdProFolder}/${NameOfaslMRI}2std_pvc_gm
    $FSLDIR/bin/imcp ${processed_aslMRI2std_file_wm} ${data2stdProFolder}/${NameOfaslMRI}2std_pvc_wm
fi

log_Msg 3 ""
log_Msg 3 "                     END: Organization of the outputs"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "


################################################################################################
## Cleanup
################################################################################################
rm -rf ${regFolder}
rm -rf ${PVCFolder}

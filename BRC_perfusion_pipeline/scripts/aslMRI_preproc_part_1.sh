#!/bin/bash
# Last update: 12/07/2021

# Authors: Stefan Pszczolkowski, Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
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
aslMRIrawFolder=`getopt1 "--aslmrirawfolder" $@`
OrigASLName=`getopt1 "--origaslname" $@`
NameOfaslMRI=`getopt1 "--nameofaslmri" $@`
SinChanT1Folder=`getopt1 "--sinchanfolder" $@`
PartialVolumeCorrection=`getopt1 "--pvcmethod" $@`
PVCFolder=`getopt1 "--pvcfolder" $@`
dataT1Folder=`getopt1 "--datat1folder" $@`
dof=`getopt1 "--dof" $@`
superlevel=`getopt1 "--superlevel" $@`
preprocFolder=`getopt1 "--preprocfolder" $@`
processedFolder=`getopt1 "--processedfolder" $@`
aslMRI2strOutputTransform=`getopt1 "--owarp" $@`
str2aslMRIOutputTransform=`getopt1 "--oinwarp" $@`
aslMRI2StandardTransform=`getopt1 "--outasl2stdtrans" $@`
Standard2aslMRITransform=`getopt1 "--outstd2asltrans" $@`
regFolder=`getopt1 "--regfolder" $@`
regT1Folder=`getopt1 "--regt1folder" $@`
Subject=`getopt1 "--subject" $@`
Start_Time=`getopt1 "--start" $@`
logFile=`getopt1 "--logfile" $@`

log_SetPath "${logFile}"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

log_Msg 3 "ASL to T1 registration"
${BRC_PMRI_SCR}/ASL_2_T1_Registration.sh \
              --workingdir=${regFolder} \
              --inputasl=${aslMRIrawFolder}/${OrigASLName} \
			  --inputt1=${dataT1Folder}/T1_unbiased_brain \
              --aslname=${NameOfaslMRI} \
			  --wmseg=${SinChanT1Folder}/T1_WM_mask \
              --wmpve=${SinChanT1Folder}/T1_pve_WM \
              --gmpve=${SinChanT1Folder}/T1_pve_GM \
              --dof=${dof} \
              --superlevel=${superlevel} \
              --owarp=${aslMRI2strOutputTransform} \
              --oinwarp=${str2aslMRIOutputTransform} \
              --logfile=${logFile}

log_Msg 3 "Partial Volume Correction"
if [ ! $PartialVolumeCorrection = "NONE" ] ; then
    log_Msg 3 "Performing Partial Volume Correction"
    ${BRC_PMRI_SCR}/Partial_Volume_Correction.sh \
                    --workingdir=${PVCFolder} \
                    --inputasl=${aslMRIrawFolder}/${OrigASLName} \
                    --aslname=${NameOfaslMRI} \
                    --pvcmethod=${PartialVolumeCorrection} \
                    --regfolder=${regFolder} \
                    --logfile=${logFile}
else
    log_Msg 3 "NOT Performing Partial Volume Correction"
fi

log_Msg 3 "Apply the final registration"
${BRC_PMRI_SCR}/Apply_Registration.sh \
              --workingdir=${regFolder} \
              --pvcfolder=${PVCFolder} \
              --pvcmethod=${PartialVolumeCorrection} \
              --inputasl=${aslMRIrawFolder}/${OrigASLName} \
              --aslname=${NameOfaslMRI} \
              --t12std=${regT1Folder}/T1_2_std_warp_field \
              --iwarp=${aslMRI2strOutputTransform} \
              --outasl2stdtrans=${aslMRI2StandardTransform} \
              --outstd2asltrans=${Standard2aslMRITransform} \
              --logfile=${logFile}

log_Msg 3 "Organizing the outputs"
${BRC_PMRI_SCR}/Data_Organization.sh \
      --preprocfolder=${preprocFolder} \
      --processedfolder=${processedFolder} \
      --pvcmethod=${PartialVolumeCorrection} \
      --pvcfolder=${PVCFolder} \
      --regfolder=${regFolder} \
      --nameofasl=${NameOfaslMRI} \
      --asl2strtransf=${aslMRI2strOutputTransform} \
      --str2asltransf=${str2aslMRIOutputTransform} \
      --asl2stdtransf=${aslMRI2StandardTransform} \
      --std2asltransf=${Standard2aslMRITransform} \
      --logfile=${logFile}

END_Time="$(date -u +%s)"

${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Subject} \
      --type=3 \
      --logfile=${logFile}
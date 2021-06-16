#!/bin/bash
# Last update: 16/03/2021

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
set -e

source ${BRC_GLOBAL_SCR}/log.shlib  # Logging related functions

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
SienaxTempFolder=`getopt1 "--sienaxtempfolder" $@`
FastT1Folder=`getopt1 "--fastfolder" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "SienaxTempFolder:$SienaxTempFolder"
log_Msg 2 "FastT1Folder:$FastT1Folder"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

if [ -e ${SienaxTempFolder} ] ; then rm -r ${SienaxTempFolder}; fi; mkdir ${SienaxTempFolder}

${FSLDIR}/bin/bet ${WD}/T1 ${SienaxTempFolder}/T1_brain -s
${FSLDIR}/bin/imrm ${SienaxTempFolder}/T1_brain

${FSLDIR}/bin/pairreg ${FSLDIR}/data/standard/MNI152_T1_2mm_brain \
                      ${WD}/T1_brain \
                      ${FSLDIR}/data/standard/MNI152_T1_2mm_skull \
                      ${SienaxTempFolder}/T1_brain_skull \
                      ${SienaxTempFolder}/T1_to_MNI_linear.mat >> ${SienaxTempFolder}/report.sienax 2>&1

${FSLDIR}/bin/avscale ${SienaxTempFolder}/T1_to_MNI_linear.mat ${FSLDIR}/data/standard/MNI152_T1_2mm > ${SienaxTempFolder}/T1_to_MNI_linear.avscale
xscale=`grep Scales ${SienaxTempFolder}/T1_to_MNI_linear.avscale | awk '{print $4}'`
yscale=`grep Scales ${SienaxTempFolder}/T1_to_MNI_linear.avscale | awk '{print $5}'`
zscale=`grep Scales ${SienaxTempFolder}/T1_to_MNI_linear.avscale | awk '{print $6}'`
vscale=`echo "10 k $xscale $yscale * $zscale * p"|dc -`
echo "VSCALING $vscale" >> ${SienaxTempFolder}/report.sienax

${FSLDIR}/bin/flirt -in ${WD}/T1               -ref ${FSLDIR}/data/standard/MNI152_T1_1mm -o ${SienaxTempFolder}/T1_to_MNI_linear             -applyxfm -init ${SienaxTempFolder}/T1_to_MNI_linear.mat -interp spline
${FSLDIR}/bin/flirt -in ${SienaxTempFolder}/T1_brain_skull -ref ${FSLDIR}/data/standard/MNI152_T1_1mm -o ${SienaxTempFolder}/T1_brain_skull_to_MNI_linear -applyxfm -init ${SienaxTempFolder}/T1_to_MNI_linear.mat -interp trilinear

${FSLDIR}/bin/applywarp --rel --interp=trilinear --in=${FSLDIR}/data/standard/MNI152_T1_2mm_strucseg_periph --ref=${WD}/T1 -w ${WD}/reg/T1_to_MNI_nonlin_coeff_inv -o ${SienaxTempFolder}/T1_segperiph
${FSLDIR}/bin/fslmaths ${SienaxTempFolder}/T1_segperiph -thr 0.5 -bin ${SienaxTempFolder}/T1_segperiph

${FSLDIR}/bin/fslmaths ${FSLDIR}/data/standard/MNI152_T1_2mm_strucseg -thr 4.5 -bin ${SienaxTempFolder}/T1_segvent
${FSLDIR}/bin/applywarp --rel --interp=nn --in=${SienaxTempFolder}/T1_segvent --ref=${WD}/T1 -w ${WD}/reg/T1_to_MNI_nonlin_coeff_inv -o ${SienaxTempFolder}/T1_segvent

echo "tissue             volume    unnormalised-volume" >> ${SienaxTempFolder}/report.sienax

${FSLDIR}/bin/fslmaths ${FastT1Folder}/T1_brain_pve_1 -mas ${SienaxTempFolder}/T1_segperiph ${SienaxTempFolder}/T1_pve_1_segperiph -odt float
S=`${FSLDIR}/bin/fslstats ${SienaxTempFolder}/T1_pve_1_segperiph -m -v`
xa=`echo $S | awk '{print $1}'`
xb=`echo $S | awk '{print $3}'`
uxg=`echo "2 k $xa $xb * 1 / p" | dc -`
xg=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
echo "pgrey              $xg $uxg (peripheral grey)" >> ${SienaxTempFolder}/report.sienax

${FSLDIR}/bin/fslmaths ${FastT1Folder}/T1_brain_pve_0 -mas ${SienaxTempFolder}/T1_segvent ${SienaxTempFolder}/T1_pve_0_segvent -odt float
S=`${FSLDIR}/bin/fslstats ${SienaxTempFolder}/T1_pve_0_segvent -m -v`
xa=`echo $S | awk '{print $1}'`
xb=`echo $S | awk '{print $3}'`
uxg=`echo "2 k $xa $xb * 1 / p" | dc -`
xg=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
echo "vcsf               $xg $uxg (ventricular CSF)" >> ${SienaxTempFolder}/report.sienax

S=`${FSLDIR}/bin/fslstats ${FastT1Folder}/T1_brain_pve_1 -m -v`
xa=`echo $S | awk '{print $1}'`
xb=`echo $S | awk '{print $3}'`
ugrey=`echo "2 k $xa $xb * 1 / p" | dc -`
ngrey=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
echo "GREY               $ngrey $ugrey" >> ${SienaxTempFolder}/report.sienax

S=`${FSLDIR}/bin/fslstats ${FastT1Folder}/T1_brain_pve_2 -m -v`
xa=`echo $S | awk '{print $1}'`
xb=`echo $S | awk '{print $3}'`
uwhite=`echo "2 k $xa $xb * 1 / p" | dc -`
nwhite=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
echo "WHITE              $nwhite $uwhite" >> ${SienaxTempFolder}/report.sienax

ubrain=`echo "2 k $uwhite $ugrey + 1 / p" | dc -`
nbrain=`echo "2 k $nwhite $ngrey + 1 / p" | dc -`
echo "BRAIN              $nbrain $ubrain" >> ${SienaxTempFolder}/report.sienax

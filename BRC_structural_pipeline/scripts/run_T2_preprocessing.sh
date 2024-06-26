#!/bin/bash
# Last update: 02/10/2018

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
T2input=`getopt1 "--t2input" $@`
TempT1Folder=`getopt1 "--tempt1folder" $@`
FastT1Folder=`getopt1 "--fastfolder" $@`
regTempT1Folder=`getopt1 "--regtempt1folder" $@`
regTempT2Folder=`getopt1 "--regtempt2folder" $@`
do_defacing=`getopt1 "--dodefacing" $@`
RegType=`getopt1 "--regtype" $@`
do_crop=`getopt1 "--docrop" $@`
BiancaTempFolder=`getopt1 "--biancatempfolder" $@`
T2LesionPath=`getopt1 "--t2lesionpath" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                     START: T2w Image preprocessing                     +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "T2input:$T2input"
log_Msg 2 "TempT1Folder:$TempT1Folder"
log_Msg 2 "FastT1Folder:$FastT1Folder"
log_Msg 2 "regTempT1Folder:$regTempT1Folder"
log_Msg 2 "regTempT2Folder:$regTempT2Folder"
log_Msg 2 "do_defacing:$do_defacing"
log_Msg 2 "RegType:$RegType"
log_Msg 2 "do_crop:$do_crop"
log_Msg 2 "BiancaTempFolder:$BiancaTempFolder"
log_Msg 2 "T2LesionPath:$T2LesionPath"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

$FSLDIR/bin/imcp ${T2input} ${WD}/T2_orig_ud

if [ $RegType == 1 ]; then

    if [ $do_crop = "yes" ] ; then
        log_Msg 3 `date`
        log_Msg 3 "Automatically cropping the image"
        head_top=`${FSLDIR}/bin/robustfov -i ${WD}/T2_orig_ud | grep -v Final | head -n 1 | awk '{print $5}'`
        ${FSLDIR}/bin/fslmaths ${WD}/T2_orig_ud -roi 0 -1 0 -1 $head_top 170 0 1 ${WD}/T2_tmp
    else
        $FSLDIR/bin/imcp ${WD}/T2_orig_ud ${WD}/T2_tmp
    fi

    log_Msg 3 `date`
    log_Msg 3 "Run a (Recursive) brain extraction"
    ${FSLDIR}/bin/bet ${WD}/T2_tmp ${WD}/T2_tmp_brain -R -m -f 0.50

    log_Msg 3 "Take T2 to T1 and also the brain mask"
    ${FSLDIR}/bin/flirt -in ${WD}/T2_tmp_brain -ref ${TempT1Folder}/T1_brain -dof 6 -cost corratio -omat ${WD}/T2toT1_cr.mat -out ${WD}/T2toT1_cr.nii.gz
#    ${FSLDIR}/bin/flirt -in ${WD}/T2_orig_ud -ref ${TempT1Folder}/T1 -dof 6 -init ${WD}/T2toT1_cr.mat -omat ${WD}/T2_orig_ud_to_T2.mat -out ${WD}/T2
    ${FSLDIR}/bin/flirt -in ${WD}/T2_tmp_brain -ref ${TempT1Folder}/T1_brain -dof 6 -init ${WD}/T2toT1_cr.mat -omat ${WD}/T2_orig_ud_to_T2.mat -out ${WD}/T2_brain
#    ${FSLDIR}/bin/flirt -in ${WD}/T2_tmp_brain -ref ${TempT1Folder}/T1_brain -dof 6 -cost bbr -wmseg ${TempT1Folder}/FAST/T1_brain_WM_mask -schedule $FSLDIR/etc/flirtsch/bbr.sch -init ${WD}/T2toT1_cr.mat -omat ${WD}/T2_orig_ud_to_T2.mat -out ${WD}/T2_brain
    ${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/T2_tmp -r ${TempT1Folder}/T1_brain --premat=${WD}/T2_orig_ud_to_T2.mat -o ${WD}/T2
    ${FSLDIR}/bin/applywarp --rel --interp=nn -i ${WD}/T2_tmp_brain_mask -r ${TempT1Folder}/T1_brain --premat=${WD}/T2_orig_ud_to_T2.mat -o ${WD}/T2_brain_mask

    ${FSLDIR}/bin/applywarp --rel --interp=nn -i ${T2LesionPath} -r ${TempT1Folder}/T1_brain --premat=${WD}/T2_orig_ud_to_T2.mat -o ${BiancaTempFolder}/lesion_mask_2_T1

elif [ $RegType == 2 ] || [ $RegType == 3 ]; then

    log_Msg 3 `date`
    log_Msg 3 "Take T2 to T1 and also the brain mask"
    #Take T2 to T1 and also the brain mask
    ${FSLDIR}/bin/flirt -in ${WD}/T2_orig_ud -ref ${TempT1Folder}/T1_orig_ud -out ${WD}/T2_tmp -omat ${WD}/T2_tmp.mat -dof 6
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/T2_tmp2.mat -concat ${regTempT1Folder}/T1_orig_ud_to_T1.mat  ${WD}/T2_tmp.mat
    ${FSLDIR}/bin/flirt -in ${WD}/T2_orig_ud -ref ${TempT1Folder}/T1_brain -refweight ${TempT1Folder}/T1_brain_mask -nosearch -init ${WD}/T2_tmp2.mat -omat ${WD}/T2_orig_ud_to_T2.mat -dof 6
    ${FSLDIR}/bin/applywarp --rel  -i ${T2input} -r ${TempT1Folder}/T1_brain -o ${WD}/T2 --premat=${WD}/T2_orig_ud_to_T2.mat --interp=spline

    ${FSLDIR}/bin/imcp ${TempT1Folder}/T1_brain_mask.nii.gz ${WD}/T2_brain_mask.nii.gz
    ${FSLDIR}/bin/fslmaths ${WD}/T2 -mul ${WD}/T2_brain_mask ${WD}/T2_brain
fi

log_Msg 3 `date`
log_Msg 3 "Generate the linear matrix from T2 to MNI"
#Generate the linear matrix from T2 to MNI (Needed for defacing)
${FSLDIR}/bin/convert_xfm -omat ${WD}/T2_orig_ud_to_MNI_linear.mat -concat ${regTempT1Folder}/T1_to_MNI_linear.mat ${WD}/T2_orig_ud_to_T2.mat
cp ${regTempT1Folder}/T1_to_MNI_linear.mat ${WD}/T2_to_MNI_linear.mat


if [ $RegType == 1 ]; then

    ${FSLDIR}/bin/flirt -interp spline -dof 12 -in ${WD}/T2 -ref $FSLDIR/data/standard/MNI152_T1_1mm -omat ${WD}/T2_to_MNI_linear.mat -out ${WD}/T2_to_MNI_linear

    # Remove negative intensity values (from eddy) from final data
    ${FSLDIR}/bin/fslmaths ${WD}/T2_to_MNI_linear -thr 0 ${WD}/T2_to_MNI_linear

elif [ $RegType == 2 ] || [ $RegType == 3 ]; then

#    ${FSLDIR}/bin/applywarp --rel  -i ${T2input} -r $FSLDIR/data/standard/MNI152_T1_1mm -o ${WD}/T2_to_MNI_linear --premat=${WD}/T2_to_MNI_linear.mat --interp=spline
    ${FSLDIR}/bin/applywarp --rel  -i ${T2input} -r $FSLDIR/data/standard/MNI152_T1_1mm -o ${WD}/T2_to_MNI_linear --premat=${WD}/T2_orig_ud_to_MNI_linear.mat --interp=spline

fi

if [ $do_defacing = "yes" ] ; then

    log_Msg 3 `date`
    log_Msg 3 "Defacing T2"
    #Defacing T2
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/grot.mat -concat ${WD}/T2_to_MNI_linear.mat ${WD}/T2_orig_ud_to_T2.mat
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/grot.mat -concat ${BRC_GLOBAL_DIR}/templates/MNI_to_MNI_BigFoV_facemask.mat ${WD}/grot.mat
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/grot.mat -inverse ${WD}/grot.mat
    ${FSLDIR}/bin/flirt -in ${BRC_GLOBAL_DIR}/templates/MNI152_T1_1mm_BigFoV_facemask -ref ${T2input} -out ${WD}/grot -applyxfm -init ${WD}/grot.mat
    ${FSLDIR}/bin/fslmaths ${WD}/grot -binv -mul ${T2input} ${WD}/T2_orig_defaced

    cp ${WD}/T2.nii.gz ${WD}/T2_not_defaced_tmp.nii.gz
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/grot.mat -concat ${BRC_GLOBAL_DIR}/templates/MNI_to_MNI_BigFoV_facemask.mat ${WD}/T2_to_MNI_linear.mat
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/grot.mat -inverse ${WD}/grot.mat
    ${FSLDIR}/bin/flirt -in ${BRC_GLOBAL_DIR}/templates/MNI152_T1_1mm_BigFoV_facemask -ref ${WD}/T2 -out ${WD}/grot -applyxfm -init ${WD}/grot.mat
    ${FSLDIR}/bin/fslmaths ${WD}/grot -binv -mul ${WD}/T2 ${WD}/T2

    rm ${WD}/grot*
fi

#Clean and reorganize
rm ${WD}/*_tmp*
if [ -e ${regTempT2Folder} ] ; then rm -r ${regTempT2Folder}; fi; mkdir ${regTempT2Folder}
mv ${WD}/*.mat ${regTempT2Folder}
#if [ $RegType == 2 ]; then
#    mv ${WD}/*warp*.* ${regTempT2Folder}
#fi
mv ${WD}/*MNI*.* ${regTempT2Folder}


log_Msg 3 `date`
log_Msg 3 "Apply bias field correction to T2 warped"
#Apply bias field correction to T2 warped
if [ -f ${FastT1Folder}/T1_brain_bias.nii.gz ] ; then
    ${FSLDIR}/bin/fslmaths ${WD}/T2.nii.gz -div ${FastT1Folder}/T1_brain_bias.nii.gz ${WD}/T2_unbiased.nii.gz
    ${FSLDIR}/bin/fslmaths ${WD}/T2_brain.nii.gz -div ${FastT1Folder}/T1_brain_bias.nii.gz ${WD}/T2_unbiased_brain.nii.gz
else
    echo "WARNING: There was no bias field estimation. Bias field correction cannot be applied to T2."
fi

${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/T2_unbiased -r $FSLDIR/data/standard/MNI152_T1_1mm --premat=${regTempT2Folder}/T2_to_MNI_linear.mat -o ${regTempT2Folder}/T2_to_MNI_linear
${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/T2_unbiased_brain -r $FSLDIR/data/standard/MNI152_T1_1mm --premat=${regTempT2Folder}/T2_to_MNI_linear.mat -o ${regTempT2Folder}/T2_brain_to_MNI_linear

# Remove negative intensity values (from eddy) from final data
${FSLDIR}/bin/fslmaths ${regTempT2Folder}/T2_to_MNI_linear -thr 0 ${regTempT2Folder}/T2_to_MNI_linear
${FSLDIR}/bin/fslmaths ${regTempT2Folder}/T2_brain_to_MNI_linear -thr 0 ${regTempT2Folder}/T2_brain_to_MNI_linear

if [ $RegType == 2 ] || [ $RegType == 3 ]; then
    log_Msg 3 `date`
    log_Msg 3 "Generate the non-linearly warped T2 in MNI"

    #Generate the non-linearly warped T2 in MNI (Needed for post-freesurfer processing)
    ${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/T2_unbiased -r $FSLDIR/data/standard/MNI152_T1_1mm -w ${regTempT1Folder}/T1_to_MNI_nonlin_field -o ${regTempT2Folder}/T2_to_MNI
    ${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/T2_unbiased_brain -r $FSLDIR/data/standard/MNI152_T1_1mm -w ${regTempT1Folder}/T1_to_MNI_nonlin_field -o ${regTempT2Folder}/T2_brain_to_MNI

    # Remove negative intensity values (from eddy) from final data
    ${FSLDIR}/bin/fslmaths ${regTempT2Folder}/T2_to_MNI -thr 0 ${regTempT2Folder}/T2_to_MNI
    ${FSLDIR}/bin/fslmaths ${regTempT2Folder}/T2_brain_to_MNI -thr 0 ${regTempT2Folder}/T2_brain_to_MNI
fi

if [ $RegType == 2 ] || [ $RegType == 3 ]; then

    log_Msg 3  `date`
    log_Msg 3 "Run BIANCA"
    ${BRC_SCTRUC_SCR}/run_T2_bianca.sh \
                      --workingdir=${WD} \
                      --tempt1folder=${TempT1Folder} \
                      --fastfolder=${FastT1Folder} \
                      --biancatempfolder=${BiancaTempFolder} \
                      --regtempt1folder=${regTempT1Folder} \
                      --logfile=${LogFile}

fi

log_Msg 3 ""
log_Msg 3 "                       END: T2w Image preprocessing"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "


################################################################################################
## Cleanup
################################################################################################
#: <<'COMMENT'

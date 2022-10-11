#!/bin/bash
# Last update: 02/10/2018

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
T1input=`getopt1 "--t1input" $@`
dosubseg=`getopt1 "--dosubseg" $@`
dotissueseg=`getopt1 "--dotissueseg" $@`
do_crop=`getopt1 "--docrop" $@`
do_defacing=`getopt1 "--dodefacing" $@`
FastT1Folder=`getopt1 "--fastfolder" $@`
FirstT1Folder=`getopt1 "--firstfolder" $@`
SienaxTempFolder=`getopt1 "--sienaxtempfolder" $@`
regTempT1Folder=`getopt1 "--regtempt1folder" $@`
RegType=`getopt1 "--regtype" $@`
fBET=`getopt1 "--fbet" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                     START: T1w Image preprocessing                     +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "T1input:$T1input"
log_Msg 2 "dosubseg:$dosubseg"
log_Msg 2 "dotissueseg:$dotissueseg"
log_Msg 2 "do_crop:$do_crop"
log_Msg 2 "do_defacing:$do_defacing"
log_Msg 2 "FastT1Folder:$FastT1Folder"
log_Msg 2 "FirstT1Folder:$FirstT1Folder"
log_Msg 2 "SienaxTempFolder:$SienaxTempFolder"
log_Msg 2 "regTempT1Folder:$regTempT1Folder"
log_Msg 2 "RegType:$RegType"
log_Msg 2 "fBET:$fBET"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

$FSLDIR/bin/imcp ${T1input} ${WD}/T1_orig_ud

#### REORIENTATION 2 STANDARD
log_Msg 3 `date`
log_Msg 3 "Reorienting to standard orientation"
$FSLDIR/bin/fslreorient2std ${WD}/T1_orig_ud ${WD}/T1_orig_ud

if [ $do_crop = "yes" ] ; then
    log_Msg 3 `date`
    log_Msg 3 "Automatically cropping the image"
    head_top=`${FSLDIR}/bin/robustfov -i ${WD}/T1_orig_ud | grep -v Final | head -n 1 | awk '{print $5}'`
    ${FSLDIR}/bin/fslmaths ${WD}/T1_orig_ud -roi 0 -1 0 -1 $head_top 170 0 1 ${WD}/T1_tmp
else
    $FSLDIR/bin/imcp ${WD}/T1_orig_ud ${WD}/T1_tmp
fi

log_Msg 3 `date`
log_Msg 3 "Run a (Recursive) brain extraction"
${FSLDIR}/bin/bet ${WD}/T1_tmp ${WD}/T1_tmp_brain -R -m -f ${fBET}

log_Msg 3 `date`
echo "Reduces the FOV"
${FSLDIR}/bin/standard_space_roi ${WD}/T1_tmp_brain ${WD}/T1_tmp2 -maskNONE -ssref $FSLDIR/data/standard/MNI152_T1_1mm_brain -altinput ${WD}/T1_orig_ud -d

${FSLDIR}/bin/immv ${WD}/T1_tmp2 ${WD}/T1

log_Msg 3 `date`
log_Msg 3 "Registering to standard space (linear)"
#Generate the actual affine from the orig_ud volume to the cut version we have now and combine it to have an affine matrix from orig_ud to MNI
${FSLDIR}/bin/flirt  -in ${WD}/T1 -ref ${WD}/T1_orig_ud -omat ${WD}/T1_to_T1_orig_ud.mat -schedule $FSLDIR/etc/flirtsch/xyztrans.sch
${FSLDIR}/bin/convert_xfm -omat ${WD}/T1_orig_ud_to_T1.mat -inverse ${WD}/T1_to_T1_orig_ud.mat
#${FSLDIR}/bin/convert_xfm -omat ${WD}/T1_to_MNI_linear.mat -concat ${WD}/T1_tmp2_tmp_to_std.mat ${WD}/T1_to_T1_orig_ud.mat
${FSLDIR}/bin/flirt -interp spline -dof 12 -in ${WD}/T1 -ref $FSLDIR/data/standard/MNI152_T1_1mm -omat ${WD}/T1_to_MNI_linear.mat -out ${WD}/T1_tmp3

if [ $RegType == 2 ]; then

    log_Msg 3 `date`
    log_Msg 3 "Registering to standard space (non-linear)"
    #Non-linear registration to MNI using the previously calculated alignment
    ${FSLDIR}/bin/fnirt --in=${WD}/T1 \
                        --ref=$FSLDIR/data/standard/MNI152_T1_1mm \
                        --aff=${WD}/T1_to_MNI_linear.mat \
                        --config=${BRC_GLOBAL_DIR}/config/bb_fnirt.cnf \
                        --refmask=${BRC_GLOBAL_DIR}/templates/MNI152_T1_1mm_brain_mask_dil_GD7 \
                        --logout=../logs/bb_T1_to_MNI_fnirt.log \
                        --cout=${WD}/T1_to_MNI_nonlin_coeff \
                        --fout=${WD}/T1_to_MNI_nonlin_field \
                        --jout=${WD}/T1_to_MNI_nonlin_jac \
                        --iout=${WD}/T1_tmp4.nii.gz \
                        --interp=spline

#    printf "2" > ${LogFile%/*}/RegType.txt

#    log_Msg 3 `date`
#    log_Msg 3 "Combine the transformations into one and then apply it."
#    ${FSLDIR}/bin/convertwarp --ref=$FSLDIR/data/standard/MNI152_T1_1mm --premat=${WD}/T1_orig_ud_to_T1.mat --warp1=${WD}/T1_to_MNI_nonlin_field --out=${WD}/T1_orig_to_MNI_warp
#    ${FSLDIR}/bin/applywarp --rel -i ${T1input} -r $FSLDIR/data/standard/MNI152_T1_1mm -w ${WD}/T1_orig_to_MNI_warp -o ${WD}/T1_brain_to_MNI --interp=spline

elif [ $RegType == 3 ]; then

    log_Msg 3 `date`
    log_Msg 3 "Registering to standard space (non-linear)"
    ${ANTSPATH}/antsRegistrationSyN.sh -d 3 \
                                       -f ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz \
                                       -m ${WD}/T1.nii.gz \
                                       -o ${WD}/SynOut \
                                       -n 48 \
                                       -j 1

    log_Msg 3 `date`
    log_Msg 3 "Converting the transformation to FSL format"

    ${C3DPATH}/c3d_affine_tool -ref ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz \
                               -src ${WD}/T1.nii.gz \
                               -itk ${WD}/SynOut0GenericAffine.mat \
                               -ras2fsl \
                               -o ${WD}/affine_fsl.mat

    ${C3DPATH}/c3d -mcs ${WD}/SynOut1Warp.nii.gz -oo ${WD}/warp_x_tmp.nii.gz ${WD}/warp_y_tmp.nii.gz ${WD}/warp_z_tmp.nii.gz
    ${FSLDIR}/bin/fslmaths ${WD}/warp_y_tmp -mul -1 ${WD}/warp_y_tmp
    ${FSLDIR}/bin/fslmerge -t ${WD}/warp_fsl ${WD}/warp_x_tmp ${WD}/warp_y_tmp ${WD}/warp_z_tmp

    ${FSLDIR}/bin/convertwarp --rel -r ${FSLDIR}/data/standard/MNI152_T1_1mm -m ${WD}/affine_fsl.mat -w ${WD}/warp_fsl -o ${WD}/total_warp_fsl
#    ${FSLDIR}/bin/applywarp -i ${WD}/T1 -r ${FSLDIR}/data/standard/MNI152_T1_1mm -w ${WD}/total_warp_fsl -o ${WD}/T1w_warped
    ${FSLDIR}/bin/invwarp -r ${WD}/T1 -w ${WD}/total_warp_fsl -o ${WD}/T1_to_MNI_nonlin_coeff_inv

    ${FSLDIR}/bin/immv ${WD}/total_warp_fsl ${WD}/T1_to_MNI_nonlin_field
    mv ${WD}/affine_fsl.mat ${WD}/T1_to_MNI_linear.mat

#    printf "3" > ${LogFile%/*}/RegType.txt
fi

log_Msg 3 `date`
log_Msg 3 "Performing brain extraction"
if [ $RegType == 1 ]; then

    ${FSLDIR}/bin/imcp ${WD}/T1_tmp_brain_mask ${WD}/T1_brain_mask
    ${FSLDIR}/bin/flirt -interp spline -in ${WD}/T1_tmp -ref ${WD}/T1 -omat ${WD}/T1_tmp_to_T1.mat -out ${WD}/T1_tmp_to_T1
    ${FSLDIR}/bin/applywarp --rel --interp=nn -i ${WD}/T1_brain_mask -r ${WD}/T1 --premat=${WD}/T1_tmp_to_T1.mat -o ${WD}/T1_brain_mask
    ${FSLDIR}/bin/fslmaths ${WD}/T1 -mul ${WD}/T1_brain_mask ${WD}/T1_brain

elif [ $RegType == 2 ] || [ $RegType == 3 ]; then

    if [ $RegType == 2 ]; then
        ${FSLDIR}/bin/invwarp --ref=${WD}/T1 -w ${WD}/T1_to_MNI_nonlin_coeff -o ${WD}/T1_to_MNI_nonlin_coeff_inv
    fi
    ${FSLDIR}/bin/applywarp --rel --interp=trilinear --in=${BRC_GLOBAL_DIR}/templates/MNI152_T1_1mm_brain_mask --ref=${WD}/T1 -w ${WD}/T1_to_MNI_nonlin_coeff_inv -o ${WD}/T1_brain_mask
    ${FSLDIR}/bin/fslmaths ${WD}/T1 -mul ${WD}/T1_brain_mask ${WD}/T1_brain
#    ${FSLDIR}/bin/fslmaths ${WD}/T1_brain_to_MNI -mul ${BRC_GLOBAL_DIR}/templates/MNI152_T1_1mm_brain_mask ${WD}/T1_brain_to_MNI

#elif [ $RegType == 3 ]; then

#    ${ANTSPATH}/antsApplyTransforms -d 3 -n NearestNeighbor -i ${BRC_GLOBAL_DIR}/templates/MNI152_T1_1mm_brain_mask.nii.gz -r ${WD}/T1.nii.gz -o ${WD}/T1_brain_mask.nii.gz -t [${WD}/T1_to_MNI_nonlin0GenericAffine.mat,1] -t [${WD}/T1_to_MNI_nonlin_coeff_inv.nii.gz]
#    ${FSLDIR}/bin/fslmaths ${WD}/T1 -mul ${WD}/T1_brain_mask ${WD}/T1_brain

#    ${FSLDIR}/bin/applywarp --rel --interp=trilinear --in=${BRC_GLOBAL_DIR}/templates/MNI152_T1_1mm_brain_mask --ref=${WD}/T1 -w ${WD}/T1_to_MNI_nonlin_coeff_inv -o ${WD}/T1_brain_mask
#    ${FSLDIR}/bin/fslmaths ${WD}/T1 -mul ${WD}/T1_brain_mask ${WD}/T1_brain

#    ${ANTSPATH}/antsApplyTransforms -d 3 -n BSpline -i ${WD}/T1_brain.nii.gz -r ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz -o ${WD}/T1_brain_2_MNI_linear.nii.gz -t [${WD}/T1_to_MNI_nonlin0GenericAffine.mat,0]
#    ${ANTSPATH}/antsApplyTransforms -d 3 -n BSpline -i ${WD}/T1.nii.gz -r ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz -o ${WD}/T1_2_MNI_linear.nii.gz -t [${WD}/T1_to_MNI_nonlin0GenericAffine.mat,0]
#
#    ${ANTSPATH}/antsApplyTransforms -d 3 -n BSpline -i ${WD}/T1_brain.nii.gz -r ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz -o ${WD}/T1_brain_2_MNI_nonlin.nii.gz -t [${WD}/T1_to_MNI_nonlin1Warp.nii.gz] -t [${WD}/T1_to_MNI_nonlin0GenericAffine.mat,0]
#    ${ANTSPATH}/antsApplyTransforms -d 3 -n BSpline -i ${WD}/T1.nii.gz -r ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz -o ${WD}/T1_2_MNI_nonlin.nii.gz -t [${WD}/T1_to_MNI_nonlin1Warp.nii.gz] -t [${WD}/T1_to_MNI_nonlin0GenericAffine.mat,0]

fi

if [ $do_defacing = "yes" ] ; then

    log_Msg 3 `date`
    echo "Defacing T1"
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/grot.mat -concat ${WD}/T1_to_MNI_linear.mat ${WD}/T1_orig_ud_to_T1.mat
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/grot.mat -concat ${BRC_GLOBAL_DIR}/templates/MNI_to_MNI_BigFoV_facemask.mat ${WD}/grot.mat
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/grot.mat -inverse ${WD}/grot.mat
    ${FSLDIR}/bin/flirt -in ${BRC_GLOBAL_DIR}/templates/MNI152_T1_1mm_BigFoV_facemask -ref ${T1input} -out ${WD}/grot -applyxfm -init ${WD}/grot.mat
    #${FSLDIR}/bin/fslmaths grot -mul -1 -add 1 -mul T1_orig T1_orig_defaced
    ${FSLDIR}/bin/fslmaths ${WD}/grot -binv -mul ${T1input} ${WD}/T1_orig_defaced

    ${FSLDIR}/bin/imcp ${WD}/T1 ${WD}/T1_not_defaced_tmp
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/grot.mat -concat ${BRC_GLOBAL_DIR}/templates/MNI_to_MNI_BigFoV_facemask.mat ${WD}/T1_to_MNI_linear.mat
    ${FSLDIR}/bin/convert_xfm -omat ${WD}/grot.mat -inverse ${WD}/grot.mat
    ${FSLDIR}/bin/flirt -in ${BRC_GLOBAL_DIR}/templates/MNI152_T1_1mm_BigFoV_facemask -ref ${WD}/T1 -out ${WD}/grot -applyxfm -init ${WD}/grot.mat
    ${FSLDIR}/bin/fslmaths ${WD}/grot -binv -mul ${WD}/T1 ${WD}/T1

    log_Msg 3 `date`
    echo "Generation of QC value: Number of voxels in which the defacing mask goes into the brain mask"
    ${FSLDIR}/bin/fslmaths ${WD}/T1_brain_mask -thr 0.5 -bin ${WD}/grot_brain_mask
    ${FSLDIR}/bin/fslmaths ${WD}/grot -thr 0.5 -bin -add ${WD}/grot_brain_mask -thr 2 ${WD}/grot_QC
    ${FSLDIR}/bin/fslstats ${WD}/grot_QC.nii.gz -V | awk '{print $ 1}' > ${WD}/T1_QC_face_mask_inside_brain_mask.txt

    rm ${WD}/grot*
fi

#Clean and reorganize
if [ $RegType == 3 ]; then
    rm ${WD}/*_fsl*
    rm ${WD}/SynOut*
fi
rm ${WD}/*tmp*
if [ -e ${regTempT1Folder} ] ; then rm -r ${regTempT1Folder}; fi; mkdir ${regTempT1Folder}
mv ${WD}/*MNI* ${regTempT1Folder}
##mv ${WD}/*warp*.* ${regTempT1Folder}
mv ${WD}/*_to_* ${regTempT1Folder}
#mv ${regTempT1Folder}/T1_brain_to_MNI.nii.gz .

log_Msg 3  `date`
log_Msg 3 "Estimating Bias field"
if [ -e ${FastT1Folder} ] ; then rm -r ${FastT1Folder}; fi; mkdir ${FastT1Folder}

${FSLDIR}/bin/fast -b -o ${FastT1Folder}/T1_brain ${WD}/T1_brain

if [ $dotissueseg = "yes" ] ; then

    log_Msg 3 `date`
    log_Msg 3 "Performing tissue-type segmentation"
    if [ -f ${FastT1Folder}/T1_brain_pveseg.nii.gz ] ; then
        $FSLDIR/bin/fslmaths ${FastT1Folder}/T1_brain_pve_0.nii.gz -thr 0.5 -bin ${FastT1Folder}/T1_brain_CSF_mask.nii.gz
        $FSLDIR/bin/fslmaths ${FastT1Folder}/T1_brain_pve_1.nii.gz -thr 0.5 -bin ${FastT1Folder}/T1_brain_GM_mask.nii.gz
        $FSLDIR/bin/fslmaths ${FastT1Folder}/T1_brain_pve_2.nii.gz -thr 0.5 -bin ${FastT1Folder}/T1_brain_WM_mask.nii.gz
    fi
fi

log_Msg 3  `date`
log_Msg 3 "Removing Bias field"
if [ -f ${FastT1Folder}/T1_brain_bias.nii.gz ] ; then
    ${FSLDIR}/bin/fslmaths ${WD}/T1.nii.gz -div ${FastT1Folder}/T1_brain_bias.nii.gz ${WD}/T1_unbiased.nii.gz
    ${FSLDIR}/bin/fslmaths ${WD}/T1_brain.nii.gz -div ${FastT1Folder}/T1_brain_bias.nii.gz ${WD}/T1_unbiased_brain.nii.gz
else
    echo "WARNING: There was no bias field estimation. Bias field correction cannot be applied to T1."
fi

#${FSLDIR}/bin/applywarp --rel -i ${WD}/T1_unbiased -r $FSLDIR/data/standard/MNI152_T1_1mm -o ${regTempT1Folder}/T1_to_MNI_linear --premat=${regTempT1Folder}/T1_to_MNI_linear.mat --interp=spline
log_Msg 3  `date`
log_Msg 3 "Apply linear and non-linear registration"
if [ $RegType == 1 ] || [ $RegType == 2 ] ; then

    ${FSLDIR}/bin/flirt -interp spline -dof 12 -in ${WD}/T1_unbiased -ref $FSLDIR/data/standard/MNI152_T1_1mm -omat ${regTempT1Folder}/T1_to_MNI_linear.mat -out ${regTempT1Folder}/T1_to_MNI_linear
    ${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/T1_unbiased_brain -r $FSLDIR/data/standard/MNI152_T1_1mm_brain --premat=${regTempT1Folder}/T1_to_MNI_linear.mat -o ${regTempT1Folder}/T1_brain_to_MNI_linear

elif [ $RegType == 3 ]; then

#    ${ANTSPATH}/antsApplyTransforms -d 3 -n BSpline -i ${WD}/T1_unbiased.nii.gz -r ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz -o ${regTempT1Folder}/T1_to_MNI_linear.nii.gz -t [${regTempT1Folder}/T1_to_MNI_nonlin0GenericAffine.mat,0]
#    ${ANTSPATH}/antsApplyTransforms -d 3 -n BSpline -i ${WD}/T1_unbiased_brain.nii.gz -r ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz -o ${regTempT1Folder}/T1_brain_to_MNI_linear.nii.gz -t [${regTempT1Folder}/T1_to_MNI_nonlin0GenericAffine.mat,0]

    ${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/T1_unbiased -r $FSLDIR/data/standard/MNI152_T1_1mm --premat=${regTempT1Folder}/T1_to_MNI_linear.mat -o ${regTempT1Folder}/T1_to_MNI_linear
    ${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/T1_unbiased_brain -r $FSLDIR/data/standard/MNI152_T1_1mm --premat=${regTempT1Folder}/T1_to_MNI_linear.mat -o ${regTempT1Folder}/T1_brain_to_MNI_linear

fi
# Remove negative intensity values (from eddy) from final data
${FSLDIR}/bin/fslmaths ${regTempT1Folder}/T1_to_MNI_linear -thr 0 ${regTempT1Folder}/T1_to_MNI_linear
${FSLDIR}/bin/fslmaths ${regTempT1Folder}/T1_brain_to_MNI_linear -thr 0 ${regTempT1Folder}/T1_brain_to_MNI_linear

#args=""
#if [ $RegType == 2 ] ; then
#    args=" --rel"
#fi
#args=" --rel"

if [ $RegType == 2 ] || [ $RegType == 3 ] ; then

    ${FSLDIR}/bin/applywarp --rel -i ${WD}/T1_unbiased -r $FSLDIR/data/standard/MNI152_T1_1mm -o ${regTempT1Folder}/T1_to_MNI_nonlin -w ${regTempT1Folder}/T1_to_MNI_nonlin_field --interp=spline
    ${FSLDIR}/bin/applywarp --rel -i ${WD}/T1_unbiased_brain -r $FSLDIR/data/standard/MNI152_T1_1mm_brain -o ${regTempT1Folder}/T1_brain_to_MNI_nonlin -w ${regTempT1Folder}/T1_to_MNI_nonlin_field --interp=spline

    ${FSLDIR}/bin/fslmaths ${regTempT1Folder}/T1_to_MNI_nonlin -thr 0 ${regTempT1Folder}/T1_to_MNI_nonlin
    ${FSLDIR}/bin/fslmaths ${regTempT1Folder}/T1_brain_to_MNI_nonlin -thr 0 ${regTempT1Folder}/T1_brain_to_MNI_nonlin

fi

if [ $dosubseg = "yes" ] ; then

    log_Msg 3 `date`
    log_Msg 3 "Performing subcortical segmentation"

    if [ -e ${FirstT1Folder} ] ; then rm -r ${FirstT1Folder}; fi; mkdir ${FirstT1Folder}

#    echo "Creates a link inside T1_first to ./T1_unbiased_brain.nii.gz (In the present working directory)"
    $FSLDIR/bin/imcp ${WD}/T1_unbiased_brain.nii.gz ${FirstT1Folder}/T1_unbiased_brain.nii.gz
    ${FSLDIR}/bin/run_first_all -i ${FirstT1Folder}/T1_unbiased_brain -b -o ${FirstT1Folder}/T1_first
fi

if [ $RegType == 2 ] || [ $RegType == 3 ]; then

    log_Msg 3  `date`
    log_Msg 3 "Run Sienax"
    ${BRC_SCTRUC_SCR}/run_T1_sienax.sh \
                      --workingdir=${WD} \
                      --sienaxtempfolder=${SienaxTempFolder} \
                      --fastfolder=${FastT1Folder} \
                      --logfile=${LogFile}

fi

log_Msg 3 ""
log_Msg 3 "                       END: T1w Image preprocessing"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################
#if [ $RegType == 3 ]; then
#    rm ${regTempT1Folder}/T1_to_MNI_nonlin0GenericAffine.mat
#    $FSLDIR/bin/imrm ${regTempT1Folder}/T1_to_MNI_nonlinWarped.nii.gz
#    $FSLDIR/bin/imrm ${regTempT1Folder}/T1_to_MNI_nonlin1Warp.nii.gz
#    $FSLDIR/bin/imrm ${regTempT1Folder}/T1_to_MNI_nonlin1InverseWarp.nii.gz
#fi
#: <<'COMMENT'

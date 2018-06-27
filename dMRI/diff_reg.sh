#!/bin/bash
# Last update: 06/06/2018

set -e
echo -e "\n START: registration"

workingdir=$1
OutputFolder=$2

datadir=${workingdir}/processed
T1dir=${OutputFolder}/analysis/anatMRI/T1
regdir=${workingdir}/reg

echo '*****  DTI Linear registration to standard space  *****'

${FSLDIR}/bin/fslmaths ${datadir}/data -mul ${datadir}/nodif_brain_mask ${datadir}/data_brain

if [ -f ${T1dir}/seg/tissue/multi_chan/T1_mc_pve_WM.nii.gz ]; then
    ${FSLDIR}/bin/fslmaths ${T1dir}/seg/tissue/multi_chan/T1_mc_pve_WM -thr 0.5 -bin ${regdir}/lin/T1_wmseg
else
    ${FSLDIR}/bin/fslmaths ${T1dir}/seg/tissue/sing_chan/T1_pve_WM -thr 0.5 -bin ${regdir}/lin/T1_wmseg
fi

#Linear registration of DTI to T1
${FSLDIR}/bin/flirt -ref ${T1dir}/preprocess/T1_biascorr_brain -in ${datadir}/nodif_brain -dof 6 -omat ${regdir}/lin/diff2std_init.mat

${FSLDIR}/bin/flirt -in ${datadir}/nodif_brain -ref ${T1dir}/preprocess/T1_biascorr_brain -out ${regdir}/lin/diff_2_T1 -init ${regdir}/lin/diff2std_init.mat \
                                         -omat ${regdir}/lin/diff_2_T1.mat -cost bbr -bbrtype global_abs -dof 6 -wmseg ${regdir}/lin/T1_wmseg

${FSLDIR}/bin/convert_xfm -omat ${regdir}/lin/diff_2_std.mat -concat ${T1dir}/reg/lin/T1_2_std.mat ${regdir}/lin/diff_2_T1.mat

${FSLDIR}/bin/flirt -in ${datadir}/data_brain -ref $FSLDIR/data/standard/MNI152_T1_2mm_brain -out ${regdir}/lin/diff_2_stf -applyxfm -init ${regdir}/lin/diff_2_std.mat -cost bbr \
                                          -dof 6  -interp spline

$FSLDIR/bin/convert_xfm -inverse ${regdir}/lin/diff_2_T1.mat -omat ${regdir}/lin/T1_2_diff.mat
$FSLDIR/bin/convert_xfm -inverse ${regdir}/lin/diff_2_std.mat -omat ${regdir}/lin/std_2_diff.mat

echo '*****  DTI non-Linear registration to standard space  *****'

###${FSLDIR}/bin/convertwarp --ref=$FSLDIR/data/standard/MNI152_T1_2mm --premat=./dMRI/reg/FLIRT/DTI_2_T1_vol1.mat --warp1=./T1/T1.anat/T1_to_MNI_nonlin_coeff.nii.gz --out=./dMRI/reg/FNIRT/DTI_to_MNI_warp.nii.gz

${FSLDIR}/bin/applywarp --rel --in=${datadir}/data --ref=$FSLDIR/data/standard/MNI152_T1_2mm --premat=${regdir}/lin/diff_2_T1.mat --warp=${T1dir}/reg/nonlin/T1_2_std_warp_coeff \
                                          --out=${regdir}/nonlin/diff_to_std_warp --interp=spline

${FSLDIR}/bin/convertwarp --ref=$FSLDIR/data/standard/MNI152_T1_2mm --premat=${regdir}/lin/diff_2_T1.mat --warp1=${T1dir}/reg/nonlin/T1_2_std_warp_coeff \
                                          --out=${regdir}/nonlin/diff_2_std_warp_coeff --relout
#$FSLDIR/bin/invwarp --ref=${datadir}/nodif -w ${regdir}/nonlin/diff_2_std_warp_coeff -o std_to_diff_warp_coeff

${FSLDIR}/bin/applywarp --rel --interp=spline --in=$FSLDIR/data/standard/MNI152_T1_2mm --ref=${datadir}/nodif --warp=$T1_dir/reg/nonlin/std_2_T1_warp_field \
                                           --postmat=${regdir}/lin/T1_2_diff.mat --out=${regdir}/nonlin/std_2_diff_warp

#!/bin/sh
#
#   Moises Hernandez-Fernandez - FMRIB Image Analysis Group
#
#   Copyright (C) 2004 University of Oxford
#
#   SHCOPYRIGHT

Usage() {
    echo ""
    echo "Usage: NODDI_Watson_finish <subject_directory>"
    echo ""
    echo "expects to find all the estimatedParameters and nodif_brain_mask in subject directory"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage
[ "$2" = "" ] && Usage

directory=$1
Datadir=$2
cd ${directory}

mv $directory/Param_0_samples.nii.gz $directory/fiso_samples.nii.gz
mv $directory/Param_1_samples.nii.gz $directory/fintra_samples.nii.gz
mv $directory/Param_2_samples.nii.gz $directory/kappa_samples.nii.gz
mv $directory/Param_3_samples.nii.gz $directory/th_samples.nii.gz
mv $directory/Param_4_samples.nii.gz $directory/ph_samples.nii.gz

Two_div_pi=0.636619772367581

$FSLDIR/bin/fslmaths $directory/fiso_samples.nii.gz -Tmean $directory/mean_fiso
$FSLDIR/bin/fslmaths $directory/fintra_samples.nii.gz -Tmean $directory/mean_fintra
$FSLDIR/bin/fslmaths $directory/kappa_samples.nii.gz -Tmean $directory/mean_kappa
$FSLDIR/bin/make_dyadic_vectors $directory/th_samples $directory/ph_samples $directory/nodif_brain_mask.nii.gz dyads1

${FSLDIR}/bin/fslmaths $directory/mean_kappa -recip -atan -mul $Two_div_pi $directory/OD

#=====================================================================================

if [ ! -d ${Datadir}/"data.dti" ]; then mkdir ${Datadir}/"data.dti"; fi
if [ ! -d ${Datadir}/"data.noddi" ]; then mkdir ${Datadir}/"data.noddi"; fi

${FSLDIR}/bin/immv ${directory}/Dtifit/dtifit_FA ${Datadir}/"data.dti"/dti_FA
${FSLDIR}/bin/immv ${directory}/Dtifit/dtifit_L1 ${Datadir}/"data.dti"/dti_L1
${FSLDIR}/bin/immv ${directory}/Dtifit/dtifit_L2 ${Datadir}/"data.dti"/dti_L2
${FSLDIR}/bin/immv ${directory}/Dtifit/dtifit_L3 ${Datadir}/"data.dti"/dti_L3
${FSLDIR}/bin/immv ${directory}/Dtifit/dtifit_V1 ${Datadir}/"data.dti"/dti_V1
${FSLDIR}/bin/immv ${directory}/Dtifit/dtifit_V2 ${Datadir}/"data.dti"/dti_V2
${FSLDIR}/bin/immv ${directory}/Dtifit/dtifit_V3 ${Datadir}/"data.dti"/dti_V3
${FSLDIR}/bin/immv ${directory}/Dtifit/dtifit_MD ${Datadir}/"data.dti"/dti_MD
${FSLDIR}/bin/immv ${directory}/Dtifit/dtifit_MO ${Datadir}/"data.dti"/dti_MO
${FSLDIR}/bin/immv ${directory}/Dtifit/dtifit_S0 ${Datadir}/"data.dti"/dti_S0
${FSLDIR}/bin/immv ${directory}/Dtifit/dtifit_tensor ${Datadir}/"data.dti"/dti_tensor

${FSLDIR}/bin/immv ${directory}/OD ${Datadir}/"data.noddi"/NODDI_ODI
${FSLDIR}/bin/immv ${directory}/mean_fintra ${Datadir}/"data.noddi"/NODDI_ICVF
${FSLDIR}/bin/immv ${directory}/mean_fiso ${Datadir}/"data.noddi"/NODDI_ISOVF

rm -r ${directory}

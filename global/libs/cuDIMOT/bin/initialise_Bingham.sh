#!/bin/sh
#
#   Moises Hernandez-Fernandez - FMRIB Image Analysis Group
#
#   Copyright (C) 2004 University of Oxford
#
#   SHCOPYRIGHT
#
# Script for initialise Psi angle and beta2kappa in NODDI-Bingham

Usage() {
    echo ""
    echo "Usage: initialise_Bingham <bindir> <DTI_output_dir> <mask_NIfTI_file><output_dir>"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage

bindir=$1
PathDTI=$2
mask=$3
outputdir=$4

${bindir}/initialise_Psi ${PathDTI}/dtifit_V1.nii.gz ${PathDTI}/dtifit_V2.nii.gz ${mask} ${outputdir}/initialPsi

#beta_to_kappa = 1 - (eigs(1)/eigs(2))^2;   eig(1)=L3   eig(2)=L2
#if L2 is too low-> beta_to_kappa = 0
${FSLDIR}/bin/fslmaths ${PathDTI}/dtifit_L2.nii.gz -uthr 0.0001 -bin ${outputdir}/temp1
${FSLDIR}/bin/fslmaths ${PathDTI}/dtifit_L3.nii.gz -mul ${outputdir}/temp1 ${outputdir}/temp1
${FSLDIR}/bin/fslmaths ${PathDTI}/dtifit_L2.nii.gz -thr 0.0001 -bin ${outputdir}/temp2
${FSLDIR}/bin/fslmaths ${PathDTI}/dtifit_L2.nii.gz -mul ${outputdir}/temp2 -add ${outputdir}/temp1 ${outputdir}/temp1

${FSLDIR}/bin/fslmaths ${PathDTI}/dtifit_L3.nii.gz -div ${outputdir}/temp1 -sqr ${outputdir}/beta2kappa
${FSLDIR}/bin/fslmaths ${mask} -thr 0 -sub ${outputdir}/beta2kappa ${outputdir}/beta2kappa
rm ${outputdir}/temp1.nii.gz
rm ${outputdir}/temp2.nii.gz
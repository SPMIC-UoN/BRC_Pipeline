#!/usr/bin/env bash
# Last update: 28/09/2018

# Script name: init_vars
#
# Description: Script to initalise the variables needed for the pipeline.
#
# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#

###########################################
#                                         #
#   USER MUST MODIFY THE INDICATED LINES  #
#                                         #
###########################################

export CLUSTER_MODE="YES"

if [ $CLUSTER_MODE = "YES" ] ; then
    export JOBSUBpath="/gpfs01/software/imaging/jobsub"
else
    # Setup FSL (if not already done so in the running environment)
    # Uncomment the following 2 lines (remove the leading #) and correct the FSLDIR setting for your setup
    export FSLDIR="/usr/local/fsl-6.0.5"
    . $FSLDIR/etc/fslconf/fsl.sh
    export FSLCONFDIR=${FSLDIR}/config
    export FSLOUTPUTTYPE="NIFTI_GZ"

    # Setup FreeSurfer (if not already done so in the running environment)
    # Uncomment the following 2 lines (remove the leading #) and correct the FREESURFER_HOME setting for your setup
    export FREESURFER_HOME="/usr/local/freesurfer"
    source $FREESURFER_HOME/SetUpFreeSurfer.sh

    export MATLABpath="/usr/local/matlab/R2018a/bin"
    export FSLDIR_5_0_11="/usr/local/fsl-5.0.11"

    #SET DYNAMIC LIBRARIES FOR Eddy
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64
fi

#ENV VARIABLES FOR THE BRC_PIPELINE
export BRCDIR="/gpfs01/software/imaging/BRC_Pipeline/1.6.3"                               #TO BE MODIFIED BY USER
export BRC_SCTRUC_DIR=${BRCDIR}/BRC_structural_pipeline
export BRC_DMRI_DIR=${BRCDIR}/BRC_diffusion_pipeline
export BRC_FMRI_DIR=${BRCDIR}/BRC_functional_pipeline
export BRC_PMRI_DIR=${BRCDIR}/BRC_perfusion_pipeline
export BRC_FMRI_GP_DIR=${BRCDIR}/BRC_func_group_analysis
export BRC_IDPEXTRACT_DIR=${BRCDIR}/BRC_IDP_extraction
export BRC_GLOBAL_DIR=${BRCDIR}/global
export BRC_SCTRUC_SCR=${BRC_SCTRUC_DIR}/scripts
export BRC_DMRI_SCR=${BRC_DMRI_DIR}/scripts
export BRC_FMRI_SCR=${BRC_FMRI_DIR}/scripts
export BRC_PMRI_SCR=${BRC_PMRI_DIR}/scripts
export BRC_FMRI_GP_SCR=${BRC_FMRI_GP_DIR}/scripts
export BRC_IDPEXTRACT_SCR=${BRC_IDPEXTRACT_DIR}/scripts
export BRC_GLOBAL_SCR=${BRC_GLOBAL_DIR}/scripts
export CUDIMOT="${BRC_GLOBAL_DIR}/libs/cuDIMOT"

#SETUP MATLAB and LIBRARIES
export SPMpath="/gpfs01/software/imaging/spm12"
export DVARSpath="/gpfs01/software/imaging/DVARS"
export ANTSPATH="/gpfs01/software/imaging/ANTs/2.3.5/bin/"
export C3DPATH="/gpfs01/software/imaging/c3d/c3d-1.3.0-Linux-gcc64/bin"

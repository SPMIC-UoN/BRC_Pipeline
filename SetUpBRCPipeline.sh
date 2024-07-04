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

export CLUSTER_MODE="NO"                                                            #TO BE MODIFIED BY USER, "YES"/"NO"

if [ $CLUSTER_MODE = "YES" ] ; then
    export JOBSUBpath="/gpfs01/software/imaging/jobsub"                             #TO BE MODIFIED BY USER
else
    # Setup FSL (if not already done so in the running environment)
    # Uncomment the following 2 lines (remove the leading #) and correct the FSLDIR setting for your setup
    export FSLDIR="/usr/local/fsl-6.0.5"                                            #TO BE MODIFIED BY USER
    . $FSLDIR/etc/fslconf/fsl.sh
    export FSLCONFDIR=${FSLDIR}/config
    export FSLOUTPUTTYPE="NIFTI_GZ"

    # Setup FreeSurfer (if not already done so in the running environment)
    # Uncomment the following 2 lines (remove the leading #) and correct the FREESURFER_HOME setting for your setup
    export FREESURFER_HOME="/usr/local/freesurfer"                                  #TO BE MODIFIED BY USER
    source $FREESURFER_HOME/SetUpFreeSurfer.sh

    export MATLABpath="/usr/local/matlab/R2018a/bin"                                #TO BE MODIFIED BY USER
    export FSLDIR_5_0_11="/usr/local/fsl-5.0.11"                                    #TO BE MODIFIED BY USER

    #SET DYNAMIC LIBRARIES FOR Eddy
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-8.0/lib64               #TO BE MODIFIED BY USER
fi

#ENV VARIABLES FOR THE BRC_PIPELINE
export BRCDIR="/home/mszam12/main/BRC_Pipeline"                                     #TO BE MODIFIED BY USER
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
export SPMpath="/usr/local/SPM/spm12"                                               #TO BE MODIFIED BY USER
export DVARSpath="/usr/local/DVARS"                                                 #TO BE MODIFIED BY USER
export ANTSPATH="/usr/local/ANTs/ants-2.1.0-redhat/"                                #TO BE MODIFIED BY USER
export C3DPATH="/usr/local/c3d/bin"                                                 #TO BE MODIFIED BY USER

#ADD ENV VARIABLES TO THE PATH
PATH=$PATH:$BRC_SCTRUC_DIR:$BRC_DMRI_DIR:$BRC_FMRI_DIR:$BRC_PMRI_DIR:$BRC_FMRI_GP_DIR:$BRC_IDPEXTRACT_DIR
export PATH

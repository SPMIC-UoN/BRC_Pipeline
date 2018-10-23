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

#SETUP FSL
export FSLDIR="/usr/local/fsl"                              #TO BE MODIFIED BY USER
. $FSLDIR/etc/fslconf/fsl.sh
export FSLCONFDIR=${FSLDIR}/config
export FSLOUTPUTTYPE="NIFTI_GZ"

#SETUP FREESURFER
export FREESURFER_HOME="/usr/local/freesurfer"              #TO BE MODIFIED BY USER

#SETUP MATLAB
export MATLABpath="/usr/local/matlab/R2017a/bin"            #TO BE MODIFIED BY USER
export SPMpath="/usr/local/spm12"                           #TO BE MODIFIED BY USER

#ENV VARIABLES FOR BIOBANK
export BRCDIR="/home/mszam12/main/BRC_Pipeline"                  #TO BE MODIFIED BY USER
export BRC_SCTRUC_DIR=${BRCDIR}/BRC_structural_pipeline
export BRC_DMRI_DIR=${BRCDIR}/BRC_diffusion_pipeline
export BRC_FMRI_DIR=${BRCDIR}/BRC_functional_pipeline
export BRC_SCTRUC_SCR=${BRC_SCTRUC_DIR}/scripts
export BRC_DMRI_SCR=${BRC_DMRI_DIR}/scripts
export BRC_FMRI_SCR=${BRC_FMRI_DIR}/scripts

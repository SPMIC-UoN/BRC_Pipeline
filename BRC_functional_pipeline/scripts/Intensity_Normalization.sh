#!/bin/bash
# Last update: 10/10/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
set -e

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

# Intensity normalisation, and bias field correction, and optional Jacobian modulation, applied to fMRI images (all inputs must be in fMRI space)

#  This code is released to the public domain.
#
#  Matt Glasser, Washington University in St Louis
#  Mark Jenkinson, FMRIB Centre, University of Oxford
#  2011-2012
#
#  Neither Washington Univeristy in St Louis, the FMRIB Centre, the
#  University of Oxford, nor any of their employees imply any warranty
#  of usefulness of this software for any purpose, and do not assume
#  any liability for damages, incidental or otherwise, caused by any
#  use of this document.

# function for parsing options
getopt1()
{
  sopt="$1"
  shift 1

  for fn in $@ ; do
      if [ `echo $fn | grep -- "^${sopt}=" | wc -w` -gt 0 ] ; then
          echo $fn | sed "s/^${sopt}=//"
          # if [ ] ; then Usage ; echo " " ; echo "Error:: option ${sopt} requires an argument"; exit 1 ; end
          return 0
      fi
  done
}

################################################## OPTION PARSING #####################################################

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
# check for correct options
if [ $# -lt 4 ] ; then Usage; exit 1; fi

# parse arguments
WD=`getopt1 "--workingdir" $@`
InputfMRI=`getopt1 "--infmri" $@`
BiasField=`getopt1 "--biasfield" $@`
Jacobian=`getopt1 "--jacobian" $@`
BrainMask=`getopt1 "--brainmask" $@`
OutputfMRI=`getopt1 "--ofmri" $@`
ScoutInput=`getopt1 "--inscout" $@`
ScoutOutput=`getopt1 "--oscout" $@`
UseJacobian=`getopt1 "--usejacobian" $@`
BiasCorrection=`getopt1 "--biascorrection" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                    START: Intensity Normalization                      +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "InputfMRI:$InputfMRI"
log_Msg 2 "BiasField:$BiasField"
log_Msg 2 "Jacobian:$Jacobian"
log_Msg 2 "BrainMask:$BrainMask"
log_Msg 2 "OutputfMRI:$OutputfMRI"
log_Msg 2 "ScoutInput:$ScoutInput"
log_Msg 2 "ScoutOutput:$ScoutOutput"
log_Msg 2 "UseJacobian:$UseJacobian"
log_Msg 2 "BiasCorrection:$BiasCorrection"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

# default parameters
OutputfMRI=`$FSLDIR/bin/remove_ext $OutputfMRI`

jacobiancom=""
if [[ $UseJacobian == "true" ]] ; then
    jacobiancom="-mul $Jacobian"
fi

biascom=""
if [[ ${BiasCorrection} == "SEBASED" ]] ; then
    biascom="-div $BiasField"
fi

# sanity checking
if [ X${ScoutInput} != X ] ; then
    if [ X${ScoutOutput} = X ] ; then
      	log_Msg 3 "Error: Must supply an output name for the normalised scout image"
      	exit 1
    fi
fi

########################################## DO WORK ##########################################

# Run intensity normalisation, with bias field correction and optional jacobian modulation, for the main fmri timeseries and the scout images (pre-saturation images)
${FSLDIR}/bin/fslmaths ${InputfMRI} $biascom $jacobiancom -mas ${BrainMask} -thr 0 -ing 10000 ${WD}/${OutputfMRI} -odt float

if [ X${ScoutInput} != X ] ; then
    ${FSLDIR}/bin/fslmaths ${ScoutInput} $biascom $jacobiancom -mas ${BrainMask} -thr 0 -ing 10000 ${WD}/${ScoutOutput} -odt float
fi

#Basic Cleanup
#rm ${InputfMRI}.nii.*
#${FSLDIR}/bin/imrm ${WD}/rfMRI_temp

log_Msg 3 ""
log_Msg 3 "                     START: Intensity Normalization"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

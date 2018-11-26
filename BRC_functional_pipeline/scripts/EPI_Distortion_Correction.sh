#!/bin/bash
# Last update: 01/10/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
set -e

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

# ---------------------------------------------------------------------
#  Constants for specification of Readout Distortion Correction Method
# ---------------------------------------------------------------------

FIELDMAP_METHOD_OPT="FIELDMAP"
SIEMENS_METHOD_OPT="SiemensFieldMap"
GENERAL_ELECTRIC_METHOD_OPT="GeneralElectricFieldMap"
SPIN_ECHO_METHOD_OPT="TOPUP"

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

defaultopt()
{
    echo $1
}

# parse arguments
WD=`getopt1 "--workingdir" $@`
topupFolderName=`getopt1 "--topupfoldername" $@`
ScoutInputName=`getopt1 "--scoutin" $@`
SpinEchoPhaseEncodeNegative=`getopt1 "--SEPhaseNeg" $@`
SpinEchoPhaseEncodePositive=`getopt1 "--SEPhasePos" $@`
EchoSpacing=`getopt1 "--echospacing" $@`
UnwarpDir=`getopt1 "--unwarpdir" $@`
TopupConfig=`getopt1 "--topupconfig" $@`
GradientDistortionCoeffs=`getopt1 "--gdcoeffs" $@`
DistortionCorrection=`getopt1 "--method" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "topupFolderName:$topupFolderName"
log_Msg 2 "ScoutInputName:$ScoutInputName"
log_Msg 2 "SpinEchoPhaseEncodeNegative:$SpinEchoPhaseEncodeNegative"
log_Msg 2 "SpinEchoPhaseEncodePositive:$SpinEchoPhaseEncodePositive"
log_Msg 2 "EchoSpacing:$EchoSpacing"
log_Msg 2 "UnwarpDir:$UnwarpDir"
log_Msg 2 "TopupConfig:$TopupConfig"
log_Msg 2 "GradientDistortionCoeffs:$GradientDistortionCoeffs"
log_Msg 2 "DistortionCorrection:$DistortionCorrection"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


TopupConfig=`defaultopt $TopupConfig ${BRC_GLOBAL_DIR}/config/b02b0.cnf.txt`
########################################## DO WORK ##########################################

case $DistortionCorrection in

    ${FIELDMAP_METHOD_OPT} | ${SIEMENS_METHOD_OPT} | ${GENERAL_ELECTRIC_METHOD_OPT})
    ;;


    ${SPIN_ECHO_METHOD_OPT})

        # Use topup to distortion correct the scout scans using a blip-reversed SE pair "fieldmap" sequence

        ${BRC_FMRI_SCR}/TopupPreprocessing.sh \
              --workingdir=${WD}/${topupFolderName} \
              --scoutin=${ScoutInputName} \
              --phaseone=${SpinEchoPhaseEncodeNegative} \
              --phasetwo=${SpinEchoPhaseEncodePositive} \
              --echospacing=${EchoSpacing} \
              --unwarpdir=${UnwarpDir} \
              --topupconfig=${TopupConfig} \
              --gdcoeffs=${GradientDistortionCoeffs} \
              --outfolder=${WD} \
              --owarp=${WD}/WarpField \
              --ojacobian=${WD}/Jacobian \
              --logfile=${LogFile}

     ;;


    *)
        log_Msg 3 "UNKNOWN DISTORTION CORRECTION METHOD: ${DistortionCorrection}"
        exit 1
esac

log_Msg 3 ""
log_Msg 3 "                     END: EPI Distortion Correction"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

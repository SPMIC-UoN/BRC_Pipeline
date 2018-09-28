#!/bin/bash
# Last update: 28/09/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
set -e

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
ScoutInputName=`getopt1 "--scoutin" $@`
SpinEchoPhaseEncodeNegative=`getopt1 "--SEPhaseNeg" $@`
SpinEchoPhaseEncodePositive=`getopt1 "--SEPhasePos" $@`
EchoSpacing=`getopt1 "--echospacing" $@`
UnwarpDir=`getopt1 "--unwarpdir" $@`
TopupConfig=`getopt1 "--topupconfig" $@`
GradientDistortionCoeffs=`getopt1 "--gdcoeffs" $@`
DistortionCorrection=`getopt1 "--method" $@`

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "WD:$WD"
echo "ScoutInputName:$ScoutInputName"
echo "SpinEchoPhaseEncodeNegative:$SpinEchoPhaseEncodeNegative"
echo "SpinEchoPhaseEncodePositive:$SpinEchoPhaseEncodePositive"
echo "EchoSpacing:$EchoSpacing"
echo "UnwarpDir:$UnwarpDir"
echo "TopupConfig:$TopupConfig"
echo "GradientDistortionCoeffs:$GradientDistortionCoeffs"
echo "DistortionCorrection:$DistortionCorrection"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


TopupConfig=`defaultopt $TopupConfig ${FSLDIR}/etc/flirtsch/b02b0.cnf`

########################################## DO WORK ##########################################

case $DistortionCorrection in

    ${FIELDMAP_METHOD_OPT} | ${SIEMENS_METHOD_OPT} | ${GENERAL_ELECTRIC_METHOD_OPT})
    ;;


    ${SPIN_ECHO_METHOD_OPT})

        # Use topup to distortion correct the scout scans using a blip-reversed SE pair "fieldmap" sequence

        ${BRC_FMRI_SCR}/TopupPreprocessing.sh \
              --workingdir=${WD}/FieldMap \
              --scoutin=${ScoutInputName} \
              --phaseone=${SpinEchoPhaseEncodeNegative} \
              --phasetwo=${SpinEchoPhaseEncodePositive} \
              --echospacing=${EchoSpacing} \
              --unwarpdir=${UnwarpDir} \
              --topupconfig=${TopupConfig} \
              --gdcoeffs=${GradientDistortionCoeffs} \
              --outfolder=${WD}
              --owarp=${WD}/WarpField \
              --ojacobian=${WD}/Jacobian

     ;;


    *)
        echo "UNKNOWN DISTORTION CORRECTION METHOD: ${DistortionCorrection}"
        exit 1
esac

echo ""
echo "                     END: EPI Distortion Correction"
echo "                    END: `date`"
echo "=========================================================================="
echo "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

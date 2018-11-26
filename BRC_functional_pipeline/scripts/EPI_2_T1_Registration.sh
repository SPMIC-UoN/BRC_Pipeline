#!/bin/bash
# Last update: 28/09/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
set -e

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

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

# parse arguments
WD=`getopt1 "--workingdir" $@`
fMRIFolder=`getopt1 "--fmrifolder" $@`
topupFolderName=`getopt1 "--topupfodername" $@`
sebfFolderName=`getopt1 "--sebffoldername" $@`
ScoutInputName=`getopt1 "--scoutin" $@`
ScoutReference=`getopt1 "--scoutrefin" $@`
T1wImage=`getopt1 "--t1" $@`
T1wBrainImage=`getopt1 "--t1brain" $@`
WMseg=`getopt1 "--wmseg" $@`
GMseg=`getopt1 "--gmseg" $@`
dof=`getopt1 "--dof" $@`
BiasCorrection=`getopt1 "--biascorrection" $@`
NameOffMRI=`getopt1 "--fmriname" $@`
SubjectFolder=`getopt1 "--subjectfolder" $@`
UseJacobian=`getopt1 "--usejacobian" $@`
RegOutput=`getopt1 "--oregim" $@`
OutputTransform=`getopt1 "--owarp" $@`
OutputInvTransform=`getopt1 "--oinwarp" $@`
JacobianOut=`getopt1 "--ojacobian" $@`
MotionCorrectionType=`getopt1 "--motioncorrectiontype" $@`
EddyOutput=`getopt1 "--eddyoutname" $@`
DistortionCorrection=`getopt1 "--method" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

ScoutInputFile=`basename $ScoutInputName`

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                   START: EPI to T1 Registration                        +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "fMRIFolder:$fMRIFolder"
log_Msg 2 "topupFolderName:$topupFolderName"
log_Msg 2 "ScoutInputName:$ScoutInputName"
log_Msg 2 "ScoutReference:$ScoutReference"
log_Msg 2 "T1wImage:$T1wImage"
log_Msg 2 "T1wBrainImage:$T1wBrainImage"
log_Msg 2 "WMseg:$WMseg"
log_Msg 2 "GMseg:$GMseg"
log_Msg 2 "dof:$dof"
log_Msg 2 "BiasCorrection:$BiasCorrection"
log_Msg 2 "NameOffMRI:$NameOffMRI"
log_Msg 2 "SubjectFolder:$SubjectFolder"
log_Msg 2 "UseJacobian:$UseJacobian"
log_Msg 2 "RegOutput:$RegOutput"
log_Msg 2 "OutputTransform:$OutputTransform"
log_Msg 2 "OutputInvTransform:$OutputInvTransform"
log_Msg 2 "JacobianOut:$JacobianOut"
log_Msg 2 "MotionCorrectionType:$MotionCorrectionType"
log_Msg 2 "EddyOutput:$EddyOutput"
log_Msg 2 "DistortionCorrection:$DistortionCorrection"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

if [[ $MotionCorrectionType == "EDDY" ]]; then
    Eddy_Folder=${fMRIFolder}/Eddy
fi

#error check bias correction opt
case "$BiasCorrection" in
    NONE)
        UseBiasField=""
        ;;

    SEBASED)
        if [[ "$DistortionCorrection" != "${SPIN_ECHO_METHOD_OPT}" ]]
        then
            log_Msg 3 "SEBASED bias correction is only available with --method=${SPIN_ECHO_METHOD_OPT}"
            exit 1
        fi
        #note, this file doesn't exist yet, gets created by Compute_SpinEcho_BiasField.sh
        UseBiasField="${WD}/Compute_SE_BiasField/${NameOffMRI}_sebased_bias.nii.gz"
        ;;

    "")
        log_Msg 3 "--biascorrection option not specified"
        exit 1
        ;;

    *)
        log_Msg 3 "unrecognized value for bias correction: $BiasCorrection"
        exit 1
esac


case $DistortionCorrection in

    ${FIELDMAP_METHOD_OPT} | ${SIEMENS_METHOD_OPT} | ${GENERAL_ELECTRIC_METHOD_OPT})
    ;;


    ${SPIN_ECHO_METHOD_OPT} | "NONE")

        if [[ $MotionCorrectionType == "EDDY" ]]; then
            ${FSLDIR}/bin/imcp ${WD}/SBRef_dc  ${WD}/${ScoutInputFile}_undistorted
        else
            if [[ $UseJacobian == "true" ]]; then
                ${FSLDIR}/bin/imcp ${WD}/${topupFolderName}/SBRef_dc_jac  ${WD}/${ScoutInputFile}_undistorted
            else
                ${FSLDIR}/bin/imcp ${WD}/SBRef_dc  ${WD}/${ScoutInputFile}_undistorted
            fi
        fi

        log_Msg 3 "register undistorted scout image to T1w"
        ${BRC_FMRI_SCR}/epi_reg_dof.sh --dof=${dof} --epi=${WD}/${ScoutInputFile}_undistorted --t1=${T1wImage} --t1brain=${T1wBrainImage} --wmseg=$WMseg --out=${WD}/${ScoutInputFile}_undistorted2T1w_init

        #copy the initial registration into the final affine's filename, as it is pretty good
        cp "${WD}/${ScoutInputFile}_undistorted2T1w_init.mat" "${WD}/fMRI2str.mat"

        log_Msg 3 "generate combined warpfields and spline interpolated images and apply bias field correction"
        ${FSLDIR}/bin/convertwarp --relout --rel -r ${T1wImage} --warp1=${WD}/WarpField.nii.gz --postmat=${WD}/${ScoutInputFile}_undistorted2T1w_init.mat -o ${WD}/${ScoutInputFile}_undistorted2T1w_init_warp

        if [[ $MotionCorrectionType == "EDDY" ]]; then
            ${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/${ScoutInputFile}_undistorted -r ${T1wImage} --premat=${WD}/${ScoutInputFile}_undistorted2T1w_init.mat -o ${WD}/${ScoutInputFile}_undistorted2T1w_init
        else
            ${FSLDIR}/bin/applywarp --rel --interp=spline -i ${ScoutInputName} -r ${T1wImage} -w ${WD}/${ScoutInputFile}_undistorted2T1w_init_warp -o ${WD}/${ScoutInputFile}_undistorted2T1w_init
        fi

        ${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/Jacobian.nii.gz -r ${T1wImage} --premat=${WD}/${ScoutInputFile}_undistorted2T1w_init.mat -o ${WD}/Jacobian2T1w.nii.gz

        #resample phase images to T1w space
        Files="PhaseOne_gdc_dc PhaseTwo_gdc_dc SBRef_dc"

        for File in ${Files}
        do
            if [[ $MotionCorrectionType == "EDDY" ]]; then
                ${FSLDIR}/bin/applywarp --interp=spline -i "${WD}/${File}" -r ${T1wImage} --premat=${WD}/fMRI2str.mat -o ${WD}/${File}
            else
                if [[ $UseJacobian == "true" ]]; then
                    ${FSLDIR}/bin/applywarp --interp=spline -i "${WD}/${topupFolderName}/${File}_jac" -r ${T1wImage} --premat=${WD}/fMRI2str.mat -o ${WD}/${File}
                else
                    ${FSLDIR}/bin/applywarp --interp=spline -i "${WD}/${File}" -r ${T1wImage} --premat=${WD}/fMRI2str.mat -o ${WD}/${File}
                fi
            fi
        done

        #correct filename is already set in UseBiasField, but we have to compute it if using SEBASED
        #we compute it in this script because it needs outputs from topup, and because it should be applied to the scout image
        log_Msg 3 "BiasCorrection=$BiasCorrection"
        if [[ "$BiasCorrection" == "SEBASED" ]]
        then
            mkdir -p "$WD/${sebfFolderName}"
            "${BRC_FMRI_SCR}/Compute_SpinEcho_BiasField.sh" \
                  --workingdir="$WD/${sebfFolderName}" \
                  --subjectfolder="$SubjectFolder" \
                  --fmriname="$NameOffMRI" \
                  --smoothingfwhm="2" \
                  --inputdir="$WD" \
                  --t1brain=${T1wBrainImage} \
                  --gmseg=${GMseg} \
                  --logfile=${LogFile}

        fi
    ;;


    *)
        log_Msg 3 "UNKNOWN DISTORTION CORRECTION METHOD: ${DistortionCorrection}"
        exit 1
esac

if [[ $UseJacobian == "true" ]] ; then

    if [[ "$UseBiasField" != "" ]]; then
        log_Msg 3 "apply Jacobian correction and bias correction options to scout image"
        ${FSLDIR}/bin/fslmaths ${WD}/${ScoutInputFile}_undistorted2T1w_init -div ${UseBiasField} -mul ${WD}/Jacobian2T1w.nii.gz ${WD}/${ScoutInputFile}_undistorted2T1w_init.nii.gz
    else
        log_Msg 3 "apply Jacobian correction to scout image"
        ${FSLDIR}/bin/fslmaths ${WD}/${ScoutInputFile}_undistorted2T1w_init -mul ${WD}/Jacobian2T1w.nii.gz ${WD}/${ScoutInputFile}_undistorted2T1w_init.nii.gz
    fi
else
    if [[ "$UseBiasField" != "" ]]; then
        log_Msg 3 "apply bias correction options to scout image"
        ${FSLDIR}/bin/fslmaths ${WD}/${ScoutInputFile}_undistorted2T1w_init -div ${UseBiasField} ${WD}/${ScoutInputFile}_undistorted2T1w_init.nii.gz
    fi
    #these all overwrite the input, no 'else' needed for "do nothing"
fi

#${FSLDIR}/bin/convertwarp --relout --rel --warp1=${WD}/${ScoutInputFile}_undistorted2T1w_init_warp.nii.gz --ref=${T1wImage} --postmat=${WD}/fMRI2str_refinement.mat --out=${WD}/fMRI2str.nii.gz
${FSLDIR}/bin/convertwarp --relout --rel --warp1=${WD}/${ScoutInputFile}_undistorted2T1w_init_warp.nii.gz --ref=${T1wImage} --postmat=$FSLDIR/etc/flirtsch/ident.mat --out=${WD}/fMRI2str.nii.gz

#create final affine from undistorted fMRI space to T1w space, will need it if it making SEBASED bias field
#overwrite old version of ${WD}/fMRI2str.mat, as it was just the initial registration
#${WD}/${ScoutInputFile}_undistorted_initT1wReg.mat is from the above epi_reg_dof, initial registration from fMRI space to T1 space
#${FSLDIR}/bin/convert_xfm -omat ${WD}/fMRI2str.mat -concat ${WD}/fMRI2str_refinement.mat ${WD}/${ScoutInputFile}_undistorted2T1w_init.mat
${FSLDIR}/bin/convert_xfm -omat ${WD}/fMRI2str.mat -concat $FSLDIR/etc/flirtsch/ident.mat ${WD}/${ScoutInputFile}_undistorted2T1w_init.mat

log_Msg 3 "Create warped image with spline interpolation, bias correction and (optional) Jacobian modulation"
if [[ $MotionCorrectionType == "EDDY" ]]; then
    ${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/${ScoutInputFile}_undistorted -r ${T1wImage} -w ${WD}/fMRI2str.nii.gz -o ${WD}/${ScoutInputFile}_undistorted2T1w
else
    ${FSLDIR}/bin/applywarp --rel --interp=spline -i ${ScoutInputName} -r ${T1wImage}.nii.gz -w ${WD}/fMRI2str.nii.gz -o ${WD}/${ScoutInputFile}_undistorted2T1w
fi

${FSLDIR}/bin/invwarp -w ${WD}/fMRI2str.nii.gz -o ${OutputInvTransform} -r ${ScoutReference}

# resample fieldmap jacobian with new registration
${FSLDIR}/bin/applywarp --rel --interp=spline -i ${WD}/Jacobian.nii.gz -r ${T1wImage} --premat=${WD}/fMRI2str.mat -o ${WD}/Jacobian2T1w.nii.gz

if [[ $UseJacobian == "true" ]]; then

    if [[ "$UseBiasField" != "" ]]; then
        log_Msg 3 "applying Jacobian modulation and bias correction"
        ${FSLDIR}/bin/fslmaths ${WD}/${ScoutInputFile}_undistorted2T1w -div ${UseBiasField} -mul ${WD}/Jacobian2T1w.nii.gz ${WD}/${ScoutInputFile}_undistorted2T1w
    else
        log_Msg 3 "applying Jacobian modulation"
        ${FSLDIR}/bin/fslmaths ${WD}/${ScoutInputFile}_undistorted2T1w -mul ${WD}/Jacobian2T1w.nii.gz ${WD}/${ScoutInputFile}_undistorted2T1w
    fi

else
    if [[ "$UseBiasField" != "" ]]; then
        log_Msg 3 "apply bias correction options"
        ${FSLDIR}/bin/fslmaths ${WD}/${ScoutInputFile}_undistorted2T1w -div ${UseBiasField} ${WD}/${ScoutInputFile}_undistorted2T1w
    fi
    #no else, the commands are overwriting their input
fi

log_Msg 3 "cp ${WD}/${ScoutInputFile}_undistorted2T1w.nii.gz ${RegOutput}.nii.gz"
cp ${WD}/${ScoutInputFile}_undistorted2T1w.nii.gz ${RegOutput}.nii.gz

OutputTransformDir=$(dirname ${OutputTransform})
if [ ! -e ${OutputTransformDir} ] ; then
    log_Msg 3 "mkdir -p ${OutputTransformDir}"
    mkdir -p ${OutputTransformDir}
fi

log_Msg 3 "cp ${WD}/fMRI2str.nii.gz ${OutputTransform}.nii.gz"
cp ${WD}/fMRI2str.nii.gz ${OutputTransform}.nii.gz

log_Msg 3 "cp ${WD}/Jacobian2T1w.nii.gz ${JacobianOut}.nii.gz"
cp ${WD}/Jacobian2T1w.nii.gz ${JacobianOut}.nii.gz

log_Msg 3 ""
log_Msg 3 "                       END: EPI to T1 Registration"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

${FSLDIR}/bin/imrm ${WD}/${ScoutInputFile}_undistorted2T1w_init_fast_*
${FSLDIR}/bin/imrm ${WD}/${ScoutInputFile}_undistorted
rm ${WD}/${ScoutInputFile}_undistorted2T1w_init_init.mat
rm ${WD}/${ScoutInputFile}_undistorted2T1w_init.mat

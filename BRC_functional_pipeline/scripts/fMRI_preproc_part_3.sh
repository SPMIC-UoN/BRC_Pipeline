#!/bin/bash
# Last update: 05/07/2019

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham

set -e

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

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
SliceTimingCorrection=`getopt1 "--slicetimingcorrection" $@`
stcFolder=`getopt1 "--stcfolder" $@`
STC_Input=`getopt1 "--stcinput" $@`
NameOffMRI=`getopt1 "--nameoffmri" $@`
SliceTimingFile=`getopt1 "--slicetimingfile" $@`
DCFolder=`getopt1 "--dcfolder" $@`
AnalysisFolder=`getopt1 "--subjectfolder" $@`
TempFolder=`getopt1 "--fmrifolder" $@`
topupFolderName=`getopt1 "--topupfodername" $@`
sebfFolderName=`getopt1 "--sebffoldername" $@`
gdcFolder=`getopt1 "--gdcfolder" $@`
ScoutName=`getopt1 "--scoutname" $@`
T1wImage=`getopt1 "--t1" $@`
T1wRestoreImageBrain=`getopt1 "--t1brain" $@`
T1wImageBrainMask=`getopt1 "--t1brainmask" $@`
wmseg=`getopt1 "--wmseg" $@`
GMseg=`getopt1 "--gmseg" $@`
dof=`getopt1 "--dof" $@`
DistortionCorrection=`getopt1 "--method" $@`
BiasCorrection=`getopt1 "--biascorrection" $@`
UseJacobian=`getopt1 "--usejacobian" $@`
MotionCorrectionType=`getopt1 "--motioncorrectiontype" $@`
EddyOutput=`getopt1 "--eddyoutname" $@`
regFolder=`getopt1 "--regfolder" $@`
RegOutput=`getopt1 "--oregim" $@`
fMRI2strOutputTransform=`getopt1 "--owarp" $@`
str2fMRIOutputTransform=`getopt1 "--oinwarp" $@`
JacobianOut=`getopt1 "--ojacobian" $@`
OsrFolder=`getopt1 "--osrfolder" $@`
data2stdT1Folder=`getopt1 "--t12std" $@`
FinalfMRIResolution=`getopt1 "--fmriresout" $@`
OutputfMRI2StandardTransform=`getopt1 "--outfmri2stdtrans" $@`
Standard2OutputfMRITransform=`getopt1 "--oiwarp" $@`
nrFolder=`getopt1 "--nrfolder" $@`
smoothingfwhm=`getopt1 "--fwhm" $@`
Do_ica_aroma=`getopt1 "--icaaroma" $@`
SSNR_motionparam=`getopt1 "--motionparam" $@`
pnmFolder=`getopt1 "--pnmfolder" $@`
PhysInputTXT=`getopt1 "--physinputtxt" $@`
SamplingRate=`getopt1 "--samplingrate" $@`
SmoothCardiac=`getopt1 "--smoothcardiac" $@`
SmoothResp=`getopt1 "--smoothresp" $@`
ColResp=`getopt1 "--colresp" $@`
ColCardiac=`getopt1 "--colcardiac" $@`
ColTrigger=`getopt1 "--coltrigger" $@`
DO_RVT=`getopt1 "--dorvt" $@`
SliceOrder=`getopt1 "--sliceorder" $@`
SE_BF_Folder=`getopt1 "--sebffolder" $@`
regT1Folder=`getopt1 "--regt1folder" $@`
EddyFolder=`getopt1 "--eddyfolder" $@`
In_Nrm_Folder=`getopt1 "--innrmfolder" $@`
Do_intensity_norm=`getopt1 "--dointensitynorm" $@`
Temp_Filter_Cutoff=`getopt1 "--tempfiltercutoff" $@`
mcFolder=`getopt1 "--mcfolder" $@`
MotionMatrixFolder=`getopt1 "--motionmatdir" $@`
MotionMatrixPrefix=`getopt1 "--motionmatprefix" $@`
DO_QC=`getopt1 "--doqc" $@`
qcFolder=`getopt1 "--qcfolder" $@`
rfMRIrawFolder=`getopt1 "--rfmrirawfolder" $@`
rfMRIFolder=`getopt1 "--rfmrifolder" $@`
preprocFolder=`getopt1 "--preprocfolder" $@`
processedFolder=`getopt1 "--processedfolder" $@`
TOPUP_Folder=`getopt1 "--topupfolder" $@`
Start_Time=`getopt1 "--start" $@`
Subject=`getopt1 "--subject" $@`
SpinEchoPhaseEncodePositive=`getopt1 "--SEPhasePos" $@`
SpinEchoPhaseEncodeNegative=`getopt1 "--SEPhaseNeg" $@`
Tmp_Filt_Folder=`getopt1 "--tmpfiltfolder" $@`
Str2rfMRITransf=`getopt1 "--str2rfmritransf" $@`
logFile=`getopt1 "--logfile" $@`

log_SetPath "${logFile}"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

case $MotionCorrectionType in

    MCFLIRT6 | MCFLIRT12)
        STC_Input=${mcFolder}/${NameOffMRI}_mc
        SSNR_motionparam=${mcFolder}/${NameOffMRI}_mc.par
        fMRI_2_str_Input=${regFolder}/${fMRI2strOutputTransform}
        OSR_Scout_In=${gdcFolder}/${ScoutName}_gdc
    ;;

    EDDY)
        STC_Input=${EddyFolder}/${EddyOutput}
        SSNR_motionparam=${EddyFolder}/${EddyOutput}.eddy_parameters
        fMRI_2_str_Input=${EddyFolder}/${EddyOutput}
        OSR_Scout_In=${EddyFolder}/SBRef_dc
    ;;

    *)
        log_Msg 3 "UNKNOWN MOTION CORRECTION METHOD: ${MotionCorrectionType}"
        exit 1
esac


if [ $SliceTimingCorrection -ne 0 ]; then

    log_Msg 3 "Slice Timing Correction"
    ${RUN} ${BRC_FMRI_SCR}/Slice_Timing_Correction.sh \
          --workingdir=${stcFolder} \
          --infmri=${STC_Input} \
          --stc_method=${SliceTimingCorrection} \
          --ofmri=${stcFolder}/${NameOffMRI}_stc \
          --slicetimingfile=${SliceTimingFile} \
          --logfile=${logFile}

else

    log_Msg 3 "NOT Performing Slice Timing Correction"
    ${FSLDIR}/bin/imcp ${STC_Input} ${stcFolder}/${NameOffMRI}_stc
fi


log_Msg 3 "EPI to T1 registration"
${RUN} ${BRC_FMRI_SCR}/EPI_2_T1_Registration.sh \
      --workingdir=${DCFolder} \
      --fmriname=${NameOffMRI} \
      --subjectfolder=${AnalysisFolder} \
      --fmrifolder=${TempFolder} \
      --topupfodername=${topupFolderName} \
      --sebffoldername=${sebfFolderName} \
      --scoutin=${gdcFolder}/${ScoutName}_gdc \
      --scoutrefin=${OSR_Scout_In} \
      --t1=${T1wImage} \
      --t1brain=${T1wRestoreImageBrain} \
      --t1brainmask=${T1wImageBrainMask} \
      --wmseg=${wmseg} \
      --gmseg=${GMseg} \
      --dof=${dof} \
      --method=${DistortionCorrection} \
      --biascorrection=${BiasCorrection} \
      --usejacobian=${UseJacobian} \
      --motioncorrectiontype=${MotionCorrectionType} \
      --eddyoutname=${EddyOutput} \
      --oregim=${regFolder}/${RegOutput} \
      --owarp=${regFolder}/${fMRI2strOutputTransform} \
      --oinwarp=${regFolder}/${str2fMRIOutputTransform} \
      --ojacobian=${regFolder}/${JacobianOut} \
      --logfile=${logFile}


log_Msg 3 "One Step Resampling"
${RUN} ${BRC_FMRI_SCR}/One_Step_Resampling.sh \
      --workingdir=${OsrFolder} \
      --scoutgdcin=${OSR_Scout_In} \
      --gdfield=${gdcFolder}/${NameOffMRI}_gdc_warp \
      --t12std=${data2stdT1Folder}/T1_2_std_warp \
      --t1brainmask=${T1wImageBrainMask} \
      --fmriresout=${FinalfMRIResolution} \
      --fmri2structin=${regFolder}/${fMRI2strOutputTransform} \
      --struct2std=${regT1Folder}/T1_2_std_warp_field \
      --oscout=${OsrFolder}/${NameOffMRI}_SBRef_nonlin \
      --owarp=${regFolder}/${OutputfMRI2StandardTransform} \
      --oiwarp=${regFolder}/${Standard2OutputfMRITransform} \
      --ojacobian=${OsrFolder}/${JacobianOut}_std.${FinalfMRIResolution} \
      --logfile=${logFile}


log_Msg 3 "Spatial Smoothing and Artifact Noise Removal"
${RUN} ${BRC_FMRI_SCR}/Spatial_Smoothing_Noise_Removal.sh \
        --workingdir=${nrFolder} \
        --infmri=${stcFolder}/${NameOffMRI}_stc \
        --fmriname=${NameOffMRI} \
        --fwhm=${smoothingfwhm} \
        --icaaroma=${Do_ica_aroma} \
        --motionparam=${SSNR_motionparam} \
        --fmri2structin=${DCFolder}/fMRI2str.mat \
        --struct2std=${regT1Folder}/T1_2_std_warp_field.nii.gz \
        --motioncorrectiontype=${MotionCorrectionType} \
        --logfile=${logFile}


log_Msg 3 "Physiological Noise Removal"
#${RUN} ${BRC_FMRI_SCR}/Physiological_Noise_Removal.sh \
#        --workingdir=${pnmFolder} \
#        --infmri=${nrFolder}/ICA_AROMA/denoised_func_data_nonaggr \
#        --physinputtxt=${PhysInputTXT} \
#        --samplingrate=${SamplingRate} \
#        --smoothcardiac=${SmoothCardiac} \
#        --smoothresp=${SmoothResp} \
#        --colresp=${ColResp} \
#        --colcardiac=${ColCardiac} \
#        --coltrigger=${ColTrigger} \
#        --dorvt=${DO_RVT} \
#        --sliceorder=${SliceOrder} \
#        --slicetimingfile=${SliceTimingFile} \
#        --logfile=${logFile}


if [[ ${DistortionCorrection} == "TOPUP" ]]
then
    #create MNI space corrected fieldmap images
#    ${FSLDIR}/bin/applywarp --rel --interp=spline --in=${DCFolder}/PhaseOne_gdc_dc_unbias -w $T1wFolder/reg/nonlin/T1_2_std_warp_field -r ${TempFolder}/${NameOffMRI}_SBRef_nonlin -o ${ResultsFolder}/${NameOffMRI}_PhaseOne_gdc_dc
#    ${FSLDIR}/bin/applywarp --rel --interp=spline --in=${DCFolder}/PhaseTwo_gdc_dc_unbias -w $T1wFolder/reg/nonlin/T1_2_std_warp_field -r ${TempFolder}/${NameOffMRI}_SBRef_nonlin -o ${ResultsFolder}/${NameOffMRI}_PhaseTwo_gdc_dc

    #create MNINonLinear final fMRI resolution bias field outputs
    if [[ ${BiasCorrection} == "SEBASED" ]]
    then
        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${SE_BF_Folder}/sebased_bias_dil -r ${OsrFolder}/${NameOffMRI}_SBRef_nonlin -w ${regT1Folder}/T1_2_std_warp_field -o ${SE_BF_Folder}/${NameOffMRI}2std_se_bias
#        ${FSLDIR}/bin/fslmaths ${SE_BF_Folder}/${NameOffMRI}2std_se_bias -mas ${OsrFolder}/${T1wRestoreImageBrain}_mask.${FinalfMRIResolution}.nii.gz ${SE_BF_Folder}/${NameOffMRI}2std_se_bias

        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${SE_BF_Folder}/sebased_reference_dil -r ${OsrFolder}/${NameOffMRI}_SBRef_nonlin -w ${regT1Folder}/T1_2_std_warp_field -o ${SE_BF_Folder}/${NameOffMRI}2std_se_ref
#        ${FSLDIR}/bin/fslmaths ${SE_BF_Folder}/${NameOffMRI}2std_se_ref -mas ${OsrFolder}/${T1wRestoreImageBrain}_mask.${FinalfMRIResolution} ${SE_BF_Folder}/${NameOffMRI}2std_se_ref

        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${SE_BF_Folder}/${NameOffMRI}_dropouts -r ${OsrFolder}/${NameOffMRI}_SBRef_nonlin -w ${regT1Folder}/T1_2_std_warp_field -o ${SE_BF_Folder}/${NameOffMRI}2std_dropouts

        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${SE_BF_Folder}/${NameOffMRI}2std_se_bias -r ${gdcFolder}/${ScoutName}_gdc -w ${regFolder}/${Standard2OutputfMRITransform} -o ${SE_BF_Folder}/${NameOffMRI}2func_se_bias
        ${FSLDIR}/bin/fslmaths ${SE_BF_Folder}/${NameOffMRI}2func_se_bias -thr 0.5 -bin ${SE_BF_Folder}/mask_1
        ${FSLDIR}/bin/fslmaths ${SE_BF_Folder}/${NameOffMRI}2func_se_bias -thr 0.0000001 -bin ${SE_BF_Folder}/mask_2
        ${FSLDIR}/bin/fslmaths ${SE_BF_Folder}/mask_2 -sub ${SE_BF_Folder}/mask_1 -bin ${SE_BF_Folder}/mask_3
        ${FSLDIR}/bin/fslmaths ${SE_BF_Folder}/${NameOffMRI}2func_se_bias -mas ${SE_BF_Folder}/mask_1 -add ${SE_BF_Folder}/mask_3 ${SE_BF_Folder}/${NameOffMRI}2func_se_bias

#        ${FSLDIR}/bin/fslmaths ${SE_BF_Folder}/${NameOffMRI}2func_se_bias -mas ${SE_BF_Folder}/mask ${SE_BF_Folder}/${NameOffMRI}2func_se_bias_masked
#        ${FSLDIR}/bin/fslmaths ${SE_BF_Folder}/${NameOffMRI}2func_se_bias -mas ${OSR_Scout_In}_mask ${SE_BF_Folder}/${NameOffMRI}2func_se_bias
#        ${FSLDIR}/bin/fslmaths ${SE_BF_Folder}/${NameOffMRI}2func_se_bias -mas ${nrFolder}/${NameOffMRI}_mask ${SE_BF_Folder}/${NameOffMRI}2func_se_bias
    fi

    if [[ $UseJacobian == "true" ]] ; then

        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${OsrFolder}/${JacobianOut}_std.${FinalfMRIResolution} -r ${gdcFolder}/${ScoutName}_gdc -w ${regFolder}/${Standard2OutputfMRITransform} -o ${OsrFolder}/${JacobianOut}_func
    fi
fi


if [ $MotionCorrectionType == "MCFLIRT6" ] || [ $MotionCorrectionType == "MCFLIRT12" ] ; then
    if [[ ${DistortionCorrection} == "TOPUP" ]] ; then
        In_Norm_Scout_In=${DCFolder}/${topupFolderName}/SBRef_dc
    else
        In_Norm_Scout_In=${gdcFolder}/${ScoutName}_gdc
    fi
elif [[ ${MotionCorrectionType} == "EDDY" ]] ; then
    In_Norm_Scout_In=${EddyFolder}/SBRef_dc
fi


log_Msg 3 "Intensity normalization and Bias removal"
${RUN} ${BRC_FMRI_SCR}/Intensity_Normalization.sh \
        --workingdir=${In_Nrm_Folder} \
        --intensitynorm=${Do_intensity_norm} \
        --infmri=${nrFolder}/ICA_AROMA/denoised_func_data_nonaggr \
        --inscout=${In_Norm_Scout_In} \
        --brainmask=${nrFolder}/${NameOffMRI}_mask \
        --biascorrection=${BiasCorrection} \
        --biasfield=${SE_BF_Folder}/${NameOffMRI}2func_se_bias \
        --usejacobian=${UseJacobian} \
        --jacobian=${OsrFolder}/${JacobianOut}_func \
        --ofmri=${NameOffMRI}_intnorm \
        --oscout="SBRef_intnorm" \
        --logfile=${logFile}


if [ $Temp_Filter_Cutoff -ne 0 ]; then

    log_Msg 3 "Temporal Filtering"

    ${RUN} ${BRC_FMRI_SCR}/Temporal_Filtering.sh \
          --workingdir=${Tmp_Filt_Folder} \
          --infmri=${In_Nrm_Folder}/${NameOffMRI}_intnorm \
          --tempfiltercutoff=${Temp_Filter_Cutoff} \
          --outfmri=${NameOffMRI}_tempfilt \
          --logfile=${logFile}

else

    log_Msg 3 "Not performing Temporal Filtering"

    ${FSLDIR}/bin/imcp ${In_Nrm_Folder}/${NameOffMRI}_intnorm ${Tmp_Filt_Folder}/${NameOffMRI}_tempfilt
fi


log_Msg 3 "Apply the final registration"
${RUN} ${BRC_FMRI_SCR}/Apply_Registration.sh \
      --workingdir=${OsrFolder} \
      --infmri=${Tmp_Filt_Folder}/${NameOffMRI}_tempfilt \
      --scoutgdcin=${OSR_Scout_In} \
      --gdfield=${gdcFolder}/${NameOffMRI}_gdc_warp \
      --t12std=${data2stdT1Folder}/T1_2_std_warp \
      --fmriresout=${FinalfMRIResolution} \
      --owarp=${regFolder}/${OutputfMRI2StandardTransform} \
      --motioncorrectiontype=${MotionCorrectionType} \
      --motionmatdir=${mcFolder}/${MotionMatrixFolder} \
      --motionmatprefix=${MotionMatrixPrefix} \
      --ofmri=${OsrFolder}/${NameOffMRI}_nonlin \
      --logfile=${logFile}


if [[ ${DO_QC} == "yes" ]]; then

    log_Msg 3 "Performing Quality Control and Outlier Detection"
    ${RUN} ${BRC_FMRI_SCR}/QC_analysis.sh \
          --workingdir=${qcFolder} \
          --infmri=${Tmp_Filt_Folder}/${NameOffMRI}_tempfilt.nii.gz \
          --motionparam=${SSNR_motionparam} \
          --logfile=${logFile}

fi


log_Msg 3 "Organizing the outputs"
${RUN} ${BRC_FMRI_SCR}/Data_Organization.sh \
      --rfmrirawfolder=${rfMRIrawFolder} \
      --rfmrifolder=${rfMRIFolder} \
      --preprocfolder=${preprocFolder} \
      --processedfolder=${processedFolder} \
      --tempfolder=${TempFolder} \
      --eddyfolder=${EddyFolder} \
      --dcfolder=${DCFolder} \
      --biasfieldfolder=${SE_BF_Folder} \
      --topupfolder=${TOPUP_Folder} \
      --gdcfolder=${gdcFolder} \
      --intennormfolder=${In_Nrm_Folder} \
      --motcorrfolder=${mcFolder} \
      --noisremfolder=${nrFolder} \
      --onestepfolder=${OsrFolder} \
      --regfolder=${regFolder} \
      --slicecorrfolder=${stcFolder} \
      --tempfiltfolder=${Tmp_Filt_Folder} \
      --qcfolder=${qcFolder} \
      --nameoffmri=${NameOffMRI} \
      --rfmri2strtransf=${fMRI2strOutputTransform} \
      --str2rfmritransf=${str2fMRIOutputTransform} \
      --rfmri2stdtransf=${OutputfMRI2StandardTransform} \
      --std2rfMRItransf=${Standard2OutputfMRITransform} \
      --logfile=${logFile}


END_Time="$(date -u +%s)"


${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Subject} \
      --type=3 \
      --logfile=${logFile}

################################################################################################
## Cleanup
################################################################################################

if [[ $DistortionCorrection == "NONE" ]] ; then
    ${FSLDIR}/bin/imrm ${SpinEchoPhaseEncodePositive}
    ${FSLDIR}/bin/imrm ${SpinEchoPhaseEncodeNegative}
fi
#: <<'COMMENT'

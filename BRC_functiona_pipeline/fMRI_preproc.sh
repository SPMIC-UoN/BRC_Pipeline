#!/bin/bash
# Last update: 28/09/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
# Preprocessing Pipeline for resting-state fMRI. Generates the "data" directory that can be used as input to fibre orientation estimation.
# Ali-Reza Mohammadi-Nejad, SPMIC, Queens Medical Centre, School of Medicine, University of Nottingham, 2018.
#Example:
#./Pipeline_fMRI.sh --path ~/main/analysis --subject Sub_001 --fmripath ~/main/analysis/Orig/5_rfMRI_2.4mm_MB4_TR1.45_400vols/__rs-fmri_singleMB4_20180312094206_601.nii.gz --fmapmag NONE --fmapphase NONE --fmapgeneralelectric NONE --echodiff NONE --SEPhaseNeg ~/main/analysis/Orig/7_8_rfMRI_SEsinglevol_rev/__rs-fmri_SE_MB4_20180312094206_801.nii.gz --SEPhasePos ~/main/analysis/Orig/7_8_rfMRI_SEsinglevol_rev/__rs-fmri_SE_MB4_rev_20180312094206_901.nii.gz --echospacing 0.00058 --unwarpdir y- --dcmethod TOPUP --biascorrection SEBASED --fmrires 2 --mctype MCFLIRT --stcmethod 1

#clear

set -e

#export ScriptsDir=$(dirname "$(readlink -f "$0")") #Absolute path where scripts are
#source ${ScriptsDir}/init_vars.sh

# --------------------------------------------------------------------------------
#  Usage Description Function
# --------------------------------------------------------------------------------

Usage()
{
  echo "`basename $0`: Description"
  echo " "
  echo "Usage: `basename $0`"
  echo " --path <Path>                        output path"
  echo " --subject <Subject name>             output directory is a subject name folder in input image directory"
  echo " --fmripath <Path>                    full path of the filename of fMRI image"
  echo " --fmriscout <Image path>             A single band reference image (SBRef) is recommended if available. Set to NONE if not available (default)"
       "                                      Set to NONE if you want to use the first volume of the timeseries for motion correction"
  echo " --mctype <Type>                      Type of motion correction. Values: MCFLIRT: between volumes (default), and EDDY: within/between volumes"
  echo " --slice2vol                          If one wants to do slice-to-volome motion correction"
  echo " --slspec <json path>                 Specifies a .json file (created by your DICOM->niftii conversion software) that describes how the"
       "                                      slices/multi-band-groups were acquired. This file is necessary when using the slice-to-vol movement correction"
  echo " --fmapmag <data path>                Expects 4D Magnitude volume with two 3D volumes (differing echo times). Set to NONE (default) if using TOPUP"
  echo " --fmapphase <data path>              Expects a 3D Phase difference volume (Siemens style). Set to NONE (default) if using TOPUP"
  echo " --fmapgeneralelectric                Path to General Electric style B0 fieldmap with two volumes"
       "                                           1. field map in degrees"
       "                                           2. magnitude"
       "                                      Set to 'NONE' (default) if not using 'GeneralElectricFieldMap' as the value for the DistortionCorrection variable"
  echo " --echodiff <value>                   Set to NONE if using TOPUP"
  echo " --SEPhaseNeg <Image path>            For the spin echo field map volume with a 'negative' phase encoding direction"
       "                                      Set to NONE if using regular FIELDMAP"
  echo " --SEPhasePos <Image path>            For the spin echo field map volume with a 'positive' phase encoding direction"
       "                                      Set to NONE if using regular FIELDMAP"
  echo " --echospacing <value>                Effective Echo Spacing of fMRI image (specified in *sec* for the fMRI processing)"
  echo " --unwarpdir <direction>              ‌Based on Phase Encoding Direction: PA: 'y', AP: 'y-', RL: 'x', and LR: 'x-'"
  echo " --dcmethod <method>                  Susceptibility distortion correction method (required for accurate processing)"
       "                                      Values: TOPUP, SiemensFieldMap (same as FIELDMAP), GeneralElectricFieldMap, and NONE (default)"
  echo " --biascorrection <method>            Receive coil bias field correction method"
       "                                      Values: NONE, or SEBASED (Spin-Echo Based)"
       "                                      SEBASED calculates bias field from spin echo images (which requires TOPUP distortion correction)"
  echo " --intensitynorm                      If one wants to do intensity normalization"
  echo " --stcmethod <method>                 Slice timing correction method"
       "                                           0: NONE (default value),"
       "                                           1: If the slices were acquired with interleaved order (0, 2, 4 ... 1, 3, 5 ...),"
       "                                           2: If slices were acquired with forward order (0, 1, 2, ...), and"
       "                                           3: If slices were acquired with backward order (n, n-1, n-2, ...)"
  echo " --fwhm <value>                       Spatial size (sigma, i.e., half-width) of smoothing, in mm. Set to 0 (default) for no spatial smooting"
  echo " --tr <value>                         Repetition Time in sec"
  echo " --fmrires <value>                    Target final resolution of fMRI data in mm (default is 2 mm)"
  echo " --printcom                           use 'echo' for just printing everything and not running the commands (default is to run)"
  echo " -h | --help                          help"
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
#if [ $# -le 4 ] ; then Usage; exit 1; fi

# default values

################################################## OPTION PARSING #####################################################

# default values
fMRIScout="NONE"
MotionCorrectionType="MCFLIRT"
Slice2Volume="no"
SliceSpec="NONE"
MagnitudeInputName="NONE"
PhaseInputName="NONE"
GEB0InputName="NONE"
Do_intensity_norm="no"
GradientDistortionCoeffs="NONE"
DistortionCorrection="NONE"
BiasCorrection="NONE"
dof=6
FinalfMRIResolution=2
SliceTimingCorrection=0
smoothingfwhm=0

opts_DefaultOpt()
{
    echo $1
}

while [ "$1" != "" ]; do
    case $1 in
      --path )                shift
                              Path=$1
                              ;;

      --subject )             shift
                              Subject=$1
                              ;;

      --fmripath )            shift
                              PathOffMRI=$1
                              ;;

      --fmriscout )           shift
                              fMRIScout=$1
                              ;;

      --mctype )              shift
                              MotionCorrectionType=$1
                              ;;

      --slice2vol )           Slice2Volume=yes
                              ;;

      --slspec )              shift
                              SliceSpec=$1
                              ;;

      --fmapmag )             shift
                              MagnitudeInputName=$1
                              ;;

      --fmapphase )           shift
                              PhaseInputName=$1
                              ;;

      --fmapgeneralelectric ) shift
                              GEB0InputName=$1
                              ;;

      --echodiff )            shift
                              deltaTE=$1
                              ;;

      --SEPhaseNeg )          shift
                              SpinEchoPhaseEncodeNegative=$1
                              ;;

      --SEPhasePos )          shift
                              SpinEchoPhaseEncodePositive=$1
                              ;;

      --echospacing )         shift
                              EchoSpacing=$1
                              ;;

      --unwarpdir )           shift
                              UnwarpDir=$1
                              ;;

      --dcmethod )            shift
                              DistortionCorrection=$1
                              ;;

      --biascorrection )      shift
                              BiasCorrection=$1
                              # Convert BiasCorrection value to all UPPERCASE (to allow the user the flexibility to use NONE, None, none, legacy, Legacy, etc.)
                              BiasCorrection="$(echo ${BiasCorrection} | tr '[:lower:]' '[:upper:]')"
                              ;;

      --usejacobian )         shift
                              UseJacobian=$1
                              # Convert UseJacobian value to all lowercase (to allow the user the flexibility to use True, true, TRUE, False, False, false, etc.)
                              UseJacobian="$(echo ${UseJacobian} | tr '[:upper:]' '[:lower:]')"
                              ;;

      --stcmethod )           shift
                              SliceTimingCorrection=$1
                              ;;

      --tr )                  shift
                              RepetitionTime=$1
                              ;;

      --intensitynorm )       Do_intensity_norm=yes
                              ;;

      --fwhm )                shift
                              smoothingfwhm=$1
                              ;;

      --fmrires )             shift
                              FinalfMRIResolution=$1
                              ;;

      --printcom )            shift
                              RUN=$1
                              ;;

    esac
    shift
done

echo "=========================================================================="
echo "               Start Time: `date`"
echo "=========================================================================="

#=====================================================================================
###                          Sanity checking of arguments
#=====================================================================================
if [ X$Path = X ] && [ X$Subject = X ] && [ X$PathOffMRI = X ] ; then
    echo "All of the compulsory arguments --path, -subject and -fmripath MUST be used"
    exit 1;
fi

if [[ $DistortionCorrection == "TOPUP" ]] ; then
    if [ X$SpinEchoPhaseEncodeNegative = X ] && [ X$SpinEchoPhaseEncodePositive = X ] && [ X$EchoSpacing = X ] && [ X$UnwarpDir = X ] ; then
        echo "Based on the the selected distortion correction method (TOPUP), all of the compulsory arguments --SEPhaseNeg, -echospacing, and -unwarpdir MUST be used"
        exit 1;
    fi

    if [ $SpinEchoPhaseEncodeNegative == "NONE" ] || [ $SpinEchoPhaseEncodePositive == "NONE" ] ; then
        echo "Based on the the selected distortion correction method (TOPUP), all of the compulsory arguments --SEPhaseNeg and -echospacing MUST be used"
        exit 1;
    fi
fi

if [[ $DistortionCorrection == "SiemensFieldMap" ]] ; then
    if [ X$MagnitudeInputName = X ] && [ X$PhaseInputName = X ] ; then
        echo "Based on the the selected distortion correction method (SiemensFieldMap), all of the compulsory arguments --fmapmag and -fmapphase MUST be used"
        exit 1;
    fi
fi

if [[ $DistortionCorrection == "GeneralElectricFieldMap" ]] ; then
    if [[ X$GEB0InputName = X ]] ; then
        echo "Based on the the selected distortion correction method (GeneralElectricFieldMap), all of the compulsory arguments --fmapgeneralelectric MUST be used"
        exit 1;
    fi
fi

if [ $SliceTimingCorrection -ne 0 ] || [ $smoothingfwhm -ne 0 ]; then
    if [[ X$RepetitionTime = X ]] ; then
        echo "--tr is a compulsory arguments when you select Slice Timing Correction or Spatial Smoothing"
        exit 1;
    fi
fi

if [[ ${MotionCorrectionType} == "EDDY" ]]; then
    if [[ X$EchoSpacing = X ]] ; then
        echo "--echospacing is a compulsory arguments when you select EDDY as a motion correction method"
        exit 1;
    fi
fi

JacobianDefault="true"
if [[ $DistortionCorrection != "TOPUP" ]]
then
    #because the measured fieldmap can cause the warpfield to fold over, default to doing nothing about any jacobians
    JacobianDefault="false"
    #warn if the user specified it
    if [[ $UseJacobian == "true" ]]
    then
        echo "WARNING: using --jacobian=true with --dcmethod other than TOPUP is not recommended, as the distortion warpfield is less stable than TOPUP"
    fi
fi
echo "JacobianDefault: ${JacobianDefault}"

UseJacobian=`opts_DefaultOpt $UseJacobian $JacobianDefault`
echo "After taking default value if necessary, UseJacobian: ${UseJacobian}"


# Setup PATHS

Path="$Path"/"$Subject"

if [ ! -d "$Path" ]; then
    mkdir $Path;
#else
#  Path="${Path}_$(date +"%d-%m-%Y_%H-%M")"
#  mkdir $Path
fi

SubjectFolder="$Path"/analysis
fMRIFolder=${SubjectFolder}/rfMRI

mkdir -p $fMRIFolder
if [ ! -d "$fMRIFolder/raw" ]; then mkdir $fMRIFolder/raw; fi
if [ ! -d "$fMRIFolder/gdc" ]; then mkdir $fMRIFolder/gdc; fi
if [ ! -d "$fMRIFolder/motioncorrection" ]; then mkdir $fMRIFolder/motioncorrection; fi
if [ ! -d "$fMRIFolder/reg" ]; then mkdir $fMRIFolder/reg; fi
if [ ! -d "$fMRIFolder/result" ]; then mkdir $fMRIFolder/result; fi

DCFolderName="EPI_Distortion_Correction"
DCFolder=${fMRIFolder}/${DCFolderName}

#if [ -e ${DCFolder} ] ; then
#    ${RUN} rm -r ${DCFolder}
#fi
#mkdir -p ${DCFolder}
if [ ! -d ${DCFolder} ]; then mkdir ${DCFolder}; fi


#NameOffMRI=$(basename $PathOffMRI)
#NameOffMRI="${NameOffMRI%.*}"
#NameOffMRI="${NameOffMRI%.*}"

echo "OutputDir is $fMRIFolder"
cd $fMRIFolder

#Naming Conventions
NameOffMRI="rfMRI"
T1wImage="T1_biascorr"                                                          #<input T1-weighted image>
T1wRestoreImage="T1_biascorr"                                                   #<input bias-corrected T1-weighted image>
T1wRestoreImageBrain="T1_biascorr_brain"                                        #<input bias-corrected, brain-extracted T1-weighted image>
T1wFolder="anatMRI/T1" #Location of T1w images
BiasField="BiasField_acpc_dc"
ScoutName="Scout"
OrigTCSName="${NameOffMRI}_orig"
OrigSE_Pos_Name="SE_PE_Pos_orig"
OrigSE_Neg_Name="SE_PE_Neg_orig"
OrigTCSName="${NameOffMRI}_orig"
OrigScoutName="${ScoutName}_orig"
MovementRegressor="Movement_Regressors" #No extension, .txt appended
MotionMatrixFolder="MotionMatrices"
MotionMatrixPrefix="MAT_"
fMRI2strOutputTransform="${NameOffMRI}2str"
EddyOutput="eddy_corrected"
RegOutput="Scout2T1w"
QAImage="T1wMulEPI"
JacobianOut="Jacobian"
OutputfMRI2StandardTransform="${NameOffMRI}2standard"
Standard2OutputfMRITransform="standard2${NameOffMRI}"

########################################## DO WORK ##########################################

T1wFolder="$SubjectFolder"/"$T1wFolder"

#Check WM segment exist or no
if [ `$FSLDIR/bin/imtest $T1wFolder/seg/tissue/multi_chan/T1_mc_WM` = 1 ] ; then
    wmseg="$T1wFolder/seg/tissue/multi_chan/T1_mc_WM"
elif [[ `$FSLDIR/bin/imtest $T1wFolder/seg/tissue/sing_chan/T1_pve_WMseg` = 1 ]]; then
    wmseg="$T1wFolder/seg/tissue/sing_chan/T1_pve_WMseg"
fi

$FSLDIR/bin/imcp ${PathOffMRI} ${fMRIFolder}/raw/${OrigTCSName}.nii.gz

#Create fake "Scout" if it doesn't exist
if [ $fMRIScout = "NONE" ] ; then
    ${RUN} ${FSLDIR}/bin/fslroi ${fMRIFolder}/raw/${OrigTCSName} ${fMRIFolder}/raw/${OrigScoutName} 0 1
else
    cp $(dirname $PathOffMRI)/${fMRIScout} ${fMRIFolder}/raw/${OrigScoutName}.nii.gz
fi

if [[ $DistortionCorrection == "TOPUP" ]] ; then

    $FSLDIR/bin/imcp ${SpinEchoPhaseEncodePositive} ${fMRIFolder}/raw/${OrigSE_Pos_Name}
    SpinEchoPhaseEncodePositive=${fMRIFolder}/raw/${OrigSE_Pos_Name}

    $FSLDIR/bin/imcp ${SpinEchoPhaseEncodeNegative} ${fMRIFolder}/raw/${OrigSE_Neg_Name}
    SpinEchoPhaseEncodeNegative=${fMRIFolder}/raw/${OrigSE_Neg_Name}

elif [[ $DistortionCorrection == "NONE" ]] ; then

    $FSLDIR/bin/imcp ${fMRIFolder}/raw/${OrigScoutName}.nii.gz  ${fMRIFolder}/raw/${OrigSE_Pos_Name}
    SpinEchoPhaseEncodePositive=${fMRIFolder}/raw/${OrigSE_Pos_Name}

    $FSLDIR/bin/imcp ${fMRIFolder}/raw/${OrigScoutName}.nii.gz  ${fMRIFolder}/raw/${OrigSE_Neg_Name}
    SpinEchoPhaseEncodeNegative=${fMRIFolder}/raw/${OrigSE_Neg_Name}

fi


echo "Gradient Distortion Correction of fMRI"
if [ ! $GradientDistortionCoeffs = "NONE" ] ; then
    echo "PERFORMING GRADIENT DISTORTION CORRECTION"
else
    echo "NOT PERFORMING GRADIENT DISTORTION CORRECTION"

    ${RUN} ${FSLDIR}/bin/imcp ${fMRIFolder}/raw/${OrigTCSName} ${fMRIFolder}/gdc/${NameOffMRI}_gdc
    ${RUN} ${FSLDIR}/bin/fslroi ${fMRIFolder}/gdc/${NameOffMRI}_gdc ${fMRIFolder}/gdc/${NameOffMRI}_gdc_warp 0 3
    ${RUN} ${FSLDIR}/bin/fslmaths ${fMRIFolder}/gdc/${NameOffMRI}_gdc_warp -mul 0 ${fMRIFolder}/gdc/${NameOffMRI}_gdc_warp
    ${RUN} ${FSLDIR}/bin/imcp ${fMRIFolder}/raw/${OrigScoutName} ${fMRIFolder}/gdc/${ScoutName}_gdc
    #make fake jacobians of all 1s, for completeness
    ${RUN} ${FSLDIR}/bin/fslmaths ${fMRIFolder}/raw/${OrigScoutName} -mul 0 -add 1 ${fMRIFolder}/gdc/${ScoutName}_gdc_warp_jacobian
    ${RUN} ${FSLDIR}/bin/fslroi ${fMRIFolder}/gdc/${NameOffMRI}_gdc_warp ${fMRIFolder}/gdc/${NameOffMRI}_gdc_warp_jacobian 0 1
    ${RUN} ${FSLDIR}/bin/fslmaths ${fMRIFolder}/gdc/${NameOffMRI}_gdc_warp_jacobian -mul 0 -add 1 ${fMRIFolder}/gdc/${NameOffMRI}_gdc_warp_jacobian
fi


# EPI Distortion Correction
echo "EPI Distortion Correction"
if [ ! $DistortionCorrection = "NONE" ] ; then
    echo "Performing EPI Distortion Correction"

    ${RUN} ${BRC_FMRI_SCR}/EPI_Distortion_Correction.sh \
           --workingdir=${DCFolder} \
           --scoutin=${fMRIFolder}/gdc/${ScoutName}_gdc \
           --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
           --SEPhasePos=${SpinEchoPhaseEncodePositive} \
           --echospacing=${EchoSpacing} \
           --unwarpdir=${UnwarpDir} \
           --gdcoeffs=${GradientDistortionCoeffs} \
           --method=${DistortionCorrection}
else
    echo "NOT Performing EPI Distortion CorrectionN"

    ${RUN} ${FSLDIR}/bin/fslroi ${fMRIFolder}/gdc/${NameOffMRI}_gdc ${DCFolder}/WarpField.nii.gz 0 3
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/WarpField.nii.gz -mul 0 ${DCFolder}/WarpField.nii.gz

    ${RUN} ${FSLDIR}/bin/fslroi ${DCFolder}/WarpField.nii.gz ${DCFolder}/Jacobian.nii.gz 0 1
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/Jacobian.nii.gz -mul 0 -add 1 ${DCFolder}/Jacobian.nii.gz

    ${FSLDIR}/bin/imcp ${fMRIFolder}/gdc/${ScoutName}_gdc ${DCFolder}/SBRef_dc
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/SBRef_dc -mul 0 -add 1 ${DCFolder}/PhaseOne_gdc_dc
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/SBRef_dc -mul 0 -add 1 ${DCFolder}/PhaseTwo_gdc_dc
fi

echo "MOTION CORRECTION"

case $MotionCorrectionType in

    MCFLIRT)
        ${RUN} ${BRC_FMRI_SCR}/MotionCorrection.sh \
              --workingdir=${fMRIFolder}/motioncorrection \
              --inputfmri=${fMRIFolder}/gdc/${NameOffMRI}_gdc \
              --scoutin=${fMRIFolder}/gdc/${ScoutName}_gdc \
              --outputfmri=${fMRIFolder}/motioncorrection/${NameOffMRI}_mc \
              --outputmotionregressors=${fMRIFolder}/motioncorrection/${MovementRegressor} \
              --outputmotionmatrixfolder=${fMRIFolder}/motioncorrection/${MotionMatrixFolder} \
              --outputmotionmatrixnameprefix=${MotionMatrixPrefix} \
              --motioncorrectiontype=${MotionCorrectionType}
    ;;

    EDDY)
        ${RUN} ${BRC_FMRI_SCR}/EddyPreprocessing.sh \
              --workingdir=${fMRIFolder}/Eddy \
              --inputfile=${fMRIFolder}/gdc/${NameOffMRI}_gdc \
              --fmriname=${NameOffMRI} \
              --dcmethod=${DistortionCorrection} \
              --dcfolder=${DCFolder} \
              --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
              --SEPhasePos=${SpinEchoPhaseEncodePositive} \
              --unwarpdir=${UnwarpDir} \
              --echospacing=${EchoSpacing} \
              --slice2vol=${Slice2Volume} \
              --slspec=${SliceSpec} \
              --output_eddy=${EddyOutput} \
              --outfolder=${DCFolder}
    ;;

    *)
        echo "UNKNOWN MOTION CORRECTION METHOD: ${MotionCorrectionType}"
        exit 1
esac


if [ $SliceTimingCorrection -ne 0 ]; then

    if [[ ${MotionCorrectionType} == "MCFLIRT" ]]; then
        STC_Input=${fMRIFolder}/gdc/${NameOffMRI}_gdc
    else
        STC_Input=${fMRIFolder}/Eddy/${EddyOutput}
    fi

    echo "Slice Timing Correction"
    ${RUN} ${BRC_FMRI_SCR}/Slice_Timing_Correction.sh \
          --workingdir=${fMRIFolder}/Slice_time_corr \
          --infmri=${STC_Input} \
          --repetitiontime=${RepetitionTime} \
          --stc_method=${SliceTimingCorrection} \
          --ofmri=${fMRIFolder}/Slice_time_corr/${NameOffMRI}_stc
fi


${RUN} ${BRC_FMRI_SCR}/EPI_2_T1_Registration.sh \
      --workingdir=${DCFolder} \
      --fmrifolder=${fMRIFolder} \
      --scoutin=${fMRIFolder}/gdc/${ScoutName}_gdc \
      --t1=${T1wFolder}/preprocess/T1_biascorr \
      --t1brain=${T1wFolder}/preprocess/${T1wRestoreImageBrain} \
      --wmseg=$wmseg \
      --dof=${dof} \
      --method=${DistortionCorrection} \
      --biascorrection=${BiasCorrection} \
      --subjectfolder=${SubjectFolder} \
      --fmriname=${NameOffMRI} \
      --usejacobian=${UseJacobian} \
      --motioncorrectiontype=${MotionCorrectionType} \
      --eddyoutname=${EddyOutput} \
      --oregim=${fMRIFolder}/reg/${RegOutput} \
      --owarp=${fMRIFolder}/reg/${fMRI2strOutputTransform} \
      --ojacobian=${fMRIFolder}/reg/${JacobianOut}


#One Step Resampling
echo "One Step Resampling"

if [[ ${MotionCorrectionType} == "MCFLIRT" ]]; then
    fMRI_2_str_Input=${fMRIFolder}/reg/${fMRI2strOutputTransform}
else
    fMRI_2_str_Input=${fMRIFolder}/Eddy/${EddyOutput}
fi

${RUN} ${BRC_FMRI_SCR}/One_Step_Resampling.sh \
      --workingdir=${fMRIFolder}/One_Step_Resampling \
      --infmri=${fMRIFolder}/raw/${OrigTCSName}.nii.gz \
      --scoutin=${fMRIFolder}/raw/${OrigScoutName} \
      --scoutgdcin=${fMRIFolder}/gdc/${ScoutName}_gdc \
      --fmrifolder=${fMRIFolder} \
      --t1=${T1wFolder}/reg/nonlin/T1_2_std_warp \
      --freesurferbrainmask=${T1wFolder}/preprocess/T1_biascorr_brain_mask \
      --fmriresout=${FinalfMRIResolution} \
      --gdfield=${fMRIFolder}/gdc/${NameOffMRI}_gdc_warp \
      --fmri2structin=${fMRIFolder}/reg/${fMRI2strOutputTransform} \
      --struct2std=${T1wFolder}/reg/nonlin/T1_2_std_warp_field \
      --motioncorrectiontype=${MotionCorrectionType} \
      --motionmatdir=${fMRIFolder}/motioncorrection/${MotionMatrixFolder} \
      --motionmatprefix=${MotionMatrixPrefix} \
      --owarp=${fMRIFolder}/reg/${OutputfMRI2StandardTransform} \
      --oiwarp=${fMRIFolder}/reg/${Standard2OutputfMRITransform} \
      --ofmri=${fMRIFolder}/One_Step_Resampling/${NameOffMRI}_nonlin \
      --oscout=${fMRIFolder}/One_Step_Resampling/${NameOffMRI}_SBRef_nonlin \
      --ojacobian=${fMRIFolder}/One_Step_Resampling/${JacobianOut}_MNI.${FinalfMRIResolution}
      #      --biasfield=${AtlasSpaceFolder}/${BiasFieldMNI} \


ResultsFolder=${fMRIFolder}/result

if [[ ${DistortionCorrection} == "TOPUP" ]]
then
    #create MNI space corrected fieldmap images
#    ${FSLDIR}/bin/applywarp --rel --interp=spline --in=${DCFolder}/PhaseOne_gdc_dc_unbias -w $T1wFolder/reg/nonlin/T1_2_std_warp_field -r ${fMRIFolder}/${NameOffMRI}_SBRef_nonlin -o ${ResultsFolder}/${NameOffMRI}_PhaseOne_gdc_dc
#    ${FSLDIR}/bin/applywarp --rel --interp=spline --in=${DCFolder}/PhaseTwo_gdc_dc_unbias -w $T1wFolder/reg/nonlin/T1_2_std_warp_field -r ${fMRIFolder}/${NameOffMRI}_SBRef_nonlin -o ${ResultsFolder}/${NameOffMRI}_PhaseTwo_gdc_dc

    #create MNINonLinear final fMRI resolution bias field outputs
    if [[ ${BiasCorrection} == "SEBASED" ]]
    then
        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${DCFolder}/Compute_SE_BiasField/sebased_bias_dil.nii.gz -r ${fMRIFolder}/One_Step_Resampling/${NameOffMRI}_SBRef_nonlin -w ${T1wFolder}/reg/nonlin/T1_2_std_warp_field -o ${DCFolder}/Compute_SE_BiasField/${NameOffMRI}2std_sebased_bias.nii.gz
        ${FSLDIR}/bin/fslmaths ${DCFolder}/Compute_SE_BiasField/${NameOffMRI}2std_sebased_bias.nii.gz -mas ${fMRIFolder}/One_Step_Resampling/${T1wRestoreImageBrain}_mask.${FinalfMRIResolution}.nii.gz ${DCFolder}/Compute_SE_BiasField/${NameOffMRI}2std_sebased_bias.nii.gz

        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${DCFolder}/Compute_SE_BiasField/sebased_reference_dil.nii.gz -r ${fMRIFolder}/One_Step_Resampling/${NameOffMRI}_SBRef_nonlin -w ${T1wFolder}/reg/nonlin/T1_2_std_warp_field -o ${DCFolder}/Compute_SE_BiasField/${NameOffMRI}2std_sebased_reference.nii.gz
        ${FSLDIR}/bin/fslmaths ${DCFolder}/Compute_SE_BiasField/${NameOffMRI}2std_sebased_reference.nii.gz -mas ${fMRIFolder}/One_Step_Resampling/${T1wRestoreImageBrain}_mask.${FinalfMRIResolution}.nii.gz ${DCFolder}/Compute_SE_BiasField/${NameOffMRI}2std_sebased_reference.nii.gz

        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${DCFolder}/Compute_SE_BiasField/${NameOffMRI}_dropouts.nii.gz -r ${fMRIFolder}/One_Step_Resampling/${NameOffMRI}_SBRef_nonlin -w ${T1wFolder}/reg/nonlin/T1_2_std_warp_field -o ${DCFolder}/Compute_SE_BiasField/${NameOffMRI}2std_dropouts.nii.gz
    fi
fi


if [ $smoothingfwhm -ne 0 ]; then

#    OUT_SPACE="std"
    OUT_SPACE="func"

    if [[ ${OUT_SPACE} == "func" ]]; then

        if [ $SliceTimingCorrection -ne 0 ]; then
            SSNR_Input=${fMRIFolder}/Slice_time_corr/${NameOffMRI}_stc
        else
            if [[ ${MotionCorrectionType} == "MCFLIRT" ]]; then
                SSNR_Input=${fMRIFolder}/gdc/${NameOffMRI}_gdc
            else
                SSNR_Input=${fMRIFolder}/Eddy/${EddyOutput}
            fi
        fi

        SSNR_InputMask=${fMRIFolder}/gdc/${ScoutName}_gdc_mask

    else

        SSNR_Input=${fMRIFolder}/One_Step_Resampling/${NameOffMRI}_nonlin
        SSNR_InputMask=${SSNR_Input}_mask

    fi

    echo "Spatial Smoothing and Artifact/Physiological Noise Removal"
    ${RUN} ${BRC_FMRI_SCR}/Spatial_Smoothing_Noise_Removal.sh \
          --workingdir=${fMRIFolder}/Noise_removal \
          --infmri=${SSNR_Input} \
          --infmrimask=${SSNR_InputMask} \
          --fmriname=${NameOffMRI} \
          --fwhm=${smoothingfwhm} \
          --repetitiontime=${RepetitionTime} \
          --motionparam=${fMRIFolder}/motioncorrection/${NameOffMRI}_mc.par \
          --fmri2structin=${DCFolder}/fMRI2str.mat \
          --struct2std=${T1wFolder}/reg/nonlin/T1_2_std_warp_field.nii.gz \
          --motioncorrectiontype=${MotionCorrectionType} \
          --outspace=${OUT_SPACE}

fi

: <<'COMMENT'

if [[ $Do_intensity_norm == yes ]]; then
    echo "Intensity Normalization and Bias Removal"
    ${RUN} ${BRC_FMRI_SCR}/Intensity_Normalization.sh \
          --workingdir=${fMRIFolder}/Intensity_norm \
          --infmri=${fMRIFolder}/One_Step_Resampling/${NameOffMRI}_nonlin \   "???????????????????????????"
          --biasfield=${ResultsFolder}/${NameOffMRI}_sebased_bias.nii.gz \
          --jacobian=${fMRIFolder}/One_Step_Resampling/${JacobianOut}_MNI.${FinalfMRIResolution} \
          --brainmask=${fMRIFolder}/One_Step_Resampling/${T1wRestoreImageBrain}_mask.${FinalfMRIResolution} \
          --inscout=${fMRIFolder}/One_Step_Resampling/${NameOffMRI}_SBRef_nonlin \
          --ofmri=${NameOffMRI}_nonlin_norm \
          --oscout=${NameOffMRI}_SBRef_nonlin_norm \
          --usejacobian=${UseJacobian}
fi


: <<'COMMENT'

matlab -nojvm -nodesktop -r "generate_eddy_affine_xfm('/home/mszam12/main/analysis/Sub_001/analysis/rfMRI/motioncorrection/' , 'rfMRI_mc.par'); exit"

${RUN} cp -r ${fMRIFolder}/${NameOffMRI}_nonlin_norm.nii.gz ${ResultsFolder}/${NameOffMRI}.nii.gz
${RUN} cp -r ${fMRIFolder}/motioncorrection/${MovementRegressor}.txt ${ResultsFolder}/${MovementRegressor}.txt
${RUN} cp -r ${fMRIFolder}/motioncorrection/${MovementRegressor}_dt.txt ${ResultsFolder}/${MovementRegressor}_dt.txt
${RUN} cp -r ${fMRIFolder}/${NameOffMRI}_SBRef_nonlin_norm.nii.gz ${ResultsFolder}/${NameOffMRI}_SBRef.nii.gz
${RUN} cp -r ${fMRIFolder}/${JacobianOut}_MNI.${FinalfMRIResolution}.nii.gz ${ResultsFolder}/${NameOffMRI}_${JacobianOut}.nii.gz
${RUN} cp -r ${fMRIFolder}/One_Step_Resampling/${T1wRestoreImageBrain}_mask.${FinalfMRIResolution}.nii.gz ${ResultsFolder}
###Add stuff for RMS###
${RUN} cp -r ${fMRIFolder}/Movement_RelativeRMS.txt ${ResultsFolder}/Movement_RelativeRMS.txt
${RUN} cp -r ${fMRIFolder}/Movement_AbsoluteRMS.txt ${ResultsFolder}/Movement_AbsoluteRMS.txt
${RUN} cp -r ${fMRIFolder}/Movement_RelativeRMS_mean.txt ${ResultsFolder}/Movement_RelativeRMS_mean.txt
${RUN} cp -r ${fMRIFolder}/Movement_AbsoluteRMS_mean.txt ${ResultsFolder}/Movement_AbsoluteRMS_mean.txt

echo "Completed"

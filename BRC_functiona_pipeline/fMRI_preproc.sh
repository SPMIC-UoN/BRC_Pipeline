#!/bin/bash
# Last update: 11/10/2018

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
  echo "                                      Set to NONE if you want to use the first volume of the timeseries for motion correction"
  echo " --mctype <Type>                      Type of motion correction. Values: MCFLIRT: between volumes (default), and EDDY: within/between volumes"
  echo " --slice2vol                          If one wants to do slice-to-volome motion correction"
  echo " --slspec <json path>                 Specifies a .json file (created by your DICOM->niftii conversion software) that describes how the"
  echo "                                      slices/multi-band-groups were acquired. This file is necessary when using the slice-to-vol movement correction"
  echo " --fmapmag <data path>                Expects 4D Magnitude volume with two 3D volumes (differing echo times). Set to NONE (default) if using TOPUP"
  echo " --fmapphase <data path>              Expects a 3D Phase difference volume (Siemens style). Set to NONE (default) if using TOPUP"
  echo " --fmapgeneralelectric                Path to General Electric style B0 fieldmap with two volumes"
  echo "                                           1. field map in degrees"
  echo "                                           2. magnitude"
  echo "                                      Set to 'NONE' (default) if not using 'GeneralElectricFieldMap' as the value for the DistortionCorrection variable"
  echo " --echodiff <value>                   Set to NONE if using TOPUP"
  echo " --SEPhaseNeg <Image path>            For the spin echo field map volume with a 'negative' phase encoding direction"
  echo "                                      Set to NONE if using regular FIELDMAP"
  echo " --SEPhasePos <Image path>            For the spin echo field map volume with a 'positive' phase encoding direction"
  echo "                                      Set to NONE if using regular FIELDMAP"
  echo " --echospacing <value>                Effective Echo Spacing of fMRI image (specified in *sec* for the fMRI processing)"
  echo " --unwarpdir <direction>              ‌Based on Phase Encoding Direction: PA: 'y', AP: 'y-', RL: 'x', and LR: 'x-'"
  echo " --dcmethod <method>                  Susceptibility distortion correction method (required for accurate processing)"
  echo "                                      Values: TOPUP, SiemensFieldMap (same as FIELDMAP), GeneralElectricFieldMap, and NONE (default)"
  echo " --biascorrection <method>            Receive coil bias field correction method"
  echo "                                      Values: NONE, or SEBASED (Spin-Echo Based)"
  echo "                                      SEBASED calculates bias field from spin echo images (which requires TOPUP distortion correction)"
  echo " --intensitynorm                      If one wants to do intensity normalization"
  echo " --stcmethod <method>                 Slice timing correction method"
  echo "                                           0: NONE (default value),"
  echo "                                           1: If the slices were acquired with interleaved order (0, 2, 4 ... 1, 3, 5 ...),"
  echo "                                           2: If slices were acquired with forward order (0, 1, 2, ...), and"
  echo "                                           3: If slices were acquired with backward order (n, n-1, n-2, ...)"
  echo " --fwhm <value>                       Spatial size (sigma, i.e., half-width) of smoothing, in mm. Set to 0 (default) for no spatial smooting"
  echo "                                      Non-zero value of this option, automatically enables ICA-AROMA for Artifact/Physiological Noise Removal"
  echo " --fmrires <value>                    Target final resolution of fMRI data in mm (default is 2 mm)"
  echo " --tempfilter <value>                 Non-zero value of this option means that one wants to do temporal filtering with High pass filter curoff <value> in Sec"
  echo "                                      default value is 0, means No Temporal Filtering"
  echo " --printcom                           use 'echo' for just printing everything and not running the commands (default is to run)"
  echo " -h | --help                          help"
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi

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
Temp_Filter_Cutoff=0

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

      --intensitynorm )       Do_intensity_norm="yes"
                              ;;

      --tempfilter )          shift
                              Temp_Filter_Cutoff=$1
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

      * )                     Usage
                              exit 1

    esac
    shift
done

${RUN} ${BRCDIR}/Show_version.sh --showdiff="no"
Start_Time="$(date -u +%s)"

#=====================================================================================
###                          Sanity checking of arguments
#=====================================================================================
if [ X$Path = X ] || [ X$Subject = X ] || [ X$PathOffMRI = X ] ; then
    echo ""
    echo "All of the compulsory arguments --path, -subject and -fmripath MUST be used"
    echo ""
    exit 1;
fi

if [[ $DistortionCorrection == "TOPUP" ]] ; then
    if [ X$SpinEchoPhaseEncodeNegative = X ] || [ X$SpinEchoPhaseEncodePositive = X ] || [ X$EchoSpacing = X ] || [ X$UnwarpDir = X ] ; then
        echo ""
        echo "Based on the the selected distortion correction method (TOPUP), all of the compulsory arguments --SEPhaseNeg, -echospacing, and -unwarpdir MUST be used"
        echo ""
        exit 1;
    fi

    if [ $SpinEchoPhaseEncodeNegative == "NONE" ] || [ $SpinEchoPhaseEncodePositive == "NONE" ] ; then
        echo ""
        echo "Based on the the selected distortion correction method (TOPUP), all of the compulsory arguments --SEPhaseNeg and -echospacing MUST be used"
        echo ""
        exit 1;
    fi
fi

if [[ $DistortionCorrection == "SiemensFieldMap" ]] ; then
    if [ X$MagnitudeInputName = X ] || [ X$PhaseInputName = X ] ; then
        echo ""
        echo "Based on the the selected distortion correction method (SiemensFieldMap), all of the compulsory arguments --fmapmag and -fmapphase MUST be used"
        echo ""
        exit 1;
    fi
fi

if [[ $DistortionCorrection == "GeneralElectricFieldMap" ]] ; then
    if [[ X$GEB0InputName = X ]] ; then
        echo ""
        echo "Based on the the selected distortion correction method (GeneralElectricFieldMap), all of the compulsory arguments --fmapgeneralelectric MUST be used"
        echo ""
        exit 1;
    fi
fi

if [[ ${MotionCorrectionType} == "EDDY" ]]; then
    if [[ X$EchoSpacing = X ]] ; then
        echo ""
        echo "--echospacing is a compulsory arguments when you select EDDY as a motion correction method"
        echo ""
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
        echo ""
        echo "WARNING: using --jacobian=true with --dcmethod other than TOPUP is not recommended, as the distortion warpfield is less stable than TOPUP"
        echo ""
    fi
fi
echo "JacobianDefault: ${JacobianDefault}"

UseJacobian=`opts_DefaultOpt $UseJacobian $JacobianDefault`
echo "After taking default value if necessary, UseJacobian: ${UseJacobian}"

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

rawFolderName="raw"
gdcFolderName="gdc"
mcFolderName="mc"
regFolderName="reg"
stcFolderName="Slice_time_corr"
nrFolderName="Noise_removal"
DCFolderName="EPI_Distortion_Correction"
eddyFolderName="Eddy"
osrFolderName="One_Step_Resampling"
sebfFolderName="Compute_SE_BiasField"
InNormfFolderName="Intensity_norm"
UnlabeledFolderName="unlabeled"
processedFolderName="processed"
figsFolderName="figs"
tempfiltFolderName="temp_filt"

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

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

Path="$Path"/"$Subject"

if [ ! -d "$Path" ]; then
    mkdir $Path;
#else
#  Path="${Path}_$(date +"%d-%m-%Y_%H-%M")"
#  mkdir $Path
fi

SubjectFolder="$Path"/analysis
rfMRIFolder=${SubjectFolder}/rfMRI
fMRIFolder=${rfMRIFolder}/unlabeled

if [ ! -e "${SubjectFolder}/anatMRI/T1" ] ; then
    echo ""
    echo "Functional preprocessing depends on the outputs generated by Structural preprocessing. So functional"
    echo "preprocessing should not be attempted on data sets for which structural preprocessing is not yet complete."
    echo ""
    exit;
fi

rawFolder=${fMRIFolder}/${rawFolderName}
gdcFolder=${fMRIFolder}/${gdcFolderName}
mcFolder=${fMRIFolder}/${mcFolderName}
regFolder=${fMRIFolder}/${regFolderName}
stcFolder=${fMRIFolder}/${stcFolderName}
nrFolder=${fMRIFolder}/${nrFolderName}
DCFolder=${fMRIFolder}/${DCFolderName}
EddyFolder=${fMRIFolder}/${eddyFolderName}
OsrFolder=${fMRIFolder}/${osrFolderName}
SE_BF_Folder=${DCFolder}/${sebfFolderName}
In_Nrm_Folder=${fMRIFolder}/${InNormfFolderName}
Tmp_Filt_Folder=${fMRIFolder}/${tempfiltFolderName}

mkdir -p $fMRIFolder
if [ ! -d "$rawFolder" ]; then mkdir $rawFolder; fi
if [ ! -d "$gdcFolder" ]; then mkdir $gdcFolder; fi
if [ ! -d "$mcFolder" ]; then mkdir $mcFolder; fi
if [ ! -d "$regFolder" ]; then mkdir $regFolder; fi
if [ ! -d "$Tmp_Filt_Folder" ]; then mkdir $Tmp_Filt_Folder; fi

#if [ -e "${fMRIFolder}/Slice_time_corr" ] ; then
#    ${RUN} rm -r ${fMRIFolder}/Slice_time_corr
#fi
#mkdir ${fMRIFolder}/Slice_time_corr
if [ ! -d "$stcFolder" ]; then mkdir $stcFolder; fi

#if [ -e "${fMRIFolder}/Noise_removal" ] ; then
#    ${RUN} rm -r ${fMRIFolder}/Noise_removal
#fi
#mkdir ${fMRIFolder}/Noise_removal
if [ ! -d "$nrFolder" ]; then mkdir $nrFolder; fi

#if [ -e ${In_Nrm_Folder} ] ; then
#    ${RUN} rm -r ${In_Nrm_Folder}
#fi
#mkdir -p $In_Nrm_Folder
if [ ! -d "$In_Nrm_Folder" ]; then mkdir $In_Nrm_Folder; fi

#if [ -e ${DCFolder} ] ; then
#    ${RUN} rm -r ${DCFolder}
#fi
#mkdir -p ${DCFolder}
if [ ! -d ${DCFolder} ]; then mkdir ${DCFolder}; fi


echo "OutputDir is $fMRIFolder"
cd $fMRIFolder


#=====================================================================================
###                                   DO WORK
#=====================================================================================

T1wFolder=${SubjectFolder}/${T1wFolder}

#Check WM segment exist or no
if [ `$FSLDIR/bin/imtest $T1wFolder/seg/tissue/multi_chan/T1_mc_WM` = 1 ] ; then
    wmseg="$T1wFolder/seg/tissue/multi_chan/T1_mc_WM"
elif [[ `$FSLDIR/bin/imtest $T1wFolder/seg/tissue/sing_chan/T1_pve_WMseg` = 1 ]]; then
    wmseg="$T1wFolder/seg/tissue/sing_chan/T1_pve_WMseg"
fi

$FSLDIR/bin/imcp ${PathOffMRI} ${rawFolder}/${OrigTCSName}.nii.gz

#Create fake "Scout" if it doesn't exist
if [ $fMRIScout = "NONE" ] ; then
    ${RUN} ${FSLDIR}/bin/fslroi ${rawFolder}/${OrigTCSName} ${rawFolder}/${OrigScoutName} 0 1
else
    cp $(dirname $PathOffMRI)/${fMRIScout} ${rawFolder}/${OrigScoutName}.nii.gz
fi

if [[ $DistortionCorrection == "TOPUP" ]] ; then

    $FSLDIR/bin/imcp ${SpinEchoPhaseEncodePositive} ${rawFolder}/${OrigSE_Pos_Name}
    SpinEchoPhaseEncodePositive=${rawFolder}/${OrigSE_Pos_Name}

    $FSLDIR/bin/imcp ${SpinEchoPhaseEncodeNegative} ${rawFolder}/${OrigSE_Neg_Name}
    SpinEchoPhaseEncodeNegative=${rawFolder}/${OrigSE_Neg_Name}

elif [[ $DistortionCorrection == "NONE" ]] ; then

    $FSLDIR/bin/imcp ${rawFolder}/${OrigScoutName}.nii.gz  ${rawFolder}/${OrigSE_Pos_Name}
    SpinEchoPhaseEncodePositive=${rawFolder}/${OrigSE_Pos_Name}

    $FSLDIR/bin/imcp ${rawFolder}/${OrigScoutName}.nii.gz  ${rawFolder}/${OrigSE_Neg_Name}
    SpinEchoPhaseEncodeNegative=${rawFolder}/${OrigSE_Neg_Name}

fi


echo "Gradient Distortion Correction of fMRI"
if [ ! $GradientDistortionCoeffs = "NONE" ] ; then
    echo "PERFORMING GRADIENT DISTORTION CORRECTION"
else
    echo "NOT PERFORMING GRADIENT DISTORTION CORRECTION"

    ${RUN} ${FSLDIR}/bin/imcp ${rawFolder}/${OrigTCSName} ${gdcFolder}/${NameOffMRI}_gdc
    ${RUN} ${FSLDIR}/bin/fslroi ${gdcFolder}/${NameOffMRI}_gdc ${gdcFolder}/${NameOffMRI}_gdc_warp 0 3
    ${RUN} ${FSLDIR}/bin/fslmaths ${gdcFolder}/${NameOffMRI}_gdc_warp -mul 0 ${gdcFolder}/${NameOffMRI}_gdc_warp
    ${RUN} ${FSLDIR}/bin/imcp ${rawFolder}/${OrigScoutName} ${gdcFolder}/${ScoutName}_gdc
    #make fake jacobians of all 1s, for completeness
    ${RUN} ${FSLDIR}/bin/fslmaths ${rawFolder}/${OrigScoutName} -mul 0 -add 1 ${gdcFolder}/${ScoutName}_gdc_warp_jacobian
    ${RUN} ${FSLDIR}/bin/fslroi ${gdcFolder}/${NameOffMRI}_gdc_warp ${gdcFolder}/${NameOffMRI}_gdc_warp_jacobian 0 1
    ${RUN} ${FSLDIR}/bin/fslmaths ${gdcFolder}/${NameOffMRI}_gdc_warp_jacobian -mul 0 -add 1 ${gdcFolder}/${NameOffMRI}_gdc_warp_jacobian
fi


# EPI Distortion Correction
echo "EPI Distortion Correction"
if [ ! $DistortionCorrection = "NONE" ] ; then
    echo "Performing EPI Distortion Correction"

#    ${RUN} ${BRC_FMRI_SCR}/EPI_Distortion_Correction.sh \
#           --workingdir=${DCFolder} \
#           --scoutin=${gdcFolder}/${ScoutName}_gdc \
#           --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
#           --SEPhasePos=${SpinEchoPhaseEncodePositive} \
#           --echospacing=${EchoSpacing} \
#           --unwarpdir=${UnwarpDir} \
#           --gdcoeffs=${GradientDistortionCoeffs} \
#           --method=${DistortionCorrection}
else
    echo "NOT Performing EPI Distortion Correction"

    ${RUN} ${FSLDIR}/bin/fslroi ${gdcFolder}/${NameOffMRI}_gdc ${DCFolder}/WarpField.nii.gz 0 3
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/WarpField.nii.gz -mul 0 ${DCFolder}/WarpField.nii.gz

    ${RUN} ${FSLDIR}/bin/fslroi ${DCFolder}/WarpField.nii.gz ${DCFolder}/Jacobian.nii.gz 0 1
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/Jacobian.nii.gz -mul 0 -add 1 ${DCFolder}/Jacobian.nii.gz

    ${FSLDIR}/bin/imcp ${gdcFolder}/${ScoutName}_gdc ${DCFolder}/SBRef_dc
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/SBRef_dc -mul 0 -add 1 ${DCFolder}/PhaseOne_gdc_dc
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/SBRef_dc -mul 0 -add 1 ${DCFolder}/PhaseTwo_gdc_dc
fi

echo "MOTION CORRECTION"

case $MotionCorrectionType in

    MCFLIRT)
        STC_Input=${mcFolder}/${NameOffMRI}_mc
        SSNR_motionparam=${mcFolder}/${NameOffMRI}_mc.par
        fMRI_2_str_Input=${regFolder}/${fMRI2strOutputTransform}
        OSR_Scout_In=${gdcFolder}/${ScoutName}_gdc

        ${RUN} ${BRC_FMRI_SCR}/MotionCorrection.sh \
              --workingdir=${mcFolder} \
              --inputfmri=${gdcFolder}/${NameOffMRI}_gdc \
              --scoutin=${gdcFolder}/${ScoutName}_gdc \
              --outputfmri=${mcFolder}/${NameOffMRI}_mc \
              --outputmotionregressors=${mcFolder}/${MovementRegressor} \
              --outputmotionmatrixfolder=${mcFolder}/${MotionMatrixFolder} \
              --outputmotionmatrixnameprefix=${MotionMatrixPrefix} \
              --motioncorrectiontype=${MotionCorrectionType}
    ;;

    EDDY)
        STC_Input=${EddyFolder}/${EddyOutput}
        SSNR_motionparam=${EddyFolder}/${EddyOutput}.eddy_parameters
        fMRI_2_str_Input=${EddyFolder}/${EddyOutput}
        OSR_Scout_In=${EddyFolder}/SBRef_dc

#        ${RUN} ${BRC_FMRI_SCR}/EddyPreprocessing.sh \
#              --workingdir=${EddyFolder} \
#              --inputfile=${gdcFolder}/${NameOffMRI}_gdc \
#              --inscout=${gdcFolder}/${ScoutName}_gdc \
#              --fmriname=${NameOffMRI} \
#              --dcmethod=${DistortionCorrection} \
#              --dcfolder=${DCFolder} \
#              --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
#              --SEPhasePos=${SpinEchoPhaseEncodePositive} \
#              --unwarpdir=${UnwarpDir} \
#              --echospacing=${EchoSpacing} \
#              --slice2vol=${Slice2Volume} \
#              --slspec=${SliceSpec} \
#              --output_eddy=${EddyOutput} \
#              --outfolder=${DCFolder}
  ;;

    *)
        echo "UNKNOWN MOTION CORRECTION METHOD: ${MotionCorrectionType}"
        exit 1
esac


if [ $SliceTimingCorrection -ne 0 ]; then

    echo "Slice Timing Correction"
#    ${RUN} ${BRC_FMRI_SCR}/Slice_Timing_Correction.sh \
#          --workingdir=${stcFolder} \
#          --infmri=${STC_Input} \
#          --stc_method=${SliceTimingCorrection} \
#          --ofmri=${stcFolder}/${NameOffMRI}_stc

else

    echo "NOT Performing Slice Timing Correction"
    ${FSLDIR}/bin/imcp ${STC_Input} ${stcFolder}/${NameOffMRI}_stc
fi


#${RUN} ${BRC_FMRI_SCR}/EPI_2_T1_Registration.sh \
#      --workingdir=${DCFolder} \
#      --fmriname=${NameOffMRI} \
#      --subjectfolder=${SubjectFolder} \
#      --fmrifolder=${fMRIFolder} \
#      --scoutin=${gdcFolder}/${ScoutName}_gdc \
#      --t1=${T1wFolder}/preprocess/T1_biascorr \
#      --t1brain=${T1wFolder}/preprocess/${T1wRestoreImageBrain} \
#      --wmseg=$wmseg \
#      --dof=${dof} \
#      --method=${DistortionCorrection} \
#      --biascorrection=${BiasCorrection} \
#      --usejacobian=${UseJacobian} \
#      --motioncorrectiontype=${MotionCorrectionType} \
#      --eddyoutname=${EddyOutput} \
#      --oregim=${regFolder}/${RegOutput} \
#      --owarp=${regFolder}/${fMRI2strOutputTransform} \
#      --ojacobian=${regFolder}/${JacobianOut}


if [ $smoothingfwhm -ne 0 ]; then

    echo "Spatial Smoothing and Artifact/Physiological Noise Removal"

#    ${RUN} ${BRC_FMRI_SCR}/Spatial_Smoothing_Noise_Removal.sh \
#          --workingdir=${nrFolder} \
#          --infmri=${stcFolder}/${NameOffMRI}_stc \
#          --fmriname=${NameOffMRI} \
#          --fwhm=${smoothingfwhm} \
#          --motionparam=${SSNR_motionparam} \
#          --fmri2structin=${DCFolder}/fMRI2str.mat \
#          --struct2std=${T1wFolder}/reg/nonlin/T1_2_std_warp_field.nii.gz \
#          --motioncorrectiontype=${MotionCorrectionType}

    ${FSLDIR}/bin/imcp ${nrFolder}/ICA_AROMA/mask ${nrFolder}/ICA_AROMA/denoised_func_data_nonaggr_mask

else

    echo "Not performing Spatial Smoothing and Artifact/Physiological Noise Removal"
    mkdir ${nrFolder}/ICA_AROMA
    ${FSLDIR}/bin/imcp ${stcFolder}/${NameOffMRI}_stc ${nrFolder}/ICA_AROMA/denoised_func_data_nonaggr
fi


echo "One Step Resampling"

#${RUN} ${BRC_FMRI_SCR}/One_Step_Resampling.sh \
#      --workingdir=${OsrFolder} \
#      --scoutgdcin=${OSR_Scout_In} \
#      --gdfield=${gdcFolder}/${NameOffMRI}_gdc_warp \
#      --t12std=${T1wFolder}/reg/nonlin/T1_2_std_warp \
#      --t1brainmask=${T1wFolder}/preprocess/${T1wRestoreImageBrain}_mask \
#      --fmriresout=${FinalfMRIResolution} \
#      --fmri2structin=${regFolder}/${fMRI2strOutputTransform} \
#      --struct2std=${T1wFolder}/reg/nonlin/T1_2_std_warp_field \
#      --oscout=${OsrFolder}/${NameOffMRI}_SBRef_nonlin \
#      --owarp=${regFolder}/${OutputfMRI2StandardTransform} \
#      --oiwarp=${regFolder}/${Standard2OutputfMRITransform} \
#      --ojacobian=${OsrFolder}/${JacobianOut}_std.${FinalfMRIResolution}


#ResultsFolder=${fMRIFolder}/result

if [[ ${DistortionCorrection} == "TOPUP" ]]
then
    #create MNI space corrected fieldmap images
#    ${FSLDIR}/bin/applywarp --rel --interp=spline --in=${DCFolder}/PhaseOne_gdc_dc_unbias -w $T1wFolder/reg/nonlin/T1_2_std_warp_field -r ${fMRIFolder}/${NameOffMRI}_SBRef_nonlin -o ${ResultsFolder}/${NameOffMRI}_PhaseOne_gdc_dc
#    ${FSLDIR}/bin/applywarp --rel --interp=spline --in=${DCFolder}/PhaseTwo_gdc_dc_unbias -w $T1wFolder/reg/nonlin/T1_2_std_warp_field -r ${fMRIFolder}/${NameOffMRI}_SBRef_nonlin -o ${ResultsFolder}/${NameOffMRI}_PhaseTwo_gdc_dc

    #create MNINonLinear final fMRI resolution bias field outputs
    if [[ ${BiasCorrection} == "SEBASED" ]]
    then
        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${SE_BF_Folder}/sebased_bias_dil.nii.gz -r ${OsrFolder}/${NameOffMRI}_SBRef_nonlin -w ${T1wFolder}/reg/nonlin/T1_2_std_warp_field -o ${SE_BF_Folder}/${NameOffMRI}2std_sebased_bias.nii.gz
        ${FSLDIR}/bin/fslmaths ${SE_BF_Folder}/${NameOffMRI}2std_sebased_bias.nii.gz -mas ${OsrFolder}/${T1wRestoreImageBrain}_mask.${FinalfMRIResolution}.nii.gz ${SE_BF_Folder}/${NameOffMRI}2std_sebased_bias.nii.gz

        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${SE_BF_Folder}/sebased_reference_dil.nii.gz -r ${OsrFolder}/${NameOffMRI}_SBRef_nonlin -w ${T1wFolder}/reg/nonlin/T1_2_std_warp_field -o ${SE_BF_Folder}/${NameOffMRI}2std_sebased_reference.nii.gz
        ${FSLDIR}/bin/fslmaths ${SE_BF_Folder}/${NameOffMRI}2std_sebased_reference.nii.gz -mas ${OsrFolder}/${T1wRestoreImageBrain}_mask.${FinalfMRIResolution}.nii.gz ${SE_BF_Folder}/${NameOffMRI}2std_sebased_reference.nii.gz

        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${SE_BF_Folder}/${NameOffMRI}_dropouts.nii.gz -r ${OsrFolder}/${NameOffMRI}_SBRef_nonlin -w ${T1wFolder}/reg/nonlin/T1_2_std_warp_field -o ${SE_BF_Folder}/${NameOffMRI}2std_dropouts.nii.gz

        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${SE_BF_Folder}/${NameOffMRI}2std_sebased_bias -r ${gdcFolder}/${ScoutName}_gdc -w ${regFolder}/${Standard2OutputfMRITransform} -o ${SE_BF_Folder}/${NameOffMRI}2func_sebased_bias.nii.gz
        ${FSLDIR}/bin/fslmaths ${SE_BF_Folder}/${NameOffMRI}2func_sebased_bias.nii.gz -mas ${gdcFolder}/${ScoutName}_gdc_mask ${SE_BF_Folder}/${NameOffMRI}2func_sebased_bias.nii.gz
    fi

    if [[ $UseJacobian == "true" ]] ; then

        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${OsrFolder}/${JacobianOut}_std.${FinalfMRIResolution} -r ${gdcFolder}/${ScoutName}_gdc -w ${regFolder}/${Standard2OutputfMRITransform} -o ${OsrFolder}/${JacobianOut}_func
    fi
fi


if [[ ${MotionCorrectionType} == "MCFLIRT" ]] ; then
    if [[ ${DistortionCorrection} == "TOPUP" ]] ; then
        In_Norm_Scout_In=${DCFolder}/FieldMap/SBRef_dc
    else
        In_Norm_Scout_In=${gdcFolder}/${ScoutName}_gdc
    fi
elif [[ ${MotionCorrectionType} == "EDDY" ]] ; then
    In_Norm_Scout_In=${EddyFolder}/SBRef_dc
fi


if [[ $Do_intensity_norm == yes ]]; then

    echo "Intensity Normalization and Bias Removal"

#    ${RUN} ${BRC_FMRI_SCR}/Intensity_Normalization.sh \
#          --workingdir=${In_Nrm_Folder} \
#          --infmri=${nrFolder}/ICA_AROMA/denoised_func_data_nonaggr \
#          --inscout=${In_Norm_Scout_In} \
#          --brainmask=${gdcFolder}/${ScoutName}_gdc_mask \
#          --biascorrection=${BiasCorrection} \
#          --biasfield=${SE_BF_Folder}/${NameOffMRI}2func_sebased_bias \
#          --usejacobian=${UseJacobian} \
#          --jacobian=${OsrFolder}/${JacobianOut}_func \
#          --ofmri=${NameOffMRI}_nonlin_norm \
#          --oscout=${NameOffMRI}_SBRef_nonlin_norm

else

    echo "Not performing Intensity Normalization and Bias Removal"

    ${FSLDIR}/bin/imcp ${nrFolder}/ICA_AROMA/denoised_func_data_nonaggr ${In_Nrm_Folder}/${NameOffMRI}_nonlin_norm
    ${FSLDIR}/bin/imcp ${OSR_Scout_In} ${In_Nrm_Folder}/${NameOffMRI}_SBRef_nonlin_norm
fi


if [ $Temp_Filter_Cutoff -ne 0 ]; then

    echo "Temporal Filtering"

    ${RUN} ${BRC_FMRI_SCR}/Temporal_Filtering.sh \
          --workingdir=${Tmp_Filt_Folder} \
          --infmri=${In_Nrm_Folder}/${NameOffMRI}_nonlin_norm \
          --tempfiltercutoff=${Temp_Filter_Cutoff} \
          --outfmri=${NameOffMRI}_tempfilt

else

    echo "Not performing Temporal Filtering"

    ${FSLDIR}/bin/imcp ${In_Nrm_Folder}/${NameOffMRI}_nonlin_norm ${Tmp_Filt_Folder}/${NameOffMRI}_tempfilt
fi


echo "Apply the final registration"
#${RUN} ${BRC_FMRI_SCR}/Apply_Registration.sh \
#      --workingdir=${OsrFolder} \
#      --infmri=${Tmp_Filt_Folder}/${NameOffMRI}_tempfilt \
#      --scoutgdcin=${OSR_Scout_In} \
#      --gdfield=${gdcFolder}/${NameOffMRI}_gdc_warp \
#      --t12std=${T1wFolder}/reg/nonlin/T1_2_std_warp \
#      --fmriresout=${FinalfMRIResolution} \
#      --owarp=${regFolder}/${OutputfMRI2StandardTransform} \
#      --motioncorrectiontype=${MotionCorrectionType} \
#      --motionmatdir=${mcFolder}/${MotionMatrixFolder} \
#      --motionmatprefix=${MotionMatrixPrefix} \
#      --ofmri=${OsrFolder}/${NameOffMRI}_nonlin


echo "Organizing the outputs"
${RUN} ${BRC_FMRI_SCR}/Data_Organization.sh \
      --workingdir=${rfMRIFolder} \
      --unlabeledfolder=${fMRIFolder} \
      --nameoffmri=${NameOffMRI} \
      --rawfoldername=${rawFolderName} \
      --method=${DistortionCorrection} \
      --origse_pos_name=${OrigSE_Pos_Name} \
      --origse_neg_name=${OrigSE_Neg_Name} \
      --origtcsname=${OrigTCSName} \
      --origscoutname=${OrigScoutName} \
      --regfoldername=${regFolderName} \
      --rfmri2strtransf=${fMRI2strOutputTransform} \
      --rfmri2stdtransf=${OutputfMRI2StandardTransform} \
      --std2rfMRItransf=${Standard2OutputfMRITransform} \
      --mcfoldername=${mcFolderName} \
      --eddyfoldername=${eddyFolderName} \
      --motioncorrectiontype=${MotionCorrectionType} \
      --eddyoutput=${EddyOutput} \
      --motionmatrixfolder=${MotionMatrixFolder} \
      --figsfoldername=${figsFolderName} \
      --processedfoldername=${processedFolderName} \
      --stc_method=${SliceTimingCorrection} \
      --stcfoldername=${stcFolderName} \
      --smoothingfwhm=${smoothingfwhm} \
      --nrfoldername=${nrFolderName} \
      --dointensitynorm=${Do_intensity_norm} \
      --innormffoldername=${InNormfFolderName} \
      --scoutname=${ScoutName} \
      --gdcfoldername=${gdcFolderName} \
      --dcfoldername=${DCFolderName} \
      --oregim=${RegOutput} \
      --onestresfoldername=${osrFolderName} \
      --tempfiltfoldername=${tempfiltFolderName} \
      --temfFiltercutoff=${Temp_Filter_Cutoff}


END_Time="$(date -u +%s)"


${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time}

#: <<'COMMENT'

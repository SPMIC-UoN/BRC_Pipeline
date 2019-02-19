#!/bin/bash
# Last update: 11/10/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
# Preprocessing Pipeline for resting-state fMRI. Generates the "data" directory that can be used as input to fibre orientation estimation.
# Ali-Reza Mohammadi-Nejad, SPMIC, Queens Medical Centre, School of Medicine, University of Nottingham, 2018.
#Example:
#./fMRI_preproc.sh --path ~/main/analysis --subject Sub_003 --input ~/P_Share/Images/3T_Harmonisation_Stam/03286_20180522_GE/NIFTI/5_rfMRI_2.4mm3_TR3.5_200vols/__resting_state_fMRI_96x2.4mm_20180522141148_8.nii.gz --echospacing 0.00058 --unwarpdir y- --dcmethod NONE --fmrires 3 --mctype EDDY --slice2vol --slspec ~/P_Share/Images/3T_Harmonisation_Stam/03286_20180522_GE/NIFTI/5_rfMRI_2.4mm3_TR3.5_200vols/__resting_state_fMRI_96x2.4mm_20180522141148_8.json --stcmethod 6 --fwhm 3 --intensitynorm

#clear

set -e

# --------------------------------------------------------------------------------
#  Usage Description Function
# --------------------------------------------------------------------------------

Usage()
{
  echo " "
  echo " "
  echo "`basename $0`: Description"
  echo " "
  echo "Usage: `basename $0`"
  echo "Compulsory arguments (You MUST set one or more of):"
  echo " --input <path>                       full path of the filename of fMRI image"
  echo " --path <path>                        output directory"
  echo " --subject <subject name>             output directory is a subject name folder in input image directory"
  echo " "
  echo "Optional arguments (You may optionally specify one or more of):"
  echo " --mctype <Type>                      Motion correction method. MCFLIRT: between volumes (default), and EDDY: within/between volumes"
  echo "                                           MCFLIRT6: between volumes with 6 degrees of freedom (default),"
  echo "                                           MCFLIRT12: between volumes with 12 degrees of freedom,"
  echo "                                           EDDY: within/between volumes"
  echo " --dcmethod <method>                  Susceptibility distortion correction method (required for accurate processing)"
  echo "                                      Values: TOPUP, SiemensFieldMap (same as FIELDMAP), GeneralElectricFieldMap, and NONE (default)"
  echo " --fmriscout <path>                   A single band reference image (SBRef) is recommended if available. Set to NONE if not available (default)"
  echo "                                      Set to NONE if you want to use the first volume of the timeseries for motion correction"
  echo " --slice2vol                          If one wants to do slice-to-volome motion correction"
  echo " --slspec <path>                      Specifies a .json file (created by your DICOM->niftii conversion software) that describes how the"
  echo "                                      slices/multi-band-groups were acquired. This file is necessary when using the slice-to-vol movement correction"
  echo " --fmapmag <path>                     Expects 4D Magnitude volume with two 3D volumes (differing echo times). Set to NONE (default) if using TOPUP"
  echo " --fmapphase <path>                   Expects a 3D Phase difference volume (Siemens style). Set to NONE (default) if using TOPUP"
  echo " --fmapgeneralelectric                Path to General Electric style B0 fieldmap with two volumes"
  echo "                                           1. field map in degrees"
  echo "                                           2. magnitude"
  echo "                                      Set to 'NONE' (default) if not using 'GeneralElectricFieldMap' as the value for the DistortionCorrection variable"
  echo " --echodiff <value>                   Set to NONE if using TOPUP"
  echo " --SEPhaseNeg <path>                  For the SE field map volume with a 'negative' phase encoding direction (the same direction of fMRI data)"
  echo "                                      Set to NONE if using regular FIELDMAP"
  echo " --SEPhasePos <path>                  For the SE field map volume with a 'positive' phase encoding direction (the opposite direction of fMRI data)"
  echo "                                      Set to NONE if using regular FIELDMAP"
  echo " --echospacing <value>                Effective Echo Spacing of spin echo field map acquisitions (in sec)"
  echo "                                           NOTE: The pipeline expects you to have used the same phase encoding axis and echo spacing in the fMRI data"
  echo "                                           as in the SE field map acquisitions. Otherwise, you need to specify the fMRI Echo spacing using --echospacing_fMRI"
  echo " --unwarpdir <direction>              ‌Based on Phase Encoding Direction: PA: 'y', AP: 'y-', RL: 'x', and LR: 'x-'"
  echo " --biascorrection <method>            Receive coil bias field correction method"
  echo "                                           Values: NONE (default), or SEBASED (Spin-Echo Based)"
  echo "                                           SEBASED calculates bias field from spin echo images (which requires TOPUP distortion correction)"
  echo " --intensitynorm                      If one wants to do intensity normalization"
  echo " --stcmethod <method>                 Slice timing correction method"
  echo "                                           0: NONE (default value),"
  echo "                                           1: (SPM) If the slices were acquired with interleaved order (0, 2, 4 ... 1, 3, 5 ...),"
  echo "                                           2: (SPM) If slices were acquired with forward order (0, 1, 2, ...),"
  echo "                                           3: (SPM) If slices were acquired with backward order (n, n-1, n-2, ...),"
  echo "                                           4: (FSL) If slices were acquired from the bottom of the brain,"
  echo "                                           5: (FSL) If slices were acquired from the top of the brain to the bottom,"
  echo "                                           6: (FSL) If the slices were acquired with interleaved order (0, 2, 4 ... 1, 3, 5 ...),"
  echo "                                           7: (FSL) If slices were not acquired in regular order you will need to use a slice order file or a slice timings file."
  echo "                                                    If a slice order file is to be used, create a text file with a single number on each line, "
  echo "                                                    where the first line states which slice was acquired first, the second line states which slice was acquired second, etc."
  echo "                                                    The first slice is numbered 1 not 0."
  echo "                                                    The file path should be specified using --slstiming"
  echo "                                           8: (FSL) If a slice timings file is to be used, put one value (ie for each slice) on each line of a text file."
  echo "                                                    The units are in TRs, with 0.5 corresponding to no shift. Therefore a sensible range of values will be between 0 and 1."
  echo "                                                    The file path should be specified using --slstiming"
  echo " --slstiming <path>                   file path of a single-column custom interleave order/timing file"
  echo " --fwhm <value>                       Spatial size (sigma, i.e., half-width) of smoothing, in mm. Set to 0 (default) for no spatial smooting"
  echo " --noaroma                            disable ICA-AROMA for Artifact/Physiological Noise Removal"
  echo " --fmrires <value>                    Target final resolution of fMRI data in mm (default is 2 mm)"
  echo " --tempfilter <value>                 Non-zero value of this option means that one wants to do temporal filtering with High pass filter curoff <value> in Sec"
  echo "                                      default value is 0, means No Temporal Filtering"
  echo " --echospacing_fMRI <value>           Echo Spacing of fMRI image (in sec)"
  echo " --name <folder name>                 Output folder name of the functional analysis pipeline. Default: rfMRI"
  echo " --printcom                           use 'echo' for just printing everything and not running the commands (default is to run)"
  echo " --help                               help"
  echo " "
  echo " "
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi

################################################## OPTION PARSING #####################################################

log=`echo "$@"`

# default values
fMRIScout="NONE"
MotionCorrectionType="MCFLIRT6"
Slice2Volume="no"
SliceSpec="NONE"
MagnitudeInputName="NONE"
PhaseInputName="NONE"
GEB0InputName="NONE"
Do_intensity_norm="no"
GradientDistortionCoeffs="NONE"
DistortionCorrection="NONE"
BiasCorrection="NONE"
SliceTimingFile="NONE"
Do_ica_aroma="yes"
OutFolderName="rfMRI"
dof=6
FinalfMRIResolution=2
SliceTimingCorrection=0
smoothingfwhm=0
Temp_Filter_Cutoff=0
EchoSpacing_fMRI=0.0

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

      --input )               shift
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

      --slstiming )           shift
                              SliceTimingFile=$1
                              ;;

      --intensitynorm )       Do_intensity_norm="yes"
                              ;;

      --tempfilter )          shift
                              Temp_Filter_Cutoff=$1
                              ;;

      --fwhm )                shift
                              smoothingfwhm=$1
                              ;;

      --noaroma )             Do_ica_aroma="no"
                              ;;

      --fmrires )             shift
                              FinalfMRIResolution=$1
                              ;;

      --echospacing_fMRI )    shift
                              EchoSpacing_fMRI=$1
                              ;;

      --name )                shift
                              OutFolderName=$1
                              ;;

      --printcom )            shift
                              RUN=$1
                              ;;

      --help )                Usage
                              exit
                              ;;

      * )                     Usage
                              exit 1

    esac
    shift
done

#=====================================================================================
###                          Sanity checking of arguments
#=====================================================================================

if [ X$Path = X ] || [ X$Subject = X ] || [ X$PathOffMRI = X ] ; then
    echo ""
    echo "All of the compulsory arguments --path, --subject and --input MUST be used"
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

if [[ ${BiasCorrection} == "SEBASED" ]]; then
    if [ $EchoSpacing_fMRI != 0.0 ]; then
        echo ""
        echo "ERROR: Spin Echo-based bias field correction of the Receive coil just works with the same Echospacing for SE and fMRI data"
        echo ""
        exit 1;
    fi
fi

if [[ ${Do_ica_aroma} == "yes" ]]; then
    if [ $FWHM -e 0 ]; then
        echo ""
        echo "ERROR: AROMA has to be applied ater after spatial smoothing. Please set sigma size in --fwhm option"
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

AnalysisFolderName="analysis"
rfMRIFolderName=${OutFolderName}
rawFolderName="raw"
AnatMRIFolderName="anatMRI"
T1FolderName="T1"
segFolderName="seg"
TissueFolderName="tissue"
SingChanFolderName="sing_chan"
MultChanFolderName="multi_chan"

logFolderName="log"
preprocessFolderName="preproc"
processedFolderName="processed"
tempFolderName="temp"
DCFolderName="epi_dc"
sebfFolderName="biasfield"
topupFolderName="topup"
eddyFolderName="eddy"
InNormfFolderName="inten_norm"
nrFolderName="noise_removal"
osrFolderName="one_step_resamp"
stcFolderName="slice_time_corr"
gdcFolderName="gdc"
mcFolderName="mc"
regFolderName="reg"
tempfiltFolderName="temp_filt"
dataFolderName="data"
data2stdFolderName="data2std"

NameOffMRI="rfMRI"
T1wImage="T1"                                                          #<input T1-weighted image>
T1wImageBrainMask="T1_brain_mask"                                                          #<input T1-weighted image>
T1wRestoreImage="T1_unbiased"                                                   #<input bias-corrected T1-weighted image>
T1wRestoreImageBrain="T1_unbiased_brain"                                        #<input bias-corrected, brain-extracted T1-weighted image>
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
str2fMRIOutputTransform="str2${NameOffMRI}"
EddyOutput="ec"
RegOutput="Scout2T1w"
QAImage="T1wMulEPI"
JacobianOut="Jacobian"
OutputfMRI2StandardTransform="${NameOffMRI}2std"
Standard2OutputfMRITransform="std2${NameOffMRI}"
log_Name="log.txt"

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

Path=${Path}/${Subject}

if [ ! -d "$Path" ]; then
    mkdir $Path;
#else
#  Path="${Path}_$(date +"%d-%m-%Y_%H-%M")"
#  mkdir $Path
fi

AnalysisFolder=${Path}/${AnalysisFolderName}
AnatMRIFolder=${AnalysisFolder}/${AnatMRIFolderName}
T1Folder=${AnatMRIFolder}/${T1FolderName}

if [ ! -e ${T1Folder} ] ; then
    echo ""
    echo "Functional preprocessing depends on the outputs generated by Structural preprocessing. So functional"
    echo "preprocessing should not be attempted on data sets for which structural preprocessing is not yet complete."
    echo ""
    exit;
fi

rawFolder=${Path}/${rawFolderName}
rfMRIrawFolder=${rawFolder}/${rfMRIFolderName}
rfMRIFolder=${AnalysisFolder}/${rfMRIFolderName}
logFolder=${rfMRIFolder}/${logFolderName}
preprocFolder=${rfMRIFolder}/${preprocessFolderName}
processedFolder=${rfMRIFolder}/${processedFolderName}
TempFolder=${rfMRIFolder}/${tempFolderName}
gdcFolder=${TempFolder}/${gdcFolderName}
mcFolder=${TempFolder}/${mcFolderName}
regFolder=${TempFolder}/${regFolderName}
stcFolder=${TempFolder}/${stcFolderName}
nrFolder=${TempFolder}/${nrFolderName}
DCFolder=${TempFolder}/${DCFolderName}
EddyFolder=${TempFolder}/${eddyFolderName}
OsrFolder=${TempFolder}/${osrFolderName}
SE_BF_Folder=${DCFolder}/${sebfFolderName}
TOPUP_Folder=${DCFolder}/${topupFolderName}
In_Nrm_Folder=${TempFolder}/${InNormfFolderName}
Tmp_Filt_Folder=${TempFolder}/${tempfiltFolderName}
preprocT1Folder=${T1Folder}/${preprocessFolderName}
processedT1Folder=${T1Folder}/${processedFolderName}
dataT1Folder=${processedT1Folder}/${dataFolderName}
data2stdT1Folder=${processedT1Folder}/${data2stdFolderName}
segT1Folder=${processedT1Folder}/${segFolderName}
TissueT1Folder=${segT1Folder}/${TissueFolderName}
SinChanT1Folder=${TissueT1Folder}/${SingChanFolderName}
MultChanT1Folder=${TissueT1Folder}/${MultChanFolderName}
regT1Folder=${preprocT1Folder}/${regFolderName}

mkdir -p ${TempFolder}
if [ ! -d ${rfMRIrawFolder} ]; then mkdir ${rfMRIrawFolder}; fi
if [ -e ${logFolder} ] ; then rm -r ${logFolder}; fi; mkdir ${logFolder}
if [ ! -d ${preprocFolder} ]; then mkdir ${preprocFolder}; fi
if [ ! -d ${processedFolder} ]; then mkdir ${processedFolder}; fi
if [ ! -d ${gdcFolder} ]; then mkdir ${gdcFolder}; fi
if [ ! -d ${mcFolder} ]; then mkdir ${mcFolder}; fi
if [ ! -d ${regFolder} ]; then mkdir ${regFolder}; fi
if [ ! -d ${stcFolder} ]; then mkdir ${stcFolder}; fi
if [ ! -d ${nrFolder} ]; then mkdir ${nrFolder}; fi
if [ ! -d ${DCFolder} ]; then mkdir ${DCFolder}; fi
if [ ! -d $In_Nrm_Folder ]; then mkdir ${In_Nrm_Folder}; fi
if [ ! -d ${Tmp_Filt_Folder} ]; then mkdir ${Tmp_Filt_Folder}; fi

#=====================================================================================
###                              Setup the Log file
#=====================================================================================

${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="no" \
      --logfile=${logFolder}/${log_Name}
Start_Time="$(date -u +%s)"

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions
log_SetPath "${logFolder}/${log_Name}"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "Original command:"
log_Msg 2 "$log"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "Parsing Command Line Options"
log_Msg 2 "Path: $Path"
log_Msg 2 "Subject: $Subject"
log_Msg 2 "PathOffMRI: $PathOffMRI"
log_Msg 2 "fMRIScout: $fMRIScout"
log_Msg 2 "MotionCorrectionType: $MotionCorrectionType"
log_Msg 2 "Slice2Volume: $Slice2Volume"
log_Msg 2 "SliceSpec: $SliceSpec"
log_Msg 2 "MagnitudeInputName: $MagnitudeInputName"
log_Msg 2 "PhaseInputName: $PhaseInputName"
log_Msg 2 "GEB0InputName: $GEB0InputName"
log_Msg 2 "deltaTE: $deltaTE"
log_Msg 2 "SpinEchoPhaseEncodeNegative: $SpinEchoPhaseEncodeNegative"
log_Msg 2 "SpinEchoPhaseEncodePositive: $SpinEchoPhaseEncodePositive"
log_Msg 2 "EchoSpacing: $EchoSpacing"
log_Msg 2 "UnwarpDir: $UnwarpDir"
log_Msg 2 "DistortionCorrection: $DistortionCorrection"
log_Msg 2 "BiasCorrection: $BiasCorrection"
log_Msg 2 "UseJacobian: $UseJacobian"
log_Msg 2 "SliceTimingCorrection: $SliceTimingCorrection"
log_Msg 2 "SliceTimingFile: $SliceTimingFile"
log_Msg 2 "Do_intensity_norm: $Do_intensity_norm"
log_Msg 2 "Temp_Filter_Cutoff: $Temp_Filter_Cutoff"
log_Msg 2 "smoothingfwhm: $smoothingfwhm"
log_Msg 2 "Do_ica_aroma: $Do_ica_aroma"
log_Msg 2 "FinalfMRIResolution: $FinalfMRIResolution"
log_Msg 2 "EchoSpacing_fMRI: $EchoSpacing_fMRI"
log_Msg 2 "RUN: $RUN"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

log_Msg 3 "OutputDir is: ${rfMRIFolder}"

#Check WM segment exist or no
if [ `$FSLDIR/bin/imtest ${MultChanT1Folder}/T1_WM_mask` = 1 ] ; then
    wmseg="${MultChanT1Folder}/T1_WM_mask"
elif [[ `$FSLDIR/bin/imtest ${SinChanT1Folder}/T1_WM_mask` = 1 ]]; then
    wmseg="${SinChanT1Folder}/T1_WM_mask"
fi

if [ `$FSLDIR/bin/imtest ${MultChanT1Folder}/T1_GM_mask` = 1 ] ; then
    GMseg="${MultChanT1Folder}/T1_GM_mask"
elif [[ `$FSLDIR/bin/imtest ${SinChanT1Folder}/T1_GM_mask` = 1 ]]; then
    GMseg="${SinChanT1Folder}/T1_GM_mask"
fi

$FSLDIR/bin/imcp ${PathOffMRI} ${rfMRIrawFolder}/${OrigTCSName}

#Create fake "Scout" if it doesn't exist
if [ $fMRIScout = "NONE" ] ; then
    ${RUN} ${FSLDIR}/bin/fslroi ${rfMRIrawFolder}/${OrigTCSName} ${rfMRIrawFolder}/${OrigScoutName} 0 1
else
    cp $(dirname $PathOffMRI)/${fMRIScout} ${rfMRIrawFolder}/${OrigScoutName}.nii.gz
fi

if [[ $DistortionCorrection == "TOPUP" ]] ; then

    ${RUN} ${FSLDIR}/bin/fslroi ${SpinEchoPhaseEncodePositive} ${rfMRIrawFolder}/${OrigSE_Pos_Name} 0 1
    SpinEchoPhaseEncodePositive=${rfMRIrawFolder}/${OrigSE_Pos_Name}

    ${RUN} ${FSLDIR}/bin/fslroi ${SpinEchoPhaseEncodeNegative} ${rfMRIrawFolder}/${OrigSE_Neg_Name} 0 1
    SpinEchoPhaseEncodeNegative=${rfMRIrawFolder}/${OrigSE_Neg_Name}

elif [[ $DistortionCorrection == "NONE" ]] ; then

    $FSLDIR/bin/imcp ${rfMRIrawFolder}/${OrigScoutName}.nii.gz  ${rfMRIrawFolder}/${OrigSE_Pos_Name}
    SpinEchoPhaseEncodePositive=${rfMRIrawFolder}/${OrigSE_Pos_Name}

    $FSLDIR/bin/imcp ${rfMRIrawFolder}/${OrigScoutName}.nii.gz  ${rfMRIrawFolder}/${OrigSE_Neg_Name}
    SpinEchoPhaseEncodeNegative=${rfMRIrawFolder}/${OrigSE_Neg_Name}

fi


log_Msg 3 "Gradient Distortion Correction of fMRI"
if [ ! $GradientDistortionCoeffs = "NONE" ] ; then
    log_Msg 3 "PERFORMING GRADIENT DISTORTION CORRECTION"
else
    log_Msg 3 "NOT PERFORMING GRADIENT DISTORTION CORRECTION"

    ${RUN} ${FSLDIR}/bin/imcp ${rfMRIrawFolder}/${OrigTCSName} ${gdcFolder}/${NameOffMRI}_gdc
    ${RUN} ${FSLDIR}/bin/fslroi ${gdcFolder}/${NameOffMRI}_gdc ${gdcFolder}/${NameOffMRI}_gdc_warp 0 3
    ${RUN} ${FSLDIR}/bin/fslmaths ${gdcFolder}/${NameOffMRI}_gdc_warp -mul 0 ${gdcFolder}/${NameOffMRI}_gdc_warp
    ${RUN} ${FSLDIR}/bin/imcp ${rfMRIrawFolder}/${OrigScoutName} ${gdcFolder}/${ScoutName}_gdc
    #make fake jacobians of all 1s, for completeness
    ${RUN} ${FSLDIR}/bin/fslmaths ${rfMRIrawFolder}/${OrigScoutName} -mul 0 -add 1 ${gdcFolder}/${ScoutName}_gdc_warp_jacobian
    ${RUN} ${FSLDIR}/bin/fslroi ${gdcFolder}/${NameOffMRI}_gdc_warp ${gdcFolder}/${NameOffMRI}_gdc_warp_jacobian 0 1
    ${RUN} ${FSLDIR}/bin/fslmaths ${gdcFolder}/${NameOffMRI}_gdc_warp_jacobian -mul 0 -add 1 ${gdcFolder}/${NameOffMRI}_gdc_warp_jacobian
fi


log_Msg 3 "EPI Distortion Correction"
if [ ! $DistortionCorrection = "NONE" ] ; then
    log_Msg 3 "Performing EPI Distortion Correction"

    ${RUN} ${BRC_FMRI_SCR}/EPI_Distortion_Correction.sh \
           --workingdir=${DCFolder} \
           --topupfoldername=${topupFolderName} \
           --scoutin=${gdcFolder}/${ScoutName}_gdc \
           --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
           --SEPhasePos=${SpinEchoPhaseEncodePositive} \
           --echospacing=${EchoSpacing} \
           --unwarpdir=${UnwarpDir} \
           --gdcoeffs=${GradientDistortionCoeffs} \
           --method=${DistortionCorrection} \
           --logfile=${logFolder}/${log_Name}
else
    log_Msg 3 "NOT Performing EPI Distortion Correction"

    ${RUN} ${FSLDIR}/bin/fslroi ${gdcFolder}/${NameOffMRI}_gdc ${DCFolder}/WarpField.nii.gz 0 3
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/WarpField.nii.gz -mul 0 ${DCFolder}/WarpField.nii.gz

    ${RUN} ${FSLDIR}/bin/fslroi ${DCFolder}/WarpField.nii.gz ${DCFolder}/Jacobian.nii.gz 0 1
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/Jacobian.nii.gz -mul 0 -add 1 ${DCFolder}/Jacobian.nii.gz

    ${FSLDIR}/bin/imcp ${gdcFolder}/${ScoutName}_gdc ${DCFolder}/SBRef_dc
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/SBRef_dc -mul 0 -add 1 ${DCFolder}/PhaseOne_gdc_dc
    ${RUN} ${FSLDIR}/bin/fslmaths ${DCFolder}/SBRef_dc -mul 0 -add 1 ${DCFolder}/PhaseTwo_gdc_dc
fi


log_Msg 3 "MOTION CORRECTION"
case $MotionCorrectionType in

    MCFLIRT6 | MCFLIRT12)
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
              --motioncorrectiontype=${MotionCorrectionType} \
              --logfile=${logFolder}/${log_Name}

    ;;

    EDDY)
        STC_Input=${EddyFolder}/${EddyOutput}
        SSNR_motionparam=${EddyFolder}/${EddyOutput}.eddy_parameters
        fMRI_2_str_Input=${EddyFolder}/${EddyOutput}
        OSR_Scout_In=${EddyFolder}/SBRef_dc

        ${RUN} ${BRC_FMRI_SCR}/EddyPreprocessing.sh \
              --workingdir=${EddyFolder} \
              --inputfile=${gdcFolder}/${NameOffMRI}_gdc \
              --inscout=${gdcFolder}/${ScoutName}_gdc \
              --fmriname=${NameOffMRI} \
              --dcmethod=${DistortionCorrection} \
              --topupfodername=${topupFolderName} \
              --dcfolder=${DCFolder} \
              --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
              --SEPhasePos=${SpinEchoPhaseEncodePositive} \
              --unwarpdir=${UnwarpDir} \
              --echospacing=${EchoSpacing} \
              --echospacingfmri=${EchoSpacing_fMRI} \
              --slice2vol=${Slice2Volume} \
              --slspec=${SliceSpec} \
              --output_eddy=${EddyOutput} \
              --outfolder=${DCFolder} \
              --logfile=${logFolder}/${log_Name}

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
          --logfile=${logFolder}/${log_Name}

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
      --t1=${dataT1Folder}/${T1wImage} \
      --t1brain=${dataT1Folder}/${T1wRestoreImageBrain} \
      --t1brainmask=${dataT1Folder}/${T1wImageBrainMask} \
      --wmseg=$wmseg \
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
      --logfile=${logFolder}/${log_Name}


log_Msg 3 "One Step Resampling"
${RUN} ${BRC_FMRI_SCR}/One_Step_Resampling.sh \
      --workingdir=${OsrFolder} \
      --scoutgdcin=${OSR_Scout_In} \
      --gdfield=${gdcFolder}/${NameOffMRI}_gdc_warp \
      --t12std=${data2stdT1Folder}/T1_2_std_warp \
      --t1brainmask=${dataT1Folder}/${T1wImageBrainMask} \
      --fmriresout=${FinalfMRIResolution} \
      --fmri2structin=${regFolder}/${fMRI2strOutputTransform} \
      --struct2std=${regT1Folder}/T1_2_std_warp_field \
      --oscout=${OsrFolder}/${NameOffMRI}_SBRef_nonlin \
      --owarp=${regFolder}/${OutputfMRI2StandardTransform} \
      --oiwarp=${regFolder}/${Standard2OutputfMRITransform} \
      --ojacobian=${OsrFolder}/${JacobianOut}_std.${FinalfMRIResolution} \
      --logfile=${logFolder}/${log_Name}


log_Msg 3 "Spatial Smoothing and Artifact/Physiological Noise Removal"
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
        --logfile=${logFolder}/${log_Name}


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
        --oscout=SBRef_intnorm \
        --logfile=${logFolder}/${log_Name}


if [ $Temp_Filter_Cutoff -ne 0 ]; then

    log_Msg 3 "Temporal Filtering"

    ${RUN} ${BRC_FMRI_SCR}/Temporal_Filtering.sh \
          --workingdir=${Tmp_Filt_Folder} \
          --infmri=${In_Nrm_Folder}/${NameOffMRI}_intnorm \
          --tempfiltercutoff=${Temp_Filter_Cutoff} \
          --outfmri=${NameOffMRI}_tempfilt \
          --logfile=${logFolder}/${log_Name}

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
      --logfile=${logFolder}/${log_Name}


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
      --nameoffmri=${NameOffMRI} \
      --rfmri2strtransf=${fMRI2strOutputTransform} \
      --str2rfmritransf=${str2fMRIOutputTransform} \
      --rfmri2stdtransf=${OutputfMRI2StandardTransform} \
      --std2rfMRItransf=${Standard2OutputfMRITransform} \
      --logfile=${logFolder}/${log_Name}


END_Time="$(date -u +%s)"


${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Subject} \
      --type=3 \
      --logfile=${logFolder}/${log_Name}

################################################################################################
## Cleanup
################################################################################################

if [[ $DistortionCorrection == "NONE" ]] ; then
    ${FSLDIR}/bin/imrm ${SpinEchoPhaseEncodePositive}
    ${FSLDIR}/bin/imrm ${SpinEchoPhaseEncodeNegative}
fi
#: <<'COMMENT'

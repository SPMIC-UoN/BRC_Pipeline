#!/bin/bash
# Last update: 05/07/2019

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham

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
  echo " --input <path>                       Full path of the filename of fMRI image."
  echo " --path <path>                        Output directory."
  echo " --subject <subject name>             Output directory is a subject name folder in input image directory."
  echo " "
  echo "Optional arguments (You may optionally specify one or more of):"
  echo " --mctype <Type>                      Motion correction method. MCFLIRT: between volumes (default), and EDDY: within/between volumes"
  echo "                                           MCFLIRT6: between volumes with 6 degrees of freedom (default),"
  echo "                                           MCFLIRT12: between volumes with 12 degrees of freedom,"
  echo "                                           EDDY: within/between volumes."
  echo " --dcmethod <method>                  Susceptibility distortion correction method (required for accurate processing)."
  echo "                                      Values: TOPUP, SiemensFieldMap (same as FIELDMAP), GeneralElectricFieldMap, and NONE (default)."
  echo " --fmriscout <path>                   A single band reference image (SBRef) is recommended if available. Set to NONE if not available (default)."
  echo "                                      Set to NONE if you want to use the first volume of the timeseries for motion correction."
  echo " --slice2vol                          If one wants to do slice-to-volome motion correction."
  echo " --slspec <path>                      Specifies a .json file (created by your DICOM->niftii conversion software) that describes how the"
  echo "                                      slices/multi-band-groups were acquired. This file is necessary when using the slice-to-vol movement correction."
  echo " --fmapmag <path>                     Expects 4D Magnitude volume with two 3D volumes (differing echo times). Set to NONE (default) if using TOPUP."
  echo " --fmapphase <path>                   Expects a 3D Phase difference volume (Siemens style). Set to NONE (default) if using TOPUP."
  echo " --fmapgeneralelectric                Path to General Electric style B0 fieldmap with two volumes"
  echo "                                           1. field map in degrees"
  echo "                                           2. magnitude"
  echo "                                      Set to 'NONE' (default) if not using 'GeneralElectricFieldMap' as the value for the DistortionCorrection variable."
  echo " --echodiff <value>                   Set to NONE if using TOPUP."
  echo " --SEPhaseNeg <path>                  For the SE field map volume with a 'negative' phase encoding direction (the same direction of fMRI data)."
  echo "                                      Set to NONE if using regular FIELDMAP."
  echo " --SEPhasePos <path>                  For the SE field map volume with a 'positive' phase encoding direction (the opposite direction of fMRI data)."
  echo "                                      Set to NONE if using regular FIELDMAP."
  echo " --echospacing <value>                Effective Echo Spacing of spin echo field map acquisitions (in sec)."
  echo "                                           NOTE: The pipeline expects you to have used the same phase encoding axis and echo spacing in the fMRI data"
  echo "                                           as in the SE field map acquisitions. Otherwise, you need to specify the fMRI Echo spacing using --echospacing_fMRI"
  echo " --unwarpdir <direction>              ‌Based on Phase Encoding Direction: PA: 'y', AP: 'y-', RL: 'x', and LR: 'x-'"
  echo " --biascorrection <method>            Receive coil bias field correction method"
  echo "                                           Values: NONE (default), or SEBASED (Spin-Echo Based)."
  echo "                                           SEBASED calculates bias field from spin echo images (which requires TOPUP distortion correction)."
  echo " --intensitynorm                      If one wants to do intensity normalization."
  echo " --stcmethod <method>                 Slice timing correction method"
  echo "                                           0: NONE (default value),"
  echo "                                           1: (SPM) If the slices were acquired with interleaved order (0, 2, 4 ... 1, 3, 5 ...),"
  echo "                                           2: (SPM) If slices were acquired with forward order (0, 1, 2, ...),"
  echo "                                           3: (SPM) If slices were acquired with backward order (n, n-1, n-2, ...),"
  echo "                                           4: (FSL) If slices were acquired from the bottom of the brain,"
  echo "                                           5: (FSL) If slices were acquired from the top of the brain to the bottom,"
  echo "                                           6: (FSL) If the slices were acquired with interleaved order (0, 2, 4 ... 1, 3, 5 ...),"
  echo "                                           7: (FSL) If slices were not acquired in regular order you will need to use a slice order file or a slice timings file."
  echo "                                                    If a slice order file is to be used, create a text file with a single number on each line, where the first "
  echo "                                                    line states which slice was acquired first, the second line states which slice was acquired second, etc."
  echo "                                                    The first slice is numbered 1 not 0."
  echo "                                                    The file path should be specified using --slstiming."
  echo "                                           8: (FSL) If a slice timings file is to be used, put one value (ie for each slice) on each line of a text file."
  echo "                                                    The units are in TRs, with 0.5 corresponding to no shift. Therefore a sensible range of values will "
  echo "                                                    be between 0 and 1. The file path should be specified using --slstiming."
  echo " --slstiming <path>                   File path of a single-column custom interleave order/timing file."
  echo " --fwhm <value>                       Spatial size (sigma, i.e., half-width) of smoothing, in mm. Set to 0 (default) for no spatial smooting."
  echo " --noaroma                            Disable ICA-AROMA for Artifact/Physiological Noise Removal."
  echo " --fmrires <value>                    Target final resolution of fMRI data in mm (default is 2 mm)."
  echo " --tempfilter <value>                 Non-zero value of this option means that one wants to do temporal filtering with High pass filter curoff <value> in Sec."
  echo "                                      Default value is 0, means No Temporal Filtering"
  echo " --echospacing_fMRI <value>           Echo Spacing of fMRI image (in sec)"
  echo " --name <folder name>                 Output folder name of the functional analysis pipeline. Default: rfMRI"
  echo " --noqc                               Turn off quality control of fMRI data"
  echo " --clean                              Delete all intermediate files"
  echo " --delvolumes <value>                 Delete a number of volumes from the start of the fMRI 4D data"

  echo " --physin <file name>                 Input physiological data filename (text format)"
  echo " --samplingrate <value>	              Sampling rate in Hz (default is 100Hz) [physiological data]"
  echo " --smoothcard <value>	                Specify smoothing amount for cardiac (in seconds) (default is 0.1 sec) [physiological data]"
  echo " --smoothresp <value>                 Specify smoothing amount for respiratory (in seconds) (default is 0.1 sec) [physiological data]"
  echo " --resp <value>	                      Specify column number of respiratory input [physiological data]"
  echo " --cardiac <value> 	                  Specify column number of cardiac input [physiological data]"
  echo " --trigger <value>	                  Specify column number of trigger input [physiological data]"
  echo " --rvt	                              Enable generating RVT data [physiological data]"
  echo " --sliceorder	 <value>                Specify slice ordering (up/down/interleaved_up/interleaved_down) [physiological data]"
  echo "                                           0: The slice order will be specified with a file path using --slstiming,"
  echo "                                           1: Up,"
  echo "                                           2: Down,"
  echo "                                           3: Interleaved Up,"
  echo "                                           4: Interleaved Down."

  echo " --printcom                           Use 'echo' for just printing everything and not running the commands (default is to run)"
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
DO_RVT="no"
DO_QC="yes"
DO_QC="yes"
DeleteIntermediates="FALSE"
dof=6
FinalfMRIResolution=2
SliceTimingCorrection=0
smoothingfwhm=0
Temp_Filter_Cutoff=0
EchoSpacing_fMRI=0.0
SamplingRate=100
SmoothCardiac=0.1
SmoothResp=0.1
DelVols=0

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

      --physin )              shift
                              PhysInputTXT=$1
                              ;;

      --samplingrate )        shift
                              SamplingRate=$1
                              ;;

      --smoothcard )          shift
                              SmoothCardiac=$1
                              ;;

      --smoothresp )          shift
                              SmoothResp=$1
                              ;;

      --resp )                shift
                              ColResp=$1
                              ;;

      --cardiac )             shift
                              ColCardiac=$1
                              ;;

      --trigger )             shift
                              ColTrigger=$1
                              ;;

      --rvt )                 DO_RVT="yes"
                              ;;

      --sliceorder )          shift
                              SliceOrder=$1
                              ;;

      --noqc )                DO_QC="no"
                              ;;

      --clean )               DeleteIntermediates="TRUE"
                              ;;

      --delvolumes )          shift
                              DelVols=$1
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

if [ X$PhysInputTXT != X ] ; then
    if [ X$ColResp = X ] || [ X$ColCardiac = X ] || [ X$ColTrigger = X ] || [ X$SliceOrder = X ] ; then
        echo ""
        echo "For the physiological noise removal option, all of the compulsory arguments --resp, --cardiac, --sliceorder, and --trigger MUST be used"
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
pnmFolderName="pnm"
qcFolderName="qc"
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
pnmFolder=${TempFolder}/${pnmFolderName}
qcFolder=${TempFolder}/${qcFolderName}
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
log_Msg 2 "DelVols: $DelVols"
log_Msg 2 "RUN: $RUN"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

#if [ $CLUSTER_MODE = "YES" ] ; then
#    module load fsl-img/5.0.11
#fi

log_Msg 3 "OutputDir is: ${rfMRIFolder}"

#Check WM segment exist or no
#if [ `$FSLDIR/bin/imtest ${MultChanT1Folder}/T1_WM_mask` = 1 ] ; then
#    wmseg="${MultChanT1Folder}/T1_WM_mask"
#el
if [[ `$FSLDIR/bin/imtest ${SinChanT1Folder}/T1_WM_mask` = 1 ]]; then
    wmseg="${SinChanT1Folder}/T1_WM_mask"
fi

#if [ `$FSLDIR/bin/imtest ${MultChanT1Folder}/T1_GM_mask` = 1 ] ; then
#    GMseg="${MultChanT1Folder}/T1_GM_mask"
#el
if [[ `$FSLDIR/bin/imtest ${SinChanT1Folder}/T1_GM_mask` = 1 ]]; then
    GMseg="${SinChanT1Folder}/T1_GM_mask"
fi

$FSLDIR/bin/imcp ${PathOffMRI} ${rfMRIrawFolder}/${OrigTCSName}
if [[ ${SliceSpec} != "NONE" ]] ; then
    cp ${SliceSpec} ${rfMRIrawFolder}/${OrigTCSName}.json
fi

if [ $DelVols != 0 ]; then

    log_Msg 3 "Deleting the first ${DelVols} volumes from the original file and save it to the raw folder"

    dimt=`${FSLDIR}/bin/fslval ${rfMRIrawFolder}/${OrigTCSName} dim4`

    ${FSLDIR}/bin/fslroi ${rfMRIrawFolder}/${OrigTCSName} ${rfMRIrawFolder}/${OrigTCSName}_temp ${DelVols} $(( ${dimt} - ${DelVols} - 1 ))
    $FSLDIR/bin/imrm ${rfMRIrawFolder}/${OrigTCSName}
    $FSLDIR/bin/immv ${rfMRIrawFolder}/${OrigTCSName}_temp ${rfMRIrawFolder}/${OrigTCSName}

fi

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

if [ $CLUSTER_MODE = "YES" ] ; then

#    export MODULEPATH=/gpfs01/software/imaging/modulefiles:$MODULEPATH
#
#    module load cuda/local/9.2
#    module load ica-aroma-img/py2.7/0.3
#    module load matlab-uon

    jobID1=`${JOBSUBpath}/jobsub -q cpu -p 1 -s BRC_1_fMRI_${Subject} -t 01:00:00 -m 60 -c "${BRC_FMRI_SCR}/fMRI_preproc_part_1.sh --gdc=${GradientDistortionCoeffs} --rfmrirawfolder=${rfMRIrawFolder} --origtcsname=${OrigTCSName} --gdcfolder=${gdcFolder} --nameoffmri=${NameOffMRI} --origscoutname=${OrigScoutName} --scoutname=${ScoutName} --distortioncorrection=${DistortionCorrection} --dcfolder=${DCFolder} --topupfoldername=${topupFolderName} --spinechophaseencodenegative=${SpinEchoPhaseEncodeNegative} --spinechophaseencodepositive=${SpinEchoPhaseEncodePositive} --echospacing=${EchoSpacing} --unwarpdir=${UnwarpDir} --logfile=${logFolder}/${log_Name}" &`
    jobID1=`echo -e $jobID1 | awk '{ print $NF }'`
    echo "jobID_1: ${jobID1}"

    jobID2=`${JOBSUBpath}/jobsub -q gpu -p 1 -g 1 -s BRC_2_fMRI_${Subject} -t 10:00:00 -m 60 -w ${jobID1} -c "${BRC_FMRI_SCR}/fMRI_preproc_part_2.sh --motioncorrectiontype=${MotionCorrectionType} --mcfolder=${mcFolder} --nameoffmri=${NameOffMRI} --regfolder=${regFolder} --fmri2stroutputtransform=${fMRI2strOutputTransform} --gdcfolder=${gdcFolder} --scoutname=${ScoutName} --movementregressor=${MovementRegressor} --motionmatrixfolder=${MotionMatrixFolder} --motionmatrixprefix=${MotionMatrixPrefix} --eddyfolder=${EddyFolder} --eddyoutput=${EddyOutput} --dcmethod=${DistortionCorrection} --topupfodername=${topupFolderName} --dcfolder=${DCFolder} --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} --SEPhasePos=${SpinEchoPhaseEncodePositive} --unwarpdir=${UnwarpDir} --echospacing=${EchoSpacing} --echospacingfmri=${EchoSpacing_fMRI} --slice2vol=${Slice2Volume} --slicespec=${SliceSpec} --logfile=${logFolder}/${log_Name}" &`
    jobID2=`echo -e $jobID2 | awk '{ print $NF }'`
    echo "jobID_2: ${jobID2}"

    jobID3=`${JOBSUBpath}/jobsub -q cpu -p 1 -s BRC_3_fMRI_${Subject} -t 12:00:00 -m 80 -w ${jobID2} -c "${BRC_FMRI_SCR}/fMRI_preproc_part_3.sh --slicetimingcorrection=${SliceTimingCorrection} --stcfolder=${stcFolder} --stcinput=${STC_Input} --nameoffmri=${NameOffMRI} --slicetimingfile=${SliceTimingFile} --dcfolder=${DCFolder} --subjectfolder=${AnalysisFolder} --fmrifolder=${TempFolder} --topupfodername=${topupFolderName} --sebffoldername=${sebfFolderName} --gdcfolder=${gdcFolder} --scoutname=${ScoutName} --t1=${dataT1Folder}/${T1wImage} --t1brain=${dataT1Folder}/${T1wRestoreImageBrain} --t1brainmask=${dataT1Folder}/${T1wImageBrainMask} --wmseg=${wmseg} --gmseg=${GMseg} --dof=${dof} --method=${DistortionCorrection} --biascorrection=${BiasCorrection} --usejacobian=${UseJacobian} --motioncorrectiontype=${MotionCorrectionType} --eddyoutname=${EddyOutput} --regfolder=${regFolder} --oregim=${RegOutput} --owarp=${fMRI2strOutputTransform} --oinwarp=${str2fMRIOutputTransform} --ojacobian=${JacobianOut} --osrfolder=${OsrFolder} --t12std=${data2stdT1Folder} --fmriresout=${FinalfMRIResolution} --outfmri2stdtrans=${OutputfMRI2StandardTransform} --oiwarp=${Standard2OutputfMRITransform} --nrfolder=${nrFolder} --fwhm=${smoothingfwhm} --icaaroma=${Do_ica_aroma} --motionparam=${SSNR_motionparam} --pnmfolder=${pnmFolder} --physinputtxt=${PhysInputTXT} --samplingrate=${SamplingRate} --smoothcardiac=${SmoothCardiac} --smoothresp=${SmoothResp} --colresp=${ColResp} --colcardiac=${ColCardiac} --coltrigger=${ColTrigger} --dorvt=${DO_RVT} --sliceorder=${SliceOrder} --sebffolder=${SE_BF_Folder} --regt1folder=${regT1Folder} --eddyfolder=${EddyFolder} --innrmfolder=${In_Nrm_Folder} --dointensitynorm=${Do_intensity_norm} --tempfiltercutoff=${Temp_Filter_Cutoff} --mcfolder=${mcFolder} --motionmatdir=${MotionMatrixFolder} --motionmatprefix=${MotionMatrixPrefix} --doqc=${DO_QC} --qcfolder=${qcFolder} --rfmrirawfolder=${rfMRIrawFolder} --rfmrifolder=${rfMRIFolder} --preprocfolder=${preprocFolder} --processedfolder=${processedFolder} --topupfolder=${TOPUP_Folder} --start=${Start_Time} --subject=${Subject} --SEPhasePos=${SpinEchoPhaseEncodePositive} --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} --tmpfiltfolder=${Tmp_Filt_Folder} --deleteintermediates=${DeleteIntermediates} --logfile=${logFolder}/${log_Name}" &`
    jobID3=`echo -e $jobID3 | awk '{ print $NF }'`
    echo "jobID_3: ${jobID3}"


else

    ${BRC_FMRI_SCR}/fMRI_preproc_part_1.sh \
                    --gdc=${GradientDistortionCoeffs} \
                    --rfmrirawfolder=${rfMRIrawFolder} \
                    --origtcsname=${OrigTCSName} \
                    --gdcfolder=${gdcFolder} \
                    --nameoffmri=${NameOffMRI} \
                    --origscoutname=${OrigScoutName} \
                    --scoutname=${ScoutName} \
                    --distortioncorrection=${DistortionCorrection} \
                    --dcfolder=${DCFolder} \
                    --topupfoldername=${topupFolderName} \
                    --spinechophaseencodenegative=${SpinEchoPhaseEncodeNegative} \
                    --spinechophaseencodepositive=${SpinEchoPhaseEncodePositive} \
                    --echospacing=${EchoSpacing} \
                    --unwarpdir=${UnwarpDir} \
                    --logfile=${logFolder}/${log_Name}


    ${BRC_FMRI_SCR}/fMRI_preproc_part_2.sh \
                    --motioncorrectiontype=${MotionCorrectionType} \
                    --mcfolder=${mcFolder} \
                    --nameoffmri=${NameOffMRI} \
                    --regfolder=${regFolder} \
                    --fmri2stroutputtransform=${fMRI2strOutputTransform} \
                    --gdcfolder=${gdcFolder} \
                    --scoutname=${ScoutName} \
                    --movementregressor=${MovementRegressor} \
                    --motionmatrixfolder=${MotionMatrixFolder} \
                    --motionmatrixprefix=${MotionMatrixPrefix} \
                    --eddyfolder=${EddyFolder} \
                    --eddyoutput=${EddyOutput} \
                    --dcmethod=${DistortionCorrection} \
                    --topupfodername=${topupFolderName} \
                    --dcfolder=${DCFolder} \
                    --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
                    --SEPhasePos=${SpinEchoPhaseEncodePositive} \
                    --unwarpdir=${UnwarpDir} \
                    --echospacing=${EchoSpacing} \
                    --echospacingfmri=${EchoSpacing_fMRI} \
                    --slice2vol=${Slice2Volume} \
                    --slicespec=${SliceSpec} \
                    --logfile=${logFolder}/${log_Name}


    ${BRC_FMRI_SCR}/fMRI_preproc_part_3.sh \
                    --slicetimingcorrection=${SliceTimingCorrection} \
                    --stcfolder=${stcFolder} \
                    --stcinput=${STC_Input} \
                    --nameoffmri=${NameOffMRI} \
                    --slicetimingfile=${SliceTimingFile} \
                    --dcfolder=${DCFolder} \
                    --subjectfolder=${AnalysisFolder} \
                    --fmrifolder=${TempFolder} \
                    --topupfodername=${topupFolderName} \
                    --sebffoldername=${sebfFolderName} \
                    --gdcfolder=${gdcFolder} \
                    --scoutname=${ScoutName} \
                    --t1=${dataT1Folder}/${T1wImage} \
                    --t1brain=${dataT1Folder}/${T1wRestoreImageBrain} \
                    --t1brainmask=${dataT1Folder}/${T1wImageBrainMask} \
                    --wmseg=${wmseg} \
                    --gmseg=${GMseg} \
                    --dof=${dof} \
                    --method=${DistortionCorrection} \
                    --biascorrection=${BiasCorrection} \
                    --usejacobian=${UseJacobian} \
                    --motioncorrectiontype=${MotionCorrectionType} \
                    --eddyoutname=${EddyOutput} \
                    --regfolder=${regFolder} \
                    --oregim=${RegOutput} \
                    --owarp=${fMRI2strOutputTransform} \
                    --oinwarp=${str2fMRIOutputTransform} \
                    --ojacobian=${JacobianOut} \
                    --osrfolder=${OsrFolder} \
                    --t12std=${data2stdT1Folder} \
                    --fmriresout=${FinalfMRIResolution} \
                    --outfmri2stdtrans=${OutputfMRI2StandardTransform} \
                    --oiwarp=${Standard2OutputfMRITransform} \
                    --nrfolder=${nrFolder} \
                    --fwhm=${smoothingfwhm} \
                    --icaaroma=${Do_ica_aroma} \
                    --motionparam=${SSNR_motionparam} \
                    --pnmfolder=${pnmFolder} \
                    --physinputtxt=${PhysInputTXT} \
                    --samplingrate=${SamplingRate} \
                    --smoothcardiac=${SmoothCardiac} \
                    --smoothresp=${SmoothResp} \
                    --colresp=${ColResp} \
                    --colcardiac=${ColCardiac} \
                    --coltrigger=${ColTrigger} \
                    --dorvt=${DO_RVT} \
                    --sliceorder=${SliceOrder} \
                    --sebffolder=${SE_BF_Folder} \
                    --regt1folder=${regT1Folder} \
                    --eddyfolder=${EddyFolder} \
                    --innrmfolder=${In_Nrm_Folder} \
                    --dointensitynorm=${Do_intensity_norm} \
                    --tempfiltercutoff=${Temp_Filter_Cutoff} \
                    --mcfolder=${mcFolder} \
                    --motionmatdir=${MotionMatrixFolder} \
                    --motionmatprefix=${MotionMatrixPrefix} \
                    --doqc=${DO_QC} \
                    --qcfolder=${qcFolder} \
                    --rfmrirawfolder=${rfMRIrawFolder} \
                    --rfmrifolder=${rfMRIFolder} \
                    --preprocfolder=${preprocFolder} \
                    --processedfolder=${processedFolder} \
                    --topupfolder=${TOPUP_Folder} \
                    --start=${Start_Time} \
                    --subject=${Subject} \
                    --SEPhasePos=${SpinEchoPhaseEncodePositive} \
                    --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
                    --tmpfiltfolder=${Tmp_Filt_Folder} \
                    --deleteintermediates=${DeleteIntermediates} \
                    --logfile=${logFolder}/${log_Name}

fi

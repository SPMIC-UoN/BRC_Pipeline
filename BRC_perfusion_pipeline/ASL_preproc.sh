#!/bin/bash
# Last update: 04/07/2024

# Authors: Stefan Pszczolkowski, Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
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
  echo "`basename $0`: Process single-TI pseudo-continuous arterial spin labelling data (difference and calibration images)"
  echo " "
  echo "Usage: `basename $0`"
  echo "Compulsory arguments (You MUST set one or more of):"
  echo " --input_pwi <path>                   full path of the filename of difference (perfusion-weighted) image"
  echo " --input_m0 <path>                    full path of the filename of calibration (M0) image"
  echo " --path <path>                        output directory"
  echo " --subject <subject name>             output directory is a subject name folder in input image directory"
  echo " "
  echo "Optional arguments (You may optionally specify one or more of):"
  echo " --tr                                 Repetition time (TR) of calibration data (default 3.2 sec)"
  echo " --ti                                 Inversion time (TI) of calibration data (default 3.0 sec)"
  echo " --bolus                              Bolus (labelling) duration (default 1)"
  echo " --cgain                              Relative gain between calibration and ASL image (default 1)"
  echo " --pvcmethod <method>                 Partial volume correction method on quantified CBF map"
  echo "                                      Values: MLTS and NONE (default)"
  echo " --name <folder name>                 Output folder name of the functional analysis pipeline. Default: aslMRI"
  echo " --help                               help"
  echo " "
  echo " "
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi

################################################## OPTION PARSING #####################################################

log=`echo "$@"`

# default values
TR="3.2"
TI="3"
Bolus="1"
Cgain="1"
PartialVolumeCorrection="NONE"
OutFolderName="aslMRI"
dof="6"
superlevel="4"
PathOfaslMRI=
PathOfM0aslMRI=

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

      --input_pwi )           shift
                              PathOfaslMRI=$1
                              ;;

      --input_m0 )            shift
                              PathOfM0aslMRI=$1
                              ;;

      --tr )                  shift
                              TR=$1
                              ;;

      --ti )                  shift
                              TI=$1
                              ;;

      --bolus )               shift
                              Bolus=$1
                              ;;

      --cgain )               shift
                              Cgain=$1
                              ;;

      --pvcmethod )           shift
                              PartialVolumeCorrection=$1
                              # Convert PartialVolumeCorrection value to all UPPERCASE (to allow the user the flexibility to use NONE, None, none, MLTS, mLTS, mlts, etc.)
                              PartialVolumeCorrection="$(echo ${PartialVolumeCorrection} | tr '[:lower:]' '[:upper:]')"
                              ;;

      --name )                shift
                              OutFolderName=$1
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

if [ X$Path = X ] || [ X$Subject = X ] || [ X$PathOfaslMRI = X ] || [ X$PathOfM0aslMRI = X ] ; then
    echo ""
    echo "All of the compulsory arguments --path, --subject, --input_pwi and --input_m0 MUST be used"
    echo ""
    exit 1;
fi

if [[ "$PartialVolumeCorrection" != "NONE" ]] && [[ "$PartialVolumeCorrection" != "MLTS" ]]; then
    echo ""
    echo "Invalid partial volume correction method: $PartialVolumeCorrection. Valud values are MLTS and NONE"
    echo ""
    exit 1;
fi

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

AnalysisFolderName="analysis"
aslMRIFolderName=${OutFolderName}
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
PVCFolderName="pvc"
regFolderName="reg"
dataFolderName="data"
data2stdFolderName="data2std"

NameOfaslMRI="aslMRI"
OrigASLName="${NameOfaslMRI}_orig"
aslMRI2strOutputTransform="${NameOfaslMRI}2str.mat"
str2aslMRIOutputTransform="str2${NameOfaslMRI}.mat"
aslMRI2StandardTransform="${NameOfaslMRI}2std"
Standard2aslMRITransform="std2${NameOfaslMRI}"
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
    echo "Perfusion preprocessing depends on the outputs generated by Structural preprocessing. So perfusion"
    echo "preprocessing should not be attempted on data sets for which structural preprocessing is not yet complete."
    echo ""
    exit;
fi

rawFolder=${Path}/${rawFolderName}
aslMRIrawFolder=${rawFolder}/${aslMRIFolderName}
aslMRIFolder=${AnalysisFolder}/${aslMRIFolderName}
logFolder=${aslMRIFolder}/${logFolderName}
preprocFolder=${aslMRIFolder}/${preprocessFolderName}
processedFolder=${aslMRIFolder}/${processedFolderName}
TempFolder=${aslMRIFolder}/${tempFolderName}
regFolder=${TempFolder}/${regFolderName}
PVCFolder=${TempFolder}/${PVCFolderName}
preprocT1Folder=${T1Folder}/${preprocessFolderName}
processedT1Folder=${T1Folder}/${processedFolderName}
dataT1Folder=${processedT1Folder}/${dataFolderName}
data2stdT1Folder=${processedT1Folder}/${data2stdFolderName}
segT1Folder=${processedT1Folder}/${segFolderName}
TissueT1Folder=${segT1Folder}/${TissueFolderName}
SinChanT1Folder=${TissueT1Folder}/${SingChanFolderName}
regT1Folder=${preprocT1Folder}/${regFolderName}

mkdir -p ${TempFolder}
if [ ! -d ${aslMRIrawFolder} ]; then mkdir ${aslMRIrawFolder}; fi
if [ -e ${logFolder} ] ; then rm -r ${logFolder}; fi; mkdir ${logFolder}
if [ ! -d ${preprocFolder} ]; then mkdir ${preprocFolder}; fi
if [ ! -d ${processedFolder} ]; then mkdir ${processedFolder}; fi
if [ ! -d ${regFolder} ]; then mkdir ${regFolder}; fi
if [ ! -d ${PVCFolder} ]; then mkdir ${PVCFolder}; fi

#=====================================================================================
###                              Setup the Log file
#=====================================================================================

${BRCDIR}/Show_version.sh \
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
log_Msg 2 "PathOfaslMRI: $PathOfaslMRI"
log_Msg 2 "PathOfM0aslMRI: $PathOfM0aslMRI"
log_Msg 2 "PartialVolumeCorrection: $PartialVolumeCorrection"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

log_Msg 3 "OutputDir is: ${aslMRIFolder}"

$FSLDIR/bin/imcp ${PathOfaslMRI} ${aslMRIrawFolder}/${OrigASLName}_PWI.nii.gz
$FSLDIR/bin/imcp ${PathOfM0aslMRI} ${aslMRIrawFolder}/${OrigASLName}_M0.nii.gz

if [ $CLUSTER_MODE = "YES" ] ; then

    jobID1=`${JOBSUBpath}/jobsub -q cpu -p 1 -s BRC_PMRI_${Subject} -t 00:30:00 -m 60 -c "${BRC_PMRI_SCR}/aslMRI_preproc_part_1.sh --aslmrirawfolder=${aslMRIrawFolder} --origaslname=${OrigASLName} --nameofaslmri=${NameOfaslMRI} --sinchanfolder=${SinChanT1Folder} --pvcmethod=${PartialVolumeCorrection} --owarp=${aslMRI2strOutputTransform} --oinwarp=${str2aslMRIOutputTransform} --outasl2stdtrans=${aslMRI2StandardTransform} --outstd2asltrans=${Standard2aslMRITransform} --pvcfolder=${PVCFolder} --datat1folder=${dataT1Folder} --regfolder=${regFolder} --regt1folder=${regT1Folder} --preprocfolder=${preprocFolder} --processedfolder=${processedFolder} --tr=${TR} --ti=${TI} --bolus=${Bolus} --cgain=${Cgain} --dof=${dof} --superlevel=${superlevel} --subject=${Subject} --start=${Start_Time} --logfile=${logFolder}/${log_Name}" &`
    jobID1=`echo -e $jobID1 | awk '{ print $NF }'`
    echo "jobID_1: ${jobID1}"

else

    ${BRC_PMRI_SCR}/aslMRI_preproc_part_1.sh \
                    --aslmrirawfolder=${aslMRIrawFolder} \
                    --origaslname=${OrigASLName} \
                    --nameofaslmri=${NameOfaslMRI} \
                    --sinchanfolder=${SinChanT1Folder} \
                    --pvcmethod=${PartialVolumeCorrection} \
                    --owarp=${aslMRI2strOutputTransform} \
                    --oinwarp=${str2aslMRIOutputTransform} \
                    --outasl2stdtrans=${aslMRI2StandardTransform} \
                    --outstd2asltrans=${Standard2aslMRITransform} \
                    --pvcfolder=${PVCFolder} \
					--datat1folder=${dataT1Folder} \
                    --regfolder=${regFolder} \
                    --regt1folder=${regT1Folder} \
                    --preprocfolder=${preprocFolder} \
                    --processedfolder=${processedFolder} \
                    --tr=${TR} \
                    --ti=${TI} \
                    --bolus=${Bolus} \
                    --cgain=${Cgain} \
                    --dof=${dof} \
                    --superlevel=${superlevel} \
                    --subject=${Subject} \
                    --start=${Start_Time} \
                    --logfile=${logFolder}/${log_Name}

fi

#!/bin/bash
# Last update: 09/10/2018
#Example:
#./struc_preproc.sh --path ~/main/analysis -s Sub_002 -i ~/P_Share/Images/3T_Harmonisation_Stam/03286_20180307_Ingenia/NIFTI/1_MPRAGE/__T1_1mm_sag_20180307162159_201.nii.gz -t2 ~/P_Share/Images/3T_Harmonisation_Stam/03286_20180307_Ingenia/NIFTI/2_3D_T2w_FLAIR/__T2_FLAIR_1mm_20180307162159_301.nii.gz --subseg

# -e  Exit immediately if a command exits with a non-zero status.
set -e

#export ScriptsDir=$(dirname "$(readlink -f "$0")") #Absolute path where scripts are
#source ${ScriptsDir}/init_vars.sh

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
  echo " --input <T1W image>              Full path of the input image (for one image only)"
  echo " --path <full path>               Output path"
  echo " --subject <Subject name>         Output directory is a subject name folder in output path directory"
  echo " "
  echo "Optional arguments (You may optionally specify one or more of):"
  echo " -t2 <T2W image>                  Full path of the input T2W image (for processing of T2 data)"
  echo " --freesurfer                     Turn on Freesurfer processing pipeline"
  echo " --subseg                         Turn on subcortical segmentation by FIRST"
  echo " --qc                             Turn on quality control of T1 data"
  echo " --strongbias                     Turn on for images with very strong bias fields"
  echo " --noreg                          Turn off steps that do registration to standard (FLIRT and FNIRT)"
  echo " --noseg                          Turn off the step that does tissue-type segmentation (FAST)"
  echo " --nocrop                         Turn off the step that does automated cropping"
  echo " --nodefacing                     Turn off the step that does automated brain defacing"
  echo " -h | --help                      help"
  echo " "
  echo " "
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi

################################################## OPTION PARSING #####################################################

log=`echo "$@"`

# default values
Sub_ID=""
IN_Img=""
Path=""
T2_IN_Img=""

T2="no"
do_Sub_seg="no"
do_QC="no"
do_freesurfer="no"
do_tissue_seg="yes"
do_anat_based_on_FS="yes"
do_crop="yes"
do_defacing="yes"

Opt_args="--clobber"

# parse arguments
while [ "$1" != "" ]; do
    case $1 in
        --subject )             shift
                                Sub_ID=$1
                                ;;

        --path )                shift
				                        Path=$1
                                ;;

        --input )               shift
				                        IN_Img=$1
                                ;;

        -t2 )                   shift
				                        T2_IN_Img=$1
                		            T2=yes
                                ;;

        --subseg )           	  do_Sub_seg=yes
                                ;;

        --qc )           	      do_QC=yes
                                ;;

        --strongbias )          Opt_args="$Opt_args --strongbias"
                                ;;

        --noreg )          	    Opt_args="$Opt_args --noreg"
                                ;;

        --noseg )         	    Opt_args="$Opt_args --noseg"
                                do_tissue_seg=no
                                ;;

        --freesurfer )         	do_freesurfer=yes
                                ;;

        -ft | --FAST_t )        shift
				                        FAST_t=$1
                                ;;

        --nocrop)               do_crop="no";
                                ;;

        --nodefacing)           do_defacing="no";
                                ;;

        -h | --help )           Usage
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
if [ X$Sub_ID = X ] && [ X$IN_Img = X ] && [ X$Path = X ] ; then
    echo "All of the compulsory arguments --path, -i and -s MUST be used"
    exit 1;
fi

#Set fsl_anat options
if [ $do_Sub_seg = "no" ] ; then
    Opt_args="$Opt_args --nosubcortseg"
fi
if [ $do_crop = "no" ] ; then
    Opt_args="$Opt_args --nocrop"
fi

Opt_args="$Opt_args -t $FAST_t"

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

AnalysisFolderName="analysis"
AnatMRIFolderName="anatMRI"
T1FolderName="T1"
T2FolderName="T2"
rawFolderName="raw"
preprocessFolderName="preproc"
processedFolderName="processed"
tempFolderName="temp"
logFolderName="log"
regFolderName="reg"
qcFolderName="qc"
biasFolderName="bias"
dataFolderName="data"
data2stdFolderName="data2std"
segFolderName="seg"
FSFolderName="FS"
FastFolderName="FAST"
FirstFolderName="FIRST"

log_Name="log.txt"

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

O_DIR=$Path/${Sub_ID};
if [ ! -d "$O_DIR" ]; then
    mkdir -p $O_DIR;
#else
#  O_DIR="${O_DIR}_$(date +"%d-%m-%Y_%H-%M")"
#  mkdir $O_DIR
fi

AnalysisFolder=${O_DIR}/${AnalysisFolderName}
AnatMRIFolder=${AnalysisFolder}/${AnatMRIFolderName}
rawFolder=${O_DIR}/${rawFolderName}
AnatMRIrawFolder=${rawFolder}/${AnatMRIFolderName}
T1Folder=${AnatMRIFolder}/${T1FolderName}
rawT1Folder=${AnatMRIrawFolder}/${T1FolderName}
preprocT1Folder=${T1Folder}/${preprocessFolderName}
processedT1Folder=${T1Folder}/${processedFolderName}
logT1Folder=${T1Folder}/${logFolderName}
TempT1Folder=${T1Folder}/${tempFolderName}
FastT1Folder=${TempT1Folder}/${FastFolderName}
FirstT1Folder=${TempT1Folder}/${FirstFolderName}
regTempT1Folder=${TempT1Folder}/${regFolderName}
regT1Folder=${preprocT1Folder}/${regFolderName}
qcT1Folder=${preprocT1Folder}/${qcFolderName}
biasT1Folder=${preprocT1Folder}/${biasFolderName}
dataT1Folder=${processedT1Folder}/${dataFolderName}
data2stdT1Folder=${processedT1Folder}/${data2stdFolderName}
segT1Folder=${processedT1Folder}/${segFolderName}
FSFolder=${processedT1Folder}/${FSFolderName}
rawT2Folder=${AnatMRIrawFolder}/${T2FolderName}
T2Folder=${AnatMRIFolder}/${T2FolderName}
preprocT2Folder=${T2Folder}/${preprocessFolderName}
processedT2Folder=${T2Folder}/${processedFolderName}
dataT2Folder=${processedT2Folder}/${dataFolderName}
data2stdT2Folder=${processedT2Folder}/${data2stdFolderName}
regT2Folder=${preprocT2Folder}/${regFolderName}
TempT2Folder=${T2Folder}/${tempFolderName}
regTempT2Folder=${TempT2Folder}/${regFolderName}

#Check existance of foldersa= and then create them
if [ ! -d ${AnalysisFolder} ]; then mkdir ${AnalysisFolder}; fi
if [ ! -d ${AnatMRIFolder} ]; then mkdir ${AnatMRIFolder}; fi
if [ ! -d ${rawFolder} ]; then mkdir ${rawFolder}; fi
if [ ! -d ${AnatMRIrawFolder} ]; then mkdir ${AnatMRIrawFolder}; fi
if [ ! -d ${T1Folder} ]; then mkdir ${T1Folder}; fi
if [ ! -d ${rawT1Folder} ]; then mkdir ${rawT1Folder}; fi
if [ ! -d ${preprocT1Folder} ]; then mkdir ${preprocT1Folder}; fi
if [ ! -d ${processedT1Folder} ]; then mkdir ${processedT1Folder}; fi
if [ -e ${logT1Folder} ] ; then rm -r ${logT1Folder}; fi; mkdir ${logT1Folder}
if [ ! -d ${TempT1Folder} ]; then mkdir ${TempT1Folder}; fi
if [ ! -d ${regT1Folder} ]; then mkdir ${regT1Folder}; fi
if [ ! -d ${qcT1Folder} ]; then mkdir ${qcT1Folder}; fi
if [ ! -d ${biasT1Folder} ]; then mkdir ${biasT1Folder}; fi
if [ ! -d ${dataT1Folder} ]; then mkdir ${dataT1Folder}; fi
if [ ! -d ${data2stdT1Folder} ]; then mkdir ${data2stdT1Folder}; fi
if [ ! -d ${segT1Folder} ]; then mkdir ${segT1Folder}; fi


if [[ $T2 == yes ]]; then
    if [ ! -d ${T2Folder} ]; then mkdir ${T2Folder}; fi
    if [ ! -d ${rawT2Folder} ]; then mkdir ${rawT2Folder}; fi
    if [ ! -d ${preprocT2Folder} ]; then mkdir ${preprocT2Folder}; fi
    if [ ! -d ${processedT2Folder} ]; then mkdir ${processedT2Folder}; fi
    if [ ! -d ${dataT2Folder} ]; then mkdir ${dataT2Folder}; fi
    if [ ! -d ${data2stdT2Folder} ]; then mkdir ${data2stdT2Folder}; fi
    if [ ! -d ${regT2Folder} ]; then mkdir ${regT2Folder}; fi
    if [ ! -d ${TempT2Folder} ]; then mkdir ${TempT2Folder}; fi
fi

#=====================================================================================
###                              Setup the Log file
#=====================================================================================

${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="no" \
      --logfile=${logT1Folder}/${log_Name}
Start_Time="$(date -u +%s)"

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions
log_SetPath "${logT1Folder}/${log_Name}"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "Original command:"
log_Msg 2 "$log"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "Parsing Command Line Options"
log_Msg 2 "Sub_ID: $Sub_ID"
log_Msg 2 "Path: $Path"
log_Msg 2 "IN_Img: $IN_Img"
log_Msg 2 "T2_IN_Img: $T2_IN_Img"
log_Msg 2 "do_Sub_seg: $do_Sub_seg"
log_Msg 2 "do_QC: $do_QC"
log_Msg 2 "do_tissue_seg: $do_tissue_seg"
log_Msg 2 "do_freesurfer: $do_freesurfer"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

log_Msg 3 "OutputDir is: ${AnatMRIFolder}"

$FSLDIR/bin/imcp $IN_Img ${rawT1Folder}/T1_orig.nii.gz

if [[ $T2 == "yes" ]]; then
    $FSLDIR/bin/imcp $T2_IN_Img ${rawT2Folder}/T2_orig.nii.gz
fi

${BRC_SCTRUC_SCR}/run_T1_preprocessing.sh \
      --workingdir=${TempT1Folder} \
      --t1input=${rawT1Folder}/T1_orig.nii.gz \
      --dosubseg=${do_Sub_seg} \
      --dotissueseg=${do_tissue_seg} \
      --docrop=${do_crop} \
      --dodefacing=${do_defacing} \
      --fastfolder=${FastT1Folder} \
      --firstfolder=${FirstT1Folder} \
      --regtempt1folder=${regTempT1Folder} \
      --logfile=${logT1Folder}/${log_Name}


if [[ $T2 == "yes" ]]; then

      ${BRC_SCTRUC_SCR}/run_T2_preprocessing.sh \
            --workingdir=${TempT2Folder} \
            --t2input=${rawT2Folder}/T2_orig.nii.gz \
            --tempt1folder=${TempT1Folder} \
            --fastfolder=${FastT1Folder} \
            --regtempt1folder=${regTempT1Folder} \
            --regtempt2folder=${regTempT2Folder} \
            --dodefacing=${do_defacing} \
            --logfile=${logT1Folder}/${log_Name}

fi


${BRC_SCTRUC_SCR}/output_organization.sh \
      --t1folder=${T1Folder} \
      --t2folder=${T2Folder} \
      --rawt1folder=${rawT1Folder} \
      --fastfolder=${FastT1Folder} \
      --firstfolder=${FirstT1Folder} \
      --regtempt1folder=${regTempT1Folder} \
      --biast1folder=${biasT1Folder} \
      --dosubseg=${do_Sub_seg} \
      --datat1folder=${dataT1Folder} \
      --data2stdt1folder=${data2stdT1Folder} \
      --segt1folder=${segT1Folder} \
      --regt1folder=${regT1Folder} \
      --tempt1folder=${TempT1Folder} \
      --t2exist=${T2} \
      --tempt2folder=${TempT2Folder} \
      --rawt2folder=${rawT2Folder} \
      --dotissueseg=${do_tissue_seg} \
      --datat2folder=${dataT2Folder} \
      --data2stdt2folder=${data2stdT2Folder} \
      --regt2folder=${regT2Folder} \
      --regtempt2folder=${regTempT2Folder} \
      --dodefacing=${do_defacing} \
      --logfile=${logT1Folder}/${log_Name}


if [[ $do_freesurfer == "yes" ]]; then
    SUBJECTS_DIR=${processedT1Folder}

    log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    log_Msg 3 "+                                                                        +"
    log_Msg 3 "+                       START: FreeSurfer Analysis                       +"
    log_Msg 3 "+                                                                        +"
    log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

    if [ -e "${processedT1Folder}/${FSFolderName}" ] ; then
        rm -r ${processedT1Folder}/${FSFolderName}
    fi

    if [[ $T2 == yes ]]; then
        recon-all -i ${rawT1Folder}/T1_orig.nii.gz -s FS -FLAIR ${rawT2Folder}/T2_orig.nii.gz -all
    else
        recon-all -i ${rawT1Folder}/T1_orig.nii.gz -s FS -all
    fi

    rm -r ${processedT1Folder}/fsaverage
fi


END_Time="$(date -u +%s)"


${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Sub_ID} \
      --type=1 \
      --logfile=${logT1Folder}/${log_Name}

#: <<'COMMENT'

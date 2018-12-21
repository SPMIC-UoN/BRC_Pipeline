#!/bin/bash
# Last update: 01/10/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#

# Preprocessing Pipeline for diffusion MRI. Generates the "data" directory that can be used as input to fibre orientation estimation.
#Example:
#./dMRI_preproc.sh -i1 ~/main/analysis/DTI/001/5_6_Diffusion_MB3_b1k_2k_100dir_b0rev/__DTI_Biobank_2mm_MB3S2_EPI_20180307162159_701.nii.gz -i2 ~/main/analysis/DTI/001/5_6_Diffusion_MB3_b1k_2k_100dir_b0rev/__blip_DTI_Biobank_2mm_MB3S2_EPI_20180307162159_601.nii.gz --path ~/main/analysis -s Sub_001 -p 2 -e 0.78 -c 2 --slice2vol --slspec ~/main/analysis/Orig/3_4_dMRI_b_1k_2k_100dir_b0rev/__DTI_Biobank_2mm_MB3S2_EPI_20180312094206_501.json

set -e

#Hard-Coded variables for the pipeline
b0dist=150     #Minimum distance in volumes between b0s considered for preprocessing
b0maxbval=50  #Volumes with a bvalue smaller than that will be considered as b0s

#ScriptsDir=$(dirname "$(readlink -f "$0")") #Absolute path where scripts are

if [ "x$SGE_ROOT" = "x" ] ; then
    if [ -f /usr/local/share/sge/default/common/settings.sh ] ; then
	. /usr/local/share/sge/default/common/settings.sh
    elif [ -f /usr/local/sge/default/common/settings.sh ] ; then
	. /usr/local/sge/default/common/settings.sh
    fi
fi

make_absolute()
{
    dir=$1;

    if [ -d ${dir} ]; then
        OLDWD=`pwd`
      	cd ${dir}
      	dir_all=`pwd`
      	cd $OLDWD
    else
    	 dir_all=${dir}
    fi

    echo ${dir_all}
}

Usage()
{
  echo " "
  echo " "
  echo "`basename $0`: Description"
  echo " "
  echo "Usage: `basename $0`"
  echo "Compulsory arguments (You MUST set one or more of):"
  echo " --input <path>	                 dataLR(AP)1@dataLR(AP)2@...dataLR(AP)N, filenames of input images (For input filenames,"
  echo "                                 if for a LR/RL (AP/PA) pair one of the two files are missing set the entry to EMPTY)"
  echo " --path <path>                   output durectory. Please provide absolute path"
  echo " --subject <subject name>        output directory is a subject name folder in output path directory"
  echo " --echospacing <value>           EchoSpacing should be in Sec"
  echo " --pe_dir <value>                Phase Encoding Direction"
  echo "                                      1 for LR/RL,"
  echo "                                      2 for AP/PA"
  echo " "
  echo "Optional arguments (You may optionally specify one or more of):"
  echo " --input_2 <path>                dataRL(PA)1@dataRL(PA)2@...dataRL(PA)N, filenames of input images (reverse phase encoding direction),"
  echo "                                 Set to NONE if not available (default)"
  echo " --qc                            turn on steps that do quality control of dMRI data"
  echo " --reg                           turn on steps that do registration to standard (FLIRT and FNIRT)"
  echo " --slice2vol                     If one wants to do slice-to-volome motion correction"
  echo " --slspec <path>                 Specifies a .json file (created by your DICOM->niftii conversion software) that describes how the"
  echo "                                 slices/multi-band-groups were acquired. This file is necessary when using the slice-to-vol movement correction"
  echo " --cm_flag <value>               CombineMatchedFlag"
  echo "                                      2 for including in the output all volumes uncombined,"
  echo "                                      1 for including in the output and combine only volumes where both LR/RL (or AP/PA) pairs have been acquired,"
  echo "                                      0 for including (uncombined) single volumes as well (default)"
  echo " --p_im <value>                  ParallelImaging_Factor, In-plane parallel imaging factor"
  echo "                                      1 for No_Parallel_Imaging"
  echo " --help                          help"
  echo " "
  echo " "
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi

################################################## OPTION PARSING #####################################################

log=`echo "$@"`

# default values
InputImages2="NONE"
Slice2Volume="no"
SliceSpec="NONE"
echospacing=
PEdir=
CombineMatched=0
PIFactor=1

do_QC=no
do_REG=no
Apply_Topup=yes

# parse arguments
while [ "$1" != "" ]; do
    case $1 in
        --path )                shift
                                Path=`make_absolute $1`
                                ;;

        --subject )             shift
                                Subject=$1
                                ;;

        --input )               shift
                                InputImages=$1
                                ;;

        --input_2 )             shift
                                InputImages2=$1
                                ;;

        --qc )           	      do_QC=yes
                                ;;

        --reg )           	    do_REG=yes
                                ;;

        --slice2vol )           Slice2Volume=yes
                                ;;

        --slspec )              shift
                                SliceSpec=$1
                                ;;

        --echospacing )         shift
                                echospacing=$1
                                ;;

        --pe_dir )              shift
                                PEdir=$1
                                ;;

        --cm_flag )             shift
                                CombineMatched=$1
                                ;;

        --p_im )                shift
                                PIFactor=$1
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

if [ X$Subject = X ] || [ X$InputImages = X ] || [ X$Path = X ] || [ X$echospacing = X ] || [ X$PEdir = X ] ; then
    echo ""
    echo "All of the compulsory arguments --path, --input, --subject, --pe_dir, and --echospacing MUST be used"
    echo ""
    exit 1;
fi

if [ $InputImages2 = "NONE" ] ; then
    Apply_Topup=no
fi

Path=`echo ${Path} | sed 's/\/$/$/g'`

#if [[ -z "$PIFactor" ]]; then  PIFactor=1; fi
#if [[ -z "$do_REG" ]]; then  do_REG=0; fi

#ErrorHandling
if [ ${PEdir} -ne 1 ] && [ ${PEdir} -ne 2 ]; then
    echo ""
    echo "Wrong Input Argument! PhaseEncodingDir flag can be 1 or 2."
    echo ""
    exit 1
fi

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

AnalysisFolderName="analysis"
dMRIFolderName="dMRI"
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
topupFolderName="topup"
eddyFolderName="eddy"
regFolderName="reg"
qcFolderName="qc"
dataFolderName="data"
data2stdFolderName="data2std"
log_Name="log.txt"

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

Path=$Path/$Subject
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
    echo "Diffusion preprocessing depends on the outputs generated by Structural preprocessing. So diffusion"
    echo "preprocessing should not be attempted on data sets for which structural preprocessing is not yet complete."
    echo ""
    exit;
fi

rawFolder=${Path}/${rawFolderName}
dMRIrawFolder=${rawFolder}/${dMRIFolderName}
dMRIFolder=${AnalysisFolder}/${dMRIFolderName};
logFolder=${dMRIFolder}/${logFolderName}
preprocFolder=${dMRIFolder}/${preprocessFolderName}
processedFolder=${dMRIFolder}/${processedFolderName}

topupFolder=${preprocFolder}/${topupFolderName}
eddyFolder=${preprocFolder}/${eddyFolderName}
qcFolder=${preprocFolder}/${qcFolderName}
regFolder=${preprocFolder}/${regFolderName}
dataFolder=${processedFolder}/${dataFolderName}
data2stdFolder=${processedFolder}/${data2stdFolderName}

preprocT1Folder=${T1Folder}/${preprocessFolderName}
processedT1Folder=${T1Folder}/${processedFolderName}
dataT1Folder=${processedT1Folder}/${dataFolderName}
segT1Folder=${processedT1Folder}/${segFolderName}
TissueT1Folder=${segT1Folder}/${TissueFolderName}
SinChanT1Folder=${TissueT1Folder}/${SingChanFolderName}
MultChanT1Folder=${TissueT1Folder}/${MultChanFolderName}
regT1Folder=${preprocT1Folder}/${regFolderName}

if [ ! -d ${dMRIrawFolder} ]; then mkdir ${dMRIrawFolder}; fi
if [ -d ${dMRIFolder} ]; then rm -rf ${dMRIFolder}; fi; mkdir -p ${dMRIFolder}
if [ -e ${logFolder} ] ; then rm -r ${logFolder}; fi; mkdir ${logFolder}
if [ ! -d ${preprocFolder} ]; then mkdir ${preprocFolder}; fi
if [ ! -d ${processedFolder} ]; then mkdir ${processedFolder}; fi
if [ $Apply_Topup = yes ] ; then
    if [ ! -d ${topupFolder} ]; then mkdir ${topupFolder}; fi
fi
if [ ! -d ${eddyFolder} ]; then mkdir ${eddyFolder}; fi
if [ $do_REG = yes ] ; then
    if [ ! -d ${regFolder} ]; then mkdir ${regFolder}; fi
    if [ ! -d ${data2stdFolder} ]; then mkdir ${data2stdFolder}; fi
fi
if [ $do_QC = yes ] ; then
    if [ ! -d ${qcFolder} ]; then mkdir ${qcFolder}; fi
fi
if [ ! -d ${dataFolder} ]; then mkdir ${dataFolder}; fi

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
log_Msg 2 "InputImages: $InputImages"
log_Msg 2 "InputImages2: $InputImages2"
log_Msg 2 "do_QC: $do_QC"
log_Msg 2 "do_REG: $do_REG"
log_Msg 2 "Slice2Volume: $Slice2Volume"
log_Msg 2 "SliceSpec: $SliceSpec"
log_Msg 2 "echospacing: $echospacing"
log_Msg 2 "PEdir: $PEdir"
log_Msg 2 "CombineMatched: $CombineMatched"
log_Msg 2 "PIFactor: $PIFactor"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

log_Msg 3 "OutputDir is: ${dMRIFolder}"

${BRC_DMRI_SCR}/data_copy.sh \
              --dmrirawfolder=${dMRIrawFolder} \
              --eddyfolder=${eddyFolder} \
              --inputimage=${InputImages} \
              --inputimage2=${InputImages2} \
              --pedirection=${PEdir} \
              --applytopup=$Apply_Topup \
              --logfile=${logFolder}/${log_Name}


${BRC_DMRI_SCR}/basic_preproc.sh \
              --dmrirawfolder=${dMRIrawFolder} \
              --topupfolder=${topupFolder} \
              --eddyfolder=${eddyFolder} \
              --echospacing=${echospacing} \
              --pedir=${PEdir} \
              --b0dist=${b0dist} \
              --b0maxbval=${b0maxbval} \
              --pifactor=${PIFactor} \
              --applytopup=$Apply_Topup \
              --logfile=${logFolder}/${log_Name}


if [ $Apply_Topup = yes ] ; then
    ${BRC_DMRI_SCR}/run_topup.sh \
          --workingdir=${topupFolder} \
          --logfile=${logFolder}/${log_Name}
fi


${BRC_DMRI_SCR}/run_eddy.sh \
      --workingdir=${eddyFolder} \
      --applytopup=$Apply_Topup \
      --doqc=$do_QC \
      --qcdir=${qcFolder} \
      --topupdir=${topupFolder} \
      --slice2vol=${Slice2Volume} \
      --slspec=${SliceSpec} \
      --logfile=${logFolder}/${log_Name}


${BRC_DMRI_SCR}/eddy_postproc.sh \
      --workingdir=${dMRIFolder} \
      --eddyfolder=${eddyFolder} \
      --datafolder=${dataFolder} \
      --combinematched=${CombineMatched} \
      --Apply_Topup=${Apply_Topup} \
      --logfile=${logFolder}/${log_Name}


if [[ $do_REG == yes ]]; then

    if [ `$FSLDIR/bin/imtest ${MultChanT1Folder}/T1_WM_mask` = 1 ] ; then
        wmseg="${MultChanT1Folder}/T1_WM_mask"
    elif [[ `$FSLDIR/bin/imtest ${SinChanT1Folder}/T1_WM_mask` = 1 ]]; then
        wmseg="${SinChanT1Folder}/T1_WM_mask"
    fi

    ${BRC_DMRI_SCR}/diff_reg.sh \
          --datafolder=${dataFolder} \
          --regfolder=${regFolder} \
          --wmseg=${wmseg} \
          --datat1folder=${dataT1Folder} \
          --regt1folder=${regT1Folder} \
          --logfile=${logFolder}/${log_Name}
fi


END_Time="$(date -u +%s)"


${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Subject} \
      --type=2 \
      --logfile=${logFolder}/${log_Name}

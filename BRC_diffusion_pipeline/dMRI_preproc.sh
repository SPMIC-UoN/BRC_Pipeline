#!/bin/bash
# Last update: 20/05/2019

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham

set -e

#Hard-Coded variables for the pipeline
b0dist=150     #Minimum distance in volumes between b0s considered for preprocessing
b0maxbval=50  #Volumes with a bvalue smaller than that will be considered as b0s

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
  echo "                                 if for a LR/RL (AP/PA) pair one of the two files are missing set the entry to EMPTY)."
  echo " --path <path>                   output directory. Please provide absolute path."
  echo " --subject <subject name>        output directory is a subject name folder in output path directory."
  echo " --echospacing <value>           EchoSpacing should be in Sec."
  echo " --pe_dir <value>                Phase Encoding Direction"
  echo "                                      1 for LR/RL,"
  echo "                                      2 for AP/PA"
  echo " "
  echo "Optional arguments (You may optionally specify one or more of):"
  echo " --input_2 <path>                dataRL(PA)1@dataRL(PA)2@...dataRL(PA)N, filenames of input images (reverse phase encoding direction),"
  echo "                                 Set to NONE if not available (default)."
  echo " --qc                            Turn on steps that do quality control of dMRI data."
  echo " --reg                           Turn on steps that do registration to standard (FLIRT and FNIRT)."
  echo " --tbss                          Turn on steps that run TBSS analysis."
  echo " --noddi                         Turn on steps that run NODDI analysis."
  echo " --slice2vol                     If one wants to do slice-to-volome motion correction."
  echo " --slspec <path>                 Specifies a .json file (created by your DICOM->niftii conversion software) that describes how the"
  echo "                                 slices/multi-band-groups were acquired. This file is necessary when using the slice-to-vol movement correction."
  echo " --cm_flag <value>               CombineMatchedFlag"
  echo "                                      2 for including in the output all volumes uncombined (default),"
  echo "                                      1 for including in the output and combine only volumes where both LR/RL (or AP/PA) pairs have been acquired,"
  echo "                                      0 for including (uncombined) single volumes as well."
  echo " --p_im <value>                  ParallelImaging_Factor, In-plane parallel imaging factor"
  echo "                                      1 for No_Parallel_Imaging"
  echo " --movebysusceptibility          By setting this option, eddy attempts to estimate how the susceptibility-induced field changes when the subject"
  echo "                                 moves in the scanner. This option activates '--estimate_move_by_susceptibility' in EDDY."
  echo "                                 This option is available for FSL 6 onwards."
  echo " --hires                         This option will increase the time limits and the required memory for the processing of high-resolution data."
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
MoveBySusceptibility="no"
SliceSpec="NONE"
echospacing=""
PEdir=""
CombineMatched=2
PIFactor=1

do_QC="no"
do_REG="no"
do_TBSS="no"
do_NODDI="no"
Apply_Topup="yes"
dof=6
Opt_args=""
HIRES="no"

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

        --qc )           	      do_QC="yes"
                                ;;

        --reg )           	    do_REG="yes"
                                ;;

        --tbss )           	    do_TBSS="yes"
                                ;;

        --noddi )           	  do_NODDI="yes"
                                ;;

        --slice2vol )           Slice2Volume="yes"
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

        --movebysusceptibility ) MoveBySusceptibility="yes"
                                ;;

        --hires )               HIRES="yes"
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
tbssFolderName="tbss"
regFolderName="reg"
qcFolderName="qc"
dataFolderName="data"
data2strFolderName="data2str"
data2stdFolderName="data2std"
log_Name="log.txt"

T1wImage="T1"
T1wRestoreImage="T1_unbiased"
T1wRestoreImageBrain="T1_unbiased_brain"

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

if [[ $do_REG == "yes" ]]; then
    if [ ! -e ${T1Folder} ] ; then
        echo ""
        echo "--reg has been activated, which needs the outputs generated by Structural preprocessing. So either turn "
        echo "this option off or run dMRI preprocessing after structural preprocessing is complete."
        echo ""
        exit;
    fi
fi

rawFolder=${Path}/${rawFolderName}
dMRIrawFolder=${rawFolder}/${dMRIFolderName}
dMRIFolder=${AnalysisFolder}/${dMRIFolderName}
logFolder=${dMRIFolder}/${logFolderName}
preprocFolder=${dMRIFolder}/${preprocessFolderName}
processedFolder=${dMRIFolder}/${processedFolderName}

topupFolder=${preprocFolder}/${topupFolderName}
eddyFolder=${preprocFolder}/${eddyFolderName}
tbssFolder=${preprocFolder}/${tbssFolderName}
qcFolder=${preprocFolder}/${qcFolderName}
regFolder=${preprocFolder}/${regFolderName}
dataFolder=${processedFolder}/${dataFolderName}
data2strFolder=${processedFolder}/${data2strFolderName}
data2stdFolder=${processedFolder}/${data2stdFolderName}

preprocT1Folder=${T1Folder}/${preprocessFolderName}
processedT1Folder=${T1Folder}/${processedFolderName}
dataT1Folder=${processedT1Folder}/${dataFolderName}
segT1Folder=${processedT1Folder}/${segFolderName}
TissueT1Folder=${segT1Folder}/${TissueFolderName}
SinChanT1Folder=${TissueT1Folder}/${SingChanFolderName}
MultChanT1Folder=${TissueT1Folder}/${MultChanFolderName}
regT1Folder=${preprocT1Folder}/${regFolderName}

if [ -d ${dMRIrawFolder} ]; then rm -rf ${dMRIrawFolder}; fi; mkdir -p ${dMRIrawFolder}
if [ -d ${dMRIFolder} ]; then rm -rf ${dMRIFolder}; fi; mkdir -p ${dMRIFolder}
if [ -e ${logFolder} ] ; then rm -r ${logFolder}; fi; mkdir ${logFolder}
if [ ! -d ${preprocFolder} ]; then mkdir ${preprocFolder}; fi
if [ ! -d ${processedFolder} ]; then mkdir ${processedFolder}; fi
if [ $Apply_Topup = yes ] ; then
    if [ ! -d ${topupFolder} ]; then mkdir ${topupFolder}; fi
fi
if [ ! -d ${eddyFolder} ]; then mkdir ${eddyFolder}; fi
if [ ! -d ${tbssFolder} ]; then mkdir ${tbssFolder}; fi
if [ $do_REG = yes ] ; then
    if [ ! -d ${regFolder} ]; then mkdir ${regFolder}; fi
    if [ ! -d ${data2strFolder} ]; then mkdir ${data2strFolder}; fi
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
log_Msg 2 "do_TBSS: $do_TBSS"
log_Msg 2 "do_NODDI: $do_NODDI"
log_Msg 2 "Slice2Volume: $Slice2Volume"
log_Msg 2 "SliceSpec: $SliceSpec"
log_Msg 2 "echospacing: $echospacing"
log_Msg 2 "PEdir: $PEdir"
log_Msg 2 "CombineMatched: $CombineMatched"
log_Msg 2 "PIFactor: $PIFactor"
log_Msg 2 "MoveBySusceptibility: $MoveBySusceptibility"
log_Msg 2 "HIRES: $HIRES"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

log_Msg 3 "OutputDir is: ${dMRIFolder}"

if [ $CLUSTER_MODE = "YES" ] ; then

    if [ $HIRES = "yes" ] ; then
        TIME_LIMIT_1=24:00:00
        TIME_LIMIT_2=20:00:00
        TIME_LIMIT_3=24:00:00
        MEM_1=30
        MEM_2=90
        MEM_3=100
    else
      TIME_LIMIT_1=01:40:00
      TIME_LIMIT_2=06:00:00
      TIME_LIMIT_3=03:00:00
      MEM_1=20
      MEM_2=60
      MEM_3=20
    fi

    jobID1=`${JOBSUBpath}/jobsub -q cpu -p 1 -s BRC_1_dMRI_${Subject} -t ${TIME_LIMIT_1} -m ${MEM_1} -c "${BRC_DMRI_SCR}/dMRI_preproc_part_1.sh --dmrirawfolder=${dMRIrawFolder} --eddyfolder=${eddyFolder} --topupfolder=${topupFolder} --inputimage=${InputImages} --inputimage2=${InputImages2} --pedirection=${PEdir} --applytopup=${Apply_Topup} --echospacing=${echospacing} --b0dist=${b0dist} --b0maxbval=${b0maxbval} --pifactor=${PIFactor} --hires=${HIRES} --donoddi=${do_NODDI} --logfile=${logFolder}/${log_Name}" &`
    jobID1=`echo -e $jobID1 | awk '{ print $NF }'`
    echo "jobID_1: ${jobID1}"

    jobID2=`${JOBSUBpath}/jobsub -q gpu -p 1 -g 1 -s BRC_2_dMRI_${Subject} -t ${TIME_LIMIT_2} -m ${MEM_2} -w ${jobID1} -c "${BRC_DMRI_SCR}/dMRI_preproc_part_2.sh --eddyfolder=${eddyFolder} --topupfolder=${topupFolder} --applytopup=${Apply_Topup} --doqc=${do_QC} --qcdir=${qcFolder} --slice2vol=${Slice2Volume} --slspec=${SliceSpec} --movebysuscept=${MoveBySusceptibility} --hires=${HIRES} --logfile=${logFolder}/${log_Name}" &`
    jobID2=`echo -e $jobID2 | awk '{ print $NF }'`
    echo "jobID_2: ${jobID2}"

    jobID3=`${JOBSUBpath}/jobsub -q cpu -p 1 -s BRC_3_dMRI_${Subject} -t ${TIME_LIMIT_3} -m ${MEM_3} -w ${jobID2} -c "${BRC_DMRI_SCR}/dMRI_preproc_part_3.sh --workingdir=${dMRIFolder} --eddyfolder=${eddyFolder} --datafolder=${dataFolder} --combinematched=${CombineMatched} --applytopup=${Apply_Topup} --doreg=${do_REG} --dotbss=${do_TBSS} --tbssfolder=${tbssFolder} --multchant1folder=${MultChanT1Folder} --sinchant1folder=${SinChanT1Folder} --regfolder=${regFolder} --t1=${dataT1Folder}/${T1wImage} --t1restore=${dataT1Folder}/${T1wRestoreImage} --t1brain=${dataT1Folder}/${T1wRestoreImageBrain} --dof=${dof} --datat1folder=${dataT1Folder} --regt1folder=${regT1Folder} --outstr=${data2strFolder} --outstd=${data2stdFolder} --start=${Start_Time} --subject=${Subject} --hires=${HIRES} --donoddi=${do_NODDI} --logfile=${logFolder}/${log_Name}" &`
    jobID3=`echo -e $jobID3 | awk '{ print $NF }'`
    echo "jobID_3: ${jobID3}"

else

    ${BRC_DMRI_SCR}/dMRI_preproc_part_1.sh \
                    --dmrirawfolder=${dMRIrawFolder} \
                    --eddyfolder=${eddyFolder} \
                    --topupfolder=${topupFolder} \
                    --inputimage=${InputImages} \
                    --inputimage2=${InputImages2} \
                    --pedirection=${PEdir} \
                    --applytopup=${Apply_Topup} \
                    --echospacing=${echospacing} \
                    --b0dist=${b0dist} \
                    --b0maxbval=${b0maxbval} \
                    --pifactor=${PIFactor} \
                    --hires=${HIRES} \
                    --donoddi=${do_NODDI} \
                    --logfile=${logFolder}/${log_Name}


    ${BRC_DMRI_SCR}/dMRI_preproc_part_2.sh \
                    --eddyfolder=${eddyFolder} \
                    --topupfolder=${topupFolder} \
                    --applytopup=${Apply_Topup} \
                    --doqc=${do_QC} \
                    --qcdir=${qcFolder} \
                    --slice2vol=${Slice2Volume} \
                    --slspec=${SliceSpec} \
                    --movebysuscept=${MoveBySusceptibility} \
                    --hires=${HIRES} \
                    --logfile=${logFolder}/${log_Name}


     ${BRC_DMRI_SCR}/dMRI_preproc_part_3.sh \
                    --workingdir=${dMRIFolder} \
                    --eddyfolder=${eddyFolder} \
                    --datafolder=${dataFolder} \
                    --combinematched=${CombineMatched} \
                    --applytopup=${Apply_Topup} \
                    --doreg=${do_REG} \
                    --dotbss=${do_TBSS} \
                    --tbssfolder=${tbssFolder} \
                    --multchant1folder=${MultChanT1Folder} \
                    --sinchant1folder=${SinChanT1Folder} \
                    --regfolder=${regFolder} \
                    --t1=${dataT1Folder}/${T1wImage} \
                    --t1restore=${dataT1Folder}/${T1wRestoreImage} \
                    --t1brain=${dataT1Folder}/${T1wRestoreImageBrain} \
                    --dof=${dof} \
                    --datat1folder=${dataT1Folder} \
                    --regt1folder=${regT1Folder} \
                    --outstr=${data2strFolder} \
                    --outstd=${data2stdFolder} \
                    --start=${Start_Time} \
                    --subject=${Subject} \
                    --hires=${HIRES} \
                    --donoddi=${do_NODDI} \
                    --logfile=${logFolder}/${log_Name}

fi

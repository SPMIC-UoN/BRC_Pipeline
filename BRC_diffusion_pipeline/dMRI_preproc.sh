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
  echo " -i1| --in_1 <input image>	     dataLR(AP)1@dataLR(AP)2@...dataLR(AP)N, filenames of input images (For input filenames,"
  echo "                                 if for a LR/RL (AP/PA) pair one of the two files are missing set the entry to EMPTY)"
  echo " -i2| --in_2 <input image>       dataRL(PA)1@dataRL(PA)2@...dataRL(PA)N, filenames of input images (reverse phase encoding direction),"
  echo "                                 Set to NONE if not available (default)"
  echo " --path <output directory>       output durectory. Please provide absolute path"
  echo " -s | --subject <Subject name>   output directory is a subject name folder in output path directory"
  echo " --qc                            turn on steps that do quality control of dMRI data"
  echo " --reg                           turn on steps that do registration to standard (FLIRT and FNIRT)"
  echo " --slice2vol                     If one wants to do slice-to-volome motion correction"
  echo " --slspec <json path>            Specifies a .json file (created by your DICOM->niftii conversion software) that describes how the"
  echo "                                 slices/multi-band-groups were acquired. This file is necessary when using the slice-to-vol movement correction"
  echo " -e | --echo_s <value>           EchoSpacing should be in msecs"
  echo " -p | --pe_dir <1..2>            PhaseEncodingDir"
  echo "                                      1 for LR/RL,"
  echo "                                      2 for AP/PA"
  echo " -c | --cm_flag <0..2>           CombineMatchedFlag"
  echo "                                      2 for including in the output all volumes uncombined,"
  echo "                                      1 for including in the output and combine only volumes where both LR/RL (or AP/PA) pairs have been acquired,"
  echo "                                      0 for including (uncombined) single volumes as well"
  echo " -g | --p_im                     ParallelImaging_Factor, In-plane parallel imaging factor"
  echo "                                      1 for No_Parallel_Imaging"
  echo " -h | --help                     help"
  echo " "
  echo " "
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
if [ $# -le 4 ] ; then Usage; exit 1; fi

# default values
InputImages2="NONE"
Slice2Volume="no"
SliceSpec="NONE"
echospacing=
PEdir=
CombineMatched=
PIFactor=1

do_QC=no
do_REG=no
Apply_Topup=yes

# parse arguments
while [ "$1" != "" ]; do
    case $1 in
        -s | --subject )        shift
                                Sub_ID=$1
                                ;;

        -i1 | --in_1 )          shift
                                InputImages=$1
                                ;;

        -i2 | --in_2 )          shift
                                InputImages2=$1
                                ;;

        --path )                shift
                                OutputFolder=`make_absolute $1`
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

        -e | --echo_s )         shift
                                echospacing=$1
                                ;;

        -p | --pe_dir )         shift
                                PEdir=$1
                                ;;

        -c | --cm_flag )        shift
                                CombineMatched=$1
                                ;;

        -g | --p_im )           shift
                                PIFactor=$1
                                ;;

        -h | --help )           Usage
                                exit
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
if [ X$Sub_ID = X ] || [ X$InputImages = X ] || [ X$OutputFolder = X ] || [ X$echospacing = X ] || [ X$PEdir = X ] ; then
    echo ""
    echo "All of the compulsory arguments --path, -i1, -s, --echo_s, and --pe_dir MUST be used"
    echo ""
    exit 1;
fi

if [ $InputImages2 = "NONE" ] ; then
    Apply_Topup=no
fi

OutputFolder=`echo ${OutputFolder} | sed 's/\/$/$/g'`

#if [[ -z "$PIFactor" ]]; then  PIFactor=1; fi
#if [[ -z "$do_REG" ]]; then  do_REG=0; fi

#ErrorHandling
if [ ${PEdir} -ne 1 ] && [ ${PEdir} -ne 2 ]; then
    echo ""
    echo "Wrong Input Argument! PhaseEncodingDir flag can be 1 or 2."
    echo ""
    exit 1
fi

outdir=$OutputFolder/$Sub_ID
if [ ! -d "$outdir" ]; then
    mkdir $outdir;
#else
#  outdir="${OutputFolder}_$(date +"%d-%m-%Y_%H-%M")"
#  mkdir $outdir
fi

outdir=${outdir}/analysis;

if [ ! -e "${outdir}/anatMRI/T1" ] ; then
    echo ""
    echo "Diffusion preprocessing depends on the outputs generated by Structural preprocessing. So diffusion"
    echo "preprocessing should not be attempted on data sets for which structural preprocessing is not yet complete."
    echo ""
    exit;
fi

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

rawFolderName="raw"
preprocessedFolderName="preprocess"
topupFolderName="topup"
eddyFolderName="eddy"
processedFolderName="processed"
regFolderName="reg"
linregFolderName="lin"
nonlinregFolderName="nonlin"
qcFolderName="qc"
logFolderName="log"
unlabelFolderName="unlabelled"


#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

if [ ! -d "$outdir" ]; then mkdir $outdir; fi

dMRIFolder=${outdir}/dMRI;

rawFolder=${dMRIFolder}/${rawFolderName}
preprocessedFolder=${dMRIFolder}/${preprocessedFolderName}
topupFolder=${preprocessedFolder}/${topupFolderName}
eddyFolder=${preprocessedFolder}/${eddyFolderName}
processedFolder=${dMRIFolder}/${processedFolderName}
regFolder=${dMRIFolder}/${regFolderName}
linregFolder=${regFolder}/${linregFolderName}
nonlinregFolder=${regFolder}/${nonlinregFolderName}
qcFolder=${dMRIFolder}/${qcFolderName}
logFolder=${dMRIFolder}/${logFolderName}
unlabelFolder=${dMRIFolder}/${unlabelFolderName}


if [ -d ${dMRIFolder} ]; then
    rm -rf ${dMRIFolder}
fi
mkdir -p ${dMRIFolder}

echo OutputDir is ${dMRIFolder}

if [ ! -d ${rawFolder} ]; then mkdir ${rawFolder}; fi
if [ ! -d ${preprocessedFolder} ]; then mkdir ${preprocessedFolder}; fi
if [ $Apply_Topup = yes ] ; then
    if [ ! -d ${topupFolder} ]; then mkdir ${topupFolder}; fi
fi
if [ ! -d ${eddyFolder} ]; then mkdir ${eddyFolder}; fi
if [ ! -d ${processedFolder} ]; then mkdir ${processedFolder}; fi
if [ $do_REG = yes ] ; then
    if [ ! -d ${regFolder} ]; then mkdir ${regFolder}; fi
    if [ ! -d ${linregFolder} ]; then mkdir ${linregFolder}; fi
    if [ ! -d ${nonlinregFolder} ]; then mkdir ${nonlinregFolder}; fi
fi
if [ $do_QC = yes ] ; then
    if [ ! -d ${qcFolder} ]; then mkdir ${qcFolder}; fi
fi
if [ ! -d ${logFolder} ]; then mkdir ${logFolder}; fi
if [ ! -d ${unlabelled} ]; then mkdir ${unlabelled}; fi


echo "Data Handling"
${BRC_DMRI_SCR}/data_copy.sh \
              --workingdir=${dMRIFolder} \
              --inputimage=${InputImages} \
              --inputimage2=${InputImages2} \
              --pedirection=${PEdir} \
              --applytopup=$Apply_Topup


echo "Basic Preprocessing"
${BRC_DMRI_SCR}/basic_preproc.sh \
              --workingdir=${dMRIFolder} \
              --echospacing=${echospacing} \
              --pedir=${PEdir} \
              --b0dist=${b0dist} \
              --b0maxbval=${b0maxbval} \
              --pifactor=${PIFactor} \
              --applytopup=$Apply_Topup


if [ $Apply_Topup = yes ] ; then
    echo "Queueing Topup"
    ${BRC_DMRI_SCR}/run_topup.sh ${topupFolder}
fi


echo "Queueing Eddy"
${BRC_DMRI_SCR}/run_eddy.sh \
      --workingdir=${eddyFolder} \
      --applytopup=$Apply_Topup \
      --doqc=$do_QC \
      --qcdir=${qcFolder} \
      --topupdir=${topupFolder} \
      --slice2vol=${Slice2Volume} \
      --slspec=${SliceSpec}



echo "Queueing Eddy PostProcessing"
${BRC_DMRI_SCR}/eddy_postproc.sh ${dMRIFolder} ${CombineMatched} $Apply_Topup

if [[ $do_REG == yes ]]; then
    ${BRC_DMRI_SCR}/diff_reg.sh ${dMRIFolder} $OutputFolder/$Sub_ID
fi


END_Time="$(date -u +%s)"


${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Sub_ID} \
      --type=2

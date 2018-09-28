#!/bin/bash
# Last update: 30/09/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#

# Preprocessing Pipeline for diffusion MRI. Generates the "data" directory that can be used as input to fibre orientation estimation.
#Example:
#./Pipeline_dMRI.sh -i1 ~/main/analysis/DTI/001/5_6_Diffusion_MB3_b1k_2k_100dir_b0rev/__DTI_Biobank_2mm_MB3S2_EPI_20180307162159_701.nii.gz -i2 ~/main/analysis/DTI/001/5_6_Diffusion_MB3_b1k_2k_100dir_b0rev/__blip_DTI_Biobank_2mm_MB3S2_EPI_20180307162159_601.nii.gz --path ~/main/analysis -s Sub_001 -p 2 -e 0.78 -c 2

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
  echo " -e | --echo_s <value>           EchoSpacing should be in msecs"
  echo " -p | --pe_dir <1..2>            PhaseEncodingDir"
  echo "                                 1 for LR/RL,"
  echo "                                 2 for AP/PA"
  echo " -c | --cm_flag <0..2>           CombineMatchedFlag"
  echo "                                 2 for including in the ouput all volumes uncombined,"
  echo "                                 1 for including in the ouput and combine only volumes where both LR/RL (or AP/PA) pairs have been acquired,"
  echo "                                 0 for including (uncombined) single volumes as well"
  echo " -g | --p_im                     ParallelImaging_Factor, In-plane parallel imaging factor"
  echo "                                 1 for No_Parallel_Imaging"
  echo " -h | --help                     help"
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
if [ $# -le 4 ] ; then Usage; exit 1; fi

# default values
InputImages2="NONE"
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

### Sanity checking of arguments

if [ X$Sub_ID = X ] && [ X$InputImages = X ] && [ X$OutputFolder = X ] ; then
  echo "All of the compulsory arguments --path, -i1 and -s MUST be used"
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
if [ ! -d "$outdir" ]; then mkdir $outdir; fi

outdir=${outdir}/dMRI;
if [ -d ${outdir} ]; then
    rm -rf ${outdir}
fi
mkdir -p ${outdir}

echo OutputDir is ${outdir}

if [ ! -d "$outdir/raw" ]; then mkdir $outdir/raw; fi
if [ ! -d "$outdir/preprocess" ]; then mkdir $outdir/preprocess; fi
if [ $Apply_Topup = yes ] ; then
    if [ ! -d "$outdir/preprocess/topup" ]; then mkdir $outdir/preprocess/topup; fi
fi
if [ ! -d "$outdir/preprocess/eddy" ]; then mkdir $outdir/preprocess/eddy; fi
if [ ! -d "$outdir/processed" ]; then mkdir $outdir/processed; fi
if [ $do_REG = yes ] ; then
    if [ ! -d "$outdir/reg" ]; then mkdir $outdir/reg; fi
    if [ ! -d "$outdir/reg/lin" ]; then mkdir $outdir/reg/lin; fi
    if [ ! -d "$outdir/reg/nonlin" ]; then mkdir $outdir/reg/nonlin; fi
fi
if [ $do_QC = yes ] ; then
    if [ ! -d "$outdir/qc" ]; then mkdir $outdir/qc; fi
fi
if [ ! -d "$outdir/log" ]; then mkdir $outdir/log; fi
if [ ! -d "$outdir/unlabelled" ]; then mkdir $outdir/unlabelled; fi

echo "Data Handling"
${BRC_DMRI_SCR}/data_copy.sh \
              --workingdir=${outdir} \
              --inputimage=${InputImages} \
              --inputimage2=${InputImages2} \
              --pedirection=${PEdir} \
              --applytopup=$Apply_Topup

echo "Basic Preprocessing"
${BRC_DMRI_SCR}/basic_preproc.sh \
              --workingdir=${outdir} \
              --echospacing=${echospacing} \
              --pedir=${PEdir} \
              --b0dist=${b0dist} \
              --b0maxbval=${b0maxbval} \
              --pifactor=${PIFactor} \
              --applytopup=$Apply_Topup

if [ $Apply_Topup = yes ] ; then
    echo "Queueing Topup"
    ${BRC_DMRI_SCR}/run_topup.sh ${outdir}/preprocess/topup
fi

echo "Queueing Eddy"
${BRC_DMRI_SCR}/run_eddy.sh ${outdir}/preprocess/eddy $Apply_Topup $do_QC ${outdir}/qc

echo "Queueing Eddy PostProcessing"
${BRC_DMRI_SCR}/eddy_postproc.sh ${outdir} ${CombineMatched} $Apply_Topup

if [[ $do_REG == yes ]]; then
    ${BRC_DMRI_SCR}/diff_reg.sh ${outdir} $OutputFolder/$Sub_ID
fi

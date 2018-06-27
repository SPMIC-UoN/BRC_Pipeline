#!/bin/bash
# Last update: 06/06/2018

# Preprocessing Pipeline for diffusion MRI. Generates the "data" directory that can be used as input to fibre orientation estimation.
# Stamatios Sotiropoulos, Analysis Group, FMRIB Centre, 2013.
#Example:
#./Pipeline_dMRI.sh -i1 ~/analysis/DTI_601.nii.gz -i2 ~/analysis/DTI_701.nii.gz -o ~/analysis/001_Prep -p 2 -e 0.78 -c 2 --reg

set -e

#Hard-Coded variables for the pipeline
b0dist=150     #Minimum distance in volumes between b0s considered for preprocessing
b0maxbval=50  #Volumes with a bvalue smaller than that will be considered as b0s

ScriptsDir=$(dirname "$(readlink -f "$0")") #Absolute path where scripts are

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
  echo " -i1| --in_1 <input image>	     dataLR1@dataLR2@...dataLRN, filenames of input images (For input filenames, if for a LR/RL (AP/PA) pair one of the two files are missing set the entry to EMPTY)"
  echo " -i2| --in_2 <input image>           dataRL1@dataRL2@...dataRLN, filenames of input images (For input filenames, if for a LR/RL (AP/PA) pair one of the two files are missing set the entry to EMPTY)"
  echo " -o | --out <output directory>       Output durectory. Please provide absolute path"
  echo " --qc                                turn on steps that do quality control of dMRI data"
  echo " --reg                               turn on steps that do registration to standard (FLIRT and FNIRT)"
  echo " -e | --echo_s <value>               EchoSpacing should be in msecs"
  echo " -p | --pe_dir <1..2>                PhaseEncodingDir"
  echo "                                     1 for LR/RL,"
  echo "                                     2 for AP/PA"
  echo " -c | --cm_flag <0..2>               CombineMatchedFlag"
  echo "                                     2 for including in the ouput all volumes uncombined,"
  echo "                                     1 for including in the ouput and combine only volumes where both LR/RL (or AP/PA) pairs have been acquired,"
  echo "                                     0 for including (uncombined) single volumes as well"
  echo " -g | --p_im                         ParallelImaging_Factor, In-plane parallel imaging factor"
  echo "                                     1 for No_Parallel_Imaging"
  echo " -h | --help                         help"
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
if [ $# -le 4 ] ; then Usage; exit 1; fi

# default values
InputImages=
InputImages2=
OutputFolder=
O_DIR=
echospacing=
PEdir=
CombineMatched=
PIFactor=1

do_QC=no
do_REG=no

# parse arguments
while [ "$1" != "" ]; do
    case $1 in
        -i1 | --in_1 )          shift
                                InputImages2=$1
                                ;;

        -i2 | --in_2 )          shift
                                InputImages=$1
                                ;;

        -o | --out )            shift
                                OutputFolder=`make_absolute $1`
                                O_DIR=$1
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

outdir=$OutputFolder
if [ ! -d "$outdir" ]; then
  mkdir $outdir;
#else
#  outdir="${OutputFolder}_$(date +"%d-%m-%Y_%H-%M")"
#  mkdir $outdir
fi

outdir=${outdir}/analysis;
if [ ! -d "$outdir" ]; then mkdir $outdir; fi

outdir=${outdir}/dMRI;
#if [ -d ${outdir} ]; then
#    rm -rf ${outdir}
#fi
#mkdir -p ${outdir}

echo OutputDir is ${outdir}

if [ ! -d "$O_DIR/raw" ]; then mkdir $O_DIR/raw; fi
if [ ! -d "$O_DIR/preprocess" ]; then mkdir $O_DIR/preprocess; fi
if [ ! -d "$O_DIR/preprocess/topup" ]; then mkdir $O_DIR/preprocess/topup; fi
if [ ! -d "$O_DIR/preprocess/eddy" ]; then mkdir $O_DIR/preprocess/eddy; fi
if [ ! -d "$O_DIR/processed" ]; then mkdir $O_DIR/processed; fi
if [ ! -d "$O_DIR/reg" ]; then mkdir $O_DIR/reg; fi
if [ ! -d "$O_DIR/reg/lin" ]; then mkdir $O_DIR/reg/lin; fi
if [ ! -d "$O_DIR/reg/nonlin" ]; then mkdir $O_DIR/reg/nonlin; fi
if [ ! -d "$O_DIR/qc" ]; then mkdir $O_DIR/qc; fi
if [ ! -d "$O_DIR/log" ]; then mkdir $O_DIR/log; fi
if [ ! -d "$O_DIR/unlabelled" ]; then mkdir $O_DIR/unlabelled; fi

#: <<'COMMENT'

echo "Data Handling"
#${ScriptsDir}/data_copy.sh ${outdir} ${InputImages} ${InputImages2} ${PEdir}

echo "Basic Preprocessing"
#${ScriptsDir}/basic_preproc.sh ${outdir} ${echospacing} ${PEdir} ${b0dist} ${b0maxbval}  ${PIFactor}

echo "Queueing Topup"
#${ScriptsDir}/run_topup.sh ${outdir}/preprocess/topup

echo "Queueing Eddy"
#${ScriptsDir}/run_eddy.sh ${outdir}/preprocess/eddy

#mv $outdir/preprocess/eddy/eddy_unwarped_images.qc/* $outdir/qc/
#rm -r $outdir/preprocess/eddy/eddy_unwarped_images.qc

echo "Queueing Eddy PostProcessing"
#ßß${ScriptsDir}/eddy_postproc.sh ${outdir} ${CombineMatched} ${ScriptsDir}

if [[ $do_REG == yes ]]; then
    ${ScriptsDir}/diff_reg.sh ${outdir} ${OutputFolder}
fi

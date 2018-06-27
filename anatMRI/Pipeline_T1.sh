#!/bin/bash
# Last update: 26/06/2018
#Example:
#./Pipeline_T1.sh -s test_02 -i ~/main/analysis/001_T1.nii.gz -t2 ~/main/analysis/T2_FLAIR.nii.gz --freesurfer
# fsl_anat -o ~/analysis/anat_T2 -i ~/analysis/T2_FLAIR.nii.gz -t T2 --nononlinreg --nosubcortseg
#clear


# -e  Exit immediately if a command exits with a non-zero status.
set -e
# The following is a debugging line (displays all commands as they are executed)
#set -x

ScriptsDir=$(dirname "$(readlink -f "$0")") #Absolute path where scripts are

Usage()
{
  echo "`basename $0`: Description"
  echo " "
  echo "Usage: `basename $0`"
  echo " -i | --IN <T1W Input image>          filename of Input image (for one image only)"
  echo " -s | --subject <Subject name>        output directory is a subject name folder IN input image directory"
  echo " -t2 | --T2 <T2W Input image>         optional, filename of Input T2W image (for processing of T2 data)"
  echo " --freesurfer                         turn on Freesurfer processing pipeline"
  echo " --subseg                             a flag to do subcortical segmentation by FAST"
  echo " --qc                                 a flag to do quality control of T1 data"
  echo " --strongbias                         (fsl_anat arg) used for images with very strong bias fields"
  echo " --noreg                              (fsl_anat arg) turn off steps that do registration to standard (FLIRT and FNIRT)"
  echo " --noseg                              (fsl_anat arg) turn off step that does tissue-type segmentation (FAST)"
  echo " -ft | --FAST_t <type>                (fsl_anat arg) specify the type of image (choose one of T1 T2 PD - default is T1)"
  echo " --betfparam                          (fsl_anat arg) specify f parameter for BET (only used if not running non-linear reg and also wanting brain extraction done)"
  echo " -h | --help                          help"
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
if [ $# -le 4 ] ; then Usage; exit 1; fi

# default values
Sub_ID=
IN_Img=
T2_IN_Img=

T2=no
do_Sub_seg=no
do_QC=no
do_freesurfer=no
do_tissue_seg=yes

Opt_args="--clobber"
FAST_t=1  # For FAST: 1 = T1w, 2 = T2w, 3 = PD

# parse arguments
while [ "$1" != "" ]; do
    case $1 in
        -s | --subject )        shift
                                Sub_ID=$1
                                ;;

        -i | --IN )             shift
				                        IN_Img=$1
                                ;;

        -t2 | --T2 )            shift
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

        --betfparam )        	  Opt_args="$Opt_args --betfparam"
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

if [ X$Sub_ID = X ] && [ X$IN_Img = X ] ; then
  echo "Both of the compulsory arguments -i and -s MUST be used"
  exit 1;
fi

Sub_ID=${Sub_ID%.nii.gz}

O_DIR=$(dirname "$IN_Img")/${Sub_ID};
if [ ! -d "$O_DIR" ]; then
  mkdir $O_DIR;
#else
#  O_DIR="${O_DIR}_$(date +"%d-%m-%Y_%H-%M")"
#  mkdir $O_DIR
fi

O_DIR=${O_DIR}/analysis;
if [ ! -d "$O_DIR" ]; then mkdir $O_DIR; fi

O_DIR=${O_DIR}/anatMRI;
if [ ! -d "$O_DIR" ]; then mkdir $O_DIR; fi

echo OutputDir is $O_DIR
cd $O_DIR

#Check existance of foldersa= and then create them
if [ ! -d "$O_DIR/T1" ]; then mkdir $O_DIR/T1; fi
if [ ! -d "$O_DIR/T1/raw" ]; then mkdir $O_DIR/T1/raw; fi
if [ ! -d "$O_DIR/T1/preprocess" ]; then mkdir $O_DIR/T1/preprocess; fi
if [ ! -d "$O_DIR/T1/seg" ]; then mkdir $O_DIR/T1/seg; fi
if [ ! -d "$O_DIR/T1/seg/tissue" ]; then mkdir $O_DIR/T1/seg/tissue; fi
if [ ! -d "$O_DIR/T1/seg/tissue/sing_chan" ]; then mkdir $O_DIR/T1/seg/tissue/sing_chan; fi
if [ ! -d "$O_DIR/T1/seg/tissue/multi_chan" ]; then mkdir $O_DIR/T1/seg/tissue/multi_chan; fi
if [ ! -d "$O_DIR/T1/seg/sub" ]; then mkdir $O_DIR/T1/seg/sub; fi
if [ ! -d "$O_DIR/T1/seg/sub/shape" ]; then mkdir $O_DIR/T1/seg/sub/shape; fi
if [ ! -d "$O_DIR/T1/reg" ]; then mkdir $O_DIR/T1/reg; fi
if [ ! -d "$O_DIR/T1/reg/lin" ]; then mkdir $O_DIR/T1/reg/lin; fi
if [ ! -d "$O_DIR/T1/reg/nonlin" ]; then mkdir $O_DIR/T1/reg/nonlin; fi
if [ ! -d "$O_DIR/T1/log" ]; then mkdir $O_DIR/T1/log; fi
if [ ! -d "$O_DIR/T1/qc" ]; then mkdir $O_DIR/T1/qc; fi
if [ ! -d "$O_DIR/T1/unlabeled" ]; then mkdir $O_DIR/T1/unlabeled; fi
if [ ! -d "$O_DIR/T1/unlabeled/fsl_anat" ]; then mkdir $O_DIR/T1/unlabeled/fsl_anat; fi

if [[ $T2 == yes ]]; then
    if [ ! -d "$O_DIR/T2" ]; then mkdir $O_DIR/T2; fi
    if [ ! -d "$O_DIR/T2/raw" ]; then mkdir $O_DIR/T2/raw; fi
    if [ ! -d "$O_DIR/T2/preprocess" ]; then mkdir $O_DIR/T2/preprocess; fi
    if [ ! -d "$O_DIR/T2/reg" ]; then mkdir $O_DIR/T2/reg; fi
    if [ ! -d "$O_DIR/T2/reg/lin" ]; then mkdir $O_DIR/T2/reg/lin; fi
    if [ ! -d "$O_DIR/T2/reg/nonlin" ]; then mkdir $O_DIR/T2/reg/nonlin; fi
    if [ ! -d "$O_DIR/T2/log" ]; then mkdir $O_DIR/T2/log; fi
    if [ ! -d "$O_DIR/T2/qc" ]; then mkdir $O_DIR/T2/qc; fi
    if [ ! -d "$O_DIR/T2/unlabeled" ]; then mkdir $O_DIR/T2/unlabeled; fi
    if [ ! -d "$O_DIR/T2/unlabeled/fsl_anat" ]; then mkdir $O_DIR/T2/unlabeled/fsl_anat; fi
fi

cp $IN_Img $O_DIR/T1/raw/T1_orig.nii.gz

if [[ $T2 == yes ]]; then
    cp $T2_IN_Img $O_DIR/T2/raw/T2_orig.nii.gz
fi

date

# run fsl_anat
echo "Queueing fsl_anat for T1w image"
echo "Command is:"
echo '***********************************************************************************************'
echo "fsl_anat -i $O_DIR/T1/raw/T1_orig.nii.gz "$Opt_args" -o $O_DIR/T1/temp"
echo '***********************************************************************************************'

${FSLDIR}/bin/fsl_anat -i $O_DIR/T1/raw/T1_orig.nii.gz "$Opt_args" -o $O_DIR/T1/temp

echo $T2

if [[ $T2 == yes ]]; then
    echo "Queueing fsl_anat for T2w image"
    echo "Command is:"
    echo '***********************************************************************************************'
    echo "fsl_anat -i $O_DIR/T2/raw/T2_orig.nii.gz -o $O_DIR/T2/temp -t T2 --nononlinreg --nosubcortseg --noreg --noseg"
    echo '***********************************************************************************************'

   ${FSLDIR}/bin/fsl_anat  -i $O_DIR/T2/raw/T2_orig.nii.gz -o $O_DIR/T2/temp -t T2 --nononlinreg --nosubcortseg --noreg --noseg
fi

echo "Queueing organizing data structure"
${ScriptsDir}/move_rename.sh $O_DIR $T2

: <<'COMMENT'

if [ $do_tissue_seg = yes ] && [ $T2 = yes ] ; then
    echo "Do multichanel tissue segmentation using FAST"

    if [ ! -d "$O_DIR/T1/temp" ]; then mkdir $O_DIR/T1/temp; fi
    if [ ! -d "$O_DIR/T1/unlabeled/mc_FAST" ]; then mkdir $O_DIR/T1/unlabeled/mc_FAST; fi

    $FSLDIR/bin/fast -o $O_DIR/T1/temp/mc_FAST -g -N -S 2 $O_DIR/T1/preprocess/T1_biascorr_brain  $O_DIR/T2/reg/lin/T2_2_T1

    $FSLDIR/bin/immv $O_DIR/T1/temp/mc_FAST_pve_0  $O_DIR/T1/seg/tissue/multi_chan/T1_mc_pve_CSF
    $FSLDIR/bin/immv $O_DIR/T1/temp/mc_FAST_pve_1  $O_DIR/T1/seg/tissue/multi_chan/T1_mc_pve_WM
    $FSLDIR/bin/immv $O_DIR/T1/temp/mc_FAST_pve_2  $O_DIR/T1/seg/tissue/multi_chan/T1_mc_pve_GM
    $FSLDIR/bin/immv $O_DIR/T1/temp/mc_FAST_pveseg  $O_DIR/T1/seg/tissue/multi_chan/T1_mc_pveseg
    $FSLDIR/bin/immv $O_DIR/T1/temp/mc_FAST_seg_0  $O_DIR/T1/seg/tissue/multi_chan/T1_mc_CSF
    $FSLDIR/bin/immv $O_DIR/T1/temp/mc_FAST_seg_1  $O_DIR/T1/seg/tissue/multi_chan/T1_mc_WM
    $FSLDIR/bin/immv $O_DIR/T1/temp/mc_FAST_seg_2  $O_DIR/T1/seg/tissue/multi_chan/T1_mc_GM
    $FSLDIR/bin/immv $O_DIR/T1/temp/mc_FAST_seg  $O_DIR/T1/seg/tissue/multi_chan/T1_mc_seg

    mv $O_DIR/T1/temp/* $O_DIR/T1/unlabeled/mc_FAST/
    rm -r $O_DIR/T1/temp
fi

echo $do_freesurfer

if [[ $do_freesurfer == yes ]]; then
    SUBJECTS_DIR=$O_DIR/T1
    echo "Queueing Freesurfer"

    if [[ $T2 == yes ]]; then
      recon-all -i $O_DIR/T1/raw/T1_orig.nii.gz -s FS -FLAIR $O_DIR/T2/raw/T2_orig.nii.gz -all
    else
      recon-all -i $O_DIR/T1/raw/T1_orig.nii.gz -s FS -all
    fi
fi

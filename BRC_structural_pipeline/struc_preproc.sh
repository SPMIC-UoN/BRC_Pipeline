#!/bin/bash
# Last update: 09/10/2018
#Example:
#./struc_preproc.sh --path ~/main/analysis -s Sub_002 -i ~/P_Share/Images/3T_Harmonisation_Stam/03286_20180307_Ingenia/NIFTI/1_MPRAGE/__T1_1mm_sag_20180307162159_201.nii.gz -t2 ~/P_Share/Images/3T_Harmonisation_Stam/03286_20180307_Ingenia/NIFTI/2_3D_T2w_FLAIR/__T2_FLAIR_1mm_20180307162159_301.nii.gz --subseg

# -e  Exit immediately if a command exits with a non-zero status.
set -e

#export ScriptsDir=$(dirname "$(readlink -f "$0")") #Absolute path where scripts are
#source ${ScriptsDir}/init_vars.sh


Usage()
{
  echo " "
  echo " "
  echo "`basename $0`: Description"
  echo " "
  echo "Usage: `basename $0`"
  echo " -i | --input <T1W Input image>   filename of Input image (for one image only)"
  echo " --path                           output path"
  echo " -s | --subject <Subject name>    output directory is a subject name folder in output path directory"
  echo " -t2 <T2W Input image>            optional, filename of Input T2W image (for processing of T2 data)"
  echo " --freesurfer                     turn on Freesurfer processing pipeline"
  echo " --subseg                         a flag to do subcortical segmentation by FIRST"
  echo " --qc                             a flag to do quality control of T1 data"
  echo " --strongbias                     (fsl_anat arg) used for images with very strong bias fields"
  echo " --noreg                          (fsl_anat arg) turn off steps that do registration to standard (FLIRT and FNIRT)"
  echo " --noseg                          (fsl_anat arg) turn off step that does tissue-type segmentation (FAST)"
  echo " -ft | --FAST_t <type>            (fsl_anat arg) specify the type of image (choose one of T1 T2 PD - default is T1)"
  echo " --betfparam                      (fsl_anat arg) specify f parameter for BET (only used if not running non-linear reg and also wanting brain extraction done)"
  echo " -h | --help                      help"
  echo " "
  echo " "
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
if [ $# -le 4 ] ; then Usage; exit 1; fi

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

Opt_args="--clobber"

FAST_t=1  # For FAST: 1 = T1w, 2 = T2w, 3 = PD

# parse arguments
while [ "$1" != "" ]; do
    case $1 in
        -s | --subject )        shift
                                Sub_ID=$1
                                ;;

        --path )                shift
				                        Path=$1
                                ;;

        -i | --input )          shift
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

${RUN} ${BRCDIR}/Show_version.sh --showdiff="no"
Start_Time="$(date -u +%s)"

#=====================================================================================
###                          Sanity checking of arguments
#=====================================================================================
if [ X$Sub_ID = X ] && [ X$IN_Img = X ] && [ X$Path = X ] ; then
    echo "All of the compulsory arguments --path, -i and -s MUST be used"
    exit 1;
fi

#Set fsl_anat options
if [ $do_Sub_seg = no ] ; then
    Opt_args="$Opt_args --nosubcortseg"
fi

Opt_args="$Opt_args -t $FAST_t"

# Setup PATHS
Sub_ID=${Sub_ID%.nii.gz}

O_DIR=$Path/${Sub_ID};
if [ ! -d "$O_DIR" ]; then
    mkdir -p $O_DIR;
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


$FSLDIR/bin/imcp $IN_Img $O_DIR/T1/raw/T1_orig.nii.gz


if [[ $T2 == "yes" ]]; then
    $FSLDIR/bin/imcp $T2_IN_Img $O_DIR/T2/raw/T2_orig.nii.gz
fi


if [[ $do_anat_based_on_FS == "yes" ]]; then
    date; echo "Intensity normalization, Bias correction, Brain Extraction"

    if [ -d $O_DIR/T1/FS ] ; then
        rm -r $O_DIR/T1/FS
    fi

    SUBJECTS_DIR=$O_DIR/T1
    recon-all -i $O_DIR/T1/raw/T1_orig.nii.gz -s FS -autorecon1

    mridir=$O_DIR/T1/FS/mri

    mri_convert -it mgz -ot nii $mridir/T1.mgz $mridir/T1_FS.nii.gz
    mri_convert -it mgz -ot nii $mridir/brainmask.mgz $mridir/brainmask_FS.nii.gz

    $FSLDIR/bin/flirt -ref $O_DIR/T1/raw/T1_orig.nii.gz -in $mridir/T1_FS.nii.gz -omat $mridir/rigid_manToFs.mat -out $mridir/T1.nii.gz -dof 12 -cost normmi -searchcost normmi
    $FSLDIR/bin/flirt -ref $O_DIR/T1/raw/T1_orig.nii.gz -in $mridir/brainmask_FS.nii.gz -out $mridir/brainmask.nii.gz -init $mridir/rigid_manToFs.mat -applyxfm

    #### REORIENTATION 2 STANDARD
    $FSLDIR/bin/fslmaths $mridir/brainmask $mridir/brainmask_orig
    $FSLDIR/bin/fslreorient2std $mridir/brainmask > $mridir/brainmask_orig2std.mat
    $FSLDIR/bin/convert_xfm -omat $mridir/brainmask_std2orig.mat -inverse $mridir/brainmask_orig2std.mat
    $FSLDIR/bin/fslreorient2std $mridir/brainmask $mridir/brainmask

    $FSLDIR/bin/imcp $mridir/brainmask $O_DIR/T1/preprocess/T1_brain_norm

#    $FSLDIR/bin/immv $mridir/brainmask $mridir/brainmask_fullfov
#    $FSLDIR/bin/robustfov -i $mridir/brainmask_fullfov -r $mridir/brainmask -m $mridir/brainmask_roi2nonroi.mat | grep [0-9] | tail -1 > $mridir/brainmask_roi.log
#
#    # combine this mat file and the one above (if generated)
#    $FSLDIR/bin/convert_xfm -omat $mridir/brainmask_nonroi2roi.mat -inverse $mridir/brainmask_roi2nonroi.mat
#    $FSLDIR/bin/convert_xfm -omat $mridir/brainmask_orig2roi.mat -concat $mridir/brainmask_nonroi2roi.mat $mridir/brainmask_orig2std.mat
#    $FSLDIR/bin/convert_xfm -omat $mridir/brainmask_roi2orig.mat -inverse $mridir/brainmask_orig2roi.mat

    Opt_args="$Opt_args --anatbasedFS"
    Opt_args="$Opt_args -i $mridir/T1.nii.gz"
else
    Opt_args="$Opt_args -i $O_DIR/T1/raw/T1_orig.nii.gz"
fi

Opt_args="$Opt_args -o $O_DIR/T1"

# run fsl_anat
date; echo "Queueing fsl_anat for T1w image"
echo "Command is:"
echo '***********************************************************************************************'
#echo "fsl_anat -i $O_DIR/T1/raw/T1_orig.nii.gz "$Opt_args" -o $O_DIR/T1/temp"
echo "fsl_anat "$Opt_args""
echo '***********************************************************************************************'

#${FSLDIR}/bin/fsl_anat "-i $O_DIR/T1/raw/T1_orig.nii.gz "$Opt_args" -o $O_DIR/T1/temp"
${BRC_SCTRUC_SCR}/FSL_anat.sh ""$Opt_args""

if [[ $T2 == "yes" ]]; then
    echo "Queueing fsl_anat for T2w image"
    echo "Command is:"
    echo '***********************************************************************************************'
    echo "fsl_anat -i $O_DIR/T2/raw/T2_orig.nii.gz -o $O_DIR/T2/temp -t T2 --nononlinreg --nosubcortseg --noreg --noseg --clobber"
    echo '***********************************************************************************************'

   ${FSLDIR}/bin/fsl_anat  -i $O_DIR/T2/raw/T2_orig.nii.gz -o $O_DIR/T2/temp -t T2 --nononlinreg --nosubcortseg --noreg --noseg --clobber
fi


echo "Queueing organizing data structure"
${BRC_SCTRUC_SCR}/move_rename.sh $O_DIR $T2 $do_Sub_seg


if [ $do_tissue_seg = "yes" ] && [ $T2 = "yes" ] ; then
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


if [[ $do_freesurfer == "yes" ]]; then
    SUBJECTS_DIR=$O_DIR/T1
    echo "Queueing Freesurfer"

#    if [[ $T2 == yes ]]; then
#      recon-all -i $O_DIR/T1/raw/T1_orig.nii.gz -s FS -FLAIR $O_DIR/T2/raw/T2_orig.nii.gz -all
#    else
        recon-all -s FS -autorecon2

        recon-all -s FS -autorecon3

        rm -r $O_DIR/T1/fsaverage
#      recon-all -i $O_DIR/T1/raw/T1_orig.nii.gz -s FS -all
#    fi
fi


END_Time="$(date -u +%s)"


${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Sub_ID} \
      --type=1


#: <<'COMMENT'

#!/bin/bash
# Last update: 09/10/2018
#Example:
#./struc_preproc.sh --path ~/main/analysis -s Sub_002 -i ~/P_Share/Images/3T_Harmonisation_Stam/03286_20180307_Ingenia/NIFTI/1_MPRAGE/__T1_1mm_sag_20180307162159_201.nii.gz -t2 ~/P_Share/Images/3T_Harmonisation_Stam/03286_20180307_Ingenia/NIFTI/2_3D_T2w_FLAIR/__T2_FLAIR_1mm_20180307162159_301.nii.gz --subseg

# -e  Exit immediately if a command exits with a non-zero status.
set -e

#export ScriptsDir=$(dirname "$(readlink -f "$0")") #Absolute path where scripts are
#source ${ScriptsDir}/init_vars.sh

# --------------------------------------------------------------------------------
#  Load Function Libraries
# --------------------------------------------------------------------------------

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

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
  echo " -i | --input <T1W image>         Full path of the input image (for one image only)"
  echo " --path <full path>               Output path"
  echo " -s | --subject <Subject name>    Output directory is a subject name folder in output path directory"
  echo " "
  echo "Optional arguments (You may optionally specify one or more of):"
  echo " -t2 <T2W image>                  Full path of the input T2W image (for processing of T2 data)"
  echo " --freesurfer                     Turn on Freesurfer processing pipeline"
  echo " --subseg                         Turn on subcortical segmentation by FIRS"
  echo " --qc                             Turn on quality control of T1 data"
  echo " --strongbias                     Turn on for images with very strong bias fields"
  echo " --noreg                          Turn off steps that do registration to standard (FLIRT and FNIRT)"
  echo " --noseg                          Turn off step that does tissue-type segmentation (FAST)"
  echo " -ft | --FAST_t <type>            Specify the type of image (choose one of T1 T2 PD - default is T1)"
  echo " -h | --help                      help"
  echo " "
  echo " "
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi
if [ $# -le 4 ] ; then Usage; exit 1; fi

################################################## OPTION PARSING #####################################################
log_Msg "Parsing Command Line Options"

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

Opt_args="--clobber"

FAST_t=1  # For FAST: 1 = T1w, 2 = T2w, 3 = PD

# parse arguments
while [ "$1" != "" ]; do
    case $1 in
        -s | --subject )        shift
                                Sub_ID=$1
                                log_Msg "Sub_ID: ${Sub_ID}"
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

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

AnalysisFolderName="analysis"
AnatMRIFolderName="anatMRI"
T1FolderName="T1"
T2FolderName="T2"
rawFolderName="raw"
preprocessFolderName="preprocess"
segFolderName="seg"
regFolderName="reg"

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================
echo $log

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
rawT1Folder=${AnatMRIrawFolder}/${T1FolderName}
rawT2Folder=${AnatMRIrawFolder}/${T2FolderName}
T1Folder=${AnatMRIFolder}/${T1FolderName}
T2Folder=${AnatMRIFolder}/${T2FolderName}
preprocT1Folder=${T1Folder}/${preprocessFolderName}
preprocT2Folder=${T2Folder}/${preprocessFolderName}
segT1Folder=${T1Folder}/${segFolderName}
regT1Folder=${T1Folder}/${regFolderName}
regT2Folder=${T2Folder}/${regFolderName}

echo OutputDir is $AnatMRIFolder

#Check existance of foldersa= and then create them
if [ ! -d ${AnalysisFolder} ]; then mkdir ${AnalysisFolder}; fi
if [ ! -d ${AnatMRIFolder} ]; then mkdir ${AnatMRIFolder}; fi
if [ ! -d ${rawFolder} ]; then mkdir ${rawFolder}; fi
if [ ! -d ${AnatMRIrawFolder} ]; then mkdir ${AnatMRIrawFolder}; fi
if [ ! -d ${T1Folder} ]; then mkdir ${T1Folder}; fi
if [ ! -d ${rawT1Folder} ]; then mkdir ${rawT1Folder}; fi
if [ ! -d ${preprocT1Folder} ]; then mkdir ${preprocT1Folder}; fi
if [ ! -d ${segT1Folder} ]; then mkdir ${segT1Folder}; fi
if [ ! -d "${segT1Folder}/tissue" ]; then mkdir ${segT1Folder}/tissue; fi
if [ ! -d "${segT1Folder}/tissue/sing_chan" ]; then mkdir ${segT1Folder}/tissue/sing_chan; fi
if [ ! -d "${segT1Folder}/tissue/multi_chan" ]; then mkdir ${segT1Folder}/tissue/multi_chan; fi
if [ ! -d "${segT1Folder}/sub" ]; then mkdir ${segT1Folder}/sub; fi
if [ ! -d "${segT1Folder}/sub/shape" ]; then mkdir ${segT1Folder}/sub/shape; fi
if [ ! -d ${regT1Folder} ]; then mkdir ${regT1Folder}; fi
if [ ! -d "${regT1Folder}/lin" ]; then mkdir ${regT1Folder}/lin; fi
if [ ! -d "${regT1Folder}/nonlin" ]; then mkdir ${regT1Folder}/nonlin; fi
if [ ! -d ${T1Folder}/log ]; then mkdir ${T1Folder}/log; fi
if [ ! -d "${T1Folder}/qc" ]; then mkdir ${T1Folder}/qc; fi
if [ ! -d "${T1Folder}/unlabeled" ]; then mkdir ${T1Folder}/unlabeled; fi
if [ ! -d "${T1Folder}/unlabeled/fsl_anat" ]; then mkdir ${T1Folder}/unlabeled/fsl_anat; fi

if [[ $T2 == yes ]]; then
    if [ ! -d ${T2Folder} ]; then mkdir ${T2Folder}; fi
    if [ ! -d ${rawT2Folder} ]; then mkdir ${rawT2Folder}; fi
    if [ ! -d ${preprocT2Folder} ]; then mkdir ${preprocT2Folder}; fi
    if [ ! -d ${regT2Folder} ]; then mkdir ${regT2Folder}; fi
    if [ ! -d ${regT2Folder}/lin ]; then mkdir ${regT2Folder}/lin; fi
    if [ ! -d ${regT2Folder}/nonlin ]; then mkdir ${regT2Folder}/nonlin; fi
    if [ ! -d "${T2Folder}/log" ]; then mkdir ${T2Folder}/log; fi
    if [ ! -d "${T2Folder}/qc" ]; then mkdir ${T2Folder}/qc; fi
    if [ ! -d "${T2Folder}/unlabeled" ]; then mkdir ${T2Folder}/unlabeled; fi
    if [ ! -d "${T2Folder}/unlabeled/fsl_anat" ]; then mkdir ${T2Folder}/unlabeled/fsl_anat; fi
fi

#=====================================================================================
###                                   DO WORK
#=====================================================================================


$FSLDIR/bin/imcp $IN_Img ${rawT1Folder}/T1_orig.nii.gz


if [[ $T2 == "yes" ]]; then
    $FSLDIR/bin/imcp $T2_IN_Img ${rawT2Folder}/T2_orig.nii.gz
fi

: <<'COMMENT'

if [[ $do_anat_based_on_FS == "yes" ]]; then
    date; echo "Intensity normalization, Bias correction, Brain Extraction"

    if [ -d ${T1Folder}/FS ] ; then
        rm -r ${T1Folder}/FS
    fi

    SUBJECTS_DIR=${T1Folder}
    recon-all -i ${rawT1Folder}/T1_orig.nii.gz -s FS -autorecon1

    mridir=${T1Folder}/FS/mri

    mri_convert -it mgz -ot nii $mridir/T1.mgz $mridir/T1_FS.nii.gz
    mri_convert -it mgz -ot nii $mridir/brainmask.mgz $mridir/brainmask_FS.nii.gz

    $FSLDIR/bin/flirt -ref ${rawT1Folder}/T1_orig.nii.gz -in $mridir/T1_FS.nii.gz -omat $mridir/rigid_manToFs.mat -out $mridir/T1.nii.gz -dof 12 -cost normmi -searchcost normmi
    $FSLDIR/bin/flirt -ref ${rawT1Folder}/T1_orig.nii.gz -in $mridir/brainmask_FS.nii.gz -out $mridir/brainmask.nii.gz -init $mridir/rigid_manToFs.mat -applyxfm

    #### REORIENTATION 2 STANDARD
    $FSLDIR/bin/fslmaths $mridir/brainmask $mridir/brainmask_orig
    $FSLDIR/bin/fslreorient2std $mridir/brainmask > $mridir/brainmask_orig2std.mat
    $FSLDIR/bin/convert_xfm -omat $mridir/brainmask_std2orig.mat -inverse $mridir/brainmask_orig2std.mat
    $FSLDIR/bin/fslreorient2std $mridir/brainmask $mridir/brainmask

    $FSLDIR/bin/imcp $mridir/brainmask ${preprocT1Folder}/T1_brain_norm

    Opt_args="$Opt_args --anatbasedFS"
    Opt_args="$Opt_args -i $mridir/T1.nii.gz"
else
    Opt_args="$Opt_args -i ${rawT1Folder}/T1_orig.nii.gz"
fi

Opt_args="$Opt_args -o ${T1Folder}"

# run fsl_anat
date; echo "Queueing fsl_anat for T1w image"
echo "Command is:"
echo '***********************************************************************************************'
#echo "fsl_anat -i ${rawT1Folder}/T1_orig.nii.gz "$Opt_args" -o ${T1Folder}/temp"
echo "fsl_anat "$Opt_args""
echo '***********************************************************************************************'

#${FSLDIR}/bin/fsl_anat "-i ${rawT1Folder}/T1_orig.nii.gz "$Opt_args" -o ${T1Folder}/temp"
${BRC_SCTRUC_SCR}/FSL_anat.sh ""$Opt_args""


if [[ $T2 == "yes" ]]; then
    echo "Queueing fsl_anat for T2w image"
    echo "Command is:"
    echo '***********************************************************************************************'
    echo "fsl_anat -i ${rawT2Folder}/T2_orig.nii.gz -o ${T2Folder}/temp -t T2 --nononlinreg --nosubcortseg --noreg --noseg --clobber"
    echo '***********************************************************************************************'

   ${FSLDIR}/bin/fsl_anat  -i ${rawT2Folder}/T2_orig.nii.gz -o ${T2Folder}/temp -t T2 --nononlinreg --nosubcortseg --noreg --noseg --clobber
fi


echo "Queueing organizing data structure"
${BRC_SCTRUC_SCR}/move_rename.sh $AnatMRIFolder $T2 $do_Sub_seg


if [ $do_tissue_seg = "yes" ] && [ $T2 = "yes" ] ; then
    echo "Do multichanel tissue segmentation using FAST"

    if [ ! -d "${T1Folder}/temp" ]; then mkdir ${T1Folder}/temp; fi
    if [ ! -d "${T1Folder}/unlabeled/mc_FAST" ]; then mkdir ${T1Folder}/unlabeled/mc_FAST; fi

    $FSLDIR/bin/fast -o ${T1Folder}/temp/mc_FAST -g -N -S 2 ${preprocT1Folder}/T1_biascorr_brain  ${T2Folder}/reg/lin/T2_2_T1

    $FSLDIR/bin/immv ${T1Folder}/temp/mc_FAST_pve_0  ${segT1Folder}/tissue/multi_chan/T1_mc_pve_CSF
    $FSLDIR/bin/immv ${T1Folder}/temp/mc_FAST_pve_1  ${segT1Folder}/tissue/multi_chan/T1_mc_pve_WM
    $FSLDIR/bin/immv ${T1Folder}/temp/mc_FAST_pve_2  ${segT1Folder}/tissue/multi_chan/T1_mc_pve_GM
    $FSLDIR/bin/immv ${T1Folder}/temp/mc_FAST_pveseg  ${segT1Folder}/tissue/multi_chan/T1_mc_pveseg
    $FSLDIR/bin/immv ${T1Folder}/temp/mc_FAST_seg_0  ${segT1Folder}/tissue/multi_chan/T1_mc_CSF
    $FSLDIR/bin/immv ${T1Folder}/temp/mc_FAST_seg_1  ${segT1Folder}/tissue/multi_chan/T1_mc_WM
    $FSLDIR/bin/immv ${T1Folder}/temp/mc_FAST_seg_2  ${segT1Folder}/tissue/multi_chan/T1_mc_GM
    $FSLDIR/bin/immv ${T1Folder}/temp/mc_FAST_seg  ${segT1Folder}/tissue/multi_chan/T1_mc_seg

    mv ${T1Folder}/temp/* ${T1Folder}/unlabeled/mc_FAST/
    rm -r ${T1Folder}/temp
fi


if [[ $do_freesurfer == "yes" ]]; then
    SUBJECTS_DIR=${T1Folder}
    echo "Queueing Freesurfer"

#    if [[ $T2 == yes ]]; then
#      recon-all -i ${rawT1Folder}/T1_orig.nii.gz -s FS -FLAIR ${rawT2Folder}/T2_orig.nii.gz -all
#    else
        recon-all -s FS -autorecon2

        recon-all -s FS -autorecon3

        rm -r ${T1Folder}/fsaverage
#      recon-all -i ${rawT1Folder}/T1_orig.nii.gz -s FS -all
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

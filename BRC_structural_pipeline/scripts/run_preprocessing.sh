#!/bin/bash
# Last update: 02/10/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
set -e

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions

# function for parsing options
getopt1()
{
    sopt="$1"
    shift 1

    for fn in $@ ; do
        if [ `echo $fn | grep -- "^${sopt}=" | wc -w` -gt 0 ] ; then
            echo $fn | sed "s/^${sopt}=//"
            return 0
        fi
    done
}

# parse arguments
processedT1Folder=`getopt1 "--workingdir" $@`
T1input=`getopt1 "--t1input" $@`
FSFolderName=`getopt1 "--fsfoldername" $@`
OutNormFolder=`getopt1 "--outnorm" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+   START: Intensity normalization, Bias correction, Brain Extraction    +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

if [ -e "${processedT1Folder}/${FSFolderName}" ] ; then
    rm -r ${processedT1Folder}/${FSFolderName}
fi

SUBJECTS_DIR=${processedT1Folder}

recon-all -i ${T1input} -s ${FSFolderName} -autorecon1

mridir=${processedT1Folder}/${FSFolderName}/mri

mri_convert -it mgz -ot nii $mridir/T1.mgz $mridir/T1_FS.nii.gz
mri_convert -it mgz -ot nii $mridir/brainmask.mgz $mridir/brainmask_FS.nii.gz

$FSLDIR/bin/flirt -ref ${T1input} -in $mridir/T1_FS.nii.gz -omat $mridir/rigid_manToFs.mat -out $mridir/T1.nii.gz -dof 12 -cost normmi -searchcost normmi
$FSLDIR/bin/flirt -ref ${T1input} -in $mridir/brainmask_FS.nii.gz -out $mridir/brainmask.nii.gz -init $mridir/rigid_manToFs.mat -applyxfm

#### REORIENTATION 2 STANDARD
$FSLDIR/bin/fslmaths $mridir/brainmask $mridir/brainmask_orig
$FSLDIR/bin/fslreorient2std $mridir/brainmask > $mridir/brainmask_orig2std.mat
$FSLDIR/bin/convert_xfm -omat $mridir/brainmask_std2orig.mat -inverse $mridir/brainmask_orig2std.mat
$FSLDIR/bin/fslreorient2std $mridir/brainmask $mridir/brainmask

$FSLDIR/bin/imcp $mridir/brainmask ${OutNormFolder}/T1_brain_norm

log_Msg 3 ""
log_Msg 3 "     END: Intensity normalization, Bias correction, Brain Extraction      "
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "


################################################################################################
## Cleanup
################################################################################################

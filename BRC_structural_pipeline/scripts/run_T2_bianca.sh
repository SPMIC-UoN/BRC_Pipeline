#!/bin/bash
# Last update: 16/03/2021

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
set -e

source ${BRC_GLOBAL_SCR}/log.shlib  # Logging related functions

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
WD=`getopt1 "--workingdir" $@`
TempT1Folder=`getopt1 "--tempt1folder" $@`
FastT1Folder=`getopt1 "--fastfolder" $@`
BiancaTempFolder=`getopt1 "--biancatempfolder" $@`
regTempT1Folder=`getopt1 "--regtempt1folder" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "TempT1Folder:$TempT1Folder"
log_Msg 2 "FastT1Folder:$FastT1Folder"
log_Msg 2 "BiancaTempFolder:$BiancaTempFolder"
log_Msg 2 "regTempT1Folder:$regTempT1Folder"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

if [ -e ${BiancaTempFolder} ] ; then rm -r ${BiancaTempFolder}; fi; mkdir ${BiancaTempFolder}

#Check if all required files are in place. In case one is missing, BIANCA will not run
for required_file in "${TempT1Folder}/T1_unbiased_brain.nii.gz" "${TempT1Folder}/T1_unbiased.nii.gz" "${WD}/T2_unbiased.nii.gz" "${regTempT1Folder}/T1_to_MNI_nonlin_coeff_inv.nii.gz" "${regTempT1Folder}/T1_to_MNI_linear.mat" "${FastT1Folder}/T1_brain_pve_0.nii.gz" ; do
    if [ ! -f ${required_file} ] ; then
        echo "Problem running Bianca. File $required_file is missing"
        exit 1
    fi
done

#Create an inclusion mask with T1 --> Used to remove GM from BIANCA results
$FSLDIR/bin/make_bianca_mask ${TempT1Folder}/T1_unbiased.nii.gz ${FastT1Folder}/T1_brain_pve_0.nii.gz ${regTempT1Folder}/T1_to_MNI_nonlin_coeff_inv.nii.gz

#Move the inclusion mask to T2_FLAIR/lesions directory
mv ${TempT1Folder}/T1_unbiased_bianca_mask.nii.gz ${TempT1Folder}/T1_unbiased_ventmask.nii.gz ${TempT1Folder}/T1_unbiased_brain_mask.nii.gz ${BiancaTempFolder}

#Generate the configuration file to run Bianca
echo ${TempT1Folder}/T1_unbiased_brain.nii.gz ${WD}/T2_unbiased.nii.gz ${regTempT1Folder}/T1_to_MNI_linear.mat > ${BiancaTempFolder}/conf_file.txt;

#Run BIANCA
$FSLDIR/bin/bianca --singlefile=${BiancaTempFolder}/conf_file.txt --querysubjectnum=1 --brainmaskfeaturenum=1 --loadclassifierdata=${BRC_GLOBAL_DIR}/templates/bianca_class_data --matfeaturenum=3 --featuresubset=1,2 -o ${BiancaTempFolder}/bianca_mask

#Apply the inclusion mask to BIANCA output to get the final thresholded mask
fslmaths ${BiancaTempFolder}/bianca_mask -mul ${BiancaTempFolder}/T1_unbiased_bianca_mask.nii.gz -thr 0.8 -bin ${BiancaTempFolder}/final_mask

#Get the volume of the lesions
fslstats ${BiancaTempFolder}/final_mask -V | awk '{print $1}' > ${BiancaTempFolder}/volume.txt

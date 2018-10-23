#!/bin/bash
# Last update: 05/10/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
set -e

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
rfMRIFolder=`getopt1 "--workingdir" $@`
unlabeledFolder=`getopt1 "--unlabeledfolder" $@`
NameOffMRI=`getopt1 "--nameoffmri" $@`

rawFolderName=`getopt1 "--rawfoldername" $@`
OrigSE_Pos_Name=`getopt1 "--origse_pos_name" $@`
OrigSE_Neg_Name=`getopt1 "--origse_neg_name" $@`
OrigTCSName=`getopt1 "--origtcsname" $@`
OrigScoutName=`getopt1 "--origscoutname" $@`
DistortionCorrection=`getopt1 "--method" $@`

regFolderName=`getopt1 "--regfoldername" $@`
rfMRI2strTransf=`getopt1 "--rfmri2strtransf" $@`
Str2rfMRITransf=`getopt1 "--str2rfmritransf" $@`
rfMRI2StandardTransform=`getopt1 "--rfmri2stdtransf" $@`
Standard2rfMRITransform=`getopt1 "--std2rfMRItransf" $@`

mcFolderName=`getopt1 "--mcfoldername" $@`
eddyFolderName=`getopt1 "--eddyfoldername" $@`
MotionCorrectionType=`getopt1 "--motioncorrectiontype" $@`
EddyOutput=`getopt1 "--eddyoutput" $@`
MotionMatrixFolder=`getopt1 "--motionmatrixfolder" $@`

figsFolderName=`getopt1 "--figsfoldername" $@`

processedFolderName=`getopt1 "--processedfoldername" $@`
SliceTimingCorrection=`getopt1 "--stc_method" $@`
stcFolderName=`getopt1 "--stcfoldername" $@`
smoothingfwhm=`getopt1 "--smoothingfwhm" $@`
nrFolderName=`getopt1 "--nrfoldername" $@`
Do_intensity_norm=`getopt1 "--dointensitynorm" $@`
InNormfFolderName=`getopt1 "--innormffoldername" $@`
ScoutName=`getopt1 "--scoutname" $@`
gdcFolderName=`getopt1 "--gdcfoldername" $@`
DCFolderName=`getopt1 "--dcfoldername" $@`
RegOutput=`getopt1 "--oregim" $@`
OneStResFolderName=`getopt1 "--onestresfoldername" $@`
tempfiltFolderName=`getopt1 "--tempfiltfoldername" $@`
Temp_Filter_Cutoff=`getopt1 "--temfFiltercutoff" $@`

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+                                                                        +"
echo "+                   START: Organization of the outputs                   +"
echo "+                                                                        +"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

rawFolder=${rfMRIFolder}/${rawFolderName}
regFolder=${rfMRIFolder}/${regFolderName}
mcFolder=${rfMRIFolder}/${mcFolderName}
figsFolder=${rfMRIFolder}/${figsFolderName}
processedFolder=${rfMRIFolder}/${processedFolderName}

rawUnlabFolder=${unlabeledFolder}/${rawFolderName}
regUnlabFolder=${unlabeledFolder}/${regFolderName}
mcUnlabFolder=${unlabeledFolder}/${mcFolderName}
EddyUnlabFolder=${unlabeledFolder}/${eddyFolderName}
StcUnlabFolder=${unlabeledFolder}/${stcFolderName}
nrUnlabFolder=${unlabeledFolder}/${nrFolderName}
InNormUnlabFolder=${unlabeledFolder}/${InNormfFolderName}
gdcUnlabFolder=${unlabeledFolder}/${gdcFolderName}
DcUnlabFolder=${unlabeledFolder}/${DCFolderName}
OneStResUnlabFolder=${unlabeledFolder}/${OneStResFolderName}
TemFilUnlabFolder=${unlabeledFolder}/${tempfiltFolderName}

if [ ! -d "$rawFolder" ]; then mkdir $rawFolder; fi
if [ ! -d "$regFolder" ]; then mkdir $regFolder; fi
if [ ! -d "$mcFolder" ]; then mkdir $mcFolder; fi
if [ ! -d "$figsFolder" ]; then mkdir $figsFolder; fi
if [ ! -d "$processedFolder" ]; then mkdir $processedFolder; fi


echo "Organizing Raw folder"
$FSLDIR/bin/imcp ${rawUnlabFolder}/${OrigTCSName} ${rawFolder}/${OrigTCSName}
$FSLDIR/bin/imcp ${rawUnlabFolder}/${OrigScoutName} ${rawFolder}/${OrigScoutName}

if [[ $DistortionCorrection == "TOPUP" ]] ; then
    $FSLDIR/bin/imcp ${rawUnlabFolder}/${OrigSE_Pos_Name} ${rawFolder}/${OrigSE_Pos_Name}
    $FSLDIR/bin/imcp ${rawUnlabFolder}/${OrigSE_Neg_Name} ${rawFolder}/${OrigSE_Neg_Name}
fi


echo "Organizing Reg folder"
$FSLDIR/bin/imcp ${regUnlabFolder}/${rfMRI2strTransf}.nii.gz ${regFolder}/${rfMRI2strTransf}.nii.gz
$FSLDIR/bin/imcp ${regUnlabFolder}/${Str2rfMRITransf}.nii.gz ${regFolder}/${Str2rfMRITransf}.nii.gz
cp ${DcUnlabFolder}/fMRI2str.mat ${regFolder}/${rfMRI2strTransf}.mat
$FSLDIR/bin/imcp ${regUnlabFolder}/${rfMRI2StandardTransform} ${regFolder}/${NameOffMRI}2std
$FSLDIR/bin/imcp ${regUnlabFolder}/${Standard2rfMRITransform} ${regFolder}/std2${NameOffMRI}


echo "Organizing MC folder"
if [[ ${MotionCorrectionType} == "EDDY" ]]; then
    $FSLDIR/bin/imcp ${EddyUnlabFolder}/${EddyOutput} ${mcFolder}/${NameOffMRI}_ec
    cp ${EddyUnlabFolder}/${EddyOutput}.eddy_parameters  ${mcFolder}/${NameOffMRI}_ec.eddy_parameters
elif [[ ${MotionCorrectionType} == "MCFLIRT" ]]; then
    $FSLDIR/bin/imcp ${mcUnlabFolder}/${NameOffMRI}_mc ${mcFolder}/${NameOffMRI}_mc
    cp ${mcUnlabFolder}/${NameOffMRI}_mc.par ${mcFolder}/${NameOffMRI}_mc.par
    cp -r ${mcUnlabFolder}/${MotionMatrixFolder} ${mcFolder}/${MotionMatrixFolder}
fi


echo "Organizing Figs folder"
if [[ ${MotionCorrectionType} == "EDDY" ]]; then
    cp ${EddyUnlabFolder}/eddy_movement_rms.png ${figsFolder}/eddy_movement_rms.png
    cp ${EddyUnlabFolder}/eddy_restricted_movement_rms.png ${figsFolder}/eddy_restricted_movement_rms.png
elif [[ ${MotionCorrectionType} == "MCFLIRT" ]]; then
    cp ${mcUnlabFolder}/rot.png ${figsFolder}/mcflirt_rot.png
    cp ${mcUnlabFolder}/trans.png ${figsFolder}/mcflirt_trans.png
fi


echo "Organizing Processed folder"
if [[ ${MotionCorrectionType} == "EDDY" ]]; then
    processed_rfMRI_file=${EddyUnlabFolder}/${EddyOutput}
    processed_SBRef_file=${DcUnlabFolder}/SBRef_dc
elif [[ ${MotionCorrectionType} == "MCFLIRT" ]]; then
    processed_rfMRI_file=${mcUnlabFolder}/${NameOffMRI}_mc
    processed_SBRef_file=${gdcUnlabFolder}/${ScoutName}_gdc
fi

if [ $SliceTimingCorrection -ne 0 ]; then
    processed_rfMRI_file=${StcUnlabFolder}/${NameOffMRI}_stc
fi


processed_rfMRI_file=${TemFilUnlabFolder}/${NameOffMRI}_tempfilt
processed_rfMRI2std_file=${OneStResUnlabFolder}/${NameOffMRI}_nonlin
processed_SBRef_file=${InNormUnlabFolder}/${NameOffMRI}_SBRef_nonlin_norm
processed_SBRef2str_file=${DcUnlabFolder}/SBRef_dc
processed_SBRef2std_file=${OneStResUnlabFolder}/${NameOffMRI}_SBRef_nonlin


$FSLDIR/bin/imcp ${processed_rfMRI_file} ${processedFolder}/${NameOffMRI}
$FSLDIR/bin/imcp ${processed_rfMRI2std_file} ${processedFolder}/${NameOffMRI}2std
$FSLDIR/bin/imcp ${processed_SBRef_file} ${processedFolder}/SBref
$FSLDIR/bin/imcp ${processed_SBRef2str_file} ${processedFolder}/SBref2str
$FSLDIR/bin/imcp ${processed_SBRef2std_file} ${processedFolder}/SBref2std


echo ""
echo "                     END: Organization of the outputs"
echo "                    END: `date`"
echo "=========================================================================="
echo "                             ===============                              "

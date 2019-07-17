#!/bin/bash
# Last update: 05/10/2018

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
rfMRIrawFolder=`getopt1 "--rfmrirawfolder" $@`
rfMRIFolder=`getopt1 "--rfmrifolder" $@`
preprocFolder=`getopt1 "--preprocfolder" $@`
processedFolder=`getopt1 "--processedfolder" $@`
TempFolder=`getopt1 "--tempfolder" $@`
EddyFolder=`getopt1 "--eddyfolder" $@`
DCFolder=`getopt1 "--dcfolder" $@`
SE_BF_Folder=`getopt1 "--biasfieldfolder" $@`
TOPUP_Folder=`getopt1 "--topupfolder" $@`
gdcFolder=`getopt1 "--gdcfolder" $@`
In_Nrm_Folder=`getopt1 "--intennormfolder" $@`
mcFolder=`getopt1 "--motcorrfolder" $@`
nrFolder=`getopt1 "--noisremfolder" $@`
OsrFolder=`getopt1 "--onestepfolder" $@`
regFolder=`getopt1 "--regfolder" $@`
stcFolder=`getopt1 "--slicecorrfolder" $@`
Tmp_Filt_Folder=`getopt1 "--tempfiltfolder" $@`
qcFolder=`getopt1 "--qcfolder" $@`
NameOffMRI=`getopt1 "--nameoffmri" $@`
rfMRI2strTransf=`getopt1 "--rfmri2strtransf" $@`
Str2rfMRITransf=`getopt1 "--str2rfmritransf" $@`
rfMRI2StandardTransform=`getopt1 "--rfmri2stdtransf" $@`
Standard2rfMRITransform=`getopt1 "--std2rfMRItransf" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                   START: Organization of the outputs                   +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "rfMRIrawFolder:$rfMRIrawFolder"
log_Msg 2 "rfMRIFolder:$rfMRIFolder"
log_Msg 2 "preprocFolder:$preprocFolder"
log_Msg 2 "processedFolder:$processedFolder"
log_Msg 2 "TempFolder:$TempFolder"
log_Msg 2 "EddyFolder:$EddyFolder"
log_Msg 2 "DCFolder:$DCFolder"
log_Msg 2 "SE_BF_Folder:$SE_BF_Folder"
log_Msg 2 "TOPUP_Folder:$TOPUP_Folder"
log_Msg 2 "gdcFolder:$gdcFolder"
log_Msg 2 "In_Nrm_Folder:$In_Nrm_Folder"
log_Msg 2 "mcFolder:$mcFolder"
log_Msg 2 "nrFolder:$nrFolder"
log_Msg 2 "OsrFolder:$OsrFolder"
log_Msg 2 "regFolder:$regFolder"
log_Msg 2 "stcFolder:$stcFolder"
log_Msg 2 "Tmp_Filt_Folder:$Tmp_Filt_Folder"
log_Msg 2 "qcFolder:$qcFolder"
log_Msg 2 "NameOffMRI:$NameOffMRI"
log_Msg 2 "rfMRI2strTransf:$rfMRI2strTransf"
log_Msg 2 "Str2rfMRITransf:$Str2rfMRITransf"
log_Msg 2 "rfMRI2StandardTransform:$rfMRI2StandardTransform"
log_Msg 2 "Standard2rfMRITransform:$Standard2rfMRITransform"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

denoisingPreFolderName="denoising"
ICA_AROMAPreFolderName="ICA_AROMA"
PNMPreFolderName="PNM"
FieldMapPreFolderName="filedmap"
topupPreFolderName="topup"
fuguePreFolderName="fugue"
mcPreFolderName="mc"
eddyPreFolderName="eddy"
mcflirtPreFolderName="mcflirt"
regPreFolderName="reg"
qcPreFolderName="qc"
dataProFolderName="data"
data2stdProFolderName="data2std"

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

denoisingPreFolder=${preprocFolder}/${denoisingPreFolderName}
icaaromaPreFolder=${denoisingPreFolder}/${ICA_AROMAPreFolderName}
pnmPreFolder=${denoisingPreFolder}/${PNMPreFolderName}
fieldmapPreFolder=${preprocFolder}/${FieldMapPreFolderName}
topupPreFolder=${fieldmapPreFolder}/${topupPreFolderName}
fuguePreFolder=${fieldmapPreFolder}/${fuguePreFolderName}
mcPreFolder=${preprocFolder}/${mcPreFolderName}
eddyPreFolder=${mcPreFolder}/${eddyPreFolderName}
mcflirtPreFolder=${mcPreFolder}/${mcflirtPreFolderName}
regPreFolder=${preprocFolder}/${regPreFolderName}
qcPreFolder=${preprocFolder}/${qcPreFolderName}
dataProFolder=${processedFolder}/${dataProFolderName}
data2stdProFolder=${processedFolder}/${data2stdProFolderName}

if [ ! -d ${denoisingPreFolder} ]; then mkdir ${denoisingPreFolder}; fi
if [ ! -d ${icaaromaPreFolder} ]; then mkdir ${icaaromaPreFolder}; fi
if [ ! -d ${pnmPreFolder} ]; then mkdir ${pnmPreFolder}; fi
if [ ! -d ${fieldmapPreFolder} ]; then mkdir ${fieldmapPreFolder}; fi
if [ ! -d ${topupPreFolder} ]; then mkdir ${topupPreFolder}; fi
if [ ! -d ${fuguePreFolder} ]; then mkdir ${fuguePreFolder}; fi
if [ ! -d ${mcPreFolder} ]; then mkdir ${mcPreFolder}; fi
if [ ! -d ${eddyPreFolder} ]; then mkdir ${eddyPreFolder}; fi
if [ ! -d ${mcflirtPreFolder} ]; then mkdir ${mcflirtPreFolder}; fi
if [ ! -d ${regPreFolder} ]; then mkdir ${regPreFolder}; fi
if [ ! -d ${qcPreFolder} ]; then mkdir ${qcPreFolder}; fi
if [ ! -d ${dataProFolder} ]; then mkdir ${dataProFolder}; fi
if [ ! -d ${data2stdProFolder} ]; then mkdir ${data2stdProFolder}; fi

#=====================================================================================
###                                   DO WORK
#=====================================================================================

log_Msg 3 "Organizing denoising folder"
if [ -n "$(ls -A ${nrFolder} 2>/dev/null)" ]; then
    cp -r ${nrFolder}/${ICA_AROMAPreFolderName}/* ${icaaromaPreFolder}/
    rm -rf ${nrFolder}
fi

log_Msg 3 "Organizing fieldmap folder"
if [ -n "$(ls -A ${TOPUP_Folder} 2>/dev/null)" ]; then
    cp -r ${TOPUP_Folder}/* ${topupPreFolder}/
    rm -rf ${TOPUP_Folder}
fi

log_Msg 3 "Organizing motion correction folder"
if [ -n "$(ls -A ${EddyFolder} 2>/dev/null)" ]; then
    cp -r ${EddyFolder}/* ${eddyPreFolder}/
    rm -rf ${EddyFolder}
fi

if [ -n "$(ls -A ${mcFolder} 2>/dev/null)" ]; then
    cp -r ${mcFolder}/* ${mcflirtPreFolder}/
    rm -rf ${mcFolder}
fi

log_Msg 3 "Organizing qc folder"
if [ -n "$(ls -A ${qcFolder} 2>/dev/null)" ]; then
    cp -r ${qcFolder}/* ${qcPreFolder}/
    rm -rf ${qcFolder}
fi

log_Msg 3 "Organizing registration folder"
$FSLDIR/bin/imcp ${regFolder}/${rfMRI2strTransf}         ${regPreFolder}/${rfMRI2strTransf}
$FSLDIR/bin/imcp ${regFolder}/${Str2rfMRITransf}         ${regPreFolder}/${Str2rfMRITransf}
              cp ${DCFolder}/fMRI2str.mat                ${regPreFolder}/${rfMRI2strTransf}.mat
$FSLDIR/bin/imcp ${regFolder}/${rfMRI2StandardTransform} ${regPreFolder}/${NameOffMRI}2std
$FSLDIR/bin/imcp ${regFolder}/${Standard2rfMRITransform} ${regPreFolder}/std2${NameOffMRI}


log_Msg 3 "Organizing data folder"
processed_rfMRI_file=${Tmp_Filt_Folder}/${NameOffMRI}_tempfilt
processed_SBRef_file=${In_Nrm_Folder}/SBRef_intnorm
processed_rfMRI2std_file=${OsrFolder}/${NameOffMRI}_nonlin
processed_SBRef2str_file=${DCFolder}/SBRef_dc
processed_SBRef2std_file=${OsrFolder}/${NameOffMRI}_SBRef_nonlin


$FSLDIR/bin/imcp ${processed_rfMRI_file}     ${dataProFolder}/${NameOffMRI}
$FSLDIR/bin/imcp ${processed_rfMRI2std_file} ${data2stdProFolder}/${NameOffMRI}2std
$FSLDIR/bin/imcp ${processed_SBRef_file}     ${dataProFolder}/SBref
$FSLDIR/bin/imcp ${processed_SBRef2str_file} ${dataProFolder}/SBref2str
$FSLDIR/bin/imcp ${processed_SBRef2std_file} ${data2stdProFolder}/SBref2std


log_Msg 3 ""
log_Msg 3 "                     END: Organization of the outputs"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "


################################################################################################
## Cleanup
################################################################################################
rm -rf ${gdcFolder}
rm -rf ${In_Nrm_Folder}
rm -rf ${stcFolder}
rm -rf ${Tmp_Filt_Folder}
rm -rf ${regFolder}

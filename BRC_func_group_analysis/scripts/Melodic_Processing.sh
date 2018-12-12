#!/bin/bash
# Last update: 28/09/2018

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

################################################## OPTION PARSING #####################################################

# parse arguments
InputFiles=`getopt1 "--inputfiles" $@`  # "$1"
ICAapproach=`getopt1 "--icaapproach" $@`  # "$1"
BGImage=`getopt1 "--bgimage" $@`  # "$1"
ThresholdMask=`getopt1 "--thresholdmask" $@`  # "$1"
DataResolution=`getopt1 "--dataresolution" $@`  # "$1"
Dimensionality=`getopt1 "--dimensionality" $@`  # "$1"
NoBET=`getopt1 "--nobet" $@`  # "$1"
BGThreshold=`getopt1 "--bgthreshold" $@`  # "$1"
AtlasFolder=`getopt1 "--atlasfolder" $@`  # "$1"
Melodic_output=`getopt1 "--melout" $@`  # "$1"
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+      START: MELODIC to decopose multiple 4D datasets based on ICA      +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "InputFiles:$InputFiles"
log_Msg 2 "ICAapproach:$ICAapproach"
log_Msg 2 "BGImage:$BGImage"
log_Msg 2 "ThresholdMask:$ThresholdMask"
log_Msg 2 "DataResolution:$DataResolution"
log_Msg 2 "Dimensionality:$Dimensionality"
log_Msg 2 "NoBET:$NoBET"
log_Msg 2 "BGThreshold:$BGThreshold"
log_Msg 2 "AtlasFolder:$AtlasFolder"
log_Msg 2 "Melodic_output:$Melodic_output"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

########################################## DO WORK ##########################################

First_data=`head -n1 ${InputFiles}`

RepetitionTime=`${FSLDIR}/bin/fslval ${First_data} pixdim4 | cut -d " " -f 1`

Melodic_args=""

if [[ $NoBET == "YES" ]] ; then
    Melodic_args="$Melodic_args --nobet --bgthreshold=${BGThreshold}"
fi

if [[ ! X$BGImage = X ]] ; then
    Melodic_args="$Melodic_args --bgimage=${BGImage}"
fi

if [[ ! X$ThresholdMask = X ]] ; then
    Melodic_args="$Melodic_args --mask=${ThresholdMask}"
fi

if [[ ! X$Dimensionality = X ]] ; then
    Melodic_args="$Melodic_args --dim=${Dimensionality}"
fi


#$FSLDIR/bin/melodic \
#        --in=${InputFiles} \
#        --outdir=${Melodic_output} \
#        --tr=${RepetitionTime} \
#        --approach=${ICAapproach} \
#        --verbose \
#        --report \
#        --Oall \
#        ${Melodic_args}


Brain_Img_base=`basename ${BGImage}`
${FSLDIR}/bin/fslmaths ${BGImage} -mul ${ThresholdMask} ${Melodic_output}/${Brain_Img_base}_brain


${BRC_FMRI_GP_SCR}/Generate_ref_Networks.sh \
        --workingdir=${Melodic_output}/refNets \
        --dataresolution=${DataResolution} \
        --atlasfolder=${AtlasFolder} \
        --refbrainimg=${Melodic_output}/${Brain_Img_base}_brain


$FSLDIR/bin/fslcc --noabs -p 3 -t .204 ${Melodic_output}/refNets/yeo2011_7_liberal_combined_${DataResolution}mm.nii.gz ${Melodic_output}/melodic_IC.nii.gz | tr -s ' ' | cut -d ' ' -f 3 | sort -u | awk '{ printf "%02d\n", $1 - 1 }'
#$FSLDIR/bin/fslcc --noabs -p 3 -t .204 ${Melodic_output}/refNets/yeo2011_7_liberal_combined_${DataResolution}mm.nii.gz ${Melodic_output}/melodic_IC.nii.gz | tr -s ' ' | cut -d ' ' -f 3 | sort -u | awk '{ printf "%02d\n", $1 - 1 }' >> nets_of_interest.txt
: <<'COMMENT'

log_Msg 3 ""
log_Msg 3 "        END: MELODIC to decopose multiple 4D datasets based on ICA"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

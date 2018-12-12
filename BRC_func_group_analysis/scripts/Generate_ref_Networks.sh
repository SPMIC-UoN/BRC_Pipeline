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
RefNetdir=`getopt1 "--workingdir" $@`  # "$1"
DataResolution=`getopt1 "--dataresolution" $@`  # "$1"
AtlasFolder=`getopt1 "--atlasfolder" $@`  # "$1"
RefBrainImg=`getopt1 "--refbrainimg" $@`  # "$1"

########################################## DO WORK ##########################################

outputdir=${RefNetdir}/${DataResolution}mm
logdir=${RefNetdir}/log
prefix="FSL_"
Netdir=${RefNetdir}/net

if [ -e ${RefNetdir} ] ; then rm -r ${RefNetdir}; fi; mkdir -p ${RefNetdir}
if [ -e ${outputdir} ] ; then rm -r ${outputdir}; fi; mkdir -p ${outputdir}
if [ -e ${logdir} ] ; then rm -r ${logdir}; fi; mkdir -p ${logdir}
if [ -e ${Netdir} ] ; then rm -r ${Netdir}; fi; mkdir -p ${Netdir}


let netno=1
for f in ${AtlasFolder}/*_7Network*LiberalMask.nii.gz; do
    echo ... converting $f
    inputimg=`basename $f`
    echo ${inputimg}

    outputimg=${prefix}${inputimg}
    echo ${outputimg}

    logname=log${netno}.txt
    dispname=display${netno}

    mri_vol2vol --mov $AtlasFolder/$inputimg --targ ${RefBrainImg}.nii.gz --regheader --o $outputdir/$outputimg --no-save-reg --interp nearest --precision uchar
#    echo "freeview $RefNetdir/$inputimg $outputdir/$outputimg&"  > $logdir/$dispname
#    echo "fslview ${RefBrainImg} $outputdir/$outputimg -l Random-Rainbow&"  >> $logdir/$dispname
#    chmod +x $logdir/$dispname
    let netno=$netno+1
done


for f in ${outputdir}/*Networks_*.nii.gz; do
    b=`basename $f`
    echo $b
    let i=1
    max=`$FSLDIR/bin/fslstats $f -R | awk '{printf("%d", $2)}'`
    while [ $i -le $max ]; do
        mkdir -p ${Netdir}/${i}
        f2=${Netdir}/${i}/net${i}_${b}
        $FSLDIR/bin/fslmaths $f -thr $i -uthr $i $f2
        let i=$i+1
    done
done


$FSLDIR/bin/fslmerge -t ${RefNetdir}/yeo2011_7_liberal_combined.nii.gz `ls ${Netdir}/*/*.nii.gz`
$FSLDIR/bin/flirt -in ${RefNetdir}/yeo2011_7_liberal_combined.nii.gz -ref ${RefNetdir}/yeo2011_7_liberal_combined.nii.gz -out ${RefNetdir}/yeo2011_7_liberal_combined_${DataResolution}mm.nii.gz -applyisoxfm ${DataResolution}

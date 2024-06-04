#!/bin/bash
# Last update: 15/07/2021

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
data=`getopt1 "--data" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "tbss_step_1_preproc"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

mkdir -p FA

for f in `$FSLDIR/bin/imglob $data` ; do

    log_Msg 3 "processing $f"

    # erode a little and zero end slices
    X=`${FSLDIR}/bin/fslval $f dim1`; X=`echo "$X 2 - p" | dc -`
    Y=`${FSLDIR}/bin/fslval $f dim2`; Y=`echo "$Y 2 - p" | dc -`
    Z=`${FSLDIR}/bin/fslval $f dim3`; Z=`echo "$Z 2 - p" | dc -`
    $FSLDIR/bin/fslmaths $f -min 1 -ero -roi 1 $X 1 $Y 1 $Z 0 1 FA/${f}

    # create mask (for use in FLIRT & FNIRT)
    $FSLDIR/bin/fslmaths FA/${f} -bin FA/${f}_mask

    $FSLDIR/bin/fslmaths FA/${f}_mask -dilD -dilD -sub 1 -abs -add FA/${f}_mask FA/${f}_mask -odt char

done

log_Msg 3 "Now running \"slicesdir\" to generate report of all input images"
cd FA
$FSLDIR/bin/slicesdir `$FSLDIR/bin/imglob *_FA.*` > grot 2>&1
cat grot | tail -n 2
/bin/rm grot

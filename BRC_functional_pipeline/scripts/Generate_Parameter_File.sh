#!/bin/bash
# Last update: 28/09/2018

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

WD=`getopt1 "--workingdir" $@`
PhaseEncodeOne=`getopt1 "--phaseone" $@`
PhaseEncodeTwo=`getopt1 "--phasetwo" $@`
UnwarpDir=`getopt1 "--unwarpdir" $@`
EchoSpacing=`getopt1 "--echospacing" $@`
OutTxt=`getopt1 "--out" $@`

# PhaseOne and PhaseTwo are sets of SE EPI images with opposite phase encodes
${FSLDIR}/bin/imcp $PhaseEncodeOne ${WD}/PhaseOne.nii.gz
${FSLDIR}/bin/imcp $PhaseEncodeTwo ${WD}/PhaseTwo.nii.gz

dimtOne=`${FSLDIR}/bin/fslval ${WD}/PhaseOne dim4`
dimtTwo=`${FSLDIR}/bin/fslval ${WD}/PhaseTwo dim4`

# X direction phase encode
if [[ $UnwarpDir = "x" || $UnwarpDir = "x-" || $UnwarpDir = "-x" ]] ; then
    dimP=`${FSLDIR}/bin/fslval ${WD}/PhaseOne dim1`
    dimPminus1=$(($dimP - 1))
    ro_time=`echo "scale=6; ${EchoSpacing} * ${dimPminus1}" | bc -l` #Compute Total_readout in secs with up to 6 decimal places

    echo "Total readout time is $ro_time secs"

    i=1
    while [ $i -le $dimtOne ] ; do
        echo "-1 0 0 $ro_time" >> $OutTxt
        ShiftOne="x-"
        i=`echo "$i + 1" | bc`
    done

    i=1
    while [ $i -le $dimtTwo ] ; do
        echo "1 0 0 $ro_time" >> $OutTxt
        ShiftTwo="x"
        i=`echo "$i + 1" | bc`
    done

# Y direction phase encode
elif [[ $UnwarpDir = "y" || $UnwarpDir = "y-" || $UnwarpDir = "-y" ]] ; then
    dimP=`${FSLDIR}/bin/fslval ${WD}/PhaseOne dim2`
    dimPminus1=$(($dimP - 1))

    ro_time=`echo "scale=6; ${EchoSpacing} * ${dimPminus1}" | bc -l` #Compute Total_readout in secs with up to 6 decimal places

    i=1
    while [ $i -le $dimtOne ] ; do
        echo "0 -1 0 $ro_time" >> $OutTxt
        ShiftOne="y-"
        i=`echo "$i + 1" | bc`
    done

    i=1
    while [ $i -le $dimtTwo ] ; do
        echo "0 1 0 $ro_time" >> $OutTxt
        ShiftTwo="y"
        i=`echo "$i + 1" | bc`
    done

# without phase encoding
else
    dimP=`${FSLDIR}/bin/fslval ${WD}/PhaseOne dim1`
    dimPminus1=$(($dimP - 1))

    ro_time=`echo "scale=6; ${EchoSpacing} * ${dimPminus1}" | bc -l` #Compute Total_readout in secs with up to 6 decimal places

    i=1
    while [ $i -le $(( ${dimtOne} + ${dimtTwo} )) ] ; do
        echo "-1 0 0 $ro_time" >> $OutTxt
        ShiftOne="x-"
        i=`echo "$i + 1" | bc`
    done
fi

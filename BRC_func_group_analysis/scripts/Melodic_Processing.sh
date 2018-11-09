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

# parse arguments
WD=`getopt1 "--workingdir" $@`  # "$1"
InputFiles=`getopt1 "--inputfiles" $@`  # "$1"
NoBET=`getopt1 "--nobet" $@`  # "$1"
BGThreshold=`getopt1 "--bgthreshold" $@`  # "$1"
BGImage=`getopt1 "--bgimage" $@`  # "$1"
Melodic_output=`getopt1 "--melout" $@`  # "$1"
ICAapproach=`getopt1 "--icaapproach" $@`  # "$1"
ThresholdMask=`getopt1 "--thresholdmask" $@`  # "$1"
Dimensionality=`getopt1 "--dimensionality" $@`  # "$1"

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+                                                                        +"
echo "+      START: MELODIC to decopose multiple 4D datasets based on ICA      +"
echo "+                                                                        +"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


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

$FSLDIR/bin/melodic \
       --in=${InputFiles} \
       --outdir=${WD}/${Melodic_output} \
       --tr=${RepetitionTime} \
       --approach=${ICAapproach} \
       --verbose \
       --report \
       --Oall \
       ${Melodic_args}


echo ""
echo "        END: MELODIC to decopose multiple 4D datasets based on ICA"
echo "                    END: `date`"
echo "=========================================================================="
echo "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

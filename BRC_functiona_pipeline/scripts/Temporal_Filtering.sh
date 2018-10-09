#!/bin/bash
# Last update: 09/10/2018

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

################################################## OPTION PARSING #####################################################

# parse arguments
WD=`getopt1 "--workingdir" $@`
Input_fMRI=`getopt1 "--infmri" $@`
Temp_Filter_Cutoff=`getopt1 "--tempfiltercutoff" $@`
OutfMRI=`getopt1 "--outfmri" $@`

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+                                                                        +"
echo "+                       START: Temporal Filtering                        +"
echo "+                                                                        +"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

RepetitionTime=`${FSLDIR}/bin/fslval ${Input_fMRI} pixdim4 | cut -d " " -f 1`


hp_sigma_sec=`echo "scale=6; (($Temp_Filter_Cutoff / 2.0))" | bc`
hp_sigma_vol=`echo "scale=6; (($hp_sigma_sec / $RepetitionTime))" | bc`

fslmaths ${Input_fMRI} -bptf $hp_sigma_vol -1 ${WD}/${OutfMRI}

echo ""
echo "                         END: Temporal Filtering"
echo "                    END: `date`"
echo "=========================================================================="
echo "                             ===============                              "

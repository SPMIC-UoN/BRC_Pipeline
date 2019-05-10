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
WD=`getopt1 "--workingdir" $@`  # "$1"
InputSubjects=`getopt1 "--inputsubjects" $@`  # "$1"
MELODIC_ICs=`getopt1 "--ingroupicmaps" $@`  # "$1"
VarNorm=`getopt1 "--varnorm" $@`  # "$1"
design_name=`getopt1 "--designmatrix" $@`  # "$1"
contrast_name=`getopt1 "--contrastmatrix" $@`  # "$1"
NumPermut=`getopt1 "--numofpermut" $@`  # "$1"
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                         START: Dual Regression                         +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "InputSubjects:$InputSubjects"
log_Msg 2 "MELODIC_ICs:$MELODIC_ICs"
log_Msg 2 "VarNorm:$VarNorm"
log_Msg 2 "design_name:$design_name"
log_Msg 2 "contrast_name:$contrast_name"
log_Msg 2 "NumPermut:$NumPermut"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

########################################## DO WORK ##########################################

$FSLDIR/bin/dual_regression \
      ${MELODIC_ICs} \
      ${VarNorm} \
      ${design_name} \
      ${contrast_name} \
      ${NumPermut} \
      ${WD} \
      `cat ${InputSubjects}`


log_Msg 3 ""
log_Msg 3 "                         END: Dual Regression"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

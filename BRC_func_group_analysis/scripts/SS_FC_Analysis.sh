#!/bin/bash
# Last update: 10/10/2018

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
          # if [ ] ; then Usage ; echo " " ; echo "Error:: option ${sopt} requires an argument"; exit 1 ; end
          return 0
      fi
  done
}

################################################## OPTION PARSING #####################################################

# parse arguments
WD=`getopt1 "--workingdir" $@`
TS=`getopt1 "--timeseries" $@`
TR=`getopt1 "--repetitiontime" $@`
VarNorm=`getopt1 "--varnorm" $@`
CorrType=`getopt1 "--corrtype" $@`
RegVal=`getopt1 "--regval" $@`
LabelList=`getopt1 "--labellist" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "+                                                                        +"
log_Msg 2 "+         START: Single subject functional connectivity analysis         +"
log_Msg 2 "+                                                                        +"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "TS:$TS"
log_Msg 2 "TR:$TR"
log_Msg 2 "VarNorm:$VarNorm"
log_Msg 2 "CorrType:$CorrType"
log_Msg 2 "RegVal:$RegVal"
log_Msg 2 "LabelList:$LabelList"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

########################################## DO WORK ##########################################


case $CorrType in
    "COV")
        method='cov'
    ;;

    "AMP")
        method='amp'
    ;;

    "CORR")
        method='corr'
    ;;

    "RCORR")
        method='rcorr'
    ;;

    "PCORR")
        method='icov'
    ;;

    "RPCORR")
          method='ridgep'
    ;;

    *)
        echo "UNKNOWN NETWORK ASSOSIATION METHOD: ${CorrType}"
        exit 1
esac


test=`${MATLABpath}/matlab -nojvm -nodesktop -r "addpath('${BRC_FMRI_GP_SCR}/FSLNets'); \
                                    addpath('${LIBSVMpath}'); \
                                    run_SS_FSL_Nets('${BRC_FMRI_GP_SCR}/FSLNets' , \
                                    '${BRC_FMRI_GP_SCR}/L1precision' , \
                                    '${BRC_FMRI_GP_SCR}/FSLNets' , \
                                    '${WD}' , \
                                    '${WD}' , \
                                    ${TR} , \
                                    ${VarNorm} , \
                                    '${method}' , \
                                    ${RegVal} , \
                                    '${LabelList}'); \
                                    exit"`

if [ -e $WD/zero_labels.txt ] ; then
    log_Msg 3 ""
    log_Msg 3 "WARNING: This subject has a label without any timeseries on it"
    log_Msg 3 ""
fi

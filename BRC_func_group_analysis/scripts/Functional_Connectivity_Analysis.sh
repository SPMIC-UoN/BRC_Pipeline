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
GruopMaps=`getopt1 "--groupmaps" $@`
TimeSeriesFolder=`getopt1 "--timeseries" $@`
TR=`getopt1 "--repetitiontime" $@`
VarNorm=`getopt1 "--varnorm" $@`
CorrType=`getopt1 "--corrtype" $@`
RegVal=`getopt1 "--regval" $@`
FISHER_R2Z=`getopt1 "--fisherr2z" $@`
NetWebFolder=`getopt1 "--netwebfolder" $@`
DO_GLM=`getopt1 "--doglm" $@`
DesignMatrix=`getopt1 "--designmatrix" $@`
ContrastMatrix=`getopt1 "--contrastmatrix" $@`
FC_Anal_Folder_name=`getopt1 "--outfolder" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+          START: Group functional connectivity network analysis         +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "WD:$WD"
log_Msg 2 "GruopMaps:$GruopMaps"
log_Msg 2 "TimeSeriesFolder:$TimeSeriesFolder"
log_Msg 2 "TR:$TR"
log_Msg 2 "VarNorm:$VarNorm"
log_Msg 2 "CorrType:$CorrType"
log_Msg 2 "RegVal:$RegVal"
log_Msg 2 "FISHER_R2Z:$FISHER_R2Z"
log_Msg 2 "NetWebFolder:$NetWebFolder"
log_Msg 2 "DO_GLM:$DO_GLM"
log_Msg 2 "DesignMatrix:$DesignMatrix"
log_Msg 2 "ContrastMatrix:$ContrastMatrix"
log_Msg 2 "FC_Anal_Folder_name:$FC_Anal_Folder_name"
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


log_Msg 2 "1: ${BRC_FMRI_GP_SCR}/FSLNets"
log_Msg 2 "2: ${LIBSVMpath}"
log_Msg 2 "3: ${BRC_FMRI_GP_SCR}/FSLNets"
log_Msg 2 "4: ${BRC_FMRI_GP_SCR}/L1precision"
log_Msg 2 "5: ${BRC_FMRI_GP_SCR}/FSLNets"
log_Msg 2 "6: ${WD}/${FC_Anal_Folder_name}"
log_Msg 2 "7: ${WD}/${GruopMaps}"
log_Msg 2 "8: ${TimeSeriesFolder}"
log_Msg 2 "9: ${TR}"
log_Msg 2 "10: ${VarNorm}"
log_Msg 2 "11: ${method}"
log_Msg 2 "12: ${RegVal}"
log_Msg 2 "13: ${FISHER_R2Z}"
log_Msg 2 "14: ${NetWebFolder}"
log_Msg 2 "15: ${DO_GLM}"
log_Msg 2 "16: ${DesignMatrix}.mat"
log_Msg 2 "17: ${DesignMatrix}.con"

#${MATLABpath}/matlab -nodesktop -nosplash -nojvm -r > ${WD}/test.txt "addpath('${BRC_FMRI_GP_SCR}/FSLNets'); Answer=test(1,2); quit"


${MATLABpath}/matlab -nodesktop -r "addpath('${BRC_FMRI_GP_SCR}/FSLNets'); \
                                    addpath('${BRC_GLOBAL_DIR}/libs/libsvm'); \
                                    run_FSL_Nets('${BRC_FMRI_GP_SCR}/FSLNets' , \
                                    '${BRC_FMRI_GP_SCR}/L1precision' , \
                                    '${BRC_FMRI_GP_SCR}/FSLNets' , \
                                    '${WD}/${FC_Anal_Folder_name}' , \
                                    '${WD}/${GruopMaps}' , \
                                    '${TimeSeriesFolder}' , \
                                    ${TR} , \
                                    ${VarNorm} , \
                                    '${method}' , \
                                    ${RegVal} , \
                                    ${FISHER_R2Z} , \
                                    '${NetWebFolder}' , \
                                    '${DO_GLM}' , \
                                    '${DesignMatrix}.mat' , \
                                    '${ContrastMatrix}.con'); \
                                    exit"


if [ `cat ${WD}/${FC_Anal_Folder_name}/result.txt` != 0 ]; then
    log_Msg 3 ""
    log_Msg 3 "ERROR: at least in one ROI, the time series Values are zero. Please check the ROI labels"
    log_Msg 3 ""
    exit;
fi


log_Msg 3 ""
log_Msg 3 "           END: Group functional connectivity network analysis"
log_Msg 3 "                    END: `date`"
log_Msg 3 "=========================================================================="
log_Msg 3 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

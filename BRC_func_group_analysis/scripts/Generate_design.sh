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
InputList=`getopt1 "--inputlist" $@`
DO_GLM=`getopt1 "--doglm" $@`
ListFolder=`getopt1 "--listfolder" $@`
DesignFolder=`getopt1 "--designfolder" $@`
SubjectList_name=`getopt1 "--subListname" $@`
GroupList_name=`getopt1 "--grouplistname" $@`
design_name=`getopt1 "--designname" $@`
contrast_name=`getopt1 "--contrastname" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "+                                                                        +"
log_Msg 2 "+                   START: Generate design matrix                        +"
log_Msg 2 "+                                                                        +"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "InputList:$InputList"
log_Msg 2 "DO_GLM:$DO_GLM"
log_Msg 2 "ListFolder:$ListFolder"
log_Msg 2 "DesignFolder:$DesignFolder"
log_Msg 2 "SubjectList_name:$SubjectList_name"
log_Msg 2 "GroupList_name:$GroupList_name"
log_Msg 2 "design_name:$design_name"
log_Msg 2 "contrast_name:$contrast_name"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

########################################## DO WORK ##########################################

#Generate two different list for the subjects and their status
cut -d' ' -f1 < $InputList > ${ListFolder}/${SubjectList_name}

if [ $DO_GLM == "yes" ]; then
#    cut -d' ' -f2 < ${InputList} > ${ListFolder}/${GroupList_name}
    awk '{print $2}' ${InputList} > ${ListFolder}/${GroupList_name}

    group_num=`sort ${ListFolder}/${GroupList_name} | uniq | wc -l`

    for Group in $(cat ${ListFolder}/${GroupList_name})
    do

        for (( i=1; i<=${group_num}; i++ ))
        do

            if (( $i == ${Group} )); then
                printf "1 " >> ${DesignFolder}/${design_name}.txt
            else
                printf "0 " >> ${DesignFolder}/${design_name}.txt
            fi

        done

        printf '\n' >> ${DesignFolder}/${design_name}.txt
    done

    ${FSLDIR}/bin/Text2Vest ${DesignFolder}/${design_name}.txt ${DesignFolder}/${design_name}.mat

    for (( i=1; i<=${group_num}; i++ ))
    do

        for (( j=1; j<=${group_num}; j++ ))
        do

            if (( $i == $j )); then
                printf "1 " >> ${DesignFolder}/${contrast_name}.txt
            else
                printf -- "-1 " >> ${DesignFolder}/${contrast_name}.txt
            fi

        done

        printf '\n' >> ${DesignFolder}/${contrast_name}.txt
    done

    ${FSLDIR}/bin/Text2Vest ${DesignFolder}/${contrast_name}.txt ${DesignFolder}/${contrast_name}.con
fi

log_Msg 2 ""
log_Msg 2 "                       END: Generate design matrix"
log_Msg 2 "                    END: `date`"
log_Msg 2 "=========================================================================="
log_Msg 2 "                             ===============                              "

################################################################################################
## Cleanup
################################################################################################

if [ $DO_GLM == "yes" ]; then
    rm ${DesignFolder}/${contrast_name}.txt
    rm ${DesignFolder}/${design_name}.txt
fi

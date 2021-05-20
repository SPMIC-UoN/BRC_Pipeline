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
ShowDiff=`getopt1 "--showdiff" $@`
SEC1=`getopt1 "--start" $@`
SEC2=`getopt1 "--end" $@`
Sub_ID=`getopt1 "--subject" $@`
Type=`getopt1 "--type" $@`
LogFile=`getopt1 "--logfile" $@`

this_tools_dir=$(dirname "${BASH_SOURCE[0]}")
product_file="${this_tools_dir}/product.txt"
version_file="${this_tools_dir}/version.txt"
#branch_file="${this_tools_dir}/branch.txt"
#deployment_file="${this_tools_dir}/deployment.txt"

#=====================================================================================
###                              Setup the Log file
#=====================================================================================

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions
log_SetPath "${LogFile}"

#=====================================================================================

log_Msg 3 "=========================================================================="
if [ -e "${product_file}" ] ; then
		log_Msg 3 "                         PRODUCT: `cat ${product_file}`"
fi

if [ -e "${version_file}" ] ; then
		log_Msg 3 "                           VERSION: `cat ${version_file}`"
fi

#if [ -e "${branch_file}" ] ; then
#	echo -n "     BRANCH: "
#	cat ${branch_file}
#fi


#if [ -e "${deployment_file}" ] ; then
#	echo -n " DEPLOYMENT: "
#	cat ${deployment_file}
#fi

if [[ ${ShowDiff} == "yes" ]]; then
    if [ ${Type} = "1" ] || [ ${Type} = "2" ] || [ ${Type} = "3" ] ; then
        log_Msg 3 "                           Subject: $Sub_ID"
    fi

    case $Type in

        1)
            log_Msg 3 "                     Type of Analysis: Structural"
        ;;

        2)
            log_Msg 3 "                     Type of Analysis: Diffusion"
        ;;

        3)
            log_Msg 3 "                     Type of Analysis: Functional"
        ;;

        4)
            log_Msg 3 "                  Type of Analysis: Group Functional"
        ;;

        5)
            log_Msg 3 "                   Type of Analysis: IDP extractor"
        ;;
    esac

		DIFFSEC=`expr ${SEC2} - ${SEC1}`

		log_Msg 3 "                 End Time: `date`"
		log_Msg 3 "                       Run Time (H:M:S): `date +%H:%M:%S -ud @${DIFFSEC}`"
else
		log_Msg 3 "               Start Time: `date`"
fi
log_Msg 3 "=========================================================================="

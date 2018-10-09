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

this_tools_dir=$(dirname "${BASH_SOURCE[0]}")
product_file="${this_tools_dir}/product.txt"
version_file="${this_tools_dir}/version.txt"
#branch_file="${this_tools_dir}/branch.txt"
#deployment_file="${this_tools_dir}/deployment.txt"

echo "=========================================================================="
if [ -e "${product_file}" ] ; then
		echo -n "                         PRODUCT: "
		cat ${product_file}
fi

if [ -e "${version_file}" ] ; then
		echo -n "                           VERSION: "
		cat ${version_file}
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
		DIFFSEC=`expr ${SEC2} - ${SEC1}`

		echo "                 End Time: `date`"
		echo "                       Run Time (H:M:S): `date +%H:%M:%S -ud @${DIFFSEC}`"
else
		echo "               Start Time: `date`"
fi
echo "=========================================================================="

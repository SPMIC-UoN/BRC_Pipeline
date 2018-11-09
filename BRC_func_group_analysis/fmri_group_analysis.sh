#!/bin/bash
# Last update: 23/10/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
# Preprocessing Pipeline for resting-state fMRI. Generates the "data" directory that can be used as input to fibre orientation estimation.
# Ali-Reza Mohammadi-Nejad, SPMIC, Queens Medical Centre, School of Medicine, University of Nottingham, 2018.
#Example:
#

set -e

# --------------------------------------------------------------------------------
#  Usage Description Function
# --------------------------------------------------------------------------------

Usage()
{
  echo " "
  echo " "
  echo "`basename $0`: Description"
  echo " "
  echo "Usage: `basename $0`"
  echo "Compulsory arguments (You MUST set one or more of):"
  echo " --in <path>                     List of all subject IDs their 4D datasets are preprocessed and are in the standard-space"
  echo " --indir <path>                  Input directory full path. All of the input list subjects must be in this direcory"
  echo " --outdir <path>                 Output directory full path for group analysis"
  echo " --parcellation <atlas>          Type of parcellation used to extract ROIs:"
  echo "                                       FS_DKA: This atlas is known as the 'Desikan-Killiany' cortical atlas in FreeSurfer."
  echo "                                               This atlas is in the functional native space."
  echo "                                       FS_DA:	This atlas is known as the 'Destrieux' cortical atlas in FreeSurfer."
  echo "                                              This atlas is in the functional native space."
  echo "                                       AAL_116: This atlas is known as AAL 'Automated Anatomical Labeling' atlas"
  echo "                                                This atlas is in the standard MNI152 space."
  echo "                                       AAL_90: This atlas is known as AAL 'Automated Anatomical Labeling' atlas"
  echo "                                               This atlas is in the standard MNI152 space."
  echo "                                       SHEN:"
  echo "                                              This atlas is in the standard MNI152 space."
  echo " --fmrires <value>               Data resolution of fMRI data and ATLAS in mm"
  echo " --tr <value>                    Repetition time in sec"
  echo " "
  echo "Optional arguments (You may optionally specify one or more of):"
  echo " --labels <path>                 List of the label values that you want to extract their time series (default all labels in the ATLAS)"
  echo " --corrtype <method>             Type of assosiation estimation:"
  echo "                                       COV: covariance (non-normalised 'correlation')"
  echo "                                       AMP: only use nodes' amplitude"
  echo "                                       CORR: full correlation (diagonal is set to zero) (default)"
  echo "                                       RCORR: full correlation after regressing out global mean timecourse"
  echo "                                       PCORR: partial correlation. If a lambda parameter is given as the --regval option,"
  echo "                                              'PCORR' will change to L1-norm regularised partial correlation with lambda= <--regval value>"
  echo "                                       RPCORR: partial correlation using L2-norm Ridge Regression (aka Tikhonov)"
  echo "                                               The rho parameter is given by --regval option"
  echo " --regval <value>                Regularization value used for 'PCORR' (default is 0) and 'RPCORR' (default is 0.1)"
  echo " --varnorm <value>               Temporal variance normalisation to apply"
  echo "                                       0 = none (default)"
  echo "                                       1 = normalise whole subject stddev"
  echo "                                       2 = normalise each separate timeseries from each subject"
  echo " "
  echo " "
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi

################################################## OPTION PARSING #####################################################

# default values
ParcelAtlas=""
CorrType="CORR"
DataResolution=""
LabelList=""
VarNorm="0"
RegVal=0

while [ "$1" != "" ]; do
    case $1 in
      --in )                  shift
                              InputList=$1
                              ;;

      --indir )               shift
                              InputDIR=$1
                              ;;

      --parcellation )        shift
                              ParcelAtlas=$1
                              ;;

      --outdir )              shift
                              OutDIR=$1
                              ;;

      --corrtype )            shift
                              CorrType=$1
                              ;;

      --fmrires )             shift
                              DataResolution=$1
                              ;;

      --labels )              shift
                              LabelList=$1
                              ;;

      --regval )              shift
                              RegVal=$1
                              ;;

      --varnorm )             shift
                              VarNorm=$1
                              ;;

      --tr )                  shift
                              RepetitionTime=$1
                              ;;

      * )                     Usage
                              exit 1

    esac
    shift
done

${RUN} ${BRCDIR}/Show_version.sh --showdiff="no"
Start_Time="$(date -u +%s)"

#=====================================================================================
###                          Sanity checking of arguments
#=====================================================================================

if [ X$InputList = X ] || [ X$InputDIR = X ] || [ X$ParcelAtlas = X ] || [ X$OutDIR = X ] || [ X$DataResolution = X ] ; then
    echo ""
    echo "All of the compulsory arguments --in, -indir, --outdir, --parcellation and -fmrires MUST be used"
    echo ""
    exit 1;
fi

if [ $RegVal -eq 0 ]; then
    if [ $CorrType = "RPCORR" ] ; then
        RegVal=0.1
    fi
fi

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

FC_Anal_Folder_name="Nets"
Unlabeled_Folder_Name="unlabeled"
Process_Folder_Name="processed"
GroupFC_folder_name="GroupFC"
TimeSeries_Folder_name="TimeSeries"
GroupMaps_Folder_name="Image_4D" #We add a .sum at the end of this name
NetWeb_Folder_name="netweb"

NameOffMRI="rfMRI"
fMRI2std_name="${NameOffMRI}2std"
TimeSeries_name="TimeSeries"

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

if [ ! -d ${OutDIR} ]; then mkdir -p $OutDIR; fi

AtlasFile=${BRCDIR}/templates
GroupFCFolder=${OutDIR}/${GroupFC_folder_name}
TimeSeriesFolder=${GroupFCFolder}/${TimeSeries_Folder_name}
GroupMapsFolder=${GroupFCFolder}/${GroupMaps_Folder_name}.sum
NetWebFolder=${GroupFCFolder}/${NetWeb_Folder_name}

case $ParcelAtlas in

    SHEN)
        AtlasFile=${AtlasFile}/shen_${DataResolution}mm_268_parcellation.nii.gz
        if [ X${LabelList} = X ] ; then
            LabelList=${BRCDIR}/templates/shen_268_labels.txt
        fi
    ;;

    *)
        echo ""
        echo "UNKNOWN ATLAS: ${ParcelAtlas}"
        echo ""
        exit 1
esac

if [ ! -d "$GroupFCFolder" ]; then mkdir -p $GroupFCFolder; fi
if [ -e ${TimeSeriesFolder} ] ; then rm -r ${TimeSeriesFolder}; fi
mkdir -p $TimeSeriesFolder
if [ -e ${NetWebFolder} ] ; then rm -r ${NetWebFolder}; fi

#=====================================================================================
###                          Sanity checking of arguments
#=====================================================================================

if [ ! -e ${AtlasFile} ] ; then
    echo ""
    echo "There is not any ATLAS image with the specified resolution"
    echo ""
    exit;
fi

#=====================================================================================
###                                   DO WORK
#=====================================================================================

#${RUN} ${BRC_FMRI_GP_SCR}/Generate_maps.sh \
#      --workingdir=${GroupFCFolder} \
#      --atlas=${AtlasFile} \
#      --labellist=${LabelList} \
#      --dataresolution=${DataResolution} \
#      --groupmaps=${GroupMapsFolder}


jj=0
for Subject in $(cat $InputList) ; do
    echo "$Subject"
    jj=$(( ${jj} + 1 ))

    #=====================================================================================
    ###                                  Setup PATHS
    #=====================================================================================

    T1wSubjFolder=${InputDIR}/${Subject}/analysis/anatMRI/T1
    fMRISubjFolder=${InputDIR}/${Subject}/analysis/rfMRI
    fMRIFile=$fMRISubjFolder/${Process_Folder_Name}/${fMRI2std_name}

    #=====================================================================================
    ###                          Sanity checking of arguments
    #=====================================================================================

    if [ ! -e ${T1wSubjFolder} ] || [ ! -e ${fMRISubjFolder} ] ; then
        echo ""
        echo "Functional group analysis depends on the outputs generated by Structural and Functional preprocessing of subject:${Subject}"
        echo "So functional preprocessing should not be attempted on data sets for which the preprocessing is not yet complete."
        echo ""
        exit;
    fi

    #check dimensions of fMRI versus ATLAS image
    if [[ `${FSLDIR}/bin/fslhd $AtlasFile | grep '^dim[123]'` != `${FSLDIR}/bin/fslhd ${fMRIFile} | grep '^dim[123]'` ]]
    then
        echo "Error: Subject:${Subject} has different dimensions than the ATLAS image, this requires a manual fix"
        exit 1
    fi

    if [[ `${FSLDIR}/bin/fslhd $AtlasFile | grep '^pixdim[123]'` != `${FSLDIR}/bin/fslhd ${fMRIFile} | grep '^pixdim[123]'` ]]
    then
        echo "Error: Subject:${Subject} has different voxel-size than the ATLAS image, this requires a manual fix"
        exit 1
    fi

    RepetitionTime=`echo "scale=6; $RepetitionTime / 1" | bc -l`

    TR=`${FSLDIR}/bin/fslval $fMRISubjFolder/${Process_Folder_Name}/${fMRI2std_name} pixdim4 | cut -d " " -f 1 | bc -l`
    if [ $TR != $RepetitionTime ]; then
        echo "Error: Subject:${Subject} has different repetition time ($TR sec) than the specified TR using --tr option ($RepetitionTime sec)"
        exit 1
    fi

    #=====================================================================================
    ###                                   DO WORK
    #=====================================================================================

    FCFolder=${fMRISubjFolder}/${Unlabeled_Folder_Name}/${FC_Anal_Folder_name}
    if [ -e ${FCFolder} ] ; then rm -r ${FCFolder}; fi
    mkdir $FCFolder

#    ${FSLDIR}/bin/fslmeants -i $fMRISubjFolder/${Process_Folder_Name}/${fMRI2std_name} --label=${GroupFCFolder}/temp_atlas -o ${TimeSeriesFolder}/meants`${FSLDIR}/bin/zeropad $jj 4`.txt

    ${FSLDIR}/bin/fslmeants -i $fMRISubjFolder/${Process_Folder_Name}/${fMRI2std_name} --label=${GroupFCFolder}/temp_atlas -o ${FCFolder}/${TimeSeries_name}.txt
    cp ${FCFolder}/${TimeSeries_name}.txt ${TimeSeriesFolder}/meants`${FSLDIR}/bin/zeropad $jj 4`.txt

    ${RUN} ${BRC_FMRI_GP_SCR}/SS_FC_Analysis.sh \
          --workingdir=${FCFolder} \
          --timeseries=${TimeSeries_name} \
          --repetitiontime=${RepetitionTime} \
          --varnorm=${VarNorm}
done

${RUN} ${BRC_FMRI_GP_SCR}/Functional_Connectivity_Analysis.sh \
      --workingdir=${GroupFCFolder} \
      --groupmaps=${GroupMaps_Folder_name} \
      --timeseries=${TimeSeriesFolder} \
      --repetitiontime=${RepetitionTime} \
      --varnorm=${VarNorm} \
      --corrtype=${CorrType} \
      --regval=${RegVal} \
      --netwebfolder=${NetWebFolder}




#      --fmrisubjfolder=${fMRISubjFolder} \
#      --infmri=${fMRIFile} \
#      --timeseries=meants.txt \
#      --atlas=${GroupFCFolder}/temp_atlas \

: <<'COMMENT'
cat <<EOF

echo " --approach <method>             Approach for multi-session/subject data:"
echo "                                       concat:	temporally-concatenated group-ICA using MIGP (default)"
echo "                                       tica:  	tensor-ICA"
echo " --nobet                         Switch off BET"
echo " --bgthreshold <value>           Brain / non-brain threshold (only if --nobet selected)"
echo " --bgimage <image path>          Specify background image for report (default: mean image)"
echo " --mask <image path>             File name of mask for thresholding"
echo " --dim <value>                   Dimensionality reduction into #num dimensions (default: automatic estimation)"


ICA_approach="concat"
NO_BET="NO"
BG_Image=""
Thresh_Mask=""
Dimensionality=""


      --approach )            shift
                              ICA_approach=$1
                              ;;

      --nobet )               shift
                              NO_BET="YES"
                              ;;

      --bgthreshold )         shift
                              BG_Threshold=$1
                              ;;

      --bgimage )             shift
                              BG_Image=$1
                              ;;

      --mask )                shift
                              Thresh_Mask=$1
                              ;;

      --dim )                 shift
                              Dimensionality=$1
                              ;;

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

melodicFolderName="melodic"

Melodic_outputs="groupICA"

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

melodicFolder=${OutDIR}/${melodicFolderName}

if [ ! -d "$melodicFolder" ]; then mkdir $melodicFolder; fi

#=====================================================================================
###                                   DO WORK
#=====================================================================================

if [ -e ${OutDIR}/input_files.txt ] ; then
    rm ${OutDIR}/input_files.txt
fi

for Subject in $(cat $InputList) ; do
    ls -1 ${InputDIR}/${Subject}/analysis/rfMRI/processed/rfMRI2std.nii.gz >> ${OutDIR}/input_files.txt
done


echo "MELODIC analysis"
${BRC_FMRI_GP_SCR}/Melodic_Processing.sh \
      --workingdir=${melodicFolder} \
      --inputfiles=${OutDIR}/input_files.txt \
      --icaapproach=${ICA_approach} \
      --thresholdmask=${Thresh_Mask} \
      --dimensionality=${Dimensionality} \
      --nobet=${NO_BET} \
      --bgthreshold=${BG_Threshold} \
      --bgimage=${BG_Image} \
      --melout=${Melodic_outputs}

: <<'COMMENT'

echo "Back Recunstruction of Component to subject space"
${BRC_FMRI_GP_SCR}/Dual_Regression_Processing.sh \
      --workingdir=${melodicFolder} \
      --inputsubjects=
      --ingroupicmaps=
      --designmat=
      --descontrast=
      --numofpermut=
      --outputdir=

: <<'COMMENT'

       --nobet \
       --bgthreshold=${BG_Threshold} \
       --bgimage=${BG_Image} \

END_Time="$(date -u +%s)"


${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time}

EOF
#: <<'COMMENT'

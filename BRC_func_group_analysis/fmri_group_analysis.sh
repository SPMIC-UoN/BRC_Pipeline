#!/bin/bash
# Last update: 23/10/2018

# Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
#
# Copyright 2018 University of Nottingham
#
# Preprocessing Pipeline for resting-state fMRI. Generates the "data" directory that can be used as input to fibre orientation estimation.
# Ali-Reza Mohammadi-Nejad, SPMIC, Queens Medical Centre, School of Medicine, University of Nottingham, 2018.
#Example: ./fmri_group_analysis.sh --in ~/main/analysis/input_list.txt --indir ~/main/analysis --outdir ~/main/analysis --parcellation SHEN --fmrires 3 --tr 1.45 --labels ~/main/analysis/input_labels.txt --varnorm 1 --groupdiffs
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
  echo "                                           This atlas is in the functional native space."
  echo "                                       FS_DA:	This atlas is known as the 'Destrieux' cortical atlas in FreeSurfer."
  echo "                                           This atlas is in the functional native space."
  echo "                                       AAL: This atlas is known as AAL 'Automated Anatomical Labeling' atlas"
  echo "                                           This atlas is in the standard MNI152 space and contains 116 ROIs."
  echo "                                       SHEN: a functional atlas that covering both cortical and sub-cortical brain regions"
  echo "                                           This atlas is in the standard MNI152 space and contains 268 ROIs."
  echo "                                       MELODIC: Multivariate Exploratory Linear Optimised Decomposition into Independent Components"
  echo "                                           By choosing this option you have to specify --approach, --dim options."
  echo "                                       NONE: a user defined atlas which can be used as an input using --inatlas option."
  echo "                                           Also, the label maps should be specified using --labels option."
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
  echo "                                           'PCORR' will change to L1-norm regularised partial correlation with lambda= <--regval value>"
  echo "                                       RPCORR: partial correlation using L2-norm Ridge Regression (aka Tikhonov)"
  echo "                                           The rho parameter is given by --regval option"
  echo " --regval <value>                Regularization value used for 'PCORR' (default is 0) and 'RPCORR' (default is 0.1)"
  echo " --varnorm <value>               Temporal variance normalisation to apply"
  echo "                                       0 = none (default)"
  echo "                                       1 = normalise whole subject stddev"
  echo "                                       2 = normalise each separate timeseries from each subject"
  echo " --groupdiffs                    do cross-subject GLM on a set of network matrices, giving uncorrected and corrected (1-p) values"
  echo "                                       assuming you already specified the corresponding group for each subject in a column next to each subject name"
  echo "                                       (e.g., 1 for the 1st group and 2 for the 2nd group) in --in option input file"
  echo " --approach <method>             Approach for multi-session/subject data:"
  echo "                                       concat:	temporally-concatenated group-ICA using MIGP (default)"
  echo "                                       tica:  	tensor-ICA"
  echo " --dim <value>                   Dimensionality reduction into #num dimensions (default: automatic estimation)"
  echo " --inatlas <path>                User defined atlas which can be used for parcellation"
  echo " --help                          help"
  echo " "
  echo " "
}

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi

################################################## OPTION PARSING #####################################################

log=`echo "$@"`

# default values
ParcelAtlas=""
CorrType="CORR"
DataResolution=""
LabelList=""
VarNorm="0"
RegVal=0
DO_GLM="no"
ICA_approach="concat"
NO_BET="NO"
BG_Image=""
Thresh_Mask=""
Dimensionality=""
InAtlas=""

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

      --groupdiffs )          DO_GLM="yes"
                              ;;

      --approach )            shift
                              ICA_approach=$1
                              ;;

      --dim )                 shift
                              Dimensionality=$1
                              ;;

      --inatlas )             shift
                              InAtlas=$1
                              ;;

      * )                     Usage
                              exit 1

    esac
    shift
done

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

if [ ${ParcelAtlas} == "NONE" ]; then
    if [ X$InAtlas = X ] || [ X$LabelList = X ] ; then
        echo ""
        echo "When the --parcellation option is NONE, user MUST define an input atlas and its labels using --inatlas and --labels options"
        echo ""
        exit 1;
    fi
fi

#=====================================================================================
###                                Naming Conventions
#=====================================================================================

AnalysisFolderName="analysis"
rfMRIFolderName="rfMRI"
AnatMRIFolderName="anatMRI"
T1FolderName="T1"
logFolderName="log"
processedFolderName="processed"
data2stdFolderName="data2std"
TemplateFolderName="templates"

GroupFC_folder_name="GroupFC"
FC_Anal_Folder_name="Nets"
TimeSeries_Folder_name="TimeSeries"
GroupMaps_Folder_name="Image_4D" #We add a .sum at the end of this name
NetWeb_Folder_name="netweb"
List_Folder_name="list"
design_Folder_name="design"
melodicFolderName="melodic"
dualregFolderName="dualreg"

NameOffMRI="rfMRI"
fMRI2std_name="${NameOffMRI}2std"
TimeSeries_name="TimeSeries"
SubjectList_name="Subject_list.txt"
GroupList_name="Group_list.txt"
design_name="design"
contrast_name="contrast"
log_Name="log.txt"
input_fildes="input_files.txt"

#=====================================================================================
###                                  Setup PATHS
#=====================================================================================

if [ ! -d ${OutDIR} ]; then mkdir -p $OutDIR; fi

AtlasFolder=${BRC_GLOBAL_DIR}/${TemplateFolderName}
GroupFCFolder=${OutDIR}/${GroupFC_folder_name}
TimeSeriesFolder=${GroupFCFolder}/${TimeSeries_Folder_name}
GroupMapsFolder=${GroupFCFolder}/${GroupMaps_Folder_name}.sum
NetWebFolder=${GroupFCFolder}/${NetWeb_Folder_name}
ListFolder=${GroupFCFolder}/${List_Folder_name}
DesignFolder=${GroupFCFolder}/${design_Folder_name}
NetFolder=${GroupFCFolder}/${FC_Anal_Folder_name}
logFolder=${GroupFCFolder}/${logFolderName}
melodicFolder=${GroupFCFolder}/${melodicFolderName}
dualregFolder=${GroupFCFolder}/${dualregFolderName}

#if [ ! ${ParcelAtlas} == "MELODIC" ]; then
    case $ParcelAtlas in

        SHEN)
            AtlasFile=${AtlasFolder}/shen_${DataResolution}mm_268_parcellation.nii.gz
            if [ X${LabelList} = X ] ; then
                LabelList=${AtlasFolder}/shen_268_labels.txt
            fi
        ;;

        AAL)
            AtlasFile=${AtlasFolder}/AAL.nii.gz
            if [ X${LabelList} = X ] ; then
                LabelList=${AtlasFolder}/AAL_labels.txt
            fi
        ;;

        MELODIC)
        ;;

        NONE)
            AtlasFile=${InAtlas}
            LabelList=${LabelList}
        ;;

        *)
            echo ""
            echo "UNKNOWN ATLAS: ${ParcelAtlas}"
            echo ""
            exit 1
    esac
#fi

if [ ! -d ${GroupFCFolder} ]; then mkdir -p ${GroupFCFolder}; fi
if [ -e ${logFolder} ] ; then rm -r ${logFolder}; fi; mkdir ${logFolder}
if [ -e ${TimeSeriesFolder} ] ; then rm -r ${TimeSeriesFolder}; fi; mkdir -p ${TimeSeriesFolder}
if [ -e ${NetWebFolder} ] ; then rm -r ${NetWebFolder}; fi
if [ -e ${ListFolder} ] ; then rm -r ${ListFolder}; fi; mkdir -p ${ListFolder}
if [ -e ${DesignFolder} ] ; then rm -r ${DesignFolder}; fi; mkdir -p ${DesignFolder}
if [ -e ${NetFolder} ] ; then rm -r ${NetFolder}; fi; mkdir -p ${NetFolder}

if [ ${ParcelAtlas} == "MELODIC" ]; then
    if [ ! -d ${melodicFolder} ]; then mkdir ${melodicFolder}; fi
    if [ -e ${dualregFolder} ] ; then rm -r ${dualregFolder}; fi

    if [ -e ${melodicFolder}/${input_fildes} ] ; then
        rm ${melodicFolder}/${input_fildes}
    fi
fi

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
###                              Setup the Log file
#=====================================================================================

${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="no" \
      --logfile=${logFolder}/${log_Name}
Start_Time="$(date -u +%s)"

source $BRC_GLOBAL_SCR/log.shlib  # Logging related functions
log_SetPath "${logFolder}/${log_Name}"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "Original command:"
log_Msg 2 "$log"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "Parsing Command Line Options"
log_Msg 2 "InputList: $InputList"
log_Msg 2 "InputDIR: $InputDIR"
log_Msg 2 "ParcelAtlas: $ParcelAtlas"
log_Msg 2 "OutDIR: $OutDIR"
log_Msg 2 "CorrType: $CorrType"
log_Msg 2 "DataResolution: $DataResolution"
log_Msg 2 "LabelList: $LabelList"
log_Msg 2 "RegVal: $RegVal"
log_Msg 2 "VarNorm: $VarNorm"
log_Msg 2 "RepetitionTime: $RepetitionTime"
log_Msg 2 "DO_GLM: $DO_GLM"
log_Msg 2 "ICA_approach: $ICA_approach"
log_Msg 2 "Dimensionality: $Dimensionality"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#=====================================================================================
###                                   DO WORK
#=====================================================================================

log_Msg 3 "Generate reference image mask"

if [ ${DataResolution} = "2" ] ; then
    ResampRefIm=$FSLDIR/data/standard/MNI152_T1_2mm
    ResampRefIm_mask=${ResampRefIm}_brain_mask
elif [ ${DataResolution} = "1" ] ; then
    ResampRefIm=$FSLDIR/data/standard/MNI152_T1_1mm
    ResampRefIm_mask=${ResampRefIm}_brain_mask
else
    ${FSLDIR}/bin/flirt -interp spline -in $FSLDIR/data/standard/MNI152_T1_1mm -ref $FSLDIR/data/standard/MNI152_T1_1mm -applyisoxfm $DataResolution -out ${GroupFCFolder}/MNI152_T1_${DataResolution}mm
    ResampRefIm=${GroupFCFolder}/MNI152_T1_${DataResolution}mm
    ${FSLDIR}/bin/applywarp --rel --interp=nn -i $FSLDIR/data/standard/MNI152_T1_1mm_brain_mask -r ${ResampRefIm} --premat=$FSLDIR/etc/flirtsch/ident.mat -o ${GroupFCFolder}/MNI152_T1_${DataResolution}mm_brain_mask
    ResampRefIm_mask=${ResampRefIm}_brain_mask

    if [ ${ParcelAtlas} == "AAL" ] || [ ${ParcelAtlas} == "NONE" ] ; then

        ${FSLDIR}/bin/applywarp --rel --interp=nn -i ${AtlasFile} -r ${ResampRefIm} --premat=$FSLDIR/etc/flirtsch/ident.mat -o ${GroupFCFolder}/ATLAS_${DataResolution}mm
        AtlasFile=${GroupFCFolder}/ATLAS_${DataResolution}mm.nii.gz

    fi
fi


if [ ! ${ParcelAtlas} == "MELODIC" ]; then

    log_Msg 3 "Generate label maps"
    ${RUN} ${BRC_FMRI_GP_SCR}/Generate_maps.sh \
          --workingdir=${GroupFCFolder} \
          --atlas=${AtlasFile} \
          --resamprefim=${ResampRefIm} \
          --resamprefimmask=${ResampRefIm_mask} \
          --labellist=${LabelList} \
          --dataresolution=${DataResolution} \
          --groupmaps=${GroupMapsFolder} \
          --logfile=${logFolder}/${log_Name}

fi


log_Msg 3 "Generate design matrix and contrast"
${RUN} ${BRC_FMRI_GP_SCR}/Generate_design.sh \
      --inputlist=${InputList} \
      --doglm=${DO_GLM} \
      --listfolder=${ListFolder} \
      --designfolder=${DesignFolder} \
      --subListname=${SubjectList_name} \
      --grouplistname=${GroupList_name} \
      --designname=${design_name} \
      --contrastname=${contrast_name} \
      --logfile=${logFolder}/${log_Name}


jj=0
for Subject in $(cat ${ListFolder}/${SubjectList_name}) ; do
    log_Msg 3 "$Subject"
    jj=$(( ${jj} + 1 ))

    #=====================================================================================
    ###                                  Setup PATHS
    #=====================================================================================

    T1wSubjFolder=${InputDIR}/${Subject}/${AnalysisFolderName}/${AnatMRIFolderName}/${T1FolderName}
    fMRISubjFolder=${InputDIR}/${Subject}/${AnalysisFolderName}/${rfMRIFolderName}
    FCFolder=${fMRISubjFolder}/${processedFolderName}/${FC_Anal_Folder_name}

    fMRIFile=$fMRISubjFolder/${processedFolderName}/${data2stdFolderName}/${fMRI2std_name}

    if [ -e ${FCFolder} ] ; then rm -r ${FCFolder}; fi; mkdir $FCFolder

    #=====================================================================================
    ###                          Sanity checking of arguments
    #=====================================================================================

    if [ ! -e ${T1wSubjFolder} ] || [ ! -e ${fMRISubjFolder} ] ; then
        log_Msg 3 ""
        log_Msg 3 "Functional group analysis depends on the outputs generated by Structural and Functional preprocessing of subject:${Subject}"
        log_Msg 3 "So functional preprocessing should not be attempted on data sets for which the preprocessing is not yet complete."
        log_Msg 3 ""
        exit;
    fi

    if [ ${ParcelAtlas} == "MELODIC" ]; then
        if ((${jj} == 1)); then
            AtlasFile=${fMRIFile}
        fi
    fi

    #check dimensions of fMRI versus ATLAS image
    if [[ `${FSLDIR}/bin/fslhd $AtlasFile | grep '^dim[123]'` != `${FSLDIR}/bin/fslhd ${fMRIFile} | grep '^dim[123]'` ]]
    then
        log_Msg 3 ""
        log_Msg 3 "Error: Subject:${Subject} has different dimensions than the ATLAS image, this requires a manual fix"
        log_Msg 3 ""
        exit 1
    fi

    if [[ `${FSLDIR}/bin/fslhd $AtlasFile | grep '^pixdim[123]'` != `${FSLDIR}/bin/fslhd ${fMRIFile} | grep '^pixdim[123]'` ]]
    then
        log_Msg 3 ""
        log_Msg 3 "Error: Subject:${Subject} has different voxel-size than the ATLAS image, this requires a manual fix"
        log_Msg 3 ""
        exit 1
    fi

    RepetitionTime=`echo "scale=6; $RepetitionTime / 1" | bc -l`

    TR=`${FSLDIR}/bin/fslval ${fMRIFile} pixdim4 | cut -d " " -f 1 | bc -l`
    if [ $TR != $RepetitionTime ]; then
        log_Msg 3 ""
        log_Msg 3 "Error: Subject:${Subject} has different repetition time ($TR sec) than the specified TR using --tr option ($RepetitionTime sec)"
        log_Msg 3 ""
        exit 1
    fi

    #=====================================================================================
    ###                                   DO WORK
    #=====================================================================================

#    ${FSLDIR}/bin/fslmeants -i ${fMRIFile} --label=${GroupFCFolder}/temp_atlas -o ${TimeSeriesFolder}/meants`${FSLDIR}/bin/zeropad $jj 4`.txt

    if [ ${ParcelAtlas} == "MELODIC" ]; then

        ls -1 ${fMRIFile}.nii.gz >> ${melodicFolder}/${input_fildes}

    else

        ${FSLDIR}/bin/fslmeants -i ${fMRIFile} --label=${GroupFCFolder}/temp_atlas -o ${FCFolder}/${TimeSeries_name}.txt
        cp ${FCFolder}/${TimeSeries_name}.txt ${TimeSeriesFolder}/meants`${FSLDIR}/bin/zeropad $jj 4`.txt


        ${RUN} ${BRC_FMRI_GP_SCR}/SS_FC_Analysis.sh \
              --workingdir=${FCFolder} \
              --timeseries=${TimeSeries_name} \
              --repetitiontime=${RepetitionTime} \
              --varnorm=${VarNorm} \
              --corrtype=${CorrType} \
              --regval=${RegVal} \
              --labellist=${LabelList} \
              --logfile=${logFolder}/${log_Name}
    fi

done

if [ ${ParcelAtlas} == "MELODIC" ]; then

    NO_BET="yes"
    BG_Threshold=1

    log_Msg 3 "MELODIC analysis"
    ${RUN} ${BRC_FMRI_GP_SCR}/Melodic_Processing.sh \
          --inputfiles=${melodicFolder}/${input_fildes} \
          --icaapproach=${ICA_approach} \
          --bgimage=${ResampRefIm} \
          --thresholdmask=${ResampRefIm_mask} \
          --dataresolution=${DataResolution} \
          --dimensionality=${Dimensionality} \
          --nobet=${NO_BET} \
          --bgthreshold=${BG_Threshold} \
          --atlasfolder=${AtlasFolder} \
          --melout=${melodicFolder} \
          --logfile=${logFolder}/${log_Name}


    echo "Back Recunstruction of Component to subject space"
    ${RUN} ${BRC_FMRI_GP_SCR}/Dual_Regression_Processing.sh \
          --workingdir=${dualregFolder} \
          --inputsubjects=${melodicFolder}/${input_fildes} \
          --ingroupicmaps=${melodicFolder}/melodic_IC \
          --varnorm=${VarNorm} \
          --designmatrix=${DesignFolder}/${design_name}.mat \
          --contrastmatrix=${DesignFolder}/${contrast_name}.con \
          --numofpermut=5000 \
          --logfile=${logFolder}/${log_Name}

else

    log_Msg 3 "Group functional connectivity network analysis"
    ${RUN} ${BRC_FMRI_GP_SCR}/Functional_Connectivity_Analysis.sh \
          --workingdir=${GroupFCFolder} \
          --groupmaps=${GroupMaps_Folder_name} \
          --timeseries=${TimeSeriesFolder} \
          --repetitiontime=${RepetitionTime} \
          --varnorm=${VarNorm} \
          --corrtype=${CorrType} \
          --regval=${RegVal} \
          --netwebfolder=${NetWebFolder} \
          --doglm=${DO_GLM} \
          --designmatrix=${DesignFolder}/${design_name} \
          --contrastmatrix=${DesignFolder}/${contrast_name} \
          --outfolder=${FC_Anal_Folder_name} \
          --logfile=${logFolder}/${log_Name}

fi

END_Time="$(date -u +%s)"


${RUN} ${BRCDIR}/Show_version.sh \
      --showdiff="yes" \
      --start=${Start_Time} \
      --end=${END_Time} \
      --subject=${Subject} \
      --type=4 \
      --logfile=${logFolder}/${log_Name}


################################################################################################
## Cleanup
################################################################################################

if [ ! -e ${GroupFCFolder}/MNI152_T1_${DataResolution}mm.nii.gz ] ; then
    ${FSLDIR}/bin/imrm ${GroupFCFolder}/MNI152_T1_${DataResolution}mm*
fi

#: <<'COMMENT'

#!/bin/bash
# Last update: 01/07/2024

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

# parse arguments
dataFolder=`getopt1 "--datafolder" $@`
T1wImage=`getopt1 "--t1" $@`
Subject=`getopt1 "--subject" $@`
json1=`getopt1 "--slspec" $@`
regFolder=`getopt1 "--regfolder" $@`
regT1Folder=`getopt1 "--regt1folder" $@`
LogFile=`getopt1 "--logfile" $@`

log_SetPath "${LogFile}"

log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 3 "+                                                                        +"
log_Msg 3 "+                              START: ALPS                               +"
log_Msg 3 "+                                                                        +"
log_Msg 3 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log_Msg 2 "dataFolder:$dataFolder"
log_Msg 2 "T1wImage:$T1wImage"
log_Msg 2 "Subject:$Subject"
log_Msg 2 "json1:$json1"
log_Msg 2 "regFolder:$regFolder"
log_Msg 2 "regT1Folder:$regT1Folder"
log_Msg 2 "LogFile:$LogFile"
log_Msg 2 "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

log_Msg 3 `date`

dtidir="${dataFolder}/data.dti"
outdir="${dataFolder}/data.alps"
mkdir -p "${outdir}"

if [ -f "${dtidir}/dti_FA.nii.gz" ]; then 
    log_Msg 3 "dti_FA.nii.gz is available for ROI analysis"; 
else 
    log_Msg 3 "ERROR! Cannot find ${dtidir}/dti_FA.nii.gz, needed for ROI analysis."; 
    log_Msg 3 "Double check that ${dtidir}/dti_FA.nii.gz exists."; 
    log_Msg 3 "if it does not exist, consider running the whole alps script (-s 0, default option)."; 
    exit 1; 
fi

if [ -f "${dtidir}/dti_tensor.nii.gz" ]; then 
    echo "dti_tensor.nii.gz is available for ROI analysis"; 
else 
    echo "ERROR! Cannot find ${dtidir}/dti_tensor.nii.gz, needed for ROI analysis."; 
    log_Msg 3 "Double check that ${dtidir}/dti_tensor.nii.gz exists."; 
    log_Msg 3 "if it does not exist, consider running the whole alps script (-s 0, default option)."; 
    exit 1; 
fi

#ROIs
log_Msg 3 "ROI analysis with default ROIs"
rois="${BRC_GLOBAL_DIR}/templates/ROIs_JHU_ALPS/L_SCR.nii.gz,${BRC_GLOBAL_DIR}/templates/ROIs_JHU_ALPS/R_SCR.nii.gz,${BRC_GLOBAL_DIR}/templates/ROIs_JHU_ALPS/L_SLF.nii.gz,${BRC_GLOBAL_DIR}/templates/ROIs_JHU_ALPS/R_SLF.nii.gz"

n_rois=`echo $rois | awk -F '[,]' '{print NF}'`

proj_L=`echo "$rois" | cut -d "," -f1`
proj_R=`echo "$rois" | cut -d "," -f2`
assoc_L=`echo "$rois" | cut -d "," -f3`
assoc_R=`echo "$rois" | cut -d "," -f4`

if [ ! -f "${proj_L}" ]; then 
    log_Msg 3 "ERROR! Cannot find the following ROI file: ${proj_L}"; 
    exit 1; 
fi
if [ ! -f "${proj_R}" ]; then 
    log_Msg 3 "ERROR! Cannot find the following ROI file: ${proj_R}"; 
    exit 1; 
fi
if [ ! -f "${assoc_L}" ]; then 
    log_Msg 3 "ERROR! Cannot find the following ROI file: ${assoc_L}"; 
    exit 1; 
fi
if [ ! -f "${assoc_R}" ]; then 
    log_Msg 3 "ERROR! Cannot find the following ROI file: ${assoc_R}"; 
    exit 1; 
fi

template="1"                    # 1: MNI_T1_1mm_brain.nii.gz (if structural data input is a T1)
struct="${T1wImage}.nii.gz"     #
regdir=${regFolder}             #
weight="1"                      # 1: T1-weighted
warp="0"                        
freg="1"                        # Use applywarp (if -w = 1 or 2 or -v is not empty) to transform the TENSOR file to the template space.

if [ "$template" != "0" ]; then #analysis in template space. Double check that the template exists.

    #conditional for existence of structural MRI data.
    if [ ! -z $struct ]; then
        if [ ! -f "$struct" ]; then 
            log_Msg 3 "ERROR! User specified to use $struct as structural MRI data, but I could not find it. Please double-check that the file exists."; 
            exit 1; 
        fi;
    fi
    
    #conditional for template selection
    if [ "$template" == "1" ]; then
        if [ -f ${FSLDIR}/data/standard/MNI152_T1_1mm_brain_mask_dil.nii.gz ]; then
            template_mask="--refmask=${FSLDIR}/data/standard/MNI152_T1_1mm_brain_mask_dil.nii.gz "
            #used only for fnirt (warp > 0 or !-z struct)
        fi
        
        if [ -z $struct ]; then
            log_Msg 3 "Default FA template will be used: JHU-ICBM-FA-1mm.nii.gz"
            template=${FSLDIR}/data/atlases/JHU/JHU-ICBM-FA-1mm.nii.gz
            template_abbreviation=JHU-FA
        elif [ ! -z $struct ]; then
            if [ $weight == "1" ]; then
                log_Msg 3 "The structural MRI $struct is a T1-weighted image, therefore the default template that will be used is: MNI152_T1_1mm"
                template=${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz
                template_abbreviation=MNI152_T1_1mm
                smri="t1w"
            elif [ $weight == "2" ]; then 
                log_Msg 3 "The structural MRI $struct is a T2-weighted image, therefore the default template that will be used is: JHU-ICBM-T2-1mm"
                template=${FSLDIR}/data/atlases/JHU/JHU-ICBM-T2-1mm.nii.gz
                template_abbreviation=JHU-ICBM-T2-1mm
                smri="t2w"
            elif [ $weight -ne 1 ] && [ $weight -ne 2 ] && [ "$template" != "0" ] && [ "$template" != "1" ] ; then
                log_Msg 3 "ERROR! A structural MRI data has been specified, but the user needs to specify with the option -h whether this is T1-weighted (-h 1) or T2-weighted (-h 2) in order to select a default template. \n\
                The only allowed option for -h are 1 or 2. Alternatively, the user can specify the file template to use, and the option -h will be ignored."; exit 1; 
            fi
        fi
    else
        template="$(echo "$(cd "$(dirname "${template}")" && pwd)/$(basename "${template}")")"
        log_Msg 3 "User specified template: $template"
        template_abbreviation=template
    fi

    if [ ! -f "${template}" ]; then 
        log_Msg 3 "ERROR! Cannot find the template "$template". The template file must exist if -t option is not 0."; 
        exit 1; 
    fi

    if [ $warp -ne 0 ] && [ $warp -ne 1 ] && [ $warp -ne 2 ]; then 
        log_Msg 3 "ERROR! The option specified with -w is $warp, which is not an allowed option. -w must be equal to 0 (for linear registration) or 1 (for non-linear registration)."; 
        exit 1; 
    fi

    if [ $freg -ne 1 ] && [ $freg -ne 2 ]; then 
        log_Msg 3 "ERROR! The option specified with -f is $freg, which is not an allowed option. -f must be equal to 1 (for using FSL's flirt and/or applywarp depending on -w) or 2 (for using FSL's vecreg)."; 
        exit 1; 
    fi
fi


log_Msg 3 "starting ROI analysis with projection fibers "$(basename "$proj_L")" (LEFT) and "$(basename "$proj_R")" (RIGHT), and association fibers "$(basename "$assoc_L")" (LEFT) and "$(basename "$assoc_R")" (RIGHT)"

#TEMPLATE
if [ "$template" != "0" ]; then #analysis in template space
    if [ -f "$struct" ]; then #if you have structural MRI data

        log_Msg 3 "Linear (flirt) + Non-Linear (fnirt) registration to template via structural scan";
        # cp "$struct" "${dtidir}/${smri}.nii.gz"

        # if [ $weight == "1" ]; then
        #     flirt -ref "${dtidir}/${smri}.nii.gz" -in "${dtidir}/dti_FA.nii.gz" -dof 6 -out "${dtidir}/dti_FA_2_${smri}.nii.gz" -omat "${dtidir}/dti2struct.mat"
        # elif [ $weight == "2" ]; then #if it's a T2, it's better to align the b0 volume rather than the FA, because the b0 contrast is more similar to T2.
        #     if [ -f "${dtidir}/b0.nii.gz" ]; then
        #         flirt -ref "${dtidir}/${smri}.nii.gz" -in "${dtidir}/b0.nii.gz" -dof 6 -out "${dtidir}/b0_2_${smri}.nii.gz" -omat "${dtidir}/dti2struct.mat"
        #     else #in case you don't have b0 (i.e., you skipped the preprocessing, and are only doing ROI analysis with a dti_FA map ready)
        #         flirt -ref "${dtidir}/${smri}.nii.gz" -in "${dtidir}/dti_FA.nii.gz" -dof 6 -out "${dtidir}/dti_FA_2_${smri}.nii.gz" -omat "${dtidir}/dti2struct.mat"    				
        #     fi
        # fi
        
        # if [ -f "${dtidir}/b0_brain_mask.nii.gz" ]; then
        #     flirt -in "${dtidir}/b0_brain_mask.nii.gz" -ref "${dtidir}/${smri}.nii.gz" -interp nearestneighbour -out "${dtidir}/b0_brain_mask_2_struct.nii.gz" -init "${dtidir}/dti2struct.mat" -applyxfm
        #     fslmaths "${dtidir}/${smri}.nii.gz" -mul "${dtidir}/b0_brain_mask_2_struct.nii.gz" "${dtidir}/${smri}_brain.nii.gz"
        # else #in case you don't have b0_brain_mask (i.e., you skipped the preprocessing, and are only doing ROI analysis)
        #     bet2 "${dtidir}/dti_FA.nii.gz" "${dtidir}/dti_FA_brain" -m
        #     flirt -in "${dtidir}/dti_FA_brain_mask.nii.gz" -ref "${dtidir}/${smri}.nii.gz" -interp nearestneighbour -out "${dtidir}/dti_FA_brain_mask_2_struct.nii.gz" -init "${dtidir}/dti2struct.mat" -applyxfm
        #     fslmaths "${dtidir}/${smri}.nii.gz" -mul "${dtidir}/dti_FA_brain_mask_2_struct.nii.gz" "${dtidir}/${smri}_brain.nii.gz"
        # fi

        # flirt -ref "${template}" -in "${dtidir}/${smri}_brain.nii.gz" -omat "${dtidir}/struct2template_aff.mat"
        
        # fnirt --in="${dtidir}/${smri}.nii.gz" --aff="${dtidir}/struct2template_aff.mat" --cout="${dtidir}/struct2template_warps" \
        # --ref="${template}" ${template_mask}--imprefm=1 \
        # --impinm=1 --imprefval=0 --impinval=0 --subsamp=4,4,2,2,1,1 --miter=5,5,5,5,5,10 --infwhm=8,6,5,4.5,3,2 --reffwhm=8,6,5,4,2,0 \
        # --lambda=300,150,100,50,40,30 --estint=1,1,1,1,1,0 --applyrefmask=1,1,1,1,1,1 --applyinmask=1 --warpres=10,10,10 --ssqlambda=1 \
        # --regmod=bending_energy --intmod=global_non_linear_with_bias --intorder=5 --biasres=50,50,50 --biaslambda=10000 --refderiv=0
        
        # applywarp --in="${dtidir}/dti_FA.nii.gz" --ref="${template}" --warp="${dtidir}/struct2template_warps" --premat="${dtidir}/dti2struct.mat" --out="${dtidir}/dti_FA_to_${template_abbreviation}.nii.gz"
        ${FSLDIR}/bin/applywarp --in="${dtidir}/dti_FA.nii.gz" --ref="${template}" --premat=${regdir}/diff_2_T1.mat --warp=${regT1Folder}/T1_2_std_warp_field --out="${outdir}/dti_FA_to_${template_abbreviation}.nii.gz"
        # ${FSLDIR}/bin/applywarp --rel --interp=spline --in="${dtidir}/dti_FA.nii.gz" --ref="${template}" --premat=${regdir}/diff_2_T1.mat --warp=${regT1Folder}/T1_2_std_warp_field --out="${outdir}/dti_FA_to_${template_abbreviation}.nii.gz"

        if [ "$freg" == "1" ]; then 
            log_Msg 3 "Transformation of the tensor to the template with applywarp";
            # applywarp --in="${dtidir}/dti_tensor.nii.gz" --ref="${template}" --warp="${dtidir}/struct2template_warps" --premat="${dtidir}/dti2struct.mat" --out="${dtidir}/dti_tensor_in_${template_abbreviation}.nii.gz"
            ${FSLDIR}/bin/applywarp --in="${dtidir}/dti_tensor.nii.gz" --ref="${template}" --premat=${regdir}/diff_2_T1.mat --warp=${regT1Folder}/T1_2_std_warp_field --out="${outdir}/dti_tensor_in_${template_abbreviation}.nii.gz"
            # ${FSLDIR}/bin/applywarp --rel --interp=spline --in="${dtidir}/dti_tensor.nii.gz" --ref="${template}" --premat=${regdir}/diff_2_T1.mat --warp=${regT1Folder}/T1_2_std_warp_field --out="${outdir}/dti_tensor_in_${template_abbreviation}.nii.gz"
        elif [ "$freg" == "2" ]; then 
            echo "Transformation of the tensor to the template with vecreg";
            vecreg -i "${dtidir}/dti_tensor.nii.gz" -r "${template}" -o "${outdir}/dti_tensor_in_struct.nii.gz" -t "${dtidir}/dti2struct.mat"
            vecreg -i "${dtidir}/dti_tensor_in_struct.nii.gz" -r "${template}" -o "${outdir}/dti_tensor_in_${template_abbreviation}.nii.gz" -w "${dtidir}/struct2template_warps"
        fi
    else
        if [ "$warp" == "0" ]; then 
            echo "Linear registration to template with flirt and default options";
            flirt -in "${dtidir}/dti_FA.nii.gz" -ref "${template}" -out "${outdir}/dti_FA_to_${template_abbreviation}.nii.gz" -omat "${dtidir}/FA_to_${template_abbreviation}.mat" -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12
            
            if [ "$freg" == "1" ]; then 
                echo "Transformation of the tensor to the template with flirt";
                flirt -in "${dtidir}/dti_tensor.nii.gz" -ref "${template}" -out "${outdir}/dti_tensor_in_${template_abbreviation}.nii.gz" -init "${dtidir}/FA_to_${template_abbreviation}.mat" -applyxfm
            elif [ "$freg" == "2" ]; then 
                echo "Transformation of the tensor to the template with vecreg";
                vecreg -i "${dtidir}/dti_tensor.nii.gz" -r "${template}" -o "${outdir}/dti_tensor_in_${template_abbreviation}.nii.gz" -t "${dtidir}/FA_to_${template_abbreviation}.mat"
            fi
        elif [ "$warp" == "1" ]; then 
            echo "Non-Linear registration to template with fnirt and default options (cf. fsl/etc/flirtsch/FA_2_FMRIB58_1mm.cnf)";
            fnirt --in="${dtidir}/dti_FA.nii.gz" --ref="${template}" ${template_mask}--cout="${dtidir}/FA_to_${template_abbreviation}_warps" --imprefm=1 --impinm=1 --imprefval=0 --impinval=0 --subsamp=8,4,2,2 \
                --miter=5,5,5,5 --infwhm=12,6,2,2 --reffwhm=12,6,2,2 --lambda=300,75,30,30 --estint=1,1,1,0 --warpres=10,10,10 --ssqlambda=1 \
                --regmod=bending_energy --intmod=global_linear --refderiv=0
        
            applywarp --in="${dtidir}/dti_FA.nii.gz" --ref="${template}" --warp="${dtidir}/FA_to_${template_abbreviation}_warps" --out="${outdir}/dti_FA_to_${template_abbreviation}.nii.gz"
            
            if [ "$freg" == "1" ]; then 
                echo "Transformation of the tensor to the template with applywarp";
                applywarp --in="${dtidir}/dti_tensor.nii.gz" --ref="${template}" --warp="${dtidir}/FA_to_${template_abbreviation}_warps" --out="${outdir}/dti_tensor_in_${template_abbreviation}.nii.gz"
            elif [ "$freg" == "2" ]; then echo "Transformation of the tensor to the template with vecreg";
                vecreg -i "${dtidir}/dti_tensor.nii.gz" -r "${template}" -o "${outdir}/dti_tensor_in_${template_abbreviation}.nii.gz" -w "${dtidir}/FA_to_${template_abbreviation}_warps"
            fi
        elif [ "$warp" == "2" ]; then 
            echo "Linear (flirt) + Non-Linear (fnirt) registration to template";
            flirt -in "${dtidir}/dti_FA.nii.gz" -ref "${template}" -omat "${outdir}/FA_to_${template_abbreviation}_aff.mat" -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12
            fnirt --in="${dtidir}/dti_FA.nii.gz" --ref="${template}" ${template_mask}--aff="${dtidir}/FA_to_${template_abbreviation}_aff.mat" \
                --cout="${dtidir}/FA_to_${template_abbreviation}_warps" --imprefm=1 --impinm=1 --imprefval=0 --impinval=0 --subsamp=8,4,2,2 \
                --miter=5,5,5,5 --infwhm=12,6,2,2 --reffwhm=12,6,2,2 --lambda=300,75,30,30 --estint=1,1,1,0 --warpres=10,10,10 --ssqlambda=1 \
                --regmod=bending_energy --intmod=global_linear --refderiv=0
        
            applywarp --in="${dtidir}/dti_FA.nii.gz" --ref="${template}" --warp="${outdir}/FA_to_${template_abbreviation}_warps" --out="${outdir}/dti_FA_to_${template_abbreviation}.nii.gz"
            
            if [ "$freg" == "1" ]; then 
                echo "Transformation of the tensor to the template with applywarp";
                applywarp --in="${dtidir}/dti_tensor.nii.gz" --ref="${template}" --warp="${outdir}/FA_to_${template_abbreviation}_warps" --out="${outdir}/dti_tensor_in_${template_abbreviation}.nii.gz"
            elif [ "$freg" == "2" ]; then 
                echo "Transformation of the tensor to the template with vecreg";
                vecreg -i "${dtidir}/dti_tensor.nii.gz" -r "${template}" -o "${outdir}/dti_tensor_in_${template_abbreviation}.nii.gz" -w "${outdir}/FA_to_${template_abbreviation}_warps"
            fi
        fi
    fi

    fslroi "${outdir}/dti_tensor_in_${template_abbreviation}.nii.gz" "${outdir}/dxx_in_${template_abbreviation}.nii.gz" 0 1
    fslroi "${outdir}/dti_tensor_in_${template_abbreviation}.nii.gz" "${outdir}/dyy_in_${template_abbreviation}.nii.gz" 3 1
    fslroi "${outdir}/dti_tensor_in_${template_abbreviation}.nii.gz" "${outdir}/dzz_in_${template_abbreviation}.nii.gz" 5 1
    dxx="${outdir}/dxx_in_${template_abbreviation}.nii.gz"
    dyy="${outdir}/dyy_in_${template_abbreviation}.nii.gz"
    dzz="${outdir}/dzz_in_${template_abbreviation}.nii.gz"
fi

	
#GATHER STATS
mkdir -p "${outdir}/alps.stat"
log_Msg 3 "id,scanner,x_proj_L,x_assoc_L,y_proj_L,z_assoc_L,x_proj_R,x_assoc_R,y_proj_R,z_assoc_R,alps_L,alps_R,alps" > "${outdir}/alps.stat/alps.csv"


id=${Subject}
if [ -f "${json1}" ]; then
    scanner1=$(cat "${json1}" | grep -w Manufacturer | cut -d ' ' -f2 | tr -d ',')
fi
x_proj_L="$(fslstats "${dxx}" -k "${proj_L}" -m)"
x_assoc_L="$(fslstats "${dxx}" -k "${assoc_L}" -m)"
y_proj_L="$(fslstats "${dyy}" -k "${proj_L}" -m)"
z_assoc_L="$(fslstats "${dzz}" -k "${assoc_L}" -m)"
x_proj_R="$(fslstats "${dxx}" -k "${proj_R}" -m)"
x_assoc_R="$(fslstats "${dxx}" -k "${assoc_R}" -m)"
y_proj_R="$(fslstats "${dyy}" -k "${proj_R}" -m)"
z_assoc_R="$(fslstats "${dzz}" -k "${assoc_R}" -m)"
alps_L=`echo "(($x_proj_L+$x_assoc_L)/2)/(($y_proj_L+$z_assoc_L)/2)" | bc -l` #proj1 and assoc1 are left side, bc -l needed for decimal printing results
alps_R=`echo "(($x_proj_R+$x_assoc_R)/2)/(($y_proj_R+$z_assoc_R)/2)" | bc -l` #proj2 and assoc2 are right side, bc -l needed for decimal printing results
alps=`echo "($alps_R+$alps_L)/2" | bc -l`

echo "${id},${scanner1},${x_proj_L},${x_assoc_L},${y_proj_L},${z_assoc_L},${x_proj_R},${x_assoc_R},${y_proj_R},${z_assoc_R},${alps_L},${alps_R},${alps}" >> "${outdir}/alps.stat/alps.csv"

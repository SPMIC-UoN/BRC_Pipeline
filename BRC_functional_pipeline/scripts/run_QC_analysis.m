function run_QC_analysis(DVARS_Path , BRC_GLOBAL_DIR , work_dir , infMRI , MovParFile)

%%% add the following paths according to input setup paths
addpath(DVARS_Path);              % % L1precision toolbox
addpath([BRC_GLOBAL_DIR , '/libs/Nifti_Util']);              % % L1precision toolbox


% Path_to_Nifti='~/your/nifti/file/118730/rfMRI_REST1_LR.nii.gz';
V1 = load_untouch_nii(infMRI);
V2 = V1.img;

X0 = size(V2 , 1);
Y0 = size(V2 , 2);
Z0 = size(V2 , 3);
T0 = size(V2 , 4);

I0 = prod([X0 , Y0 , Z0]);
Y  = reshape(V2 , [I0 , T0]);
clear V2 V1;


% DVARS Inference
[DVARS , DVARS_Stat] = DVARSCalc(Y , 'scale' , 1/100 , 'TransPower' , 1/3 , 'RDVARS' , 'verbose' , 1);
save(strcat(work_dir , '/DVARS.mat') ,'DVARS');
save(strcat(work_dir , '/DVARS_Stat.mat') ,'DVARS_Stat');


%DSE Variance Decomposition
[V , DSE_Stat] = DSEvars(Y , 'scale' , 1/100);
save(strcat(work_dir , '/V.mat') ,'V');
save(strcat(work_dir , '/DSE_Stat.mat') ,'DSE_Stat');


%Visualisation
% fMRIDiag_plot(V,DVARS_Stat)
% fMRIDiag_plot(V , DVARS_Stat , 'BOLD' , Y)

% MovPar = MovPartextImport(MovParFile);
MovPar = dlmread(MovParFile);
[FDts , FD_Stat] = FDCalc(MovPar);
save(strcat(work_dir , '/FDts.mat') ,'FDts');
save(strcat(work_dir , '/FD_Stat.mat') ,'FD_Stat');

Idx = find(DVARS_Stat.pvals<0.05 ./ (DVARS_Stat.dim(2)-1));

%   PracticalSigThr = 5;
%   idx = find(Stat.pvals<0.05./(T-1) & Stat.DeltapDvar>PracticalSigThr);
DVARSreg = zeros(T0,1);
DVARSreg(Idx)   = 1;
DVARSreg(Idx+1) = 1;

dlmwrite(strcat(work_dir , '/Idx.txt') , Idx , 'delimiter' , ' ' , 'precision' , '%4d');
dlmwrite(strcat(work_dir , '/DVARSreg.txt') , DVARSreg , 'delimiter' , ' ' , 'precision' , '%4d');

f_hdl=figure('visible', 'off' , 'position' , [10 , 10 , 1600 , 2400]);
fMRIDiag_plot(V , DVARS_Stat , 'BOLD' , Y , 'FD' , FDts , 'AbsMov' , [FD_Stat.AbsRot FD_Stat.AbsTrans] , 'figure' , f_hdl)
print(strcat(work_dir , '/movemen_parameters.png') , '-dpng' , '-r300');

function run_SS_FSL_Nets(FSLNets_Path, L1precision_Path, PWling_Path, work_dir , ts_dir, TR, varnorm)

%%% change the following paths according to your local setup
addpath(FSLNets_Path);              % wherever you've put this package
addpath(L1precision_Path);          % L1precision toolbox
% addpath(PWling_Path)              % pairwise causality toolbox
addpath(sprintf('%s/etc/matlab',getenv('FSLDIR')))    % you don't need to edit this if FSL is setup already


%%% load timeseries data from the dual regression output directory
ts=nets_load(ts_dir , TR , varnorm);

%%% create network matrix and optionally convert correlations to z-stats.
cov_netmats = nets_netmats(ts , 1 , 'cov');
dlmwrite(strcat(work_dir , '/cov_netmats.txt') , cov_netmats , 'delimiter' , ' ' , 'precision' , '%4d');

amp_netmats = nets_netmats(ts , 1 , 'amp');
dlmwrite(strcat(work_dir , '/amp_netmats.txt') , amp_netmats , 'delimiter' , ' ' , 'precision' , '%4d');

corr_netmats = nets_netmats(ts , 1 , 'corr');
dlmwrite(strcat(work_dir , '/corr_netmats.txt') , corr_netmats , 'delimiter' , ' ' , 'precision' , '%4d');

rcorr_netmats = nets_netmats(ts , 1 , 'rcorr');
dlmwrite(strcat(work_dir , '/rcorr_netmats.txt') , rcorr_netmats , 'delimiter' , ' ' , 'precision' , '%4d');

pcorr_netmats = nets_netmats(ts , 1 , 'icov');
dlmwrite(strcat(work_dir , '/pcorr_netmats.txt') , pcorr_netmats , 'delimiter' , ' ' , 'precision' , '%4d');

rpcorr_netmats = nets_netmats(ts , 1 , 'ridgep' , 0.1);
dlmwrite(strcat(work_dir , '/rpcorr_netmats.txt') , rpcorr_netmats , 'delimiter' , ' ' , 'precision' , '%4d');

end

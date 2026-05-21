function run_SS_FSL_Nets(FSLNets_Path, L1precision_Path, PWling_Path, work_dir , ts_dir, TR, varnorm , method , RegVal , Fr2z , ListPath)

%%% change the following paths according to your local setup
addpath(FSLNets_Path);              % wherever you've put this package
addpath(L1precision_Path);          % L1precision toolbox
% addpath(PWling_Path)              % pairwise causality toolbox
addpath(sprintf('%s/etc/matlab',getenv('FSLDIR')))    % you don't need to edit this if FSL is setup already


%%% load timeseries data from the dual regression output directory
ts=nets_load(ts_dir , TR , varnorm , ListPath);

%%% create network matrix and optionally convert correlations to z-stats.
if (RegVal == 0)
    out_netmats = nets_netmats(ts , Fr2z , method);
else
    out_netmats = nets_netmats(ts , Fr2z , method , RegVal);
end
dlmwrite(strcat(work_dir , '/' , 'netmats_' , method , '.txt') , out_netmats , 'delimiter' , ' ' , 'precision' , '%4d');

end

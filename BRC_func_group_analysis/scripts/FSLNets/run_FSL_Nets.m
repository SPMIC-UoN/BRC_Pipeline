
function run_FSL_Nets(FSLNets_Path, L1precision_Path, PWling_Path, work_dir , group_maps, ts_dir, TR, varnorm, method, RegVal , NetWebFolder)

%%% change the following paths according to your local setup
addpath(FSLNets_Path);              % wherever you've put this package
addpath(L1precision_Path);          % L1precision toolbox
% addpath(PWling_Path)                % pairwise causality toolbox
addpath(sprintf('%s/etc/matlab',getenv('FSLDIR')))    % you don't need to edit this if FSL is setup already


%%% load timeseries data from the dual regression output directory
ts=nets_load(ts_dir , TR , varnorm);


ts_spectra=nets_spectra(ts);   % have a look at mean timeseries spectra
print(strcat(work_dir , '/spectra.png') , '-dpng' , '-r300');


%%% cleanup and remove bad nodes' timeseries (whichever is not listed in ts.DD is *BAD*).
% ts.DD=[1 2 3 4 5 6 7 9 11 14 15 17 18];  % list the good nodes in your group-ICA output (counting starts at 1, not 0)
% ts.UNK=[10];  optionally setup a list of unknown components (where you're unsure of good vs bad)
ts=nets_tsclean(ts , 1);                 % regress the bad nodes out of the good, and then remove the bad nodes' timeseries (1=aggressive, 0=unaggressive (just delete bad)).
                                         % For partial-correlation netmats, if you are going to do nets_tsclean, then it *probably* makes sense to:
                                         %    a) do the cleanup aggressively,
                                         %    b) denote any "unknown" nodes as bad nodes - i.e. list them in ts.DD and not in ts.UNK
                                         %    (for discussion on this, see Griffanti NeuroImage 2014.)


%%% quick views of the good and bad components
nets_nodepics(ts,group_maps);
print(strcat(work_dir , '/nodes.png') , '-dpng' , '-r300');

Znet = zeros(6 , ts.Nnodes , ts.Nnodes);
Mnet = zeros(6 , ts.Nnodes , ts.Nnodes);

for i = 1:6
    switch i
        case 1
            Method='cov';
            Reg=0;
            Text='cov';

        case 2
            Method='amp';
            Reg=0;
            Text='amp';

        case 3
            Method='corr';
            Reg=0;
            Text='corr';

        case 4
            Method='rcorr';
            Reg=0;
            Text='rcorr';

        case 5
            Method='icov';
            Reg=0;
            Text='pcorr';

        case 6
            Method='ridgep';
            Reg=0.1;
            Text='rpcorr';
    end

    %%% create network matrix and optionally convert correlations to z-stats.
    out_netmats = nets_netmats(ts , 1 , Method , Reg);
    dlmwrite(strcat(work_dir , '/' , 'netmats.txt' , Text) , out_netmats , 'delimiter' , ' ' , 'precision' , '%4d');


    %%% view of consistency of netmats across subjects; returns t-test Z values as a network matrix
    %%% Znet is Z-stat from one-group t-test across subjects
    %%% Mnet is mean netmat across subjects

    if (i == 2)
        [Znet_amp , Mnet_amp] = nets_groupmean(out_netmats , 1);
        dlmwrite(strcat(work_dir , '/' , 'Znet_' , Text , '.txt') , Znet_amp , 'delimiter' , ' ' , 'precision' , '%4d');
        dlmwrite(strcat(work_dir , '/' , 'Mnet_' , Text , '.txt') , Mnet_amp , 'delimiter' , ' ' , 'precision' , '%4d');
    else
        [Znet(i,:,:) , Mnet(i,:,:)] = nets_groupmean(out_netmats , 1);
        Z_netmat=reshape(Znet(i,:,:) , size(Znet(i,:,:) ,2) , size(Znet(i,:,:) ,3));
        dlmwrite(strcat(work_dir , '/' , 'Znet_' , Text , '.txt') , Z_netmat , 'delimiter' , ' ' , 'precision' , '%4d');

        M_netmat=reshape(Mnet(i,:,:) , size(Mnet(i,:,:) ,2) , size(Mnet(i,:,:) ,3));
        dlmwrite(strcat(work_dir , '/' , 'Mnet_' , Text , '.txt') , M_netmat , 'delimiter' , ' ' , 'precision' , '%4d');
    end
    print(strcat(work_dir , '/one-group-t-test-group-level_' , Text , '.png') , '-dpng' , '-r300');
end


%%% view hierarchical clustering of nodes
netmatL=reshape(Znet(3,:,:) , size(Znet(3,:,:) ,2) , size(Znet(3,:,:) ,3));
netmatH=reshape(Znet(6,:,:) , size(Znet(6,:,:) ,2) , size(Znet(6,:,:) ,3));
nets_hierarchy(netmatL , netmatH , ts.DD , group_maps);
print(strcat(work_dir , '/hierarchy.png') , '-dpng' , '-r300');


%%% view interactive netmat web-based display
nets_netweb(netmatL , netmatH , ts.DD , group_maps , NetWebFolder);

end
%f = figure('visible', 'off');

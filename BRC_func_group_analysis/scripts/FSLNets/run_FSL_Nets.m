
function [result] = run_FSL_Nets(FSLNets_Path , L1precision_Path , PWling_Path , work_dir , group_maps , ts_dir , TR , varnorm , method , RegVal , NetWebFolder , DO_GLM , DesignMatrix , ContrastMatrix)

result = 0;
%%% change the following paths according to your local setup
addpath(FSLNets_Path);              % wherever you've put this package
addpath(L1precision_Path);          % L1precision toolbox
% addpath(PWling_Path)                % pairwise causality toolbox
addpath(sprintf('%s/etc/matlab',getenv('FSLDIR')))    % you don't need to edit this if FSL is setup already


%%% load timeseries data from the dual regression output directory
ts=nets_load(ts_dir , TR , varnorm);

for i = 1 : ts.Nsubjects
    grot = ts.ts((i - 1) * ts.NtimepointsPerSubject + 1 : i*ts.NtimepointsPerSubject , :);
    if (~ isempty(find(sum(grot , 1) == 0)))
        fileID = fopen(strcat(work_dir , '/result.txt') , 'w');
        fprintf(fileID , '%d' , result);
        fclose(fileID);
        return
    end
end

result=1;
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


%%% create network matrix and optionally convert correlations to z-stats.
out_netmats = nets_netmats(ts , 1 , method , RegVal);
dlmwrite(strcat(work_dir , '/' , 'netmats_' , method , '.txt') , out_netmats , 'delimiter' , ' ' , 'precision' , '%4d');


%%% view of consistency of netmats across subjects; returns t-test Z values as a network matrix
%%% Znet is Z-stat from one-group t-test across subjects
%%% Mnet is mean netmat across subjects

[Znet , Mnet] = nets_groupmean(out_netmats , 1);

dlmwrite(strcat(work_dir , '/' , 'Znet_' , method , '.txt') , Znet , 'delimiter' , ' ' , 'precision' , '%4d');
dlmwrite(strcat(work_dir , '/' , 'Mnet_' , method , '.txt') , Mnet , 'delimiter' , ' ' , 'precision' , '%4d');

print(strcat(work_dir , '/one-group-t-test-group-level_' , method , '.png') , '-dpng' , '-r300');


%%% view hierarchical clustering of nodes
%%% netmatL=reshape(Znet(3,:,:) , size(Znet(3,:,:) ,2) , size(Znet(3,:,:) ,3));
%%% netmatH=reshape(Znet(6,:,:) , size(Znet(6,:,:) ,2) , size(Znet(6,:,:) ,3));
nets_hierarchy(Znet , Znet , ts.DD , group_maps);
print(strcat(work_dir , '/hierarchy.png') , '-dpng' , '-r300');


%%% view interactive netmat web-based display
nets_netweb(Znet , Znet , ts.DD , group_maps , NetWebFolder);

%%% cross-subject GLM, with inference in randomise (assuming you already have the GLM design.mat and design.con files).
%%% arg4 determines whether to view the corrected-p-values, with non-significant entries removed above the diagonal.
if (DO_GLM == 'yes')
    [p_uncorrected , p_corrected] = nets_glm(out_netmats , DesignMatrix , ContrastMatrix , 1);  % returns matrices of 1-p
    print(strcat(work_dir , '/Group_diff.png') , '-dpng' , '-r300');


    %%% OR - GLM, but with pre-masking that tests only the connections that are strong on average across all subjects.
    %%% change the "8" to a different tstat threshold to make this sparser or less sparse.

    netmats = out_netmats;
    [grotH , grotP , grotCI , grotSTATS] = ttest(netmats);
    netmats(: , abs(grotSTATS.tstat) < 8) = 0;
    [p_uncorrected , p_corrected] = nets_glm(netmats , DesignMatrix , ContrastMatrix ,1);
    print(strcat(work_dir , '/Group_diff_8.png') , '-dpng' , '-r300');


    %%% view 1 most significant edges from this GLM
    nets_edgepics(ts , group_maps , Znet , reshape(p_corrected(1,:) , ts.Nnodes , ts.Nnodes) , 1);
    print(strcat(work_dir , '/most_significant_edges.png') , '-dpng' , '-r300');
end

fileID = fopen(strcat(work_dir , '/result.txt') , 'w');
fprintf(fileID , '%d' , result);
fclose(fileID);

end
%f = figure('visible', 'off');

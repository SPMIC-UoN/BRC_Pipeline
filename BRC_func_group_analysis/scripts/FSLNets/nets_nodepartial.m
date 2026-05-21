%
% nets_nodepartial - replace node timeseries with node partial timeseries
% Steve Smith, 2013
%
% [new_ts] = nets_nodepartial(ts); 
%

function [newts] = nets_nodepartial(ts);

newts=ts; newts.ts=[];

for s=1:ts.Nsubjects
  disp(sprintf('doing subject %d of %d\b\b\b',s,ts.Nsubjects))
  grot=nets_demean(ts.ts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:));
  for i=1:size(grot,2)
    TSr=grot(:,setdiff(1:size(grot,2),i));
    grot2(:,i)= grot(:,i) - TSr*(pinv(TSr)*grot(:,i));
  end
  newts.ts=[newts.ts;grot2];
end


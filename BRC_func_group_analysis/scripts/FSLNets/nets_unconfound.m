function yd=nets_unconfound(y,conf)

% nets_unconfound(y,conf) 
% regresses conf out of y, handling missing data
% data, confounds and output are all demeaned

y = nets_demean(y);
conf = nets_demean(conf);

if sum(isnan(y(:)))+sum(isnan(conf(:))) == 0   % if there's no missing data, can use faster code

  yd = nets_demean( y - conf * ( pinv(conf) * y ) );

else

  yd = (y*0)/0; % set to all NaN because we are not going to necessarily write into all elements below

  for i=1:size(y,2)
    grot=~isnan(sum([y(:,i) conf],2));
    grotconf=nets_demean(conf(grot,:));
    yd(grot,i) = nets_demean( y(grot,i) - grotconf * ( pinv(grotconf) * y(grot,i) ) );
  end

end


function [impute_replace,impute_noreplace,pcaU,pcaS,pcaV]=nets_impute(impute_input,Npca)

% nets_impute(impute_input,Npca) 
% inpute missing data in matrix impute_input based on a soft-shrunk PCA data recon with Npca dimensions
% impute_replace is output where estimated data is replaced with (non-missing) input data
% impute_noreplace is output where estimated data is not replaced with input data (ie output is directly from PCA)

if size(impute_input,2)==1

  impute_replace=impute_input; impute_replace(isnan(impute_replace))=nanmean(impute_replace);
  impute_noreplace=impute_replace; pcaU=impute_replace; pcaS=1; pcaV=1;

else

  nanmask=isnan(impute_input);
  impute_noreplace=zeros(size(impute_input));
  impute_corr=0;

  while (impute_corr<0.9999 | isnan(impute_corr))
    impute_replace=impute_input;
    impute_replace(nanmask)=impute_noreplace(nanmask);
    [pcaU,pcaS,pcaV]=nets_svds(impute_replace,Npca);
    pcaSmin=min(diag(pcaS));
    impute_noreplace = pcaU * (pcaS-diag(((0:(size(pcaS,1)-1))/(size(pcaS,1)-1)).^4*pcaSmin)) *pcaV' ;
    impute_corr=corr(impute_replace(nanmask),impute_noreplace(nanmask));
  end

end


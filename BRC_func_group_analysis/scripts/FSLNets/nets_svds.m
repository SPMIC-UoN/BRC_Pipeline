%
% nets_svds - SVD: RAM/time-efficient wrapper for eig/eigs
% Steve Smith  2013-2014
%
% [u,s,v]=nets_svds(x,n);
%
% x is any 2D matrix, which will be approximated by:  x = u s v'
% n is the number of components to estimate
%   If n<=0 then we will estimate  rank-abs(n)  components
%
% Note: no demeaning of x takes place within this function
%

function [u,s,v]=nets_svds(x,n);

if n<1
  n = max( min(size(x))+n , 1);
end

if size(x,1) < size(x,2)

  u=x*x';  if isa(u,'double')==0, u=double(u); end    % convert to double if necessary, for sake of eigs
  if n < size(x,1)
    [u,d] = eigs(u,n);
  else
    [u,d] = eig(u); u=fliplr(u); d=flipud(fliplr(d));
  end
  s = sqrt(abs(d));
  v = x' * (u * diag((1./diag(s)))); 

else

  v=x'*x;  if isa(v,'double')==0, v=double(v); end
  if n < size(x,2)
    [v,d] = eigs(v,n);
  else
    [v,d] = eig(v); v=fliplr(v); d=flipud(fliplr(d));
  end
  s = sqrt(abs(d));
  u = x * (v * diag((1./diag(s)))); 

end


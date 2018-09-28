% Last update: 28/09/2018
%
% Authors: Ali-Reza Mohammadi-Nejad, & Stamatios N Sotiropoulos
%
% Copyright 2018 University of Nottingham
%

function extract_slice_specifications(json_file_path, slscpec_file_path)

fp = fopen(json_file_path,'r');
fcont = fread(fp);
fclose(fp);
cfcont = char(fcont');
i1 = strfind(cfcont,'SliceTiming');
i2 = strfind(cfcont(i1:end),'[');
i3 = strfind(cfcont((i1+i2):end),']');
cslicetimes = cfcont((i1+i2+1):(i1+i2+i3-2));
slicetimes = textscan(cslicetimes,'%f','Delimiter',',');
[sortedslicetimes,sindx] = sort(slicetimes{1});
mb = length(sortedslicetimes)/(sum(diff(sortedslicetimes)~=0)+1);
slspec = reshape(sindx,[mb length(sindx)/mb])'-1;
dlmwrite(slscpec_file_path , slspec , 'delimiter' , ' ' , 'precision' , '%3d');

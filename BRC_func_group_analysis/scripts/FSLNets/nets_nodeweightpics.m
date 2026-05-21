%
% nets_nodeweightpics(ts,group_maps,NodeWeights,showN,[decimal-places-for-value]);
% Steve Smith - 2016
%
% show the strongest elements from "NodeWeights" (the number shown is controlled by showN)
% 
% ts is the node timeseries structure; group_maps is a string pointing to the thumbnail images folder
%

function nets_nodeweightpics(ts,group_maps,NodeWeights,showN,varargin);    %%%% show a snapshot of the kept and rejected components

decimalplaces=8;
if nargin==5
 decimalplaces=varargin{1};
end; 
if showN>ts.Nnodes
  showN=ts.Nnodes;
end

NodeWeightsORIG=NodeWeights;  NodeWeights=abs(NodeWeights);

grott=sprintf('%s.png',tempname);

[grotA,grotB,grotC]=fileparts(group_maps); if size(grotA,1)==0, grotA='.'; end; group_maps=sprintf('%s/%s.sum',grotA,grotB);

[yy,ii]=sort(NodeWeights(:),'descend');   % find strongest showN edges

xf=ceil(2*sqrt(showN)); yf=ceil(showN/xf);   % dimensions of display tiling

XX=1560; YY=650; % total image size

bd=15; bdx=bd/XX; bdy=bd/YY; % borders size
th=35/YY; % title height
isx=(1-(xf+1)*bdx)/(xf);  isy=(1-(yf+1)*bdy-yf*th)/yf;

gap=0;
if exist('octave_config_info')~=0  % because octave has a stupid subplot bug
  gap=0.0001;
end;

YY=(109/91) * (isx*XX) / isy;
figure('Position',[10 10 XX YY]); 

for iii=1:showN
  xxx=ii(iii);  yfi=ceil(iii/xf); xfi=iii-((yfi-1)*xf); yfi=1+yf-yfi;   [xxx xfi yfi];

  call_fsl(sprintf('slices_summary %s %s %s',group_maps,grott,num2str(ts.DD([xxx])-1)));  picgood=imread(grott);
  subplot('position',[xfi*bdx+(xfi-1)*isx yfi*bdy+(yfi-1)*(isy+th) isx-gap isy-gap]);
  imagesc(picgood); axis off; axis equal;

  subplot('position',[xfi*bdx+(xfi-1)*isx yfi*bdy+(yfi-1)*(isy+th)+isy isx th]); axis off;
  if NodeWeightsORIG(xxx)>0
    grot='red';
  else
    grot='blue';
  end

  title1=sprintf('node %d',xxx);
  title2=sprintf('\\fontsize{12}\\color{%s}%s',grot,sprintf(sprintf('%%.%df',decimalplaces),NodeWeightsORIG(xxx)));
  title({title1,title2},'Position',[0.5 0.1]);

end

set(gcf,'PaperPositionMode','auto'); 


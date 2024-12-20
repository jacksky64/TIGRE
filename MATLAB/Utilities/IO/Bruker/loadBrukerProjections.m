function [proj,geo,angles]=loadBrukerProjections(filepath,geo,angles,varargin)
%[proj,angles]=loadBrukerProjections(filepath,geo,angles,varargin)
%   loads Bruker uCT machine projections
%
%   loadBrukerData(filepath,geo,angles) Loads a dataset given its FILEPATH,
%      a geometry GEO and angles ANGLES (loaded from readXtekctGeometry()) 
%
%   loadBrukerData(filepath,geo,angles, OPT,VAL,...) uses options and values. 
%      These are options in case you don't want to load the entire
%      dataset, but only particular sets of projections. 
%      The possible options in OPT are:
%           'sampling': type of sampling. default 'equidistant' Can be:
%                  'equidistant': equidistantly sample the entire set
%                       of angles. 'num_angles' should be set for partial
%                       loading of the data. 
%                  'step': sample the entire set of projections every
%                         'sampling_step' angles.
%                  'continuous': Load the first 'num_angles' amount of
%                             angles only.
%
%           'num_angles': Number of total angles to load. Default all of
%                    them. Useful for 'equidistant' and 'continuous' loading
%
%           'sampling_step': step to load when loading projections. Default
%           1. Useful for 'step' loading.
% 
%           'dataset number': id of the dataset to load.
% 

% developed by A. Biguri 


%% Parse inputs. 


[angles_to_load,index,dataset_number]=parse_inputs(geo,angles,varargin);

% make sure its path
if filepath(end)~='\' && filepath(end)~='/'
   filepath=[filepath '/']; 
end

%% get filename
% assuming TIF and 4 digits.
firstfile = dir([filepath,'/*.tif']); %
firstfile = firstfile(2).name;
filename = firstfile(1:end-8);
if dataset_number~=-1
    filename(end-4)=num2str(dataset_number);
end
fprintf("Dataset in: %s \n", filepath);

%% load images
%proj=[];
l = length(angles_to_load);

test_image=single(imread([filepath,filename,num2str(index(1)-1,'%04d'),'.tif']));
if any(size(test_image)~=fliplr(geo.nDetector'))
    warning('Information in the Log file does not match the projection sizes, chosing projection information');
    geo.nDetector=fliplr(size(test_image))';
    geo.sDetector=geo.nDetector.*geo.dDetector;
end

proj = zeros(geo.nDetector(2),geo.nDetector(1),l,'single');
for ii=1:length(angles_to_load)
    if(~mod(ii,50))
      fprintf("Loading: %d / %d \n", ii, length(angles_to_load));
    end
     proj(:,:,ii)=single(imread([filepath,filename,num2str(index(ii)-1,'%04d'),'.tif']));
end
%% Beer lambert
if any(proj(:))>single(geo.whitelevel)
    warning('Changing the Whitelevel value as projection data has higher value than specified in the file');
    geo.whitelevel=max(proj(:)+1);
end
proj=-log(proj/single(geo.whitelevel));
geo=rmfield(geo,'whitelevel');
%%
angles=angles_to_load;
end

function [angles,indices,dataset_number]=parse_inputs(geo,angles,argin)
opts=     {'sampling','num_angles','sampling_step','dataset_number'};
defaults=ones(length(opts),1);
% Check inputs
nVarargs = length(argin);
if mod(nVarargs,2)
    error('Invalid number of inputs')
end

% check if option has been passed as input
for ii=1:2:nVarargs
    ind=find(ismember(opts,lower(argin{ii})));
    if ~isempty(ind)
        defaults(ind)=0;
    else
        error(['Optional parameter "' argin{ii} '" does not exist' ]);
    end
end

for ii=1:length(opts)
    opt=opts{ii};
    default=defaults(ii);
    % if one option is not default, then extract value from input
    if default==0
        ind=double.empty(0,1);jj=1;
        while isempty(ind)
            ind=find(isequal(opt,lower(argin{jj})));
            jj=jj+1;
        end
        if isempty(ind)
            error(['Optional parameter "' argin{jj} '" does not exist' ]);
        end
        val=argin{jj};
    end
    
    switch opt
        case 'sampling'
            if default
                sampling='equidistant';
            else
                if strcmpi(val,'equidistant') || strcmpi(val,'step')|| strcmpi(val,'continuous')
                    sampling=val;
                else
                   error('sampling type not understood, must be  equidistant, step or continuous');
                end
            end
        case 'num_angles'
            if default
                num_angles=length(angles);
            else
                num_angles=val;
            end
        case 'sampling_step'
            if default
               sampling_step=1;
            else
               sampling_step=val;
            end
        case 'dataset_number'
            if default
                dataset_number=-1;
            else
                dataset_number=val;
            end
        otherwise
            error(['Invalid input name:', num2str(opt),'\n No such option']);
    end
end
% now lets build the angles

if strcmpi(sampling,'equidistant')
   sampling_step=round(length(angles)/num_angles);
   indices=1:sampling_step:length(angles);
   angles=angles(indices);
   return;
end
if strcmpi(sampling,'continuous')
   indices=1:num_angles;
   angles=angles(indices);
   return;
end
if strcmpi(sampling,'step')
   indices=1:sampling_step:length(angles);
   angles=angles(indices);
   return;
end
end
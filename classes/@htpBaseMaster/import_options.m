%% Import Options XML
%%% Usage
%    
% obj = import_options( obj, xmlfile)
% 
%%% Parameters
% 
% * INPUTS: obj, xmlfile
%
% * OUTPUTS: obj
%
% The input parameter xml_file is an xml file that is in the format seen in
% the cfg_htpPreprocessingOptions.xml atrribute of an htpPreprocessMaster
% object.  The second input of obj as the htpPreprocessMaster object is
% optional depending upon if the function is self-invoked or not.  The
% output, if the function is not self-invoked, is the htpPreprocessMaster
% object with the htpcfg attribute updated with options for each stage of 
% the preprocessing experience. 
% output
% 
%    struct with stage options:
%    [1x1] struct
%   |--Stage1:  [1x1] struct
%   |  |--FilterLow:  [1x4] cell
%   |  |--FilterHigh:  [1x5] cell
%   |  |--Notch1:  [1x2] cell
%   |  |--Resample:  [1x4] cell
%   |  '--Rereference:  [1x7] char
%   |--Stage2:  [1x1] struct
%   |  |--Interpolation:  [1x3] cell
%   |  |--CleanMode:  [1x2] cell
%   |  '--EpochLength:  [1x3] cell
%   '--Stage3:  [1x1] struct
%      '--PCA:  [1x3] cell
%
%%% Copyright and Contact Information
% Copyright © 2020 Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% import_options
% Configuring the options necessary for each stage
% of preprocessing events for quick future reference and the user is 
% alerted to how many options were imported.
% Options are pulled from preconfigured xml files
% that can be modified by user for their preference.

function obj = import_options( obj, xmlfile)

htpcfg = obj.htpcfg;

optxml = ext_xml2struct( xmlfile );

stageNames = fields(optxml.PreProcessOptions);

for i = 1 : length(stageNames)
    
    stageOpt{i} = fields(optxml.PreProcessOptions.(stageNames{i}));
    
end

o1 = optxml.PreProcessOptions;

for j = 1 : length(stageNames)
    
    s1 = o1.(stageNames{j});
    
    s1Fields = fields(s1);
    
    for i= 1 : length(s1Fields)
        allopt = [];
        opttemp = s1.(s1Fields{i});
        opttemplength = length(opttemp.opt');
        
        if opttemplength == 1
            allopt = opttemp.opt.Text;
        else
            allopt = [opttemp.opt{:}];
            allopt = { allopt.Text};
            
        end
       % newopt{i,1,j} = s1Fields{i};
       % newopt{i,2,j} = allopt;
        
        newStruct.(stageNames{j}).(s1Fields{i}) = allopt;
    end
    
end

obj.xml_opt = newStruct;

stagename = fields(obj.xml_opt);

for i = 1 : length( stagename )
   
    stagedetail = fields(obj.xml_opt.(stagename{i}));
    opttemp = obj.xml_opt.(stagename{i});
    for j = 1 : length( stagedetail )
        
        htpcfg.opt.(genvarname([stagename{i} '_' stagedetail{j}])) = opttemp.(stagedetail{j});
        
        
    end
    
end

obj.htpcfg = htpcfg;

disp(obj.htpcfg.opt);
obj.msgout(sprintf('Number of Options Imported: %d\n', length(fields(obj.htpcfg.opt))),'step_complete');

end

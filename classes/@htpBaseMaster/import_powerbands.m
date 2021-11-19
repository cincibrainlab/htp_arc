%% Import Powerbands
%%% Usage
%   
% obj = import_powerbands( obj, xmlfile )
%
%%% Parameters
%
% * INPUTS: obj, xmlfile
%
% * OUTPUTS: obj
%
% The input parameter xmlfile is a configuration xml for the powerbands,
% and the second optional input parameter if the function is not
% self-invoked is obj as the htpPreprocessMaster.  The output, 
% if the function is not self-invoked, is the htpPreprocessMaster with 
% power band configuration attributes updated to reflect the bands the 
% user needs for preprocessing.
%
%%% Copyright and Contact Information
%
% Copyright © 2020 Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% import_powerbands
% Obtain the various bands related to the power band types.
% The various bands are constructed accordingly to default band ranges and
% special ranges such as 'Six_Band' and 'Seven_Band_Gamma' to be used as
% needed by the user.
function obj = import_powerbands( obj, xmlfile )

str = sprintf('Import from %s', xmlfile );
obj.msgout(str, 'proc_complete');

outStr ='';

try
    cfgFilename = fullfile(obj.htpcfg.scriptPath, xmlfile);
    
    xmldata = ext_xml2struct( cfgFilename );
    
    PowOptions = xmldata.PowOptions;
    PowOptions = {PowOptions.Study{:}};
    
    pl = PowOptions;
    pl = {};
    for i = 1 : length( PowOptions )
       
        pl{i,1}  = PowOptions{i}.('Title').Text;
        pl{i,2}  = 'Begin Options';
        
        f = fields(PowOptions{i}.Bands);
        
        idx = 3;
        
        for k = 1 : length( f )
           
            pl{i,idx} = f{k};
            pl{i,idx+1} = PowOptions{i}.Bands.(f{k}).Text;
            idx = idx + 2;
        end
    end
    

    tmpcell = cell(1, length(pl));
    tmpcell{1,1} = 'No preset selected';
    tmpcell{1,2} = 'Default';
    obj.xml_power = [ tmpcell; pl];
      
    str = sprintf('%s imported. %d Power Options Loaded.', xmlfile, size(obj.xml_power,1)-1);
    obj.msgout(str, 'step_complete');
    
catch
    
    outStr = sprintf('ERROR: Preset Import. Check format of %s', xmlfile);    
    obj.msgout(outStr, 'step_error');
    

end
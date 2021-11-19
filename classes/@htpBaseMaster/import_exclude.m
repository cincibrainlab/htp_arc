% IMPORT_EXCLUDE create array of electrodeConfigClass objects from
%                    xml configuration file config/cfg_htpEegSystems.xml
%
% Use as
%   htp_readEegSystems( filename )
%
% arguments
%   filename  xml file with the format
% <?xml version="1.0"?>
% <ExcludeReasons>
% <opt>Exclude Reason</opt>
% </ExcludeRasons>
%
% Copyright (C) 2019  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP), see
% https://bitbucket.org/eped1745/htp_stable/src/master/
% Contact: ernest.pedapati@cchmc.org


function obj = import_exclude(obj, xmlfile)

obj.msgout('Starting Preset Import from config/cfg_exclude.xml', 'step_complete');

outStr ='';

try
    cfgFilename = fullfile(obj.htpcfg.scriptPath, xmlfile);
    
    xmldata = ext_xml2struct( cfgFilename );
    
    presetList = xmldata.ExcludeReasons;
    presetList = {presetList.opt{:}};
    
    pl = presetList;
    pl = {};
    for i = 1 : length( presetList )
       
        pl{i,1}  = presetList{i}.Text;

    
    end
    
    obj.xml_exclude = pl;
      
    str = sprintf('%s imported. %d Exclude Reasons Loaded.', xmlfile, size(obj.xml_presets,1)-1);
    obj.msgout(str, 'step_complete');
    
catch
    
    outStr = sprintf('ERROR: Preset Import. Check format of %s', xmlfile);    
    obj.msgout(outStr, 'step_error');
    

end
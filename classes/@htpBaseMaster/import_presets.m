%% Import EEG Presets
%%% Usage:
%
% obj = import_presets( obj, xmlfile )
%
%%% Parameters
%
% The input parameter xmlfile is an xml file that contains EEG system
% configuration options.  The second option obj, optiponal if the
% function is not self-invoked, is the htpPreprocessMaster object updated 
% with the input xml presets loaded for preprocessing 
%
%
% arguments
%   filename  xml file with the format
% <?xml version="1.0"?>
% <PresetOptions>
%     <Study>
%         <Title>Minocycline</Title>
%         <Code>Mino</Code>
%         <Net>EGI32</Net>
%         <Setting>
%             <opt>Default</opt>
%             <opt>PCA</opt>
%         </Setting>
%     </Study>
%     <Study>
%         <Title>Stimulant in Autism Trial (SAT)</Title>
%         <Code>SAT</Code>
%         <Net>EGI32</Net>
%         <Setting>
%             <opt>Default</opt>
%             <opt>PCA</opt>
%             <opt>Net128</opt>
%         </Setting>
%     </Study>
%
% </PresetOptions>
%
%
%%% Copyright and Contact Information
%
% Copyright © 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% import_presets
% Obtain pipeline option presets for various studies by creating array of 
% electrodeConfigClass objects from xml configuration file 
% config/cfg_htpEegSystems.xml. Allows the user to ensure that the correct 
% measures are being taken during preprocessing for their specific study via
% populated pipeline options.
function obj = import_presets(obj, xmlfile)

obj.msgout('Starting Preset Import from config/cfg_htpPresets.xml', 'step_complete');

outStr ='';

try
    cfgFilename = fullfile(obj.htpcfg.scriptPath, xmlfile);
    
    xmldata = ext_xml2struct( cfgFilename );
    
    presetList = xmldata.PresetOptions;
    presetList = {presetList.Study{:}};
    
    pl = presetList;
    pl = {};
    for i = 1 : length( presetList )
       
        pl{i,1}  = presetList{i}.('Title').Text;
        pl{i,2}  = presetList{i}.('Code').Text;
        pl{i,3}  = presetList{i}.('Net').Text;
        pl{i,4}  = 'Begin Options';
        
        f = fields(presetList{i}.Settings);
        
        idx = 5;
        
        for k = 1 : length( f )
           
            pl{i,idx} = f{k};
            pl{i,idx+1} = presetList{i}.Settings.(f{k}).Text;
            idx = idx + 2;
        end
    end
    
    tmpcell = cell(1, length(pl));
    tmpcell{1,1} = 'No preset selected';
    tmpcell{1,2} = 'Default';
    obj.xml_presets = [ tmpcell; pl];
      
    str = sprintf('%s imported. %d Presets Loaded.', xmlfile, size(obj.xml_presets,1)-1);
    obj.msgout(str, 'step_complete');
    
catch
    
    outStr = sprintf('ERROR: Preset Import. Check format of %s', xmlfile);    
    obj.msgout(outStr, 'step_error');
    

end
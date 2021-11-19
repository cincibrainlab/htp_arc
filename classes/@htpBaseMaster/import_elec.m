%% Import Electrode Configuration
%%% Usage
%    
% obj = import_elec( obj, xmlfile )
%
%%% Parameters
%
% * INPUTS: obj, xmlfile
%
% * OUTPUTS: obj
%
%  The input parameter xmlfile is an xml configuration file with EEG
%  system configuration options.  The obj parameter, optional if the 
%  function is not self-invoked, is an htpPreprocessMaster object.  The 
%  output, if the function is not self-invoked, is the 
%  htpPreprocessMaster object with the electrode configuration options set.  
%    
% arguments
%   filename  xml file with the format
% <item>
% <listitem>
%     <net_displayname>'EGI Hydrocel 128'</net_displayname>
%     <net_name>'EGI128'</net_name>
%     <net_file>'chanfiles/GSN-HydroCel-129.sfp'</net_file>
%     <net_graphic>'chanfiles/EEG_128_channel_array_map.pdf'</net_graphic>
%     <net_filter>'*.raw'</net_filter>
%     <net_nochans>128</net_nochans>
%     <net_regions>
%         <Frontal>'[1,2,3,4,8,9,10,11,15,16,18,19,20,23,24,26,27,33,125,128]'</Frontal>
%         <Premotor>'[21,30,36,29,40,35,25,28,34,39,119,124,112,123,118,122,117,116,121]'</Premotor>
%         <SMA>'[5,6,12,13,21,119,113]'</SMA>
%         <Motor>'[36,41,37,42,38,32,7,107,106,105,104,111,110,81,88,]</Motor>
%         <Somatosensory>'[32,38,43,48,42,46,47,54,55,80,81,88,94,99,104,103]'</Somatosensory>
%         <Parietal>'[51,52,53,54,57,58,59,60,61,62,66,67,68,72,73,77,78,79,80,85,86,87]'</Parietal>
%         <Occipital>'[65,66,72,73,77,85,91,69,70,71,76,84,90,75,83]'</Occipital>
%     </net_regions>
% </listitem>
% </item>
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

%% import_elec
% Import the electrode configuration options and details, via array creation
% of electrodeConfigClass objects from xml configuration file 
% config/cfg_htpEegSystems.xml, due to 
% the information being crucial for preprocessing as it provides 
% fields such as net parameters for the input data
% that will guide most of the pipeline processing. 
% The user is alerted in the case of an error since most of the issues
% are due to improperly formatted xml configuration files.

function obj = import_elec( obj, xmlfile )

if nargin < 2
    xmlfile = 'config/cfg_htpEegSystems.xml';
    %obj.msgout('Electrode Import from config/cfg_htpEegSystems.xml', 'step_complete');
end

obj.msgout(sprintf('Electrode Import from %s', xmlfile), 'step_complete');
outStr ='';

try
    cfgFilename = xmlfile;
    
    xmldata = ext_xml2struct( cfgFilename );
    
    eegList = xmldata.list;
    eegList = {eegList.listitem{:}};
    
    for i = 1 : length( eegList )
        
        eegItem(i) = eegList{i};
        
        fn = fieldnames(eegItem(i));
        
        for k=1 : numel(fn)
            
            if isfield(eegItem(i).(fn{k}), 'Text') == 1
                
                eegItem(i).(fn{k})  = eegItem(i).(fn{k}).Text;
                
                
            else
                
                if strcmp(fn{k}, 'net_regions')
                    
                    regions = fieldnames(eegItem(i).(fn{k}));
                    
                    for l = 1 : numel( regions )
                        
                        eegItem(i).(fn{k}).(regions{l}) = cellfun(@str2double,regexp(eegItem(i).(fn{k}).(regions{l}).Text,'\d*','Match'));
                        
                    end
                    
                end            
                
            end
            
        end
        
        
        elecObj(i) = electrodeConfigClass;
        elecObj(i).setSystemProperties( eegItem(i) );
        
        str = sprintf('\tLoaded(%d): %s\n', i, elecObj(i).net_displayname);
        outStr = sprintf('%s\n%s', outStr, str);        

        obj.xml_elec = elecObj;
        
    end
    
    outStr = sprintf('%s\n%s', outStr, 'htp_readEegSystem.m: Success with Electrode Import\n\n');
    notify(obj, 'step_complete');
    obj.htpcfg.chaninfo = obj.xml_elec;
catch
    
    outStr = sprintf('%s\n%s', outStr, 'htp_readEegSystem.m: ERROR: Check format of config/cfg_htpEegSystems.xmlxt\n\n');
    obj.msgout(outStr, 'step_error');    
    
end
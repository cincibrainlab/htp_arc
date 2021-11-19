%% Load Subjects
%
%%% Usage
%    
% sub = loadSub( obj, stage_last )
%
%%% Parameters
%
% * INPUTS: obj, stage_last
%
% * OUTPUTS: sub
%
% The input parameter is a string represeting the last stage of preprocessing 
% completed for the subject (i.e. 'postcomps') and a second optional input 
% if the function is not self-invoked obj is the htpPreprocessMaster 
% object.  The output is the subject object with the subjects and their 
% respective settings and file paths updated. 
%
%%% Copyright and Contact Information
%
% Copyright (C) 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% loadSub
% The object's subjects are updated with various attributes dealing with subjects such
% as data file paths, configurations, and stage information
% which will be used while processing each subject throughout each stage.
function sub = loadSub( obj, stage_last)

try
    mode = char(obj.htpcfg.optnow.Stage2_CleanMode);
catch
    obj.msgout('Command Line Mode','step_warning');
    mode = 'Manual';
end

switch mode
    
    case 'FullAuto'
     try
       % obj.htpcfg.csvfile = obj.htpcfg.fullauto.csvfile;
       % obj.htpcfg.matfile = obj.htpcfg.fullauto.matfile;
        obj.getStageCSV( stage_last, obj.htpcfg.basePath );
     catch
         obj.getStageCSV( stage_last, obj.htpcfg.basePath );
     end
        
    case 'Manual'
        obj.getStageCSV( stage_last, obj.htpcfg.basePath );
        
end

load( obj.htpcfg.matfile, 'sub' );
sub = loadobj(sub);
arrayfun(@( s ) s.createPaths( obj.htpcfg.basePath )  , sub, 'UniformOutput', false);
arrayfun(@( s ) s.setCsv( obj.htpcfg.csvfile )        , sub, 'UniformOutput',false );
arrayfun(@( s ) s.setMat( obj.htpcfg.matfile )        , sub, 'UniformOutput',false );
arrayfun(@( s ) s.updatePaths( obj.htpcfg.basePath )  , sub, 'UniformOutput',false );
arrayfun(@( s ) obj.update_htpcfg( s )                , sub, 'UniformOutput',false );

obj.msgout(sprintf('htpPreprocessingClass loadSub method results:'),'step_complete');
obj.msgout(sprintf('Current Data Directory: %s', obj.htpcfg.basePath'));
obj.msgout(sprintf('CSV file loaded: %s', obj.htpcfg.csvfile));
obj.msgout(sprintf('MAT file loaded: %s', obj.htpcfg.matfile));
obj.msgout(sprintf('Number of Subjects: %d', length(sub)));
obj.msgout(['' obj.countStrings({sub.subj_subfolder})]);

end


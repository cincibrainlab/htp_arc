%% Create Results CSV
%%% Usage
% 
% filename = createResultsCsv( obj, sub, stage, varargin )
%
%%% Parameters
%
% * INPUTS: obj, sub, stage, varargin
%
% * OUTPUTS: filename
%
% The input parameters sub, stage, varargin, and an optional obj if the 
% function is not self-invoked by the object.  The sub input is an object
% representing the subject, the stage is a string representing the stage
% (i.e. 'postcomps'), and varargin is a string that defines the state of
% the subject (i.e. 'Merge' or 'Default' or 'reprocess_').  The optional 
% parameter obj is the htpPreprocessMaster object.  The output is 
% the file name of the results csv for the subject.
%
%%% Copyright and Contact Information
% Copyright © 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
%
% Contact: ernest.pedapati@cchmc.org

%% createResultsCsv
% Updating the associated stage information and determining correct output
% location for data file upon completion of preprocessing step.
% Finalizing the updated paths and data outputted from the completed stage to
% the associated data files to be used in the next steps of the
% preprocessing.

function filename = createResultsCsv( obj, sub, stage, varargin )
if nargin > 2
    userdesc = genvarname(varargin{1});
    userdesc = [userdesc '_'];
else
    userdesc = '';
end

msgout = @sub.msgout;
%timetag2    = datestr(now,'yymmddHHMM');
if strcmp(obj.htpcfg.chanNow.net_name,'EDFGENERIC')
    timetag2 = datestr(now, 'yymmddHHMMSS');
else
    timetag2    = datestr(now,'yymmddHHMM');
end

switch stage
    
    case 'level1'
        
        desc = 'Stage5';
        msg = 'FIVE';
        outputrowstage = 'level1';
        
    case 'preanalysis'
        desc = 'Stage4b';
        msg = 'FOUR-B';
        outputrowstage = 'preanalysis';
        
    case 'postcomps'
        
        desc = 'Stage4';
        msg = 'FOUR';
        outputrowstage = 'postcomps';
        
    case 'postica'
        
        desc = 'Stage3';
        msg = 'THREE';
        outputrowstage = 'postica';
        
        
    case 'preica'
        
        desc = 'Stage2';
        msg = 'TWO';
        outputrowstage = 'preica';
        
        
    case 'import'
        
        desc = 'Stage1';
        msg = 'ONE';
        outputrowstage = 'import';
        
    case 'combined'
        
        desc = 'Stage3';
        msg = 'FOUR';
        outputrowstage = 'postcomps';
        
        
        
end

if strcmp('same_', userdesc)
    
    [a,b,c] = fileparts(obj.htpcfg.csvfile);
    pathdb = sub(1).pathdb;
    saveFN = fullfile(pathdb.analysis, b);
    
    
else
    
    if strcmp('reprocess_', userdesc)
        pathdb = sub(1).pathdb;
        saveFN = [pathdb.analysis 'A' timetag2 '_subjTable_' userdesc desc '_AUTO'];
        %
        %                     [a,b,c] = fileparts(obj.htpcfg.csvfile);
        %                     b = [b '_AUTO'];
        %                     obj.htpcfg.csvfile = [a, b, c];
        %                     pathdb = sub(1).pathdb;
        %                     saveFN = fullfile(pathdb.analysis, b);
        %
        
    else
        
        pathdb = sub(1).pathdb;
        saveFN = [pathdb.analysis 'A' timetag2 '_subjTable_' userdesc desc];
         saveFN = [pathdb.analysis 'A' timetag2 '_subjTable_' userdesc desc];

        
    end
end


subjHeader = regexprep(sub(1).log_subjHeader, '\.', '') ;


%             for i = 1 : length(sub)
%                 %sub(i).outputRow(outputrowstage);
%                 subjTable(i,:) = cell2table(vertcat(sub(i).log_subjRow));
%             end
tcell = {sub.log_subjRow};

for k = 1 : length(tcell)
    
    maxSize = max(cellfun(@numel, tcell));               % Get the maximum vector size
    if size(tcell{k},2) < maxSize
        
        tcell{k} = [tcell{k} cell(1, maxSize-numel(tcell{k}))];
        
    end
end

vertcat(tcell);

subjTable = cell2table(vertcat(tcell{:}));

maxSize = max(cellfun(@numel, {sub.log_subjHeader}));
headsizes = cellfun(@(x) size(x,2), {sub.log_subjHeader},'uni',0);
headsizes = cell2mat(headsizes);
bestsize = find(headsizes == maxSize);

subjTable.Properties.VariableNames = sub(bestsize(1)).log_subjHeader;

csvfile = fullfile([saveFN '.csv']);
try
    writetable(subjTable, csvfile );
catch
    obj.msgout(sprintf('If writetable error, type ''which strjoin'' to check for conflict.\nMove MATLAB libraries to top of the path.'), 'step_error');
end
%objSaveFile = fullfile([saveFN '.mat']);
objSaveFile = fullfile([saveFN '.mat']);
obj.htpcfg.csvfile = csvfile;
arrayfun(@( s ) s.unloadDataset, sub, 'UniformOutput',false );
arrayfun(@( s ) s.setCsv( csvfile ), sub, 'UniformOutput',false );
arrayfun(@( s ) s.setMat( objSaveFile ), sub, 'UniformOutput',false );
arrayfun(@( s ) obj.update_htpcfg( s ), sub, 'UniformOutput',false );

filename = objSaveFile;
obj.htpcfg.fullauto.csvfile = csvfile;
obj.htpcfg.fullauto.matfile = objSaveFile;

save(objSaveFile, 'sub','-v7.3');

obj.msgout(sprintf('\nSTAGE %s COMPLETE\n', msg), 'step_complete');
obj.msgout(sprintf('\nTable of Results:\n%s\n', csvfile), 'step_complete');
obj.msgout(sprintf('\nFile of Data Objects:\n%s\n\n',objSaveFile), 'step_complete');

end

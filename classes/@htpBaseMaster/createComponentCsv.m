function filename = createComponentCsv(obj,sub)
%CREATECOMPONENTCSV Summary of this function goes here
%   Detailed explanation goes here
timetag    = datestr(now,'yymmddHHMM');
desc = 'Stage4';
userdesc = '_ComponentSelection_';
maxcomps = 24;
m=pop_selectcomps(s.EEG, 1:maxcomps);
pathdb = sub(1).pathdb;
saveFN = [pathdb.analysis 'A' timetag '_subjTable_' userdesc desc];

subjHeader = 1:length(sub);
tcell = {sub.log_subjRow};
for k = 1 : length(tcell)
    
    maxSize = max(cellfun(@numel, tcell));               % Get the maximum vector size
    if size(tcell{k},2) < maxSize
        
        tcell{k} = [tcell{k} cell(1, maxSize-numel(tcell{k}))];
        
    end
end

vertcat(tcell);

subjTable = cell2table(vertcat(tcell{:}));

%maxSize = max(cellfun(@numel, {sub.log_subjHeader}));
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

filename = objSaveFile;

obj.msgout(sprintf('\nFile of Component Data:\n%s\n\n',filename), 'step_complete');
end


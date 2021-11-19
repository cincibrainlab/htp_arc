function composeComponentCsv(obj,sub,pca_rank)
timetag    = datestr(now,'yymmddHHMM');
desc = 'Stage4';
userdesc = 'ComponentSelection_';
% sub(1).loadDataset('postcomps');
% pop_selectcomps(pop_runica(sub(1).EEG,'icatype','binica', 'extended',1,'interupt','on','pca',24),1:24);
pathdb = sub(1).pathdb;
saveFN = [pathdb.analysis 'A' timetag '_subjTable_' userdesc desc];
subject_title = 'Subject_';
for i=1:length(sub)
    subjHeader{i} = [subject_title num2str(i)];
end
component_title = 'Component ';
for i=1:24
    compHeader{i,1} = [component_title num2str(i)];
end

comp_SelectTable = cell2table(cell(size(compHeader,1),size(subjHeader,2)));
comp_SelectTable.Properties.RowNames = compHeader;
comp_SelectTable.Properties.VariableNames = subjHeader;

xlsxfile = fullfile([saveFN '.xlsx']);
try
    writetable(comp_SelectTable, xlsxfile, 'WriteRowNames', true);
catch
    obj.msgout(sprintf('If writetable error, type ''which strjoin'' to check for conflict.\nMove MATLAB libraries to top of the path.'), 'step_error');
end

filename = xlsxfile;

obj.msgout(sprintf('\nFile of Component Selection Data:\n%s\n\n',filename), 'step_complete');
end




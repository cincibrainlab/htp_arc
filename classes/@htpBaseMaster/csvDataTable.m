function obj = csvDataTable( obj, stage, action )
% save and load

% selecting objects by CSV
stage_last = stage;
stage_next = 'NA';

switch action
    
    case 'load'
        
        load(obj.htpcfg.matfile, 'sub');
        arrayfun(@(sub) sub.setCsv( obj.htpcfg.csvfile ), sub, 'UniformOutput',false );
        arrayfun(@(sub) sub.setMat( obj.htpcfg.matfile ), sub, 'UniformOutput',false );
        arrayfun(@(sub) sub.updatePaths( obj.htpcfg.basePath), sub, 'UniformOutput',false );
        
        for i = 1 : length(sub)
           
            sub(i).htpcfg = obj.htpcfg;
            
        end
        
       % arrayfun(@(x) x.htpcfg2sub , sub, 'UniformOutput',false );
        obj.sub = arrayfun(@(x) x.outputRow(stage_last), sub);
        obj.createResultsCsv(obj.sub, stage_last, 'same');
        obj.dataTable = readtable(obj.htpcfg.csvfile);
        obj.sub = sub;
        
        %obj.include_all_subjects('yes');
        % arrayfun(@(x) x.exclude_subject( 'no' ), sub, 'UniformOutput',false );
        
    case 'save'
        
        proc_stage_idx = find(strcmp('proc_state', obj.sub(1).log_subjHeader));
        new_proc_state_idx = find(strcmp('proc_state', obj.dataTable.Properties.VariableNames));        
        
        for i = 1 : length( obj.sub )
                       
            obj.sub(i).proc_state = char(obj.dataTable{i, new_proc_state_idx});
                    
        end
        
        arrayfun(@(x) x.outputRow(stage_last), obj.sub);
        try
        prompt = {'Create a suffix for this new dataset?'};
            dlgtitle = 'Input';
            dims = [1 35];
            definput = {'new_subset'};
            answer = char(inputdlg(prompt,dlgtitle,dims,definput));
        catch
            answer = 'new_subset';
        end
        
        obj.createResultsCsv(obj.sub, stage_last, answer );
        
        
        
        
        
end


% %
% %             [csvfile, matfile, pathdb] = obj.getStageCSV( stage_last, obj.htpcfg.basePath);
% %             objStageStatus = find(obj.selectObjects(stage_last, csvfile)); % current stage
% %             objStageStatus_completed = find(obj.selectObjects(stage_next, csvfile)); % completed
% %  % csvtable = readtable(obj.htpcfg.csvfile);
%
%             % update bad files
%             totalIdx = {sub.proc_state};
%           %  badIdx = obj.selectObjects(stage_last, csvfile);
%
%             %[sub(~badIdx).proc_state] = deal('BAD');
%
%            % csvtable = readtable(obj.htpcfg.csvfile);
%
%             dataT = cell2table(vertcat(sub(:).log_subjRow));
%             dataT.Properties.VariableNames = sub(1).log_subjHeader;
%
%             obj.dataTable = dataT;
%
%             obj.sub = sub;

%            end

end
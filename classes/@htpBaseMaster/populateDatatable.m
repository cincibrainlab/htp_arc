function obj = populateDatatable( obj, stage )
            
            
            
            % selecting objects by CSV
            stage_last = stage; 
            stage_next = 'NA';
            
            if strcmp(stage_last, 'No Stages')
                obj.msgout('No stages available to load', 'step_warning');
                return;
            else
                
%             
%             [csvfile, matfile, pathdb] = obj.getStageCSV( stage_last, obj.htpcfg.basePath);
%             objStageStatus = find(obj.selectObjects(stage_last, csvfile)); % current stage
%             objStageStatus_completed = find(obj.selectObjects(stage_next, csvfile)); % completed
%             
%             
            pathDb = obj.htpcfg.pathdb;
            
            %htpcfg2sub
            
            % Load subject objects
            load(obj.htpcfg.matfile, 'sub');
            arrayfun(@(sub) sub.setCsv( obj.htpcfg.csvfile ), sub, 'UniformOutput',false );
            arrayfun(@(sub) sub.setMat( obj.htpcfg.matfile ), sub, 'UniformOutput',false );
            arrayfun(@(sub) sub.updatePaths( obj.htpcfg.basePath), sub, 'UniformOutput',false );

            %obj.include_all_subjects('yes');
            arrayfun(@(x) x.exclude_subject( 'no' ), sub, 'UniformOutput',false );
            
            % update bad files
            totalIdx = {sub.proc_state};
          %  badIdx = obj.selectObjects(stage_last, csvfile);
            
            %[sub(~badIdx).proc_state] = deal('BAD');
            for i = 1:length(sub), sub(i).outputRow(stage_last); end
            
   
            dataT = cell2table(vertcat(sub(:).log_subjRow));
            dataT.Properties.VariableNames = sub(1).log_subjHeader;
            
            obj.dataTable = dataT;
            
            obj.sub = sub;
            
            end
            
        end
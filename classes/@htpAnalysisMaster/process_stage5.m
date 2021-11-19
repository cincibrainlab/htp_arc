function obj = process_stage5( obj, instruction )

[mc, mm, mw] = obj.tools_log;

mm('\nStarting Stage 5: Subject-Level Analysis (Level1)');

stage_last = 'postcomps';
stage_next = 'level1';

%obj.sub = obj.loadSub( stage_last );
opt     = obj.formatOptions;

arrayfun(@( s ) s.setopt( opt ), obj.sub, 'uni', 0);


objStageStatus              = obj.htpcfg.objStageStatus;
objStageStatus_completed    = obj.htpcfg.objStageStatus_completed;


htpcfg = obj.htpcfg;
mm(sprintf('\nCurrent Data Directory: %s\n\n', htpcfg.basePath'));

prev_files = 0; skip_files = 0; errorchk = 0;

for i = 1 : length(obj.sub)
    
    s = obj.sub(i);
    
    switch instruction
        
        case 1 %'tf_power'
            
            s.setFreqTable();
            s.getPntsTable;
            s.generateStoreRoom;
            s.bandAverageTrials;
            
    end
    
    obj.sub(i) = s;
    

end
function sub = mergeSubjects( sub )

for i = 1 : length( sub )
    filelist{i} = fullfile(sub(i).pathdb.import, sub(i).subj_subfolder, sub(i).filename.import);
end

sub_number = length( sub );

uniSub = cell(sub_number, 2);

for i = 1 : sub_number
    
    uniSub{i,1} = sub(i).proc_merge.subId;
    uniSub{i,2} = sub(i).proc_merge.partId;
    uniSub{i,3} = sub(i).proc_merge.fileId;
    uniSub{i,4} = sub(i).subj_basename;
end

uniSubArr = unique(uniSub(:,1));
uniPartArr = strcmp('1',uniSub(:,2));

savedSub = sub(uniPartArr);

for i = 1 : sub_number
    
    n = str2double(uniSub{i,1});
    subid = str2double(sub(i).proc_merge.subId);
    partid = str2double(sub(i).proc_merge.partId);
    
    savedSub( n ).proc_merge.EEG2{ partid } = filelist{i};
    
    fprintf('File: %s \t Sub: %d\tPart: %d\tRaw:%s\n', ...
        sub(i).subj_basename,   str2double(sub(i).proc_merge.subId), ...
        str2double(sub(i).proc_merge.partId), filelist{i});
    %str2double(sub(i).proc_merge.partId)
    
end

for i = 1 : length( savedSub )
    
    fprintf('File: %s \t Parts: %d\n', savedSub(i).subj_basename, ...
        length( savedSub( i ).proc_merge.EEG2 ));
    
end

for i = 1 : length( savedSub )
    fprintf('set: %d %s\n', i, savedSub(i).subj_basename);
    
    % CLEAR CURRENT DATASETS
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
    
    number_of_parts = length( savedSub( i ).proc_merge.EEG2 );
    
    if number_of_parts > 1
        
        for j = 1 : number_of_parts
            
            fprintf('loading: %s\n', savedSub( i ).proc_merge.EEG2{j});
            
            set_list = [savedSub( i ).proc_merge.EEG2];
            
        end
        
        for dset = set_list
            % Load single dataset
            EEG = pop_loadset( dset{1} );
            % Store current dataset
            [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
            
            % "check" dataset
            EEG = eeg_checkset( EEG );
        end
        
        % EEGLAB Merge command for all datasets (dynamic)
        EEG = pop_mergeset( ALLEEG, [ 1:length(set_list) ], 0);
        savedSub(i).EEG = eeg_checkset( EEG );
        savedSub(i).proc_xmax_raw = EEG.xmax;
        
        
        mrgStr = length(savedSub( i ).proc_merge.EEG2);
        
    else
        
        fprintf('loading: %s\n', savedSub( i ).proc_merge.EEG2{1});
        
        set_list = [savedSub( i ).proc_merge.EEG2];
        
        for dset = set_list
            % Load single dataset
            EEG = pop_loadset( dset{1} );
            % Store current dataset
            [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
            
            % "check" dataset
            EEG = eeg_checkset( EEG );
        end
        savedSub(i).EEG = eeg_checkset( EEG );
        savedSub(i).proc_xmax_raw = EEG.xmax;
        mrgStr = length(savedSub( i ).proc_merge.EEG2);
        
    end
    
    savedSub(i).subj_basename = [savedSub(i).subj_basename '_' genvarname(num2str(mrgStr)) '_'];
    
    fprintf('\n');
    
    
end

sub = savedSub;



end
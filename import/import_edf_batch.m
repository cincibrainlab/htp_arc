% Coded 5/4/2020 by Kyle Cullion
% Adapted from edfreadUntilDone.m coded by Brett Shoelson, PHD

function import_edf_batch(basePath, outputPath, stage)
file_struct_list = dir([basePath filesep() '*.edf']);
config = eegDataClass();
config.createPaths(outputPath);
if ~isempty(file_struct_list)
    filename_list = {file_struct_list.name};
    headerOutput=cell(1,length(filename_list));
    recordOutput = cell(1,length(filename_list));
    for p=1:length(filename_list)
        sub(p) = eegDataClass();
        sub(p).pathdb = config.pathdb;
        sub(p).pathCellArr = config.pathCellArr;
    end
    [~,subfolder] = fileparts(basePath);
    for p=1:length(filename_list)
        [ headerOutput{p}, recordOutput{p} ]=read_record(basePath,filename_list{p});
        sub(p).EEG = eeg_emptyset;
        sub(p).EEG.data = recordOutput{p};
        sub(p).EEG.pnts = size(sub(p).EEG.data,2);
        sub(p).EEG.nbchan = length(headerOutput{p}.labels);
        sub(p).EEG.srate = headerOutput{p}.samplingRate(1);
        sub(p).EEG = eeg_checkset(sub(p).EEG);
        sub(p).EEG = eeg_checkchanlocs(sub(p).EEG);
        sub(p).net_nbchan_orig =  sub(p).EEG.nbchan;
        sub(p).proc_sRate_raw = sub(p).EEG.srate;
        sub(p).proc_xmax_raw = sub(p).EEG.xmax; 
        sub(p).proc_state =stage;
        sub(p).subj_subfolder = subfolder;
        %pop_saveset(sub(p).EEG, 'filename',[extractBefore(filename_list{p},'.') '_rest_postcomp_'], 'filepath', outputPath);
        sub(p).outputRow(stage);
    end
    obj = htpPreprocessMaster();
    createResultsCsv(obj, sub,stage, 'Default');
    clear sub;
    clear obj;
else
    disp('Ensure that the directory you provided is the correct directory. \n No edf files were found\n');
end


function [ headerRecord, record ]=read_record(path,file)
    headerRecord = struct; 
    [fileID, message] = fopen(fullfile(path,file));
    headerRecord.version = sscanf(fread(fileID,8,'*char'),'%f')';
    headerRecord.patientID = fread(fileID,80,'*char')';
    headerRecord.recordID = fread(fileID,80,'*char')';
    headerRecord.startDate = fread(fileID,8,'*char')';
    headerRecord.startTime = fread(fileID,8,'*char')';
    headerRecord.bytes = sscanf(fread(fileID,8,'*char')','%f');
    reservedData = fread(fileID,44);
    headerRecord.numRecords = sscanf(fread(fileID,8,'*char')','%f');
    headerRecord.duration = sscanf(fread(fileID, 8,'*char'),'%f')';
    headerRecord.numSignals = sscanf(fread(fileID,4,'*char')','%f');
    if headerRecord.numSignals > 0
        headerRecord.labels = split(deblank(fread(fileID,16*headerRecord.numSignals,'*char')'))';
        for signal = 1:headerRecord.numSignals
            headerRecord.transducerType{signal} = fread(fileID,80,'*char');
        end
        %headerRecord.physicalDimension = split(deblank(fread(fileID,8*headerRecord.numSignals,'*char')'))';
        for signal = 1:headerRecord.numSignals
            headerRecord.physicalDimension{signal} = fread(fileID,8,'*char')';
        end
        for signal = 1:headerRecord.numSignals
            headerRecord.physicalMinimum(signal) = str2double(fread(fileID,8,'*char')');
        end
        %headerRecord.physicalMinimum = sscanf(fread(fileID,8*(headerRecord.numSignals),'*char'),'%f')';
        %headerRecord.physicalMaximum = sscanf(fread(fileID,8*headerRecord.numSignals,'*char')','%f');
        for signal = 1:headerRecord.numSignals
            headerRecord.physicalMaximum(signal) = str2double(fread(fileID,8,'*char')');
        end
        headerRecord.digitalMinimum = sscanf(fread(fileID,8*headerRecord.numSignals,'*char')','%f')';
        headerRecord.digitalMaximum = sscanf(fread(fileID,8*headerRecord.numSignals,'*char')','%f')';
        for signal = 1:headerRecord.numSignals    
            headerRecord.prefiltering{signal} = fread(fileID,80,'*char');
        end
        headerRecord.numSamples = sscanf(fread(fileID,8*headerRecord.numSignals,'*char'),'%f')';
        signalReserved = (fread(fileID,32*headerRecord.numSignals,'*char')')';
    end
    headerRecord.samplingRate = headerRecord.numSamples ./ headerRecord.duration;
    intermediateData = struct;
    gainScalingFactor = (headerRecord.physicalMaximum - headerRecord.physicalMinimum)./(headerRecord.digitalMaximum - headerRecord.digitalMinimum);
	dataExists = true;
    dc = headerRecord.physicalMaximum - gainScalingFactor .* headerRecord.digitalMaximum;
    for recordNumber = 1:headerRecord.numRecords
        if ~(dataExists)
            break
        end
        for i = 1:headerRecord.numSignals
            sampleData = fread(fileID,headerRecord.numSamples(i),'int16')*gainScalingFactor(i) + dc(i);
            %sampleData = fread(fileID,headerRecord.numSamples(i),'int16');
            if isempty(sampleData)
                dataExists = false;
                headerRecord.numRecords = recordNumber-1;
                break
            else
                intermediateData(recordNumber).data{i} = sampleData;
            end
        end
    end
    record = zeros(numel(headerRecord.labels), headerRecord.numSamples(1)*headerRecord.numRecords);
	recordNumber = 1;
	for i = 1:headerRecord.numSignals
			sampleIndex = 1;
			for j = 1:headerRecord.numRecords
				record(recordNumber, sampleIndex : sampleIndex + headerRecord.numSamples(i) - 1) = intermediateData(j).data{i};
				sampleIndex = sampleIndex + headerRecord.numSamples(i);
			end
			recordNumber = recordNumber + 1;
    end
    fclose(fileID);
end
end


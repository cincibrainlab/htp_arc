% Created 5/4/2020 by Kyle Cullion
% Adapted from edfreadUntilDone.m coded by Brett Shoelson, PHD

function [headerRecord,record] = import_edf(file)
    headerRecord = struct; 
    [fileID, ~] = fopen(file);
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
        headerRecord.digitalMaximum = sscanf(fread(fileID,8*headerRecord.numSignals,'*char'),'%f')';
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


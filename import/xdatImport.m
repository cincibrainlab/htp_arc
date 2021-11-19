function [signalStruct,timeRange,jsonData] = xdatImport(xdat_filename)
    x=allegoXDatFileReaderR2018a();
    timeRange = x.getAllegoXDatTimeRange(xdat_filename);
    signalStruct.PriSigs = x.getAllegoXDatPriSigs(xdat_filename,timeRange);
%     signalStruct.AuxSigs = x.getAllegoXDatAuxSigs(xdat_filename,timeRange);
%     signalStruct.DinSigs = x.getAllegoXDatDinSigs(xdat_filename,timeRange);
%     signalStruct.DoutSigs = x.getAllegoXDatDoutSigs(xdat_filename,timeRange);
%     signalStruct.AllSigs = x.getAllegoXDatAllSigs(xdat_filename,timeRange);
    str = fileread([xdat_filename '.xdat.json']); % dedicated for reading files as text
    jsonData = jsondecode(str);
    clear x;
    clear str;
end


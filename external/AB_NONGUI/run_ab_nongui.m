Parameters.Approach = 'Window';

Parameters.Threshold = 100;
Parameters.Fs = 512;
fprintf('Reffer to Line 11 and enter the address of the file you wish to read\nSimilarly reffer to Line 35 for the output file');
fprintf('\nIMPORTANT NOTE:If you have any channels of zeros only,mention them to the programm.Look at the example on line 16 and follow a similar manner.');

%//////////
% get some data, put FirstSamp to 1, LastSamp to datapoints, data in InData
    %Parameters.FirstSamp = 1;
    infile = 'C:\code\test\Random_Scripts\Arc\Test_Cooling\Output_Cooling_Files\Bin_1_Cooling.set';
    eegdata = read_eep_cnt(infile,1,2);  %reading the EEG data

    datapoints = eegdata.nsample;
    eegdata = read_eep_cnt(infile,1,datapoints);  %reading the EEG data
    eegdata.data(129,:) = [];                      % last channels seems to be all zeros
    %eegdata.data(127,:) = [];      % add more similar lines if there are
                                    % multiple such cases
    eegdata.nchan = size(eegdata.data,1);        %updates 


    Parameters.InData = eegdata.data;       % data should be channels by points
    
% end of setting up input data

%///////////////////

Parameters = Run_AB(Parameters);



% deblocked data will be in Parameters.OutData

% write the data out.
outfile = 'C:\Users\Dorsa\Desktop\AB-Dorsa\EEG_data\4AB.cnt';
eegdata.data = Parameters.OutData;
disp(['Writing the clean data into the output file: (' outfile ') ...\n']);
write_eep_cnt(outfile, eegdata);
fprintf('Done. \n')
% clear eegp

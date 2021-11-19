%% Clean Raw Data Class
%%% Methods:
%%% Usage
% param = CleanRawDataClass.CleanRawDataInit()
%
% The input is empty since the method called sets the default values 
% for the param property of the class.  The output is the param property 
% with the updated default values  
%
%
% [ EEG ] = CleanRawDataClass.cleanRawData(EEG, param) 
%
% The input is EEG and param where EEG is the EEG structure of the
% htpPreprocessMaster object and param is a struct with the parameters used
% to guide the cleaning process of the raw data.  The output is the
% updated EEG struct with the cleaned raw data.
%
%
% Copyright © 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP), see 
% https://bitbucket.org/eped1745/htp_stable/src/master/
% Contact: ernest.pedapati@cchmc.org

classdef CleanRawDataClass
    properties
        param
    end
    
    methods (Static)
        %Specific default initialization parameters to guide the cleaning process of the 
        %raw input EEG data.
        function param = CleanRawDataInit()
            
            param.arg_flatline  = 5;
            param.arg_highpass  = [0.25 0.75];
            param.arg_channel   = 0.85;
            param.arg_noisy     = 4;
            param.arg_burst     = 20;
            param.arg_window    = 0.25;
            
        end
        
        %Count channels with locations while avoiding EOG
        %because weighted functions will crash otherwise.
        %Create 2 vectors for candidate channels as well as
        %create backup of original channels pre-cleaning of raw data
        %just to have in case cleaning procedure errors out.
        %Performs necessary cleaning on the raw data to remove flatline
        %channels, low-frequency drifts, noisy channels, and incomplete
        %segments
        function EEG = cleanRawData( EEG, param )
            
            %EEG = clean_rawdata(EEG, 5, -1, 0.85, 4, 20, 0.25);
            
            chan_w_locs = length(find([EEG.chanlocs(:).X]));
            
            vchan        = 1 : EEG.nbchan;
            vchan_w_locs = 1 : chan_w_locs;
            
            originalEEG = EEG;
            originalEEG.data = [];
            
            try
                EEG = clean_rawdata(EEG, ...
                    param.arg_flatline, param.arg_highpass, ...
                    param.arg_channel, param.arg_noisy, ...
                    param.arg_burst, param.arg_window);
            catch
                disp('Error in Channel Cleaning');
            end
            
            EEG = pop_interp(EEG, originalEEG.chanlocs, 'spherical');           
            
        end
        
        
        
    end
    
    methods
        function obj = CleanRawDataClass
            
        end
        
        
    end
end


%% Log Message
%%% Usage
% obj = lm( obj, inputStr )
%
%%% Parameters
%
% * INPUTS: obj, inputStr
%
% * OUTPUTS: obj
%
% The input parameter is a string represeting the log message to be added
% to the htpPreprocessMaster object's log and the second optional input
% parameter if the function is not self-invoked obj is an 
% htpPreProcessMaster.  The output, if not self-invoked, is the htpPreprocessMaster
% object with its log updated. 
%
%%% Copyright and Contact Information
%
% Copyright © 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP) 
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org


%% lm
% Officially appending the current logged message to the analysis object's log
% related attributes for future inspection
% and relaying the output to the user for notification. 
function  obj = lm( obj, inputStr )

obj.turnOffWarnings;

datetime.setDefaultFormats('default','MMddyy hh:mm');

obj.outStr = inputStr;
% log messages
%outStr = sprintf('%s\n%s (%s)\t%s' , obj.outStr, datetime, obj.msgtype, inputStr);
if strcmp('step_msg', obj.msgtype)
    obj.outStr = sprintf('\n\t\t%s' ,  inputStr);
else
    obj.outStr = sprintf('\n%s (%s)\t%s' ,  datetime, obj.msgtype, inputStr);
end
%obj.outStr = outStr;
try
    obj.htpcfg.logfile_id = fopen(fullfile(obj.htpcfg.scriptPath, 'local/logfiles/', obj.htpcfg.logfile),'a');
    fprintf(obj.htpcfg.logfile_id, obj.outStr);
    fprintf('%s',obj.outStr);
    
    fclose(obj.htpcfg.logfile_id);
catch
    fprintf('Check MATLAB working directory. No access to log files');
    %error('Check MATLAB working directory. No access to log files');
end


end
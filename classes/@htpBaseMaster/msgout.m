%% Message Out
%%% Usage
%    
% obj = msgout( obj, str, varargin )
%
%%% Parameters
%
% * INPUTS: obj, str, varargin
%
% * OUTPUTS: obj
%
% The input parameter str is the message that the user wants to append to 
% the log.  The second input parameter of varargin is the string 
% corresponding to the message type of the appended message.  The third 
% optional parameter if the function is not self_invoked is obj which is 
% an htpPreprocessMaster object.  The output, if the function is not self-invoked, is the 
% htpPreprocessMaster object that was passed in with the log updated with 
% the input message.
%
%%% Copyright and Contact Information
%
% Copyright (C) 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
%
% Contact: ernest.pedapati@cchmc.org

%% msgout
% Relay message to command console to alert user as to 
% whether their processing event produced a successful run, errored out, or
% completed yet possibly not as expected, so they can act accordingly to the output.
function obj = msgout( obj, str, varargin) 

if nargin > 2
    msgtype = varargin{1};
else
    msgtype = 'step_msg';
end

obj.msg = str;

switch msgtype
    
    case 'step_error'
        %obj.lm(obj.msg);
        %obj.htpcfg.logger.error('obj.msgout',sprintf('step_error: %s',obj.msg));
        notify( obj, 'step_error' );
        obj.msgtype = 'Error';
        obj.msglog.err{end+1} = obj.msg;
        error('%s', obj.msg);
        obj.htpcfg.logger.error('obj.msgout',obj.msg);
    case 'step_warning'
        notify( obj, 'step_warning' )
        obj.msgtype = 'Warning';
        obj.msglog.war{end+1} = obj.msg;
        obj.htpcfg.logger.warn('obj.msgout',obj.msg);
        
    case 'step_msg'
        notify(obj, 'step_msg');
        obj.msgtype = 'step_msg';
        obj.msglog.msg{end+1} = obj.msg;
        obj.htpcfg.logger.info('obj.msgout',obj.msg);
    case 'step_complete'
        notify(obj, 'step_complete');
        obj.msgtype = 'Complete';
        obj.msglog.com{end+1} = obj.msg;
        obj.htpcfg.logger.info('obj.msgout',obj.msg);
    otherwise
        notify(obj, 'step_msg');
        obj.msgtype = 'step_msg';
        obj.msglog.msg{end+1} = obj.msg;
        obj.htpcfg.logger.info('obj.msgout',obj.msg);
end


%obj.htpcfg.logger.info('obj.msgout',sprintf(' %s',obj.msg));

end
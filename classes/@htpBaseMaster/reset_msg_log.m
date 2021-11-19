%% Reset Message Log 
%%% Usage
% o = reset_msg_log( o )
%
%%% Parameters
%
% * INPUTS: o
%
% * OUTPUTS: o
%
% The optional input parameter if the function is not self-invoked o is
% an htpPreprocessMaster object.  The output is just the 
% htpPreprocessMaster object with the related message log attributes
% reset and initiated. 
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

%% reset_msg_log
% Initalize message logs to be used throughout preprocessing
% to alert the user via general messages, stage messages, warning messages,
% and error messages.
function o = reset_msg_log( o )

o.msglog.msg = {'***** MESSAGE LOG ******'};
o.msglog.war = {'***** WARNING LOG ******'};
o.msglog.err = {'***** ERROR LOG *******'};
o.msglog.com = {'***** STAGE LOG *******'};

end
%% Count Strings
%%% Usage
% str = countStrings( cellArrIn )
%
%%% Parameters
% * INPUTS: cellArrIn
%
% * OUTPUTS: str
%
% The function is invoked via an htpPreprocessMaster and the input parameter is a cell array represeting the subjects respective 
% study group folder.  The output is a character array that is composed of 
% text of the groups and their subject count. 
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

%% countStrings
% Provide the seperated groups of the study and the number of subjects
% that belong to each group and the number of subjects per group will be 
% counted and displayed via command console to allow user to understand the
% breakdown of the study subjects.
function str = countStrings( cellArrIn )

xx = cellArrIn;

a=unique(xx,'stable');
b=cellfun(@(x) sum(ismember(xx,x)),a,'un',0);
cell2table([a;b]', 'VariableNames', {'Group', 'Count'});

str = sprintf('\nstudyStructUtilities: CountGroups\n');

for i = 1 : length( a )
    str = [str  sprintf('\t%s Count: %d\n', a{i}, b{i})];
end
        
end
function objectIdx = selectObjects( stage, csvfile )

if nargin < 2
    cprintf('*blue', '\n\nFunction: objectIdx = selectObjects( stage, csvfile)\n');
    cprintf('blue', 'Output: Logical array meeting stage criteria\n');
    cprintf('blue', 'Input 1: desired stage\n');
    cprintf('blue', 'Input 2: CSV file created by scripts\n\n');    
    cprintf('blue', 'Desc: Select Objects using CSV file criteria.\n');
    cprintf('blue', 'Desc: Edit the CSV file to put any file to repeat a stage.\n');
    cprintf('blue', '\nStage Options:\n');
    cprintf('blue', '''raw'': N/A (filelist created by directory)\n');
    cprintf('blue', '''import'': ready for stage 2\n');
    cprintf('blue', '''preica'': ready for stage 3\n');
    cprintf('blue', '''postica'': ready for stage 4\n');
    cprintf('blue', '''postcomps'': ready for stage 5\n');
    
    cprintf('blue', '\n');
    
    return;
end

switch stage
    
    
    case 'import'
        searchStr = 'Import';
        
    case 'preica'
        searchStr = 'PreICA';
        
    case 'postica'
        searchStr = 'PostICA';
        
    case 'postcomps'
        searchStr = 'postcomps';
        
    case 'level1'
        searchStr = 'Level1';

        
end

T = readtable( csvfile );
TC = table2cell(T);
TC_Header = T.Properties.VariableNames;

idxState = strcmp(TC_Header(1,:), 'proc_state');
% numerical index, not used
objectIdx2 = find(strcmp(TC(:, idxState),searchStr));

% logical index (can be inverted)
objectIdx = strcmp(TC(:, idxState),searchStr);

end
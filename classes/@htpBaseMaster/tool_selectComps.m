%% Tool to Select Comps
%
%%% Usage
%    
% s = tool_selectComps( obj, s, stage )
%
%%% Parameters
%
% * INPUTS: obj, s, stage
%
% * OUTPUTS: s
%
% The input parameters are s which is a subject object (RestEegDataClass object), 
% stage is the string representing the next stage of preprocessing and 
% obj is the htpPreprocessMaster object that is passed in if the function
% is not self-invoked.  There is no output, instead the subject, input s parameter, is saved to the 
% designated preica file directory.
% 
%%% Copyright and Contact Information
% Copyright (C) 2019  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% tool_selectComps
% Generate a user-specified number of components to
% inspect and select for exclusion by the user.  Along with the
% topographical plots generated for each component, the user can view the
% time series for the components, and individualized windows of information such
% as power spectrum and dipole location to guide the exclusion process.
% After selecting one, or multiple, components to reject, the user is
% presented with the same process for the next subject and this continues
% until completion for all subjects to complete the stage of preprocessing.
function s = tool_selectComps( obj, s)

scsize      = obj.htpcfg.screensize;
sc_height   = scsize(4);
sc_width    = scsize(3);

main_height = (sc_height / 3) / sc_height;
user_height = (sc_height / 6) / sc_height ;

main_width = (sc_width / 5) / sc_width;
user_width = (sc_width / 6) / sc_width;

maxcomps = 24;

% Open component topoplot, 20 components
if maxcomps<=length(s.EEG.icachansind)
    pop_selectcomps(s.EEG, 1:maxcomps);
else
    maxcomps = size(s.EEG.icaweights,1);
    pop_selectcomps(s.EEG, 1:maxcomps);
end

h.tp = gcf;
h.tp.Units = 'norm';
h.tp.Position = [sc_width/200/sc_width .5 main_width main_height];

%    h.tp.OuterPosition = [100 50 700 700];

%  p = uipanel(h.tp,'Title','Component Selection Tool',...
%     'Position',[.40 .1 .55 .22]);
% test = figure;
p = figure('Name','Component Selection Tool',...
    'Position',[800 300 400 200], ...
    'MenuBar', 'none');

p.Units = 'norm';
p.Position =  [sc_width/200/sc_width  0.3 user_width user_height];

strStatus = sprintf('(%d of %d): %s', s.subj_id(1), s.subj_id(2), s.subj_basename);

title = uicontrol(p,'Style','text',...
    'String', strStatus,...
    'FontSize', 10,...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', [1 1 1], 'ForegroundColor', [0 0 0], ...
    'Position',[0.05 0.8 0.9 0.15]);
% delete(title)

b1 = uicontrol(p,'Style','pushbutton','String','Save Components',...
    'Units','normalized',...
    'UserData', s, ...
    'Callback',@b1_callback, ...
    'BackgroundColor', [0 1 0], ...
    'Position',[.6 0.05 .35 .25]);

t1 = uicontrol(p,'Style','edit',...
    'tag', 'comp_entry', ...
    'String','',...
    'Max',1,'Min',0,...
    'Units', 'normalized', ...
    'Position',[0.6 0.34 0.35 .30]);

b2 = uicontrol(p,'Style','pushbutton','String','C. Detail',...
    'Units','normalized',...
    'UserData', s, ...
    'Callback', @b2_callback, ...
    'Position',[.05 0.05 .20 .25]);
%        delete(bguess)
bguess = uicontrol(p,'Style','pushbutton','String','ICView Guess',...
    'Units','normalized',...
    'UserData', s, ...
    'Callback', @bguess_callback, ...
    'Position',[0.6 0.65 0.35 0.10]);


excludeStatus = s.get_exclude_switch;
% global excludeButton;
excludeButton = uicontrol(p,'Style','pushbutton','String','Exclude Sub',...
    'Units','normalized',...
    'UserData', s, ...
    'Tag', 'exbutton', ...
    'Callback', @ex_callback, ...
    'BackgroundColor', [0 1 0], ...
    'Position',[.30 0.36 .25 .25]);

if excludeStatus == 1
    excludeButton.Value = 1;
    excludeButton.BackgroundColor = [1 0 0];
    
else
    excludeButton.Value = 0;
    
    excludeButton.BackgroundColor = [0 1 0];
end


closebtn = findobj('tag', 'Set thresholds', 'parent', h.tp);

UIButtonArr = findobj(h.tp, 'Type', 'UIControl');
OriginalButtons = findobj(UIButtonArr, 'BackgroundColor', '[0.6600 0.7600 1]');
for button_i = 1 : length(OriginalButtons), OriginalButtons(button_i).Visible = 'off'; end
% UI = findobj(UIButtonArr, 'String', 'OK');

% okbutton.Visible = 'off';

% loop with comp number

for ri = 1 : maxcomps
    
    chbutton = findobj('tag', ['comp' num2str(ri)], 'Parent', h.tp);
    %disp(chbutton);
    chbutton.UserData = {s, ri};
    chbutton.Callback = @prop_extended;
    %chbutton.Callback = ['pop_prop_extended( s.EEG, 0,' num2str(ri) ')']';
    
end

%  delete(t2)
t2 = uicontrol(p,'Style','edit',...
    'tag', 'comp_entry2', ...
    'String','',...
    'Max',1,'Min',0,...
    'Units', 'normalized', ...
    'Position',[0.05 0.34 0.20 0.30]);

b3 = uicontrol(p,'Style','pushbutton','String','ICLABEL',...
    'Units','normalized',...
    'UserData', s, ...
    'Callback', @b3_callback, ...
    'Position',[.35 0.05 .20 .25]);
b4 = uicontrol('tag', 'qualitylabel', 'Style', 'text', ...
    'Units', 'norm', 'Position', [0.4 0.01 0.55 0.09]);
x=5;
box_title = 'Data Quality : Included';

set(b4,'string', sprintf('%s', box_title));


% Open component time series
pop_eegplot( s.EEG, 0, 1, 1);
h.ep = gcf;
h.ep.Units = 'norm';

h.ep.Position = [ main_width*1.05 .5 main_width main_height];


g = h.ep.UserData;

% adjust default spacing/zoom
ESpacing = findobj('tag','ESpacing','parent', h.ep);
ESpacing.String = 50;
eegplot('draws',0);

% adjust default number of epochs & components shown
g.winlength = 10;
g.dispchans = 10;

if g.dispchans < 0 || g.dispchans > g.chans
    g.dispchans = g.chans;
end

set(h.ep, 'UserData', g);
eegplot('updateslider', h.ep);
eegplot('drawp',0);
eegplot('scaleeye', [], h.ep);

% draw amplitude time series

cdef = {'g','b'};
carr = repmat(cdef,1, size(s.EEG.data,1));
carr = carr(1:size(s.EEG.data, 1));
carr(s.proc_autobadchannel) = {'r'};

eegplot(s.EEG.data,'srate',s.EEG.srate,'winlength',10, ...
    'plottitle', ['View Time Series: ' s.subj_basename], ...
    'events',s.EEG.event,'color',carr,'wincolor',[1 0.5 0.5], ...
    'eloc_file',s.EEG.chanlocs,  'butlabel', 'Close Window', 'submean', 'on', ...
    'command', 't = 1', 'position', [400 400 1024 768] ...
    );

ts.ep = gcf;
ts.ep.Units = 'norm';

ts.ep.Position = h.ep.Position;
ts.ep.Position(2) = ts.ep.Position(2) - 0.28;
ts.ep.Position(3) = ts.ep.Position(3) - 0.02;
ts.ep.Position(4) = ts.ep.Position(4) - 0.1;

allui = {p, h.tp, h.ep, ts.ep};

for mi = 1 : length(allui)
    allui{mi}.Position(2) = allui{mi}.Position(2) * 1.20;
    % allui{mi}.Position(1) = allui{mi}.Position(1) * 1.20;
    allui{mi}.Tag = 'selectcomps';
end

position_factor = [];

uiwait(h.ep);

s.proc_state = 'postcomps';

    function prop_extended( src, event)
        
        s = src.UserData{1};
        ri = src.UserData{2};
        pop_prop_extended( s.EEG, 0, ri,  NaN, {'freqrange', [0 55]});
        
    end
    
    %Callback function for the exclusion button
    function ex_callback(src, event)
        % get subject exclude status (default 0 = not excluded)
        s = src.UserData;
        exstatus = s.get_exclude_switch;
        
        % get handle for button
        % comps = findobj('tag', 'exbutton');
        comps = src;
        % change button based on exstatus
        switch exstatus
            case 0
                s.exclude_subject( 'yes' );
                set(comps, 'String', 'Include Subject')
                comps.BackgroundColor = [1 0 0];
                list = obj.xml_exclude;
                [indx,tf] = listdlg('ListString',list);
                s.exclude_category = list(indx)';
                str = [list(indx)'];
            case 1
                s.exclude_subject('no');
                set(comps, 'String', 'Exclude Subject')
                comps.BackgroundColor = [0 1 0];
                s.exclude_category = [];
                str = 'Quality Sufficient';
        end
        
        b4  = findobj('tag', 'qualitylabel');
        b4.String  = str;
        
        
    end

    %% bguess_callback
    %Callback function for generated component topographical plot window
    function bguess_callback(src, event)
        
        
        threshold = 0.75;
        %range = 1:24;
        range = 1:maxcomps;
        
        get_ic = @(x) s.get_icview_comps(x, threshold, range);
        
        comps_artifact = [get_ic('Eye') get_ic('Heart') get_ic('Muscle') get_ic('Line Noise') get_ic('Channel Noise')];
        
        try
            h_comp_entry = findobj(p, 'Type', 'UIControl', 'tag', 'comp_entry');
            
            h_comp_entry.String = num2str(comps_artifact);
            
        catch
            
        end
        
        
    end

    %% b2_callback
    %Callback function for detail button to get component specific
    %information such as power spectrum, EVP, diploe location, etc.
    function b2_callback(src, event)
        
        comps = findobj('tag', 'comp_entry2');
        
        EEG = src.UserData.EEG;
        
        % pop_prop( EEG , 0, str2num(comps.String), NaN, {'freqrange' [2 50] });
        
        pop_prop_extended( EEG, 0, str2num(comps.String), NaN, {'freqrange', [0 55]});
        
        %pop_selectcomps(src.UserData.EEG);
        
    end

    %% b3_callback
    % Callback function to handle the ICLABEL button which allows the view
    % of many components and channels as well as set the spectral options of
    % the component topographical plots
    function b3_callback(src, event)
        
        comps = findobj('tag', 'comp_entry2');
        
        EEG = src.UserData.EEG;
        
        EEG = pop_iclabel(EEG);
        
        pop_viewprops( EEG, 0 );
        
        src.UserData.EEG = EEG;
        
        %pop_selectcomps(src.UserData.EEG);
        
    end

    %% b1_callback
    % Callback function for save component button
    % which allows the user to save their selected components for further
    % analysis in the post processing stages
    function b1_callback(src, event)
        
        comps = findobj('tag', 'comp_entry');
        
        src.UserData.proc_removeComps = str2num(comps.String);
        try
            s.EEG.etc.clean_channel_mask = true(1,s.EEG.nbchan);
            s.EEG.etc.clean_sample_mask = true(1,s.EEG.pnts * s.EEG.trials);
        catch
            
        end
        
        EEGTMP = s.EEG;
        
        % remove components
        s.compRemove;
        
        % replot components
        vis_artifacts( s.EEG, EEGTMP);
        vis_h = gcf;
        vis_h.Units = 'norm';
        vis_h.Position(1) = 0.05;
        vis_h.Position(2) = 0.5;
        
        vis_h.Units = 'pixels';
        vis_h.Position(3) = 1000;
        vis_h.Position(4) = 500;
        
       % vis_h.
%        saveButton = uicontrol(vis_h, 'Style', 'pushbutton','String','Save Components',...
%            'Units','normalized',...
%            'UserData', s, ...
%            'Callback',@b1_callback, ...
%            'BackgroundColor', [0 1 0], ...
%            'Position',[.6 0.05 .35 .25]);


       
        
        uiwait(vis_h);
        EEGTMP = [];
        s.msgout('Manual Verification Complete', 'step_complete');
        
        h = findobj('Tag', 'selectcomps');
        
        for mi = 1 : length( h )
            close( h(mi) );
        end
        
        
    end

end


function o = removeComps_auto( o, threshold, remove )
% eegDataClass method
% uses ICview plugin to classify and optionally remove artifactual components
% for creating a draft artifact free dataset.

% assumptions: if # of removed comps > 10% of total channels, exclude file

% inputs
% threshold: 0-1 proportion of confidence that component is classified.
% remove: true, also remove components and recalculate or false, classify
% only
% output: eegDataclass object

range = 1:24;       % only screen and select 1:n components 

get_ic = @(x) o.get_icview_comps(x, threshold, range);  % parse classification from plugin

comps_artifact = [get_ic('Eye') get_ic('Heart') get_ic('Muscle') get_ic('Line Noise')];

n_comps = length(comps_artifact);

o.proc_removeComps = comps_artifact;

o.proc_state = 'postcomps';

if n_comps > round( 0.1 * o.EEG.nbchan)
    
    obj.msgout(sprintf('ID: s: exceeded threshold comps (%n > %n)', o.subj_basename, n_comps, o.EEG.nbchan));
    o.exclude_subject( 'yes' );
    
end

if remove
    o.compRemove;
    
end


end

function dh = detailHandler( obj, idx, operation, varargin )

if nargin > 3
    searchstr = varargin{1};
end

switch operation
    
    case 'init'
        
        strout = sprintf('Loading detail for obj %s', obj.sub(idx).subj_basename);
        obj.msgout(strout, 'msg_complete');
        
        dh = prepareDetails( obj.sub(idx) );

    case 'get' 
        
        dh = prepareDetails( obj.sub(idx) );
        
        dh = retrieveDetails( searchstr, dh.fn, obj.sub(idx) );

        
    otherwise
        obj.msgout('Invalid operation passed to detailHandler.', 'step_error');
end

    function dh = prepareDetails( s )
        
        dh.fn = fields( s );
        
        dh.basename =  s.subj_basename;
        dh.exclude = s.get_exclude_switch;
        dh.postcomp = checkifpostcomps( s );
        
    end

    function str = retrieveDetails( searchstr, fn, s )
        
        idx = find(strcmp(searchstr, fn));
        str = evalc('disp(s.(fn{idx}));');
        
    end

    function result = checkifpostcomps( sub )
        
        if strcmp('postcomps', sub.proc_state)
            
            result = true;
        else
            result = false;
        end
    end

%             if strcmp('postcomps', value)
%
%                 app.ComponentViewButton.Enable = 1;
% %                 app.htpPC.sub = getSubject(app, value);
%                 s = app.htpPC.sub(1);
%                 s.loadDataset( app.stageselect );
%
%                 app.CompstoRemoveEditField.Value = mat2str(s.proc_removeComps);
%                 app.EditCheckBox.Value = 0;
%                 app.RemoveCheckBox.Value = 0;
%                 app.ComponentViewButton.Enable = 1;
%
%                 if strcmp( 'postcomps', app.stageselect )
%                     app.CompstoRemoveEditField.Enable = 0;
%                     app.updateStatusText(sprintf('Loading Postcomp Data: %s', s.study_csv));
%                     app.orig_removeComps = s.proc_removeComps;
%                 end
%
%             else
%                 app.ComponentViewButton.Enable = 0;
%             end


end
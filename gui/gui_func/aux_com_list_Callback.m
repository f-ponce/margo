function aux_com_list_Callback(hObject, ~)
% Callback function for menu items in the aux COM list

gui_fig = findall(groot,'Name','margo','Type','figure');       % get gui_handle
expmt = getappdata(gui_fig,'expmt');          % load master data struct

% update the gui menu and COM list
switch hObject.Checked
    
    case 'on'                                                 
        % close object and delete
        hObject.Checked = 'off';
        if ~isempty(expmt.hardware.COM.aux) && isvalid(expmt.hardware.COM.aux)
            fclose(expmt.hardware.COM.aux);
        end
        expmt.hardware.COM.aux = [];

    case 'off'
        
        % uncheck other items in list and remove COM obj
        hParent = hObject.Parent;
        set(hParent.Children,'Checked','off');
        if ~isempty(expmt.hardware.COM.aux) && isvalid(expmt.hardware.COM.aux)
            fclose(expmt.hardware.COM.aux);
        end
        expmt.hardware.COM.aux = [];
        
        % initialize new obj
        hObject.Checked = 'on';
        expmt.hardware.COM.aux = serial(hObject.Label);
        
        % open the COM device
        if strcmpi(get(expmt.hardware.COM.aux, "Status"), 'closed')
            fopen(expmt.hardware.COM.aux);
        end
        
end

% save loaded settings to master struct
setappdata(gui_fig,'expmt',expmt);  
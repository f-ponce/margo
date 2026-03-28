function camInfo=initializeCamera(camInfo)
vid = videoinput(camInfo.AdaptorName,camInfo.DeviceIDs{camInfo.activeID},camInfo.ActiveMode{:});
src = getselectedsource(vid);
info = propinfo(src);
names = fieldnames(info);

if isfield(camInfo,'settings')
    % apply saved settings from profile in safe order
    % first apply frame rate enable and frame rate, then exposure, then rest
    priority_props = {'AcquisitionFrameRateEnable','AcquisitionFrameRate','ExposureAuto','ExposureTime'};
    [i_src,i_set] = cmpCamSettings(src,camInfo.settings);
    set_names = fieldnames(camInfo.settings);

    % reorder so priority props are applied first
    all_set_names = set_names(i_set);
    [~, priority_order] = ismember(priority_props, all_set_names);
    priority_order(priority_order==0) = [];
    other_order = setdiff(1:length(i_src), priority_order);
    ordered = [priority_order(:); other_order(:)];
    i_src = i_src(ordered);
    i_set = i_set(ordered);

    for i = 1:length(i_src)
        if ~isempty(camInfo.settings.(set_names{i_set(i)}))
            val = camInfo.settings.(set_names{i_set(i)});
            constr = info.(set_names{i_set(i)}).ConstraintValue;
            set_prop = false;
            switch info.(set_names{i_set(i)}).Constraint
                case 'enum'
                    if ismember(val,constr)
                        set_prop = true;
                    end
                case 'bounded'
                    if all(val(:) >= constr(1)) && all(val(:) <= constr(2))  % fixed >= and <=
                        set_prop = true;
                    end
            end
            if set_prop
                try
                    src.(names{i_src(i)}) = val;
                catch ME
                    warning('Could not restore setting %s: %s', names{i_src(i)}, ME.message);
                end
            end
        end
    end

else
    %%%%%% FPonce edit start - safe defaults for Firefly USB (FlyCapture / pointgrey adaptor)
    fprintf('No saved camera settings found. Applying Firefly USB defaults.\n');
    try, src.FrameRateMode = 'Manual'; catch, end
    try, src.FrameRate     = '15';     catch, end
    try, src.ShutterMode   = 'Manual'; catch, end
    try, src.Shutter       = 10.0;     catch, end  % ms
    try, src.GainMode      = 'Manual'; catch, end
    try, src.Gain          = 0;        catch, end
    try, src.GammaMode     = 'Manual'; catch, end
    try, src.Gamma         = 0.8;      catch, end
    try, src.Brightness    = 0;        catch, end
    camInfo.settings.FrameRateMode = 'Manual';
    camInfo.settings.FrameRate     = '15';
    camInfo.settings.ShutterMode   = 'Manual';
    camInfo.settings.Shutter       = 10.0;
    camInfo.settings.GainMode      = 'Manual';
    camInfo.settings.Gain          = 0;
    camInfo.settings.GammaMode     = 'Manual';
    camInfo.settings.Gamma         = 0.8;
    camInfo.settings.Brightness    = 0;
    %%%%%% FPonce edit end

end

try
    vid.ReturnedColorSpace = 'grayscale';
catch
    warning('Tried and failed to adjust the colorspace to grayscale');
end

%%%%%% FPonce edit start - fixed settings, always applied regardless of profile
try, vid.ReturnedColorSpace = 'grayscale'; catch, end
try, src.WhiteBalanceRBMode = 'Manual'; catch, end
pause(0.1),
try, src.WhiteBalanceRB = [530 530]; catch, end  % neutral, no white balance shift
%%%%%% FPonce edit end

triggerconfig(vid,'manual');
camInfo.vid = vid;
camInfo.src = src;









% 
% 
% function camInfo=initializeCamera(camInfo)
% 
% vid = videoinput(camInfo.AdaptorName,camInfo.DeviceIDs{camInfo.activeID},camInfo.ActiveMode{:});
% 
% src = getselectedsource(vid);
% info = propinfo(src);
% names = fieldnames(info);
% 
% if isfield(camInfo,'settings')
% 
%     % query saved cam settings
%     [i_src,i_set]=cmpCamSettings(src,camInfo.settings);
%     set_names = fieldnames(camInfo.settings);
% 
%     for i = 1:length(i_src)
% 
%         % if property in settings list
%         if ~isempty(camInfo.settings.(set_names{i_set(i)}))
% 
%             % query property value and constraints
%             val = camInfo.settings.(set_names{i_set(i)});
%             constr = info.(set_names{i_set(i)}).ConstraintValue;
%             set_prop = false;
% 
%             % check to see if value falls in constraints
%             switch info.(set_names{i_set(i)}).Constraint
%                 case 'enum'
%                     if ismember(val,constr)
%                         set_prop = true;
%                     end
%                 case 'bounded'
%                     if all(val(:) > constr(1)) && all(val(:) < constr(2))
%                         set_prop = true;
%                     end
%             end
% 
%             % set the property
%             if set_prop
%                 try
%                     src.(names{i_src(i)}) = val;
%                 catch
%                 end
%             end
%         end
%     end
% 
% end
% 
% try
%     vid.ReturnedColorSpace = 'grayscale';
% catch
%     warning('Tried and failed to agjust the colorspace to grayscale');
% end
% 
% %%%%%%FPONCE EDIT
% % Always set link throughput to maximum
% try
%     src.DeviceLinkThroughputLimit = 500000000;
%     camInfo.settings.DeviceLinkThroughputLimit = 500000000;
% catch
%     warning('Could not set DeviceLinkThroughputLimit to maximum.');
% end
% %%%%%%
% %%%%%%
% 
% 
% triggerconfig(vid,'manual');
% 
% camInfo.vid = vid;
% camInfo.src = src;
% 
% 
% 
% 

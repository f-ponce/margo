function camInfo=initializeCamera(camInfo)
vid = videoinput(camInfo.AdaptorName,camInfo.DeviceIDs{camInfo.activeID},camInfo.ActiveMode{:});
src = getselectedsource(vid);
info = propinfo(src);
names = fieldnames(info);

if isfield(camInfo,'settings')
    % apply saved settings from profile in safe order
    % first apply frame rate enable and frame rate, then exposure, then rest
    priority_props = {'AcquisitionFrameRateEnabled','AcquisitionFrameRate','ExposureAuto','ExposureTime'};
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
                    if all(val(:) >= constr(1)) && all(val(:) <= constr(2))
                        set_prop = true;
                    end
            end
            if set_prop
                if ismember(names{i_src(i)}, {'Exposure','ExposureMode'})
                    continue;
                end
                %%%%%% FPonce edit start - skip read-only properties
                if isfield(info, names{i_src(i)}) && ...
                        isfield(info.(names{i_src(i)}), 'ReadOnly') && ...
                        strcmpi(info.(names{i_src(i)}).ReadOnly, 'always')
                    continue;
                end
                %%%%%% FPonce edit end
                try
                    src.(names{i_src(i)}) = val;
                catch ME
                    warning('Could not restore setting %s: %s', names{i_src(i)}, ME.message);
                end
            end
        end
    end

    %%%%%% FPonce edit start - print actual camera settings after profile is loaded
    verify_props = {'AcquisitionFrameRateEnabled','AcquisitionFrameRate',...
        'ExposureAuto','ExposureTime','GainAuto','Gain',...
        'GammaEnabled','Gamma','BlackLevel',...
        'pgrExposureCompensationAuto','pgrExposureCompensation',...
        'DeviceLinkThroughputLimit'};
    fprintf('\n--- Camera Settings After Profile Load ---\n');
    for k = 1:numel(verify_props)
        fname = verify_props{k};
        try
            fprintf('  %s = %s\n', fname, num2str(src.(fname)));
        catch
            fprintf('  %s = UNREADABLE\n', fname);
        end
    end
    fprintf('------------------------------------------\n\n');
    %%%%%% FPonce edit end

else
    %%%%%% FPonce edit start - safe defaults for FLIR Firefly USB (gentl adaptor)
    fprintf('No saved camera settings found. Applying defaults.\n');

    try, src.AcquisitionFrameRateEnabled = true;      catch, end  % enable manual frame rate
    try, src.AcquisitionFrameRate        = 25;        catch, end  % 25 fps (safe for 1288x964 within bandwidth limit)
    try, src.ExposureAuto                = 'Off';     catch, end  % manual exposure
    try, src.ExposureTime                = 10000;     catch, end  % 10ms in microseconds
    try, src.GainAuto                    = 'Off';     catch, end  % manual gain
    try, src.Gain                        = 0;         catch, end
    try, src.GammaEnabled                = 'True';    catch, end  % must enable before setting value (enum: 'True'/'False')
    pause(0.05);
    try, src.Gamma                       = 0.8;       catch, end  % only works if GammaEnabled = true
    try, src.BlackLevel                  = 1.367;     catch, end
    try, src.pgrExposureCompensationAuto = 'Off';     catch, end
    try, src.pgrExposureCompensation     = 0;         catch, end
    try, src.DeviceLinkThroughputLimit   = src.DeviceMaxThroughput; catch, end  % set to camera's max bandwidth

    % Print actual values from camera after applying defaults
    verify_props = {'AcquisitionFrameRateEnabled','AcquisitionFrameRate',...
        'ExposureAuto','ExposureTime','GainAuto','Gain',...
        'GammaEnabled','Gamma','BlackLevel',...
        'pgrExposureCompensationAuto','pgrExposureCompensation',...
        'DeviceLinkThroughputLimit'};
    fprintf('\n--- Camera Settings Verification ---\n');
    for k = 1:numel(verify_props)
        fname = verify_props{k};
        try
            fprintf('  %s = %s\n', fname, num2str(src.(fname)));
        catch
            fprintf('  %s = UNREADABLE\n', fname);
        end
    end
    fprintf('------------------------------------\n\n');
    %%%%%% FPonce edit end

end

try
    vid.ReturnedColorSpace = 'grayscale';
catch
    warning('Tried and failed to adjust the colorspace to grayscale');
end

%%%%%% FPonce edit start - fixed settings, always applied regardless of profile
try, vid.ReturnedColorSpace = 'grayscale'; catch, end
try, src.DeviceLinkThroughputLimit = src.DeviceMaxThroughput; catch, end  % always enforce max bandwidth
try, src.SharpnessAuto = 'Off'; catch, end  % prevent auto-adjustment of sharpness
%%%%%% FPonce edit end

triggerconfig(vid,'manual');
camInfo.vid = vid;
camInfo.src = src;
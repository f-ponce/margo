function cam_settings_subgui(expmt)
% CAM_SETTINGS_SUBGUI - Camera settings GUI for FLIR Blackfly S via GenTL
%
% Does NOT stop the camera - properties are set while camera is running.
% Controls: Exposure, Gain, Frame Rate, Gamma, Black Level

% --- Check camera exists and is initialized ---
if ~isfield(expmt.hardware.cam,'vid') || ~isvalid(expmt.hardware.cam.vid)
    errordlg('Camera not initialized. Please confirm camera in MARGO first.');
    return;
end

vid = expmt.hardware.cam.vid;
src = expmt.hardware.cam.src;

% NOTE: Do NOT stop the camera. GenTL properties are only writable while
% the camera is running. Stopping locks all source properties.

% --- Read current values ---
try, exp_val  = src.ExposureTime;               catch, exp_val  = 2400;    end
try, exp_auto = src.ExposureAuto;               catch, exp_auto = 'Off';   end
try, gain_val = src.Gain;                       catch, gain_val = 0;       end
try, gain_auto= src.GainAuto;                   catch, gain_auto= 'Off';   end
try, fps_val  = src.AcquisitionFrameRate;       catch, fps_val  = 30;      end
try, fps_en   = src.AcquisitionFrameRateEnable; catch, fps_en   = 'False'; end
try, gam_val  = src.Gamma;                      catch, gam_val  = 0.8;     end
try, gam_en   = src.GammaEnable;                catch, gam_en   = 'False'; end
try, bl_val   = src.BlackLevel;                 catch, bl_val   = 0;       end

% Clamp to valid ranges
exp_val  = max(4,    min(29999999, exp_val));
gain_val = max(0,    min(47.9943,  gain_val));
fps_val  = max(1,    min(226.4431, fps_val));
gam_val  = max(0.25, min(4.0,      gam_val));
bl_val   = max(-5,   min(10,       bl_val));

% Boolean states
exp_is_auto  = ~strcmpi(exp_auto, 'Off');
gain_is_auto = ~strcmpi(gain_auto,'Off');
fps_enabled  =  strcmpi(fps_en,   'True');
gam_enabled  =  strcmpi(gam_en,   'True');

% =========================================================================
% GUI Layout
% =========================================================================
bg    = get(0,'defaultUicontrolBackgroundColor');
fig_w = 500;
fig_h = 400;

f = figure('Name','Camera Settings','NumberTitle','off',...
    'MenuBar','none','Toolbar','none','Resize','off',...
    'Units','pixels','Position',[200 200 fig_w fig_h],...
    'Color',bg,...
    'CloseRequestFcn',@(hObj,~) do_close(hObj));

% Column positions
xL  = 10;    % label x
xCB = 170;   % checkbox x
xE  = 255;   % edit box x
xS  = 320;   % slider x
wS  = 160;   % slider width
wE  = 60;    % edit width
rH  = 48;    % row height
hH  = 22;    % header height
pad = 10;

y = fig_h - pad;

% Store handles
h.src     = src;
h.vid     = vid;
h.expmt   = expmt;
h.gui_fig = findall(groot,'Name','margo');

% =========================================================================
% SECTION: ACQUISITION
% =========================================================================
y = y - hH;
uicontrol('Parent',f,'Style','text','String','ACQUISITION',...
    'Units','pixels','Position',[xL y fig_w-20 hH],...
    'FontSize',9,'FontWeight','bold','ForegroundColor',[0.2 0.2 0.5],...
    'BackgroundColor',bg,'HorizontalAlignment','left');

% --- EXPOSURE ---
y = y - rH;
uicontrol('Parent',f,'Style','text','String','Exposure (µs)',...
    'Units','pixels','Position',[xL y+18 155 16],...
    'FontSize',8,'FontWeight','bold','BackgroundColor',bg,'HorizontalAlignment','left');
h.exp_cb = uicontrol('Parent',f,'Style','checkbox','String','Auto',...
    'Units','pixels','Position',[xCB y+16 65 18],...
    'Value',double(exp_is_auto),'FontSize',8,'BackgroundColor',bg);
h.exp_eb = uicontrol('Parent',f,'Style','edit',...
    'String',num2str(round(exp_val)),...
    'Units','pixels','Position',[xE y+2 wE 20],...
    'FontSize',8,'BackgroundColor','white',...
    'Enable',onoff(~exp_is_auto));
h.exp_sl = uicontrol('Parent',f,'Style','slider',...
    'Min',0,'Max',1,'Value',log2sl(exp_val,4,29999999),...
    'Units','pixels','Position',[xS y+4 wS 16],...
    'Enable',onoff(~exp_is_auto));

% --- GAIN ---
y = y - rH;
uicontrol('Parent',f,'Style','text','String','Gain (dB)',...
    'Units','pixels','Position',[xL y+18 155 16],...
    'FontSize',8,'FontWeight','bold','BackgroundColor',bg,'HorizontalAlignment','left');
h.gain_cb = uicontrol('Parent',f,'Style','checkbox','String','Auto',...
    'Units','pixels','Position',[xCB y+16 65 18],...
    'Value',double(gain_is_auto),'FontSize',8,'BackgroundColor',bg);
h.gain_eb = uicontrol('Parent',f,'Style','edit',...
    'String',sprintf('%.2f',gain_val),...
    'Units','pixels','Position',[xE y+2 wE 20],...
    'FontSize',8,'BackgroundColor','white',...
    'Enable',onoff(~gain_is_auto));
h.gain_sl = uicontrol('Parent',f,'Style','slider',...
    'Min',0,'Max',1,'Value',lin2sl(gain_val,0,47.9943),...
    'Units','pixels','Position',[xS y+4 wS 16],...
    'Enable',onoff(~gain_is_auto));

% --- FRAME RATE ---
y = y - rH;
uicontrol('Parent',f,'Style','text','String','Frame Rate (fps)',...
    'Units','pixels','Position',[xL y+18 155 16],...
    'FontSize',8,'FontWeight','bold','BackgroundColor',bg,'HorizontalAlignment','left');
h.fps_cb = uicontrol('Parent',f,'Style','checkbox','String','Enable',...
    'Units','pixels','Position',[xCB y+16 75 18],...
    'Value',double(fps_enabled),'FontSize',8,'BackgroundColor',bg);
h.fps_eb = uicontrol('Parent',f,'Style','edit',...
    'String',sprintf('%.1f',fps_val),...
    'Units','pixels','Position',[xE y+2 wE 20],...
    'FontSize',8,'BackgroundColor','white',...
    'Enable',onoff(fps_enabled));
h.fps_sl = uicontrol('Parent',f,'Style','slider',...
    'Min',0,'Max',1,'Value',lin2sl(fps_val,1,226.4431),...
    'Units','pixels','Position',[xS y+4 wS 16],...
    'Enable',onoff(fps_enabled));

% =========================================================================
% SECTION: IMAGE
% =========================================================================
y = y - 8 - hH;
uicontrol('Parent',f,'Style','text','String','IMAGE',...
    'Units','pixels','Position',[xL y fig_w-20 hH],...
    'FontSize',9,'FontWeight','bold','ForegroundColor',[0.2 0.2 0.5],...
    'BackgroundColor',bg,'HorizontalAlignment','left');

% --- GAMMA ---
y = y - rH;
uicontrol('Parent',f,'Style','text','String','Gamma',...
    'Units','pixels','Position',[xL y+18 155 16],...
    'FontSize',8,'FontWeight','bold','BackgroundColor',bg,'HorizontalAlignment','left');
h.gam_cb = uicontrol('Parent',f,'Style','checkbox','String','Enable',...
    'Units','pixels','Position',[xCB y+16 75 18],...
    'Value',double(gam_enabled),'FontSize',8,'BackgroundColor',bg);
h.gam_eb = uicontrol('Parent',f,'Style','edit',...
    'String',sprintf('%.3f',gam_val),...
    'Units','pixels','Position',[xE y+2 wE 20],...
    'FontSize',8,'BackgroundColor','white',...
    'Enable',onoff(gam_enabled));
h.gam_sl = uicontrol('Parent',f,'Style','slider',...
    'Min',0,'Max',1,'Value',lin2sl(gam_val,0.25,4.0),...
    'Units','pixels','Position',[xS y+4 wS 16],...
    'Enable',onoff(gam_enabled));

% --- BLACK LEVEL ---
y = y - rH;
uicontrol('Parent',f,'Style','text','String','Black Level',...
    'Units','pixels','Position',[xL y+18 155 16],...
    'FontSize',8,'FontWeight','bold','BackgroundColor',bg,'HorizontalAlignment','left');
h.bl_eb = uicontrol('Parent',f,'Style','edit',...
    'String',sprintf('%.3f',bl_val),...
    'Units','pixels','Position',[xE y+2 wE 20],...
    'FontSize',8,'BackgroundColor','white');
h.bl_sl = uicontrol('Parent',f,'Style','slider',...
    'Min',0,'Max',1,'Value',lin2sl(bl_val,-5,10),...
    'Units','pixels','Position',[xS y+4 wS 16]);

% Apply & Close
uicontrol('Parent',f,'Style','pushbutton','String','Apply & Close',...
    'Units','pixels','Position',[fig_w-148 8 136 28],...
    'FontSize',9,'FontWeight','bold',...
    'Callback',@(s,~) do_close(f));

% Store handles
set(f,'UserData',h);

% =========================================================================
% ASSIGN CALLBACKS
% =========================================================================
% Exposure
set(h.exp_sl,'Callback', @(s,~) on_slider(f,'ExposureTime',  s.Value,'log', 4,29999999, h.exp_eb));
set(h.exp_eb,'Callback', @(s,~) on_edit(  f,'ExposureTime',  s,      'log', 4,29999999, h.exp_sl));
set(h.exp_cb,'Callback', @(s,~) on_auto(  f,'ExposureAuto',  s,'Off','Continuous', h.exp_sl,h.exp_eb));

% Gain
set(h.gain_sl,'Callback',@(s,~) on_slider(f,'Gain',          s.Value,'lin', 0,47.9943,  h.gain_eb));
set(h.gain_eb,'Callback',@(s,~) on_edit(  f,'Gain',          s,      'lin', 0,47.9943,  h.gain_sl));
set(h.gain_cb,'Callback', @(s,~) on_auto( f,'GainAuto',      s,'Off','Continuous', h.gain_sl,h.gain_eb));

% Frame Rate
set(h.fps_sl,'Callback', @(s,~) on_slider(f,'AcquisitionFrameRate', s.Value,'lin',1,226.4431,h.fps_eb));
set(h.fps_eb,'Callback', @(s,~) on_edit(  f,'AcquisitionFrameRate', s,      'lin',1,226.4431,h.fps_sl));
set(h.fps_cb,'Callback', @(s,~) on_enable(f,'AcquisitionFrameRateEnable','AcquisitionFrameRate', s, h.fps_sl,h.fps_eb));

% Gamma
set(h.gam_sl,'Callback', @(s,~) on_slider(f,'Gamma',         s.Value,'lin',0.25,4.0, h.gam_eb));
set(h.gam_eb,'Callback', @(s,~) on_edit(  f,'Gamma',         s,      'lin',0.25,4.0, h.gam_sl));
set(h.gam_cb,'Callback', @(s,~) on_enable(f,'GammaEnable','Gamma',   s, h.gam_sl,h.gam_eb));

% Black Level
set(h.bl_sl,'Callback',  @(s,~) on_slider(f,'BlackLevel',    s.Value,'lin',-5,10, h.bl_eb));
set(h.bl_eb,'Callback',  @(s,~) on_edit(  f,'BlackLevel',    s,      'lin',-5,10, h.bl_sl));

end

% =========================================================================
% CALLBACKS
% =========================================================================

function on_slider(f, prop, sl_val, scale, mn, mx, eb)
    h   = get(f,'UserData');
    raw = sl2val(sl_val, mn, mx, scale);
    raw = max(mn, min(mx, raw));
    set(eb,'String', fmt(raw, prop));
    try_set(h.src, prop, raw);
    h = save_prop(h, prop, raw);
    set(f,'UserData',h);
end

function on_edit(f, prop, eb, scale, mn, mx, sl)
    h   = get(f,'UserData');
    raw = str2double(get(eb,'String'));
    if isnan(raw), return; end
    raw = max(mn, min(mx, raw));
    set(eb,'String', fmt(raw, prop));
    set(sl,'Value', val2sl(raw, mn, mx, scale));
    try_set(h.src, prop, raw);
    h = save_prop(h, prop, raw);
    set(f,'UserData',h);
end

function on_auto(f, auto_prop, cb, off_val, on_val, sl, eb)
% For Exposure/Gain: checkbox ON = auto mode, controls disabled
    h = get(f,'UserData');
    if cb.Value
        try_set(h.src, auto_prop, on_val);
        h = save_prop(h, auto_prop, on_val);
        set(sl,'Enable','off');
        set(eb,'Enable','off');
    else
        try_set(h.src, auto_prop, off_val);
        h = save_prop(h, auto_prop, off_val);
        set(sl,'Enable','on');
        set(eb,'Enable','on');
    end
    set(f,'UserData',h);
end

function on_enable(f, en_prop, val_prop, cb, sl, eb)
% For FrameRate/Gamma: checkbox ON = feature enabled, controls active
    h = get(f,'UserData');
    if cb.Value
        try_set(h.src, en_prop, 'True');
        h = save_prop(h, en_prop, 'True');
        set(sl,'Enable','on');
        set(eb,'Enable','on');
    else
        try_set(h.src, en_prop, 'False');
        h = save_prop(h, en_prop, 'False');
        set(sl,'Enable','off');
        set(eb,'Enable','off');
    end
    set(f,'UserData',h);
end

function do_close(f)
    set(f,'CloseRequestFcn','');
    h = get(f,'UserData');
    if isstruct(h) && isfield(h,'src')
        props = {'ExposureTime','ExposureAuto','Gain','GainAuto',...
            'AcquisitionFrameRate','AcquisitionFrameRateEnable',...
            'Gamma','GammaEnable','BlackLevel'};
        for i = 1:length(props)
            try
                h = save_prop(h, props{i}, h.src.(props{i}));
            catch
            end
        end
    end
    delete(f);
end

% =========================================================================
% HELPERS
% =========================================================================

function try_set(src, prop, val)
    try
        src.(prop) = val;
    catch ME
        warning('Could not set %s: %s', prop, ME.message);
    end
end

function h = save_prop(h, prop, val)
    h.expmt.hardware.cam.settings.(prop) = val;
    if ~isempty(h.gui_fig) && isvalid(h.gui_fig)
        try
            expmt = getappdata(h.gui_fig,'expmt');
            expmt.hardware.cam.settings.(prop) = val;
            setappdata(h.gui_fig,'expmt',expmt);
        catch
        end
    end
end

function s = val2sl(v, mn, mx, scale)
    if strcmp(scale,'log')
        if mn <= 0, mn = 1; end
        s = (log(max(v,mn)) - log(mn)) / (log(mx) - log(mn));
    else
        if mx == mn, s = 0; return; end
        s = (v - mn) / (mx - mn);
    end
    s = max(0, min(1, s));
end

function v = sl2val(s, mn, mx, scale)
    if strcmp(scale,'log')
        if mn <= 0, mn = 1; end
        v = exp(log(mn) + s*(log(mx) - log(mn)));
    else
        v = mn + s*(mx - mn);
    end
end

function s = log2sl(v, mn, mx)
    s = val2sl(v, mn, mx, 'log');
end

function s = lin2sl(v, mn, mx)
    s = val2sl(v, mn, mx, 'lin');
end

function str = fmt(v, prop)
    switch prop
        case 'ExposureTime'
            str = sprintf('%d', round(v));
        case 'AcquisitionFrameRate'
            str = sprintf('%.1f', v);
        case 'Gain'
            str = sprintf('%.2f', v);
        otherwise
            str = sprintf('%.3f', v);
    end
end

function e = onoff(tf)
    if tf, e = 'on'; else, e = 'off'; end
end
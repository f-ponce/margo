function expmt = run_activation(expmt, gui_handles, varargin)
%% Parse variable inputs

for i = 1:length(varargin)

    arg = varargin{i};

    if ischar(arg)
        switch arg
            case 'Trackdat'
                i=i+1;
                trackDat = varargin{i};     % manually pass in trackDat rather than initializing
        end
    end
end

%% Initialization: Get handles and set default preferences

gui_notify(['executing ' mfilename '.m'],gui_handles.disp_note);

% clear memory
clearvars -except gui_handles expmt trackDat

% get image handle
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');


%% Experimental Setup

% Initialize tracking variables
trackDat.fields = {'centroid';'time';'StimStatus'};

% initialize labels, files, and cam/video
[trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);

% lastFrame = false until last frame of the last video file is reached
trackDat.lastFrame = false;


%% Initialize the psychtoolbox window and query projector properties
bg_color=[0 0 0];
expmt = initialize_projector(expmt, bg_color);
pause(3);

set(gui_handles.display_menu.Children,'Checked','off')
set(gui_handles.display_menu.Children,'Enable','on')
gui_handles.display_none_menu.Checked = 'on';
gui_handles.display_menu.UserData = 5;


%% Calculate ROI coords in the projector space

nROIs = expmt.meta.roi.n;
scor  = NaN(size(expmt.meta.roi.corners));
rcor  = expmt.meta.roi.corners;
scen  = NaN(nROIs,2);
rcen  = expmt.meta.roi.centers;

Fx = expmt.hardware.projector.Fx;
Fy = expmt.hardware.projector.Fy;

% Project centers
scen(:,1) = Fx(rcen(:,1), rcen(:,2));
scen(:,2) = Fy(rcen(:,1), rcen(:,2));

% Project corners and fix ordering
x1 = Fx(rcor(:,1), rcor(:,2));
y1 = Fy(rcor(:,1), rcor(:,2));
x2 = Fx(rcor(:,3), rcor(:,4));
y2 = Fy(rcor(:,3), rcor(:,4));

% Ensure left < right and top < bottom
scor(:,1) = min(x1, x2);  % left
scor(:,3) = max(x1, x2);  % right
scor(:,2) = min(y1, y2);  % top
scor(:,4) = max(y1, y2);  % bottom

% Add buffer to ensure entire ROI is covered
sbbuf = nanFilteredMean([scor(:,3)-scor(:,1), scor(:,4)-scor(:,2)],2)*0.05;
scor(:,[1 3]) = [scor(:,1)-sbbuf, scor(:,3)+sbbuf];
scor(:,[2 4]) = [scor(:,2)-sbbuf, scor(:,4)+sbbuf];

expmt.hardware.projector.Fx = Fx;
expmt.hardware.projector.Fy = Fy;


%% Activation-specific parameters

% Pixel scale from direct arena measurement:
% arena diameter = 27.5 mm = 78.7988 px => 2.8654 px/mm
arena_diameter_mm = 27.5;
arena_diameter_px = 78.7988;
px_per_mm         = arena_diameter_px / arena_diameter_mm;

% Default parameters
if ~isfield(expmt.parameters,'zone_radius')
    expmt.parameters.zone_radius = 5 * px_per_mm;   % 2.5 mm radius in px
end
if ~isfield(expmt.parameters,'stim_duration')
    expmt.parameters.stim_duration = 2;                % s
end
if ~isfield(expmt.parameters,'stim_int')
    expmt.parameters.stim_int = 9.0;                   % s refractory period
end
if ~isfield(expmt.parameters,'baseline_dur')
    expmt.parameters.baseline_dur = 10 * 60;           % s (10 min acclimation before stimuli activate)
end
if ~isfield(expmt.parameters,'spot_radius_mm')
    expmt.parameters.spot_radius_mm = 2.5;               % mm radius of projected light spot
end

% Initialize stimulus tracking variables
stim.t       = zeros(nROIs,1);    % time stimulus was turned ON per fly
stim.timer   = zeros(nROIs,1);    % refractory timer per fly
stim.centers = scen;
stim.corners = scor;              % projector-space ROI bounding boxes

% Compute spot half-size in projector pixels from physical spot radius.
% Uses mean ROI width in projector px as reference for px/mm conversion.
stim.spot_half = round((expmt.parameters.spot_radius_mm / arena_diameter_mm) * ...
                        nanFilteredMean(scor(:,3) - scor(:,1)));

expmt.meta.stim = stim;

trackDat.StimStatus = false(nROIs,1);


%% Main Experimental Loop

% make sure the mouse cursor is at screen edge
robot = java.awt.Robot;
robot.mouseMove(1,1);

% run experimental loop until duration is exceeded or last frame
% of the last video file is reached
while ~trackDat.lastFrame

    % update time stamps and frame rate
    [trackDat] = autoTime(trackDat, expmt, gui_handles);

    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);

    % track, sort to ROIs, and output optional fields to sorted fields,
    % and sample the number of pixels above the image threshold
    trackDat = autoTrack(trackDat,expmt,gui_handles);

    % update the stimuli
    [trackDat,expmt] = updateActivationStim(trackDat, expmt);

    % output data to binary files
    [trackDat,expmt] = autoWriteData(trackDat, expmt, gui_handles);

    % update ref at the reference frequency or reset if noise thresh is exceeded
    [trackDat,expmt] = autoReference(trackDat, expmt, gui_handles);

    % update the display
    trackDat = autoDisplay(trackDat, expmt, imh, gui_handles);

end
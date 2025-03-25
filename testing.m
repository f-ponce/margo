
gui_dir = which('margo');
gui_dir = gui_dir(1:strfind(gui_dir,'/gui/'));
disp(gui_dir)
fName = 'projector_fit.mat';


if exist([gui_dir 'hardware/projector_fit/'],'dir') == 7 &&...
        exist([gui_dir 'hardware/projector_fit/' fName],'file') == 2
    load([gui_dir '/hardware/projector_fit/' fName]);
else
    disp('nah') 
end

trackDat.fields={'centroid';'orientation';'time';...
    'speed';'StimStatus';'Texture';'SpatialFreq';...
    'AngularVel';'Contrast'};  % properties of the tracked objects to be recorded

expmt = getappdata(handles.gui_fig,'expmt');
expmt.meta.initialize = true;

[trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);
expmt = initialize_projector(expmt, bg_color);
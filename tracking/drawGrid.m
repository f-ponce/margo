function [gui_handles,hPatch]=drawGrid(grid_idx,gui_handles)

% query the enable states of objects in the gui
on_objs = findobj('enable','on');
off_objs = findobj('enable','off');

% disable all gui features during camera initialization
set(findall(gui_handles.gui_fig, '-property', 'enable'), 'enable', 'off');

% get drawn rectangle from user outlining well plate boundary
roi = getrect();
nRow = gui_handles.add_ROI_pushbutton.UserData.grid(grid_idx).nRows;
nCol = gui_handles.add_ROI_pushbutton.UserData.grid(grid_idx).nCols;

% get coordinates of vertices from rectangle bounds
polyPos = NaN(4,2);                                 
polyPos(1,:) = [sum(roi([1 3])) roi(2)];
polyPos(2,:) = [sum(roi([1 3])) sum(roi([2 4]))];
polyPos(3,:) = [roi(1) sum(roi([2 4]))];
polyPos(4,:) = [roi(1) roi(2)];

% sort coordinates from top left to bottom right
[xData,yData] = getGridVertices(polyPos(:,1),polyPos(:,2),nRow,nCol);

% create interactible polygon
gui_handles.add_ROI_pushbutton.UserData.grid(grid_idx).hp = ...
    impoly(gui_handles.axes_handle, polyPos);

hPatch = patch('Faces',1:size(xData,2),'XData',xData,'YData',yData,...
    'FaceColor','none','EdgeColor','r','Parent',gui_handles.axes_handle);
uistack(hPatch,'down');

set(on_objs,'Enable','on');
function [varargout] = intializeRef(handles,exp_vars)

% Automatically average out flies from reference image

% Clear old video objects
imaqreset
pause(0.2);

% Create camera object with input parameters
vid = initializeCamera(exp_vars.camInfo);
start(vid);
pause(0.2);

cla reset
res = vid.videoResolution;
blank = zeros(res(2),res(1));
axh = imagesc(blank);

ref = peekdata(vid,1);
if size(ref,3)>2
    ref=ref(:,:,2);                                     % Assign reference image
end

nROIs = size(exp_vars.ROI.corners, 1);
lastCentroid=exp_vars.ROI.centers;                     % Create placeholder for most recent non-NaN centroids
referenceCentroids=zeros( nROIs, 2, 10);                % Create placeholder for cen. coords when references are taken
propFields={'Centroid';'Area'};                         % Define fields for regionprops
nRefs=zeros(nROIs, 1);                      % Reference number placeholder
numbers=1:nROIs;                           % Numbers to display while tracking
centStamp=zeros(nROIs,1);
vignetteMat=filterVignetting(ref,exp.ROI.im,exp.ROI.corners);

% Set maximum allowable distance to center of ROI as the long axis of the
% ROI + some error
widths=(exp_vars.ROI.bounds(:,3));
heights=(exp_vars.ROI.bounds(:,4));
w=median(widths);
h=median(heights);
exp_vars.parameters.distanceThresh=sqrt(w^2+h^2)/2*0.95;

% Calculate threshold for distance to end of maze arms for turn scoring
mazeLengths=mean([widths heights],2);
exp_vars.parameters.armThresh=mazeLengths*0.2;

% Time stamp placeholders
tElapsed=0;
tic
previous_tStamp=toc;
current_tStamp=0;

% Collect reference until timeout OR "accept reference" GUI press
while toc<referenceTime&&get(handles.accept_track_thresh_pushbutton,'value')~=1
    
    % Update image threshold value from GUI
    imageThresh=get(handles.track_thresh_slider,'value');
    
    % Update tStamps
    current_tStamp=toc;
    set(handles.edit_frame_rate,'String',num2str(round(1/(current_tStamp-previous_tStamp))));
    tElapsed=tElapsed+current_tStamp-previous_tStamp;
    previous_tStamp=current_tStamp;
    
        % Report time remaining to reference timeout to GUI
        timeRemaining = round(referenceTime - toc);
        if timeRemaining < 60; 
            set(handles.edit_time_remaining, 'String', ['00:00:' sprintf('%0.2d',timeRemaining)]);
            set(handles.edit_time_remaining, 'BackgroundColor', [1 0.4 0.4]);
        elseif (3600 > timeRemaining) && (timeRemaining > 60);
            min = floor(timeRemaining/60);
            sec = rem(timeRemaining, 60);
            set(handles.edit_time_remaining, 'String', ['00:' sprintf('%0.2d',min) ':' sprintf('%0.2d',sec)]);
            set(handles.edit_time_remaining, 'BackgroundColor', [1 1 1]);
        elseif timeRemaining > 3600;
            hr = floor(timeRemaining/3600);
            min = floor(rem(timeRemaining, 3600)/60);
            sec = timeRemaining - hr*3600 - min*60;
            set(handles.edit_time_remaining, 'String', [sprintf('%0.2d', hr) ':' sprintf('%0.2d',min) ':' sprintf('%0.2d',sec)]);
            set(handles.edit_time_remaining, 'BackgroundColor', [1 1 1]);
        end
        
        % Take difference image
        imagedata=peekdata(vid,1);
        
        if size(imagedata,3)>2
            imagedata=imagedata(:,:,2);
        end
        subtractedData=(ref-vignetteMat)-(imagedata-vignetteMat);

        % Extract regionprops and record centroid for blobs with (11 > area > 30) pixels
        props=regionprops((subtractedData>imageThresh),propFields);
        validCentroids=([props.Area]>4&[props.Area]<120);
        cenDat=reshape([props(validCentroids).Centroid],2,length([props(validCentroids).Centroid])/2)';

        % Match centroids to ROIs by finding nearest ROI center
        [cen_permutation,update_centroid]=matchCentroids2ROIs(cenDat,lastCentroid,centers,distanceThresh);

        % Apply speed threshold to centroid tracking
        if any(update_centroid)
        d = sqrt([cenDat(cen_permutation,1)-lastCentroid(update_centroid,1)].^2 + [cenDat(cen_permutation,2)-lastCentroid(update_centroid,2)].^2);
        dt = tElapsed-centStamp(update_centroid);
        speed = d./dt;
        above_spd_thresh = speed > speedThresh;
        cen_permutation(above_spd_thresh)=[];
        update_centroid=find(update_centroid);
        update_centroid(above_spd_thresh)=[];
        end

        % Use permutation vector to sort raw centroid data and update
        % vector to specify which centroids are reliable and should be updated
        lastCentroid(update_centroid,:)=cenDat(cen_permutation,:);
        
        % Step through each ROI one-by-one
        for i=1:nROIs

        % Calculate distance to previous locations where references were taken
        tCen=repmat(lastCentroid(i,:),size(referenceCentroids,3),1);
        d=abs(sqrt(dot((tCen-squeeze(referenceCentroids(i,:,:))'),(squeeze(referenceCentroids(i,:,:))'-tCen),2)));

            % Create a new reference image for the ROI if fly is greater than distance thresh
            % from previous reference locations
            if ~any(d<10) && ~any(isnan(lastCentroid(i,:)))
                
                nRefs(i)=sum(sum(referenceCentroids(i,:,:)>0));
                referenceCentroids(i,:,mod(nRefs(i)+1,10))=lastCentroid(i,:);
                newRef=imagedata(exp_vars.ROI.corners(i,2):exp_vars.ROI.corners(i,4),exp_vars.ROI.corners(i,1):exp_vars.ROI.corners(i,3));
                oldRef=refImage(exp_vars.ROI.corners(i,2):exp_vars.ROI.corners(i,4),exp_vars.ROI.corners(i,1):exp_vars.ROI.corners(i,3));
                nRefs(i)=sum(sum(referenceCentroids(i,:,:)>0));                                         % Update num Refs
                averagedRef=newRef.*(1/nRefs(i))+oldRef.*(1-(1/nRefs(i)));               % Weight new reference by 1/nRefs
                refImage(exp_vars.ROI.corners(i,2):exp_vars.ROI.corners(i,4),exp_vars.ROI.corners(i,1):exp_vars.ROI.corners(i,3))=averagedRef;
                
            end
        end
        
       % Check "Display ON" toggle button from GUI 

           % Update the plot with new reference
               cla reset
            imagesc(subtractedData>imageThresh);

           % Draw last known centroid for each ROI and update ref. number indicator
           hold on
           for i=1:nROIs
               color=[(1/nRefs(i)) 0 (1-1/nRefs(i))];
               color(color>1)=1;
               color(color<0)=0;
               plot(exp_vars.ROI.corners(i,1),exp_vars.ROI.corners(i,2),'o','Linew',3,'Color',color);      
               text(exp_vars.ROI.corners(i,1),exp_vars.ROI.corners(i,2)+15,int2str(numbers(i)),'Color','m')
               text(lastCentroid(i,1),lastCentroid(i,2),int2str(numbers(i)),'Color','R')
           end
       hold off
       set(gca,'Xtick',[],'Ytick',[]);
       drawnow

end

% Reset accept reference button
set(handles.accept_track_thresh_pushbutton,'value',0);
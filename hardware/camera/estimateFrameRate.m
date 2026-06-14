function [frameRate,camInfo]=estimateFrameRate(camInfo)

if ~isfield(camInfo,'vid') || strcmp(camInfo.vid.Running,'off')
    imaqreset;
    camInfo = initializeCamera(camInfo);
    start(camInfo.vid);
    pause(0.1);
end

%%%%%% FPonce edit start
% Original estimation using peekdata is unreliable with manual trigger mode.
% peekdata reads the current live frame from the stream without consuming it.
% Since the loop runs ~40x faster than frame delivery, the same frame gets
% detected multiple times, producing an incorrect frame rate estimate.
% Fix: use getdata with a controlled trigger to get hardware timestamps,
% which are guaranteed to be accurate regardless of loop speed.

nFrames = max(25, ceil(camInfo.src.AcquisitionFrameRate * 1.0));  % at least 1 second worth
old_fpt = camInfo.vid.FramesPerTrigger;

% stop camera to change FramesPerTrigger (cannot be changed while running)
if strcmp(camInfo.vid.Running, 'on')
    stop(camInfo.vid);
end
camInfo.vid.FramesPerTrigger = nFrames;
start(camInfo.vid);
trigger(camInfo.vid);
wait(camInfo.vid, 10);  % wait up to 10 seconds for frames
[~, tStamps] = getdata(camInfo.vid, nFrames);
frameRate = 1/median(diff(tStamps));
fprintf('estimateFrameRate result: %.4f fps\n', frameRate);

if isnan(frameRate)
    error('estimateFrameRate: measurement returned NaN. Check camera connection and settings.');
end

% restore original FramesPerTrigger and restart camera for normal operation
stop(camInfo.vid);
camInfo.vid.FramesPerTrigger = old_fpt;
start(camInfo.vid);
%%%%%% FPonce edit end




% function [frameRate,camInfo]=estimateFrameRate(camInfo)
% if ~isfield(camInfo,'vid') || strcmp(camInfo.vid.Running,'off')
%     imaqreset;
%     camInfo = initializeCamera(camInfo);
%     start(camInfo.vid);
%     pause(0.1);
% end
% nFrames = 100;
% tStamps = NaN(nFrames,1);
% prev_im = peekdata(camInfo.vid,1);
% prev_im = prev_im(:,:,1);
% fCount=0;
% tic
% tElapsed = 0;
% tPrev = toc;
% while tElapsed < 1.5 && any(isnan(tStamps))
%     tCurr = toc;
%     tElapsed = tElapsed + tCurr - tPrev;
%     tPrev = tCurr;
%     im = peekdata(camInfo.vid,1);
%     im = im(:,:,1);
%     if ~(isempty(im)||isempty(prev_im)) && any(any(im~=prev_im))
%         fCount=fCount+1;
%         tStamps(fCount)=tCurr;
%     end
%     prev_im = im;
% end
% frameRate=1/median(diff(tStamps(~isnan(tStamps))));
% if isnan(frameRate)
%     frameRate = 30;
% end
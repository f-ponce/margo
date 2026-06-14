imaqreset
vid = videoinput('gentl');
src = getselectedsource(vid);
src.AcquisitionFrameRateEnabled = 'True';
src.AcquisitionFrameRate = 25;
vid.FramesPerTrigger = Inf;
triggerconfig(vid, 'immediate');
start(vid);
pause(0.2);  % same short pause as original estimateFrameRate

nFrames = 100;
tStamps = NaN(nFrames,1);
prev_im = peekdata(vid,1);
prev_im = prev_im(:,:,1);
fCount=0;
tic
tElapsed = 0;
tPrev = toc;
while tElapsed < 1.5 && any(isnan(tStamps))
    tCurr = toc;
    tElapsed = tElapsed + tCurr - tPrev;
    tPrev = tCurr;
    im = peekdata(vid,1);
    im = im(:,:,1);
    if ~(isempty(im)||isempty(prev_im)) && any(any(im~=prev_im))
        fCount=fCount+1;
        tStamps(fCount)=tCurr;
    end
    prev_im = im;
end
frameRate=1/median(diff(tStamps(~isnan(tStamps))));
fprintf('estimateFrameRate result: %.2f fps\n', frameRate);
fprintf('Unique frames detected: %i\n', fCount);
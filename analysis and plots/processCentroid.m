function [expmt] = processCentroid(expmt,opt)


if isempty(opt.raw) && ~opt.handedness
    return
end

% initialize tracking properties struct
nFrames = expmt.nFrames;

% initialize raw data files if necessary
if ~isempty(opt.raw)
    rawdir = [expmt.fdir 'raw_data/'];
    for i=1:length(opt.raw)
        % get new path
        path = [rawdir expmt.date opt.raw{i} '.bin'];
        
        % delete any existing contents
        expmt.(opt.raw{i}).fID = fopen(path,'w');
        fclose(expmt.(opt.raw{i}).fID);
        
        % intialize new raw file
        expmt.(opt.raw{i}).fID = fopen(path,'a');
        expmt.(opt.raw{i}).precision = 'single';
        expmt.(opt.raw{i}).dim = [expmt.nTracks 1];
        expmt.(opt.raw{i}).path = path;
    end
end
        

% query available memory to determine how many batches to process data in
[umem,msz] = memory;
msz = msz.PhysicalMemory.Available;
switch expmt.Centroid.precision
    case 'double'
        cen_prcn = 8;
    case 'single'
        cen_prcn = 4;
end
bytes_per = 16;
rsz = expmt.nTracks * expmt.nFrames * (cen_prcn*2 + bytes_per);
nBatch = ceil(rsz/msz * 2);
bsz = ceil(expmt.nFrames/nBatch);
spd = NaN(expmt.nTracks,nBatch);
    
% calculate track properties
for j = 1:nBatch
    
    % read next batch from mapped raw data
    if j==nBatch
        inx = squeeze(expmt.Centroid.map.Data.raw(:,1,(j-1)*bsz+1:end)) - ...
            repmat(expmt.ROI.centers(:,1),1,nFrames-(j-1)*bsz);
        iny = squeeze(expmt.Centroid.map.Data.raw(:,2,(j-1)*bsz+1:end)) - ...
            repmat(expmt.ROI.centers(:,2),1,nFrames-(j-1)*bsz);
    else
        inx = squeeze(expmt.Centroid.map.Data.raw(:,1,(j-1)*bsz+1:j*bsz)) - ...
            repmat(expmt.ROI.centers(:,1),1,bsz);
        iny = squeeze(expmt.Centroid.map.Data.raw(:,2,(j-1)*bsz+1:j*bsz)) - ...
            repmat(expmt.ROI.centers(:,2),1,bsz);
    end
    
    % get x and y coordinates of the centroid and normalize to upper left ROI corner        
    trackProps.Speed = single([zeros(expmt.nTracks,1) ...
        sqrt(diff(inx,1,2).^2+diff(iny,1,2).^2)]);   
    trackProps.Speed(trackProps.Speed(:,j) > 12, j) = NaN;
    spd(:,j) = nanmean(trackProps.Speed,2);

    
    if opt.handedness
        trackProps.Theta = single(atan2(iny,inx));
        trackProps.Direction = single([zeros(expmt.nTracks,1) ...
            atan2(diff(iny,1,2),diff(inx,1,2))]);
        clearvars inx iny
        tmp(j) = getHandedness(trackProps);
        expmt.handedness = tmp(j);
    end    
    
    for i = 1:length(opt.raw)
        f = opt.raw{i};
        fwrite(expmt.(f).fID,trackProps.(f),expmt.(f).precision);
    end
    
    clear trackProps inx iny
    
end

% record mean speed
expmt.Speed.avg = nanmean(spd,2);

% close raw data and initialize new memmap for raw data
for i = 1:length(opt.raw)
    f = opt.raw{i};
    fclose(expmt.(f).fID);
    prcn = expmt.(f).precision;
    dim = expmt.(f).dim;
    expmt.(f).map = memmapfile(expmt.(f).path, 'Format',{prcn,dim,'raw'});
end


% concatenate handedness data
if nBatch>1 && opt.handedness
    weight = NaN(expmt.nTracks,nBatch);
    for i = 1:nBatch
        weight(:,i) = sum(tmp(i).include,2);
    end
    weight = weight ./ repmat(sum(weight,2),1,nBatch);
    
    for i = 1:nBatch
        tmp(i).angle_histogram = tmp(i).angle_histogram .* ...
            repmat(weight(:,i)',length(tmp(i).bins),1);
    end
    
    handedness = tmp(1);
    for i = 2:nBatch
        handedness.angle_histogram =  handedness.angle_histogram + ...
            tmp(i).angle_histogram ;
        handedness.include = [handedness.include tmp(i).include];
    end
    handedness.mu = -sin(sum(handedness.angle_histogram .*...
        repmat((handedness.bins' + handedness.bin_width/2),1,expmt.nTracks)))';
    
    expmt.handedness = handedness;
    
end
    
    




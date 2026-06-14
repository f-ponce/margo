function [trackDat, expmt] = updateActivationStim(trackDat, expmt)

% Calculate radial distance of each fly from its ROI center (camera px)
r = sqrt((trackDat.centroid(:,1) - expmt.meta.roi.centers(:,1)).^2 + ...
         (trackDat.centroid(:,2) - expmt.meta.roi.centers(:,2)).^2);

stim    = expmt.meta.stim;
stim_on = trackDat.StimStatus;

% Conditions for triggering a new stimulus
in_zone = r < expmt.parameters.zone_radius;
timeup  = trackDat.t - stim.timer > expmt.parameters.stim_int;

% Activate: fly in zone, refractory period over, not already ON, and past baseline
baseline_over = trackDat.t > expmt.parameters.baseline_dur;
activate_stim = in_zone & timeup & ~stim_on & baseline_over;

stim_on(activate_stim) = true;
stim.t(activate_stim)  = trackDat.t;

% Turn OFF after stim_duration elapsed
stim_OFF = (trackDat.t - stim.t >= expmt.parameters.stim_duration) & stim_on;
stim_on(stim_OFF) = false;

% Reset refractory timer for flies whose stimulus just turned off
if any(stim_OFF)
    stim.timer(stim_OFF) = trackDat.t;
end

% Draw stimulus on projector every frame
win   = expmt.hardware.screen.window;
black = expmt.hardware.screen.black;

% Clear to black every frame
Screen('FillRect', win, black);

spot_half = stim.spot_half;

for i = 1:expmt.meta.roi.n
    if stim_on(i)
        cx = stim.centers(i, 1);
        cy = stim.centers(i, 2);
        spot_rect = [cx - spot_half, cy - spot_half, cx + spot_half, cy + spot_half];
        Screen('FillOval', win, 255, spot_rect');
    end
end

% Flip every frame
expmt.hardware.screen.vbl = ...
    Screen('Flip', win, ...
        expmt.hardware.screen.vbl + ...
        (expmt.hardware.screen.waitframes - 0.5) * ...
        expmt.hardware.screen.ifi);

% Re-assign stim struct and StimStatus
expmt.meta.stim     = stim;
trackDat.StimStatus = stim_on;
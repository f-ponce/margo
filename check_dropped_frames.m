%load('C:\Users\de Bivort Lab\Documents\MATLAB\margo_data\03-27-2026-21-57-33__Y-Maze_1-96_Day1\03-27-2026-21-57-33__Y-Maze_1-96_Day1.mat')

total = expmt.meta.num_frames;
dropped = expmt.meta.num_dropped;
drop_rate = dropped ./ total * 100;
n_rois = expmt.meta.roi.n;

figure('Name','Dropped Frames Summary');

% Plot 1: drop rate per ROI as bar chart
subplot(2,2,1);
bar(drop_rate);
xlabel('ROI #');
ylabel('Drop rate (%)');
title('Drop rate per ROI');
yline(100,'r--','100%');

% Plot 2: histogram of drop rates
subplot(2,2,2);
histogram(drop_rate(drop_rate < 100), 20);
xlabel('Drop rate (%)');
ylabel('Number of ROIs');
title('Distribution of drop rates (excluding 100%)');

% Plot 3: spatial map of drop rates overlaid on ROI centers
subplot(2,2,3);
scatter(expmt.meta.roi.centers(:,1), expmt.meta.roi.centers(:,2), ...
    100, drop_rate, 'filled');
colorbar;
colormap(gca, 'hot');
axis image;
set(gca,'YDir','reverse');
xlabel('X (px)');
ylabel('Y (px)');
title('Spatial map of drop rates (%)');

% Plot 4: summary stats
subplot(2,2,4);
axis off;
summary = {
    sprintf('Total frames: %d', total)
    sprintf('Total ROIs: %d', n_rois)
    sprintf('ROIs at 100%%: %d', sum(drop_rate >= 99))
    sprintf('ROIs > 3-3%%: %d', sum(drop_rate > 3 & drop_rate < 5))
    sprintf('ROIs <= 3%%: %d', sum(drop_rate <= 3))
    sprintf('Mean drop rate (excl 100%%): %.1f%%', mean(drop_rate(drop_rate < 99)))
    sprintf('Max drop rate (excl 100%%): %.1f%%', max(drop_rate(drop_rate < 99)))
};
text(0.1, 0.5, summary, 'Units','normalized', 'VerticalAlignment','middle', 'FontSize', 11);
title('Summary');
function [num_frames, num_batches] = get_batch_sizes(data)

% split data into batches
data_sz = size(data);
precision = class(data(1));

% query bytes per element
switch precision
    case 'logical'
        bytes_per_el = 1/8;
    case 'uint8'
        bytes_per_el = 1;
    case 'int8'
        bytes_per_el = 1;
    case 'uint16'
        bytes_per_el = 2;
    case 'int16'
        bytes_per_el = 2;
    case 'uint32'
        bytes_per_el = 4;
    case 'int32'
        bytes_per_el = 4;
    case 'single'
        bytes_per_el = 4;
    case 'double'
        bytes_per_el = 8;
    case 'uint64'
        bytes_per_el = 8;
    case 'int64'
        bytes_per_el = 8;
    otherwise
        error('data is not numeric');
end

% get total number of bytes (oversize by factor 2) and query available memory
total_bytes = numel(data) * bytes_per_el *2;
mem_stats = memory;

% calculate batch size and number
num_batches = ceil(total_bytes/mem_stats.MemAvailableAllArrays);
num_frames = ceil(data_sz(1)/num_batches);

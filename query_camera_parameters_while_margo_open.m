vid = imaqfind;
src = getselectedsource(vid);
info = propinfo(src);
names = fieldnames(info);

fprintf('\n=== All Camera Parameters ===\n\n');
for i = 1:length(names)
    try
        val = src.(names{i});
        if isnumeric(val)
            fprintf('%-30s: %g\n', names{i}, val);
        else
            fprintf('%-30s: %s\n', names{i}, num2str(val));
        end
    catch
        fprintf('%-30s: [could not read]\n', names{i});
    end
end
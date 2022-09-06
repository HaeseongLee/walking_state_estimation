% This function is for finding the "end_index"
% "end_index" means in two ways. One is the falling time, or the other is
% the time when the robot completes the walking without falling.

function end_index = getEndIndex(f_z, min_grf)
    end_index = find(f_z<=min_grf, 1);
end
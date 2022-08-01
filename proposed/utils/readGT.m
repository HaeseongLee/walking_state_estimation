function [gt] = readGT(filename)

    file_dir = "data/test/" + filename;
    jsonData = jsondecode(fileread(file_dir + '/walking_result.json'));
    
    total_num_steps = jsonData.number_of_foot_off;
    
    n_step_map = ones(total_num_steps,1);  % indices for nominal WS
    i_step_map = zeros(total_num_steps,1); % indices for disturbed, but insignificant WS
    c_step_map = zeros(total_num_steps,1); % indices for disturbed, and cautious WS
    f_step_map = zeros(total_num_steps,1); % indices for falling WS
    gt = zeros(total_num_steps,1);
    
    if ~ischar(jsonData.disturbed_footstep_index)
        for i = 1:length(jsonData.disturbed_footstep_index)
            idx(i) = jsonData.disturbed_footstep_index(i)+1; 
        end
        i_step_map(idx) = 1;
    end
       
    if jsonData.walking_result == "fail"
       f_step_map(idx(end-1)) = 1;
       c_step_map(idx(end)) = 1;
       % remove
       i_step_map(idx(end-1:end)) = 0;
    end

    n_step_map(i_step_map == 1) = 0;
    n_step_map(f_step_map == 1) = 0;
    n_step_map(c_step_map == 1) = 0;
    
    gt(n_step_map == 1) = 0;
    gt(i_step_map == 1) = 1;
    gt(f_step_map == 1) = 2;
    gt(c_step_map == 1) = 3;

    gt = reshape(gt',1,[]);
    if jsonData.walking_result == "fail"
        gt = gt(1:find(gt == 3, 1));
    end
end


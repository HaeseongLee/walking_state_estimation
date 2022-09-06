function [gt] = readGT(filename)

    jsonData = jsondecode(fileread(filename + '/walking_result.json'));
    
    total_num_steps = jsonData.number_of_foot_off;
    
    step_s_map = ones(total_num_steps,1);
    step_d_map = zeros(total_num_steps,1);
    step_f_map = zeros(total_num_steps,1);
    step_h_map = zeros(total_num_steps,1);
    gt = zeros(total_num_steps,1);
    
    if ~ischar(jsonData.disturbed_footstep_index)
        for i = 1:length(jsonData.disturbed_footstep_index)
            idx(i) = jsonData.disturbed_footstep_index(i)+1;
        end
        step_d_map(idx) = 1;
    end
    
    if jsonData.walking_result == "fail"
        step_h_map(idx(end-1)) = 1;
        step_f_map(idx(end)) = 1;
        % remove
        step_d_map(idx(end-1:end)) = 0;
    end
    
    step_s_map(step_d_map == 1) = 0;
    step_s_map(step_h_map == 1) = 0;
    step_s_map(step_f_map == 1) = 0;
    
    gt(step_s_map == 1) = 0;
    gt(step_d_map == 1) = 0;
    gt(step_h_map == 1) = 0;
    gt(step_f_map == 1) = 1;
    
    gt = reshape(gt',1,[]);
    %     if jsonData.walking_result == "fail"
    %         gt = gt(1:find(gt == 1, 1));
    %     end
end


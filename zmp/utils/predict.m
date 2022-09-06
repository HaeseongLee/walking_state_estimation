function [y_true, y_pred, falling_idx] = predict(filename, padding)
    hz = 2000;
    walking_start = 4*hz;
    step_duration = 1.1*hz;
    falling_start_ratio = 0.5;
    falling_end_ratio = 0.1;
   
    %% Load data
    ft_raw = load(filename+"/f.txt");
    num_steps = load(filename+"/num_steps.txt");
    json_data = jsondecode(fileread(filename+'/walking_result.json'));
    
    ft_nominal = load("../data/nominal_walking/ft_nominal.mat");
    ft_mean = ft_nominal.ft_nominal.mean;
    
    ft_add = abs(ft_raw(:,1:6) + ft_raw(:,7:12));
    
    num_samples = length(ft_add);
    
    falling_start_grf = ft_mean(3)*falling_start_ratio;
    falling_end_grf = ft_mean(3)*falling_end_ratio;
    falling_start_index = getEndIndex(ft_add(:,3), falling_start_grf);
    falling_end_index = getEndIndex(ft_add(:,3), falling_end_grf);
    end_index = falling_end_index;
    
    if isempty(end_index)
        end_index = walking_start + (max(num_steps)+1)*step_duration;
        total_num_steps = max(num_steps)+1;
    else
        total_num_steps = num_steps(end_index)+1;
    end    
    
    %% Estimate data using zmp    
    zmp_result_split = split(filename,"/");
    
    falling_idx = load("pad_"+padding+"/"+zmp_result_split(end)+".mat");    
    falling_idx=falling_idx.falling_idx;
    
    ws = zeros(num_samples,1);
    ws(falling_idx+walking_start) = 1;

    window = 400;%500;
    cs_filtered = zeros(length(ws),1);
    for j = window:length(ws)    
        roi = ws(j-window+1:j,1);     
        if length(find(roi~=0)) == window
            cs_filtered(j) = ws(j);
        end
    end
    falling_idx = find(cs_filtered==1,1);
 
    %% get ground truth
    step_phase = 1:step_duration:(total_num_steps+1)*step_duration;
    step_phase = step_phase + walking_start;
    step_phase = reshape(step_phase,1,[]);

    gt = readGT(filename);
    
    dominant_cs = zeros(length(gt),1);
    for i = 1:length(gt)
        if i == length(gt)
            cs_slice = cs_filtered(step_phase(i):end);
        else
            cs_slice = cs_filtered(step_phase(i):step_phase(i+1)-1);
        end
        dominant_cs(i) = max(cs_slice);
    end
    
    y_true = gt';
    y_pred = dominant_cs;
    
    if falling_idx > end_index
        disp("Falling!!!")
        falling_idx = [];
    end
end



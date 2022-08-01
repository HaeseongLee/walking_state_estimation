function [y_true, y_pred, falling_idx, step_phase, total_foot_steps] = predict(filename)
    % add train dataset path     
    if isempty(filename)
        addpath("data/test/")
    else
        addpath("data/test/"+filename)
    end

    model_serial = "50";
    min_grf = str2double(model_serial);
    
    % load foot height(fh) indicator
    fh_model = load("model/pose_"+model_serial+"/gmm_p.mat");
    fh_info = load("model/pose_"+model_serial+"/foot_height_indicator.mat");
    fh_model = fh_model.gmm_p;
    fh_info = fh_info.foot_height_indicator;
    
    % load disturbance(di) indicator
    di_model = load("model/force_"+model_serial+"/gmm_f.mat");
    di_info = load("model/force_"+model_serial+"/disturbance_indicator.mat");
    add_mean = load("model/nominal_walking/add_mean.mat");
    add_cov = load("model/nominal_walking/add_cov.mat");
    
    di_model = di_model.gmm_f;
    di_info = di_info.disturbance_indicator;
    add_mean = add_mean.f_add_mean;
    add_cov = add_cov.f_add_cov;
    
    hz = 2000;
    walking_start = 4*hz;
    step_duration = 1.1*hz;
    %% Load data
    p_raw = load("p.txt");
    f = load("f.txt");
    % num_step = load("num_steps.txt");
    jsonData = jsondecode(fileread('walking_result.json'));
    num_step = jsonData.number_of_foot_off;
    
    num_samples = length(p_raw); % the number of samples
    total_foot_steps = ceil((num_samples-walking_start)/step_duration);
    
    f_add_raw = abs(f(:,1:6) + f(:,7:end));
    end_index = find(f_add_raw(:,3)<=min_grf, 1);
    
    % pre-process for the input of each indicator
    f_add = zeros(length(f_add_raw),1);
    sigma_inv = (add_cov)^-1;
    for i = 1:length(f_add)
        f_add(i) = (f_add_raw(i,:)-add_mean)*sigma_inv*(f_add_raw(i,:)-add_mean)';
    end
    f_add = sqrt(f_add);
    
    step_start = zeros(max(num_step),1);
    for i = 0:max(num_step)
        step_start(i+1) = walking_start + i*step_duration;
    end
    p_z = zeros(num_samples,1);
    p_z(1:walking_start,1) = p_raw(1:walking_start,6);
    for i = 1:max(num_step)+1     
        if i == max(num_step)+1
            if mod(i-1,2) == 1 % left foot suuport phase, get right foot info
                p_z(step_start(i)+1:end_index) = p_raw(step_start(i),6);
            else % right foot suuport phase, get left foot info
                p_z(step_start(i)+1:end_index) = p_raw(step_start(i),3);
            end    
        else
            if mod(i-1,2) == 1 % left foot suuport phase, get right foot info
                p_z(step_start(i)+1:step_start(i+1)) = p_raw(step_start(i),6);
            else % right foot suuport phase, get left foot info
                p_z(step_start(i)+1:step_start(i+1)) = p_raw(step_start(i),3);
            end
        end
    end
    
    p_z = abs(p_z);
    %% Estimate data using indicators
    [Zn, Zs, Zl] = footHeightPredict(p_z, fh_model, fh_info, false);
    Zn_index = Zn == 1;
    Zs_index = Zs == 1;
    Zl_index = Zl == 1;
    
    % Position along z-axis
    Z = zeros(num_samples,1);
    Z(Zn_index) = fh_info.Zn;
    Z(Zs_index) = fh_info.Zs;
    Z(Zl_index) = fh_info.Zl;
    
    [Fn, Fs, Fl, Ff] = disturbanceIndicator(f_add, di_model, di_info, false);
    Fn_index = Fn == 1;
    Fs_index = Fs == 1;
    Fl_index = Fl == 1;
    Ff_index = Ff == 1;
    
    F = zeros(num_samples,1);
    F(Fn_index) = di_info.Fn;
    F(Fs_index) = di_info.Fs;
    F(Fl_index) = di_info.Fl;
    F(Ff_index) = di_info.Ff;
    
    % estimate the current walking state(ws)
    ws = rule(Z, F, fh_info, di_info);

    % filtering    
    ws_i_buffer = 200;
    ws_c_buffer = 200;
    ws_f_buffer = 100;
    ws_filtered = wsFilter(ws, 1, ws_i_buffer);    
    ws_filtered = wsFilter(ws_filtered, 2, ws_c_buffer);    
    ws_filtered = wsFilter(ws_filtered, 3, ws_f_buffer);    
    ws = ws_filtered;

    falling_idx = find(ws == 3, 1);
    %% get ground truth
    step_phase = 1:step_duration:(total_foot_steps+1)*step_duration;
    step_phase = step_phase + walking_start;
    step_phase = reshape(step_phase,1,[]);
    gt = readGT(filename);
    
    dominant_ws = zeros(length(gt),1);    
    for i = 1:length(gt)
        if i == length(gt)
            ws_slice = ws(step_phase(i):end);
        else
            ws_slice = ws(step_phase(i):step_phase(i+1)-1);
        end
        dominant_ws(i) = max(ws_slice);
    end
    
    y_true = gt';
    y_pred = dominant_ws;
    
end



% This function is the same as "plot_ws.m"

function [y_true, y_pred, falling_index, step_phase, falling_index_diff] = predict(filename)

hz = 2000;
walking_start = 4*hz;
step_duration = 1.1*hz;
falling_start_ratio = 0.5;
falling_end_ratio = 0.1;

% load ft indicator
ft_model = load("model/gmm_ft.mat");
ft_info = load("model/ft_indicator.mat");
ft_model = ft_model.gmm_ft;
ft_info = ft_info.ft_indicator;

ft_nominal = load("../data/nominal_walking/ft_nominal.mat");
ft_mean = ft_nominal.ft_nominal.mean;
ft_cov = ft_nominal.ft_nominal.cov;

p_model = load("model/gmm_p.mat");
p_info = load("model/p_indicator.mat");
p_model = p_model.gmm_p;
p_info = p_info.p_indicator;

p_raw = load(filename+"/p.txt");
ft_raw = load(filename+"/f.txt");
num_steps = load(filename+"/num_steps.txt");
json_data = jsondecode(fileread(filename+'/walking_result.json'));

ft_add = abs(ft_raw(:,1:6) + ft_raw(:,7:12));


%% Load data
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
%% pre-process data

% for disturbance indicator
f_mahal = zeros(length(ft_add),1);
m_mahal = zeros(length(ft_add),1);
sigma_inv = (ft_cov)^-1;
for i = 1:length(ft_add)
    f_mahal(i) = (ft_add(i,1:3)-ft_mean(1:3))*sigma_inv(1:3,1:3)*(ft_add(i,1:3)-ft_mean(1:3))';
    m_mahal(i) = (ft_add(i,4:6)-ft_mean(4:6))*sigma_inv(4:6,4:6)*(ft_add(i,4:6)-ft_mean(4:6))';
end
f_mahal = sqrt(f_mahal);
m_mahal = sqrt(m_mahal);
f_in = [f_mahal, m_mahal];

% for foot height indicator
step_start = zeros(total_num_steps+1,1);
for i = 1:total_num_steps
    step_start(i) = walking_start + (i-1)*step_duration;
end

p_z = zeros(length(p_raw),1);
p_z(1:walking_start,1) = p_raw(1:walking_start,6);
for i = 1:total_num_steps
    if i == total_num_steps
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
[FTz, FTs, FTm, FTl] = disIndicator(f_in, ft_model, ft_info, false);
FTz_index = FTz == 1;
FTs_index = FTs == 1;
FTm_index = (FTm == 1);
FTl_index = (FTl == 1);

FT = zeros(num_samples,1);
FT(FTz_index) = ft_info.z;
FT(FTs_index) = ft_info.s;
FT(FTm_index) = ft_info.m;
FT(FTl_index) = ft_info.l;

[Ps, Pl] = fhIndicator(p_z, p_model, p_info, false);
Ps_index = (Ps == 1);
Pl_index = (Pl == 1);

P = zeros(num_samples,1);
P(Ps_index) = p_info.s;
P(Pl_index) = p_info.l;

%%
ws = rule(P, FT, p_info, ft_info);

% filtering
ws_i_buffer = 80;
ws_c_buffer = 80;
ws_f_buffer = 60;
ws_filtered = wsFilter(ws, 1, ws_i_buffer);
ws_filtered = wsFilter(ws_filtered, 2, ws_c_buffer);
ws_filtered = wsFilter(ws_filtered, 3, ws_f_buffer);
ws = ws_filtered;


falling_index = find(ws == 3, 1);
ws(falling_index:end) = 3;

step_phase = (step_start - walking_start)/hz;

% when "falling_index_diff" > 0 : early estimation!
% when "falling_index_diff" < 0 : late estimation!
falling_index_diff = falling_start_index - falling_index;

%%
gt= readGT(filename);
dominant_ws = zeros(total_num_steps,1);
for i = 1:total_num_steps
    if i == total_num_steps
        ws_slice = ws(step_start(i)+1:end_index);
    else
        ws_slice = ws(step_start(i)+1:step_start(i)+step_duration);
    end
    dominant_ws(i) = max(ws_slice);
end

% when the falling state is estimated before GT
if length(dominant_ws)<length(gt)
    dominant_ws(length(dominant_ws)+1:length(gt)) = dominant_ws(end);
end
y_true = gt';
y_pred = dominant_ws;

end



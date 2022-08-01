clc
clear

% add train dataset path
addpath("../data_3/50/")
addpath("model/")

% add model path
% addpath("model/")

model_root = "~/catkin_ws/src/foot_contact_estimation/myClassifier_mahal/model/";
model_serial = "50";
min_grf = str2double(model_serial);

% load position model
pos_model = load(model_root+"/pose_"+model_serial+"/1e-8/gmm_p.mat");
pos_info = load(model_root+"/pose_"+model_serial+"/1e-8/pose_indicator.mat");
pos_model = pos_model.gmm_p;
pos_info = pos_info.PoseIndicator;

% load disturbance model
add_model = load(model_root+"/force_"+model_serial+"/1e-4/gmm_f.mat");
add_info = load(model_root+"/force_"+model_serial+"/1e-4/add_indicator.mat");
add_mean = load("model/base_walking/add_mean.mat");
add_cov = load("model/base_walking/add_cov.mat");

add_model = add_model.gmm_f;
add_info = add_info.AddIndicator;
add_mean = add_mean.f_add_mean;
add_cov = add_cov.f_add_cov;

%% Load data
hz = 2000;
walking_start = 4*hz;
step_duration = 1.1*hz;
ds_duration = 0.23*hz;

p_z = load("support_foot_p.txt");
f_add = load("f_add.txt");
num_step = load("num_steps.txt");

num_samples = length(p_z); % the number of samples
total_foot_steps = ceil((num_samples-walking_start)/step_duration);

f_in = zeros(length(f_add),1);
sigma_inv = (add_cov)^-1;
for i = 1:length(f_add)
    f_in(i) = (f_add(i,:)-add_mean)*sigma_inv*(f_add(i,:)-add_mean)';
end
f_in = sqrt(f_in);


%% Estimate data using indicators
[Pn, Ps, Pl] = posePredict_3d(p_z, pos_model, pos_info, false);
Pn_index = find(Pn == 1);
Ps_index = find(Ps == 1);
Pl_index = find(Pl == 1);

% Position along z-axis
P = zeros(num_samples,1);
P(Pn_index) = pos_info.Pn;
P(Ps_index) = pos_info.Ps;
P(Pl_index) = pos_info.Pl;

[Fn, Fs, Fl, Ff] = addPredict_4d(f_in, add_model, add_info, false);
Fn_index = find(Fn == 1);
Fs_index = find(Fs == 1);
Fl_index = find(Fl == 1);
Ff_index = find(Ff == 1);

F = zeros(num_samples,1);
F(Fn_index) = add_info.Fn;
F(Fs_index) = add_info.Fs;
F(Fl_index) = add_info.Fl;
F(Ff_index) = add_info.Ff;

cs = rule(P, F, pos_info, add_info);
disturbed_window = 200;
hazard_window = 200;
falling_window = 100;
cs_filtered = csFilter(cs, 1, disturbed_window);    
cs_filtered = csFilter(cs_filtered, 2, hazard_window);    
cs_filtered = csFilter(cs_filtered, 3, falling_window);    

%%
F_plot(Fn_index) = 0;
F_plot(Fs_index) = 200;
F_plot(Fl_index) = 400;
F_plot(Ff_index) = 600;

P_plot = zeros(num_samples,1);
P_plot(Pn_index) = 0;
P_plot(Ps_index) = 0.05;
P_plot(Pl_index) = 0.1;

%%
ws_n = cs_filtered == 0;
ws_i = cs_filtered == 1;
ws_c = cs_filtered == 2;
ws_f = cs_filtered == 3;

% ws_n = cs == 0;
% ws_i = cs == 1;
% ws_c = cs == 2;
% ws_f = cs == 3;


figure(5)
scatter(f_in(ws_n), p_z(ws_n),0.1, '.r')
hold on
scatter(f_in(ws_i), p_z(ws_i),0.1, '.g')
scatter(f_in(ws_c), p_z(ws_c),0.1,'.b')
scatter(f_in(ws_f), p_z(ws_f),0.1, '.m')
hold off
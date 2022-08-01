clc
clear

% add train dataset path
addpath("data/test/test_30")

addpath("utils/") % call custom functions

% proposed vs CoP-ZMP with test_30!
zmp = load("data/zmp_result_30.mat");
zmp = zmp.zmp_filtered();

model_serial = "50";
min_grf = str2double(model_serial);

% load foot-height(fh) indicator
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

%% Load data
hz = 2000;
walking_start = 4*hz;
step_duration = 1.1*hz;

p_raw = load("p.txt");
f = load("f.txt");
num_step = load("num_steps.txt");

num_samples = length(p_raw); % the number of samples
total_foot_steps = ceil((num_samples-walking_start)/step_duration);

f_add_raw = abs(f(:,1:6) + f(:,7:end));
end_index = find(f_add_raw(:,3)<=min_grf, 1);

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
p_z = zeros(length(p_raw),1);
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
Zn_index = find(Zn == 1);
Zs_index = find(Zs == 1);
Zl_index = find(Zl == 1);

% Position along z-axis
Z = zeros(num_samples,1);
Z(Zn_index) = fh_info.Zn;
Z(Zs_index) = fh_info.Zs;
Z(Zl_index) = fh_info.Zl;

[Fn, Fs, Fl, Ff] = disturbanceIndicator(f_add, di_model, di_info,false);
Fn_index = find(Fn == 1);
Fs_index = find(Fs == 1);
Fl_index = find(Fl == 1);
Ff_index = find(Ff == 1);

F = zeros(num_samples,1);
F(Fn_index) = di_info.Fn;
F(Fs_index) = di_info.Fs;
F(Fl_index) = di_info.Fl;
F(Ff_index) = di_info.Ff;

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

falling_index = find(ws_filtered == 3, 1);
if falling_index > end_index
    disp("Wrong Estimation!!")
end
%%
F_plot(Fn_index) = 0;
F_plot(Fs_index) = 200;
F_plot(Fl_index) = 400;
F_plot(Ff_index) = 600;

P_plot = zeros(num_samples,1);
P_plot(Zn_index) = 0;
P_plot(Zs_index) = 0.03;
P_plot(Zl_index) = 0.06;

% gt = readGT(filename);
[y_true, est, ~, step_phase, valid_step_num] = predict("test_30");

if isempty(end_index)
    end_index = (valid_step_num)*step_duration + walking_start ;
end
if isempty(falling_index)
    falling_index = end_index;
end

tick = 0:end_index-walking_start;
time = tick/hz;

last_time = end_index/hz;
falling_time = falling_index/hz;
start_time = walking_start/hz;
%%
figure(1)
cla reset

subplot(3,1,1)
plot(time,f_add_raw(walking_start:end_index,1),LineWidth=1.5)
hold on
plot(time, f_add_raw(walking_start:end_index,2:6),LineWidth=1.5)
hold off
grid on
set(gca,'FontName','Times','FontSize',13,'TickLabelInterpreter','latex');
ylabel("$\textbf{F}$ (N or Nm)", FontName='Times', Interpreter="latex", FontSize=13)
set(gca, 'YTick',[0.0, 500, 1000])
xlim([0,max(time)])
ylim([-100,1400])
legend("$f_x$",'$f_y$','$f_z$',...
    '$m_x$','$m_y$','$m_z$',NumColumns=6,FontName='Times',Interpreter='latex',...
    FontSize=13)

subplot(3,1,2)
set(gcf, 'renderer', 'painters', 'Position',[4000,0,600,600]);
plot(time, p_z(walking_start:end_index), LineWidth=1.5)
grid on
set(gca,'FontName','Times','FontSize',13,'TickLabelInterpreter','latex');
ylim([-0.001,0.021])
xlim([0,max(time)])
ylabel("$\textup{P}_z$ (m)","FontName",'Times',Interpreter='latex',FontSize=13)
set(gca, 'YTick',[0.0, 0.01,0.02])


subplot(3,1,3)
plot(time, ws(walking_start:end_index,1), LineWidth=1.5)
grid on
xlim([0, max(time)])
ylim([-0.1,3.1])
set(gca,'FontName','Times','TickLabelInterpreter','latex');
set(gca, 'YTick',[0,1,2,3],'YTickLabels',{'$\textup{WS}_n$','$\textup{WS}_i$',...
    '$\textup{WS}_c$','$\textup{WS}_f$'},'FontSize',13)
ylabel("Proposed",Interpreter='latex', FontName='Times', FontSize=13)
xlabel("\textbf{Time} (sec)", "FontName",'Times',Interpreter='latex', FontSize=13)

yyaxis right
plot(time, zmp(walking_start:end_index,1), LineWidth=1.5)
set(gca,'YColor','k')
set(gca, 'YLim', [-0.1,3.1])
set(gca,'FontName','Times','FontSize',13,'TickLabelInterpreter','latex');
set(gca, 'YTick',[0.0, 3.0],'YTickLabels',{'stable','falling'})
ylabel("CoP-ZMP", FontName='times', Interpreter='latex', fontsize=13)
legend("$\textup{Proposed}$",'$\textup{CoP}$-$\textup{ZMP}$', FontName='Times',Interpreter='latex',...
    FontSize=12, location='northwest')
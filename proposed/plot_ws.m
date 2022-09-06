% This script is for plotting the result of the proposed framework

clc
clear

addpath("utils/")

% add train dataset path
filename = "test_11";
addpath("../data/test/"+filename)

% set the basic walking paramters
hz = 2000;
walking_start = 4*hz;
step_duration = 1.1*hz;
ds_duration = 0.23*hz;
falling_start_ratio = 0.5;
falling_end_ratio = 0.1;

% Load disturbance indicator
ft_model = load("model/gmm_ft.mat");
ft_info = load("model/ft_indicator.mat");
ft_model = ft_model.gmm_ft;
ft_info = ft_info.ft_indicator;

% Load nominal walking data
ft_nominal = load("../data/nominal_walking/ft_nominal.mat");
ft_mean = ft_nominal.ft_nominal.mean;
ft_cov = ft_nominal.ft_nominal.cov;

% Load foot height indicator
p_model = load("model/gmm_p.mat");
p_info = load("model/p_indicator.mat");
p_model = p_model.gmm_p;
p_info = p_info.p_indicator;

p_raw = load("p.txt");
ft_raw = load("f.txt");
num_steps = load("num_steps.txt");
json_data = jsondecode(fileread('walking_result.json'));

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

% Get mahalanobis distance for the f/t measurments
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

step_start = zeros(total_num_steps+1,1);
for i = 1:total_num_steps+1
    step_start(i) = walking_start + (i-1)*step_duration;
end

% Get the difference between the previous and current footsteps
p_z = zeros(length(p_raw),1);
p_z(1:walking_start,1) = p_raw(1:walking_start,6);
for i = 1:total_num_steps+1
    if i == total_num_steps+1
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

% Inference through disturbance indicator
[FTz, FTs, FTm, FTl] = disIndicator(f_in, ft_model, ft_info, false);
FTz_index = find(FTz == 1);
FTs_index = find(FTs == 1);
FTm_index = find(FTm == 1);
FTl_index = find(FTl == 1);

% For visualizing
FT_plot = zeros(num_samples,1);
FT_plot(FTz_index) = 1;
FT_plot(FTs_index) = 2;
FT_plot(FTm_index) = 3;
FT_plot(FTl_index) = 4;

% For inference through the discriminator
FT = zeros(num_samples,1);
FT(FTz_index) = ft_info.z;
FT(FTs_index) = ft_info.s;
FT(FTm_index) = ft_info.m;
FT(FTl_index) = ft_info.l;

% Inference through foot height indicator
[Ps, Pl] = fhIndicator(p_z, p_model, p_info, false);
Ps_index = find(Ps == 1);
Pl_index = find(Pl == 1);

% For visualizing
P_plot = zeros(num_samples,1);
P_plot(Ps_index) = 1;
P_plot(Pl_index) = 2;

% For inference through the discriminator
P = zeros(num_samples,1);
P(Ps_index) = p_info.s;
P(Pl_index) = p_info.l;

%%

% Estimate the current WS using the discriminator
ws = rule(P, FT, p_info, ft_info);

% filtering
ws_i_buffer = 80;
ws_c_buffer = 80;
ws_f_buffer = 60;
ws_filtered = wsFilter(ws, 1, ws_i_buffer);
ws_filtered = wsFilter(ws_filtered, 2, ws_c_buffer);
ws_filtered = wsFilter(ws_filtered, 3, ws_f_buffer);
ws = ws_filtered;

falling_index = find(ws == 3, 1) - walking_start;

% Set all following WS as WS_f from the first detection of WS_f.
ws(falling_index+walking_start:end) = 3;

tick = 0:end_index-walking_start;
time = tick/hz;

end_time = (end_index-walking_start)/hz;
falling_time = falling_index/hz;
start_time = walking_start/hz;
step_phase = (step_start - walking_start)/hz;
falling_start_time = (falling_start_index-walking_start)/hz;

% Compare the estimated WS to the ground truth.
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



%%
figure(1)
set(gcf, 'renderer', 'painters', 'Position',[4000,0,600,200]);
cla reset
plot(time,f_in(walking_start:end_index,:),LineWidth=2)
ylabel("$\textbf{F}_{in}$", FontName='Times', Interpreter="latex", FontSize=13)
xlabel("\textbf{Time} (sec)", "FontName",'Times',Interpreter='latex', FontSize=13)
set(gca, 'YTick',[0.0, 20, 40])
xlim([0,max(time)])
ylim([-0,45])

yyaxis right
plot(time, FT_plot(walking_start:end_index),LineWidth=2.0, color='k', LineStyle="-")
hold on
for i = 1:total_num_steps
    plot([step_phase(i), step_phase(i)], [0, 10], LineWidth=2, Color="k", LineStyle="--")
end
hold off
grid on
set(gca,'YColor','k')
set(gca, 'YLim', [0.9,8])
set(gca,'FontName','Times','FontSize',13,'TickLabelInterpreter','latex');
set(gca, 'YTick',[1,2, 3, 4],'YTickLabels',{'$\tau_z$','$\tau_s$','$\tau_m$','$\tau_l$'})
ylabel("\textup{Output}", FontName='times', Interpreter='latex', fontsize=13)
legend("$\textup{F}$","\textup{M}",'$\textup{output}$',NumColumns=6,FontName='Times',Interpreter='latex',...
    FontSize=13)
%%
figure(2)
cla reset
set(gcf, 'renderer', 'painters', 'Position',[4000,300,600,200]);
plot(time, p_z(walking_start:end_index,1),LineWidth=1.5)
hold on
for i = 1:total_num_steps
    plot([step_phase(i), step_phase(i)], [0, 0.1], LineWidth=2, Color="k", LineStyle="--")
end
hold off
grid on
ylabel("$\textbf{P}_{in}$ (m)","FontName",'Times',Interpreter='latex',FontSize=13)
xlabel("\textbf{Time} (sec)", "FontName",'Times',Interpreter='latex', FontSize=13)
xlim([0, (end_index-walking_start)/hz+0.001])
ylim([-0.001,0.03])
set(gca, 'YTick',[0.0, 0.01,0.02])
set(gca,'FontName','Times','FontSize',13,'TickLabelInterpreter','latex');

yyaxis right
plot(time, P_plot(walking_start:end_index),LineWidth=2.0, color='k')
set(gca,'YColor','k')
set(gca, 'YLim', [0.9,4])
set(gca,'FontName','Times','FontSize',13,'TickLabelInterpreter','latex');
set(gca, 'YTick',[1,2],'YTickLabels',{'$Z_s$','$Z_l$'})
ylabel("\textup{Output}", FontName='times', Interpreter='latex', fontsize=13)
legend("$p_z$",'$\textup{output}$',NumColumns=6,FontName='Times',Interpreter='latex',...
    FontSize=13, location="northwest")
%%
figure(3)
set(gcf, 'renderer', 'painters', 'Position',[4000,600,600,200]);
cla reset
plot(time, ws(walking_start:end_index), LineWidth=2.0)
hold on
if ~isempty(falling_time)
    plot([falling_time, falling_time], [0,3], LineWidth=2, Color='r', LineStyle="-.")
end
plot([step_phase, step_phase], [0,3], LineWidth=2, Color='k', LineStyle="--")
grid on
xlim([0, max(time)])
ylim([-0.1,3.1])
set(gca,'FontName','Times','TickLabelInterpreter','latex');
set(gca, 'YTick',[0,1,2,3],'YTickLabels',{'$\textup{WS}_n$','$\textup{WS}_i$',...
    '$\textup{WS}_c$','$\textup{WS}_f$'},'FontSize',13)
ylabel("Walking State",Interpreter='latex', FontName='Times', FontSize=13)
xlabel("\textbf{Time} (sec)", "FontName",'Times',Interpreter='latex', FontSize=13)

%%
figure(4)
set(gcf, 'renderer', 'painters', 'Position',[3300,600,600,200]);
cla reset
plot([step_phase(1),step_phase(2)], [gt(1),gt(1)], LineWidth=2, Color="k")
hold on
plot([step_phase(1),step_phase(2)], [dominant_ws(1),dominant_ws(1)], LineWidth=2, Color="r", LineStyle="--")
for i = 2:total_num_steps
    plot([step_phase(i),step_phase(i+1)], [gt(i),gt(i)], LineWidth=2, Color="k")
end
for i = 2:total_num_steps
    plot([step_phase(i),step_phase(i+1)], [dominant_ws(i),dominant_ws(i)], LineWidth=2, Color="r", LineStyle="--")
end
if ~isempty(falling_time)
    plot([falling_time, falling_time], [0,3], LineWidth=2, Color='r', LineStyle="-.")
end
plot([step_phase, step_phase], [0,3], LineWidth=2, Color='k', LineStyle="--")
grid on
xlim([0, max(time)])
ylim([-0.1,3.1])
set(gca,'FontName','Times','TickLabelInterpreter','latex');
set(gca, 'YTick',[0,1,2,3],'YTickLabels',{'$\textup{WS}_n$','$\textup{WS}_i$',...
    '$\textup{WS}_c$','$\textup{WS}_f$'},'FontSize',13)
ylabel("Walking State",Interpreter='latex', FontName='Times', FontSize=13)
xlabel("\textbf{Time} (sec)", "FontName",'Times',Interpreter='latex', FontSize=13)
legend("$\textup{GT}$","$\textup{EST}$",NumColumns=6,FontName='Times',Interpreter='latex',...
    FontSize=13, location="northwest")
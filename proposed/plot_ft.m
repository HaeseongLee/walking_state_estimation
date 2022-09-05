% This script is for plotting the result of the disturbance indicator

clc
clear

addpath("utils/")

% add train dataset path
filename = "test_11";
addpath("~/.ros/data/"+filename)

% set the basic walking paramters
hz = 2000;
walking_start = 4*hz;
step_duration = 1.1*hz;
ds_duration = 0.23*hz;
falling_start_ratio = 0.5;
falling_end_ratio = 0.1;

% load disturbance indicator
ft_model = load("model/gmm_ft.mat");
ft_info = load("model/ft_indicator.mat");
ft_model = ft_model.gmm_ft;
ft_info = ft_info.ft_indicator;

% load nominal walking data
ft_nominal = load("data/nominal_walking/ft_nominal.mat");
ft_mean = ft_nominal.ft_nominal.mean;
ft_cov = ft_nominal.ft_nominal.cov;

%%
f_raw = load("f.txt");
json_data = jsondecode(fileread('walking_result.json'));
num_steps = json_data.number_of_foot_off;

ft_add = abs(f_raw(:,1:6) + f_raw(:,7:12));
num_samples = length(f_raw);

falling_start_grf = ft_mean(3)*falling_start_ratio;
falling_end_grf = ft_mean(3)*falling_end_ratio;

falling_start_index = getEndIndex(ft_add(:,3), falling_start_grf);
end_index = getEndIndex(ft_add(:,3), falling_start_grf);

if isempty(end_index)
    end_index = walking_start + num_steps*step_duration;
end

% Compute Mahalanobis distance
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

%% Estimate data using indicators

% Inference
[z, s, m, l] = disIndicator(f_in, ft_model, ft_info, false);
z_index = find(z == 1);
s_index = find(s == 1);
m_index = find(m == 1);
l_index = find(l == 1);

% For visualizing
FT_plot = zeros(num_samples,1);
FT_plot(z_index) = 1;
FT_plot(s_index) = 2;
FT_plot(m_index) = 3;
FT_plot(l_index) = 4;

tick = 0:end_index-walking_start;
time = tick/hz;

last_time = end_index/hz;
start_time = walking_start/hz;
falling_start_time = (falling_start_index-walking_start)/hz;

%%
figure(1)
set(gcf, 'renderer', 'painters', 'Position',[4000,0,600,200]);
cla reset
plot(time,f_in(walking_start:end_index,:),LineWidth=2)
hold on
grid on
ylabel("$\textbf{F}_in$", FontName='Times', Interpreter="latex", FontSize=13)
set(gca, 'YTick',[0.0, 20, 40])
xlim([0,max(time)])
ylim([-0,45])

yyaxis right
plot(time, FT_plot(walking_start:end_index),LineWidth=2.0, color='k', LineStyle="-")
set(gca,'YColor','k')
set(gca, 'YLim', [0.9,8])
set(gca,'FontName','Times','FontSize',13,'TickLabelInterpreter','latex');
set(gca, 'YTick',[1,2, 3, 4],'YTickLabels',{'$\tau_z$','$\tau_s$','$\tau_m$','$\tau_l$'})
ylabel("Output", FontName='times', Interpreter='latex', fontsize=13)
legend("$\textup{F}$","\textup{M}",'$\textup{output}$',NumColumns=6,FontName='Times',Interpreter='latex',...
    FontSize=13)
xlabel("\textbf{Time} (sec)", "FontName",'Times',Interpreter='latex', FontSize=13)

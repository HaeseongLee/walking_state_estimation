% This script is for plotting the result of the foot height indicator

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
falling_end_ratio = 0.3;

p_model = load("model/gmm_p.mat");
p_info = load("model/p_indicator.mat");
p_model = p_model.gmm_p;
p_info = p_info.p_indicator;

p_raw = load("p.txt");
ft_raw = load("f.txt");
json_data = jsondecode(fileread('walking_result.json'));
num_steps = json_data.number_of_foot_off;

% load nominal walking data
ft_nominal = load("data/nominal_walking/ft_nominal.mat");
ft_mean = ft_nominal.ft_nominal.mean;
ft_cov = ft_nominal.ft_nominal.cov;

ft_add = abs(ft_raw(:,1:6) + ft_raw(:,7:12));

%%
num_samples = length(ft_add);

falling_start_grf = ft_mean(3)*falling_start_ratio;
falling_end_grf = ft_mean(3)*falling_end_ratio;
falling_start_index = getEndIndex(ft_add(:,3), falling_start_grf);
falling_end_index = getEndIndex(ft_add(:,3), falling_end_grf);
end_index = falling_end_index;

if isempty(end_index)
    end_index = walking_start + (max(num_steps))*step_duration;
end

%%
step_start = zeros(max(num_steps),1);
for i = 1:max(num_steps)
    step_start(i) = walking_start + (i-1)*step_duration;
end

% Compute the difference between the previous and current footsteps
p_z = zeros(length(p_raw),1);
p_z(1:walking_start,1) = p_raw(1:walking_start,6);
for i = 1:max(num_steps)-1
    if i == max(num_steps)-1
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

% Inference
[Zs, Zl] = fhIndicator(p_z, p_model, p_info, false);
Zs_index = find(Zs == 1);
Zl_index = find(Zl == 1);

% For visualizing
Z_plot = zeros(num_samples,1);
Z_plot(Zs_index) = 1;
Z_plot(Zl_index) = 2;

tick = 0:end_index-walking_start;
time = tick/hz;

last_time = end_index/hz;
start_time = walking_start/hz;
step_start_time = (step_start - walking_start)/hz;
falling_start_time = (falling_start_index-walking_start)/hz;

%%
figure(1)
cla reset
set(gcf, 'renderer', 'painters', 'Position',[2000,0,600,200]);
plot(time, p_z(walking_start:end_index,1),LineWidth=1.5)
hold on
for i = 1:max(num_steps)
    plot([step_start_time(i), step_start_time(i)], [0, 0.1], LineWidth=2, Color="k", LineStyle="--")
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
plot(time, Z_plot(walking_start:end_index),LineWidth=2.0, color='k')
set(gca,'YColor','k')
set(gca, 'YLim', [0.9,4])
set(gca,'FontName','Times','FontSize',13,'TickLabelInterpreter','latex');
set(gca, 'YTick',[1,2],'YTickLabels',{'$Z_s$','$Z_l$'})
ylabel("\textup{Output}", FontName='times', Interpreter='latex', fontsize=13)
legend("$P_z$",'$output$',NumColumns=6,FontName='Times',Interpreter='latex',...
    FontSize=13, location="northwest")
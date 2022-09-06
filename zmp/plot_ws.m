% This script is for plotting the result of the Cop-ZMP criterion

clc
clear

addpath("utils/")

% missing cases
% #18, #26, #30

% add train dataset path
filename = "test_18";
addpath("../data/test/"+filename)

% set the basic walking paramters
hz = 2000;
walking_start = 4*hz;
step_duration = 1.1*hz;
ds_duration = 0.23*hz;
falling_start_ratio = 0.5;
falling_end_ratio = 0.1;

zmp_result = load("pad_0.8/" + filename + ".mat");

% Load nominal walking data
ft_nominal = load("../data/nominal_walking/ft_nominal.mat");
ft_mean = ft_nominal.ft_nominal.mean;
ft_cov = ft_nominal.ft_nominal.cov;

p_raw = load("p.txt");
ft_raw = load("f.txt");
num_steps = load("num_steps.txt");
json_data = jsondecode(fileread('walking_result.json'));

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

%%

falling_idx = zmp_result.falling_idx + walking_start;

zmp_estimation = zeros(num_samples,1);
zmp_estimation(falling_idx) = 1;

window = 400;
zmp_filtered = zeros(length(zmp_estimation),1);
for i = window:num_samples
    roi = zmp_estimation(i-window+1:i,1);     
    if length(find(roi~=0)) == window
        zmp_filtered(i) = zmp_estimation(i);
    end
end

tick = 0:end_index-walking_start;
time = tick/hz;

figure(1)
subplot(3,1,1)
cla reset
plot(time, zmp_filtered(walking_start:end_index), Color='r', LineWidth=1.2, LineWidth=2)
grid on
xlim([0,max(time)])
ylim([0,1.2])
set(gca, 'YTick',[0.0, 1.0],'YTickLabels',{'Stable','falling'})
set(gca,'FontName','Times','FontSize',13,'TickLabelInterpreter','latex');


subplot(3,1,2)
cla reset
plot(time, p_z(walking_start:end_index,1),LineWidth=1.5)
grid on
ylabel("$\textbf{P}_{in}$ (m)","FontName",'Times',Interpreter='latex',FontSize=13)
xlabel("\textbf{Time} (sec)", "FontName",'Times',Interpreter='latex', FontSize=13)
xlim([0, (end_index-walking_start)/hz+0.001])
ylim([-0.001,0.03])
set(gca, 'YTick',[0.0, 0.01,0.02])
set(gca,'FontName','Times','FontSize',13,'TickLabelInterpreter','latex');

subplot(3,1,3)
cla reset
plot(time,f_in(walking_start:end_index,:),LineWidth=2)
ylabel("$\textbf{F}_{in}$", FontName='Times', Interpreter="latex", FontSize=13)
xlabel("\textbf{Time} (sec)", "FontName",'Times',Interpreter='latex', FontSize=13)
set(gca, 'YTick',[0.0, 20, 40])
xlim([0,max(time)])
ylim([-0,45])
grid on

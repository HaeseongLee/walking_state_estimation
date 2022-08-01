clc
clear all

% add train dataset path
filename = "test_29";
addpath("data/test/"+filename)
addpath("utils/") % call custom functions

hz = 2000;
min_grf = 50;
walking_start = 4*hz;
step_duration = 1.1*hz;

p_raw = load("p.txt");
f_raw = load("f.txt");
num_step = load("num_steps.txt");

f_add = abs(f_raw(:,1:6) + f_raw(:,7:end));

end_index = find(f_add(:,3)<=min_grf, 1);


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


[~, ~, ~, step_phase, ~] = predict(filename);

if isempty(end_index)
    end_index = max(step_phase) + step_duration - walking_start;
end

step_phase = (step_phase-walking_start)/hz;
tick = 0:end_index-walking_start;
time = tick/hz;


figure(1)
cla reset
set(gcf, 'renderer', 'painters', 'Position',[2000,0,600,200]);
plot(time, p_z(walking_start:end_index,1),LineWidth=1.5)
hold on
grid on
ylabel("$\textbf{P}_{in}$ (m)","FontName",'Times',Interpreter='latex',FontSize=13)
xlabel("\textbf{Time} (sec)", "FontName",'Times',Interpreter='latex', FontSize=13)
xlim([0, (end_index-walking_start)/hz+0.001])
ylim([-0.001,0.085])
set(gca, 'YTick',[0.0, 0.04,0.08])
set(gca,'FontName','Times','FontSize',13,'TickLabelInterpreter','latex');


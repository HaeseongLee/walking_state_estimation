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

add_mean = load("model/nominal_walking/add_mean.mat");
add_cov = load("model/nominal_walking/add_cov.mat");

add_mean = add_mean.f_add_mean;
add_cov = add_cov.f_add_cov;


f_raw = load("f.txt");
f_add = abs(f_raw(:,1:6) + f_raw(:,7:end));

end_index = find(f_add(:,3)<=min_grf, 1);

f_in = zeros(length(f_add),1);
sigma_inv = (add_cov)^-1;
for i = 1:length(f_add)
    f_in(i) = (f_add(i,:)-add_mean)*sigma_inv*(f_add(i,:)-add_mean)';
end
f_in = sqrt(f_in);

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
plot(time, f_add(walking_start:end_index,1),LineWidth=1.5)
hold on
plot(time, f_add(walking_start:end_index,2:end),LineWidth=1.5)
for i = 2:length(step_phase)-3
    plot([step_phase(i), step_phase(i)],[-50,1200], LineWidth=1.5, LineStyle="--", Color='k')
end
plot([(end_index-walking_start)/hz,(end_index-walking_start)/hz],...
    [-50,1200], LineWidth=1.5, LineStyle="-", Color='r')
hold off
grid on
ylabel('$\textbf{F}$ (N or Nm)','FontName','Times','Interpreter','latex', FontSize=13);
xlabel('\textbf{Time} (sec)','FontName','Times','Interpreter','latex', FontSize=13);
xlim([0, (end_index-walking_start)/hz+0.001])
ylim([-50.0,1200])
set(gca,'FontName','Times','FontSize',13,'TickLabelInterpreter','latex');
% legend("$f_x$",'$f_y$','$f_z$',...
%     '$m_x$','$m_y$','$m_z$',NumColumns=6,FontName='Times',Interpreter='latex',...
%     FontSize=13)

%%
figure(2)
cla reset
set(gcf, 'renderer', 'painters', 'Position',[2000,300,600,200]);
plot(time, f_in(walking_start:end_index,1),LineWidth=1.5)
grid on
ylabel("$\textbf{F}_{in}$","FontName",'Times',Interpreter='latex',FontSize=13)
xlabel("\textbf{Time} (sec)", "FontName",'Times',Interpreter='latex', FontSize=13)
xlim([0, (end_index-walking_start)/hz+0.001])
ylim([0,45])
set(gca,'FontName','Times','FontSize',13, 'TickLabelInterpreter','latex');
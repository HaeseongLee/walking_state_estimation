% This script is for evaluating the proposed framework

clc
clear

addpath("utils/")

num_files = 30;

falling_label = zeros(num_files,1);
falling_est = zeros(num_files,1);

label = [];
est = [];

time = 0;
for i = 1:num_files
    filename = "~/.ros/data/test_" + i;
    [y_true, y_pred, falling_idx, step_phase, falling_index_diff] = predict(filename);
    
    label = [label; y_true];
    est = [est; y_pred];
    
    if ~isempty(falling_index_diff)
        time = time + falling_index_diff;
    end
    % check if the robot is fallen
    if ~isempty(find(y_true == 3, 1))
        falling_label(i) = 1;
    end
    % check the estimation result
    if ~isempty(falling_idx)
        falling_est(i) = 1;
    end
    if ~isempty(falling_idx)
        disp(i+"th data is under the evaluation...-> fail")
    else
        disp(i+"th data is under the evaluation...-> success")
    end
end

time = time/2000; % 2 kHz
time = time/sum(falling_est);

%%
% Plot as the binary classification

plot_label(falling_label==0) = "stable";
plot_label(falling_label==1) = "falling";
plot_est(falling_est==0) = "stable";
plot_est(falling_est==1) = "falling";

figure(1)
cm = confusionchart(plot_label, plot_est);
sortClasses(cm, 'cluster')
sortClasses(cm, ["falling","stable"])
cm.Title="Confusion Matrix";
cm.RowSummary = 'row-normalized';
cm.ColumnSummary = 'column-normalized';

%%

% Plot as the multi-lable classification

plot_label(label==0) = "nominal";
plot_label(label==1) = "disturbed";
plot_label(label==2) = "disturbed";
plot_label(label==3) = "falling";
plot_est(est==0) = "nominal";
plot_est(est==1) = "disturbed";
plot_est(est==2) = "disturbed";
plot_est(est==3) = "falling";

figure(2)
cm = confusionchart(plot_label, plot_est);
sortClasses(cm, 'cluster')
sortClasses(cm, ["falling","disturbed","nominal"])
cm.Title="Confusion Matrix";
cm.RowSummary = 'row-normalized';
cm.ColumnSummary = 'column-normalized';

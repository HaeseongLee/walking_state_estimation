clc
clear

addpath("utils/")

label = zeros(30,1);
estimation = zeros(30,1);

% typical falling case : 18, 26, 30
for i = 1:30
    filename = "../data/test/test_" + i;
    [y_true, y_pred, falling_idx] = predict(filename,"0.8");
    
    if ~isempty(find(y_true == 1, 1))
        label(i) = 1;
    end
    if ~isempty(falling_idx)
        estimation(i) = 1;
    end
    if ~isempty(falling_idx)
        disp(i+"th data is under the evaluation...-> fail")
    else
        disp(i+"th data is under the evaluation...-> success")
    end
end
%%
% answer = zeros(length(label),1);
plot_label(label==0) = "stable";
plot_label(label==1) = "falling";
plot_est(estimation==0) = "stable";
plot_est(estimation==1) = "falling";

figure(1)
cm = confusionchart(plot_label, plot_est);
sortClasses(cm, 'cluster')
sortClasses(cm, ["falling","stable"])
cm.Title="Confusion Matrix";
cm.RowSummary = 'row-normalized';
cm.ColumnSummary = 'column-normalized';


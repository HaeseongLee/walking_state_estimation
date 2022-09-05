% This script is for obtaining "Disturbance Indicator"

clc
clear

% load training data
ft_n = load("data/training/f_n_train.txt");
ft_i = load("data/training/f_i_train.txt");
ft_c = load("data/training/f_c_train.txt");
ft_f = load("data/training/f_f_train.txt");

% make balanced dataset
samples = length(ft_f);
ft_c = datasample(ft_c, samples, Replace=false);
ft_i = datasample(ft_i, samples, Replace=false);
ft_n = datasample(ft_n, samples, Replace=false);

ft_train = [ft_n; ft_i; ft_c; ft_f];

% add noise
noise_1 = normrnd(0, 0.1, [length(ft_train),1]);
noise_2 = normrnd(0, 0.1, [length(ft_train),1]);
ft_train(:,1) = abs(ft_train(:,1) + noise_1);
ft_train(:,2) = abs(ft_train(:,2) + noise_2);

figure(1)
cla reset
scatter(ft_n(:,1), ft_n(:,2), 0.5, 'r')
hold on
scatter(ft_i(:,1), ft_i(:,2), 0.5, 'g')
scatter(ft_c(:,1), ft_c(:,2), 0.5, 'b')
scatter(ft_f(:,1), ft_f(:,2), 0.5, 'm')
hold off
grid on

%%
% following parameters are default values for the dis indicator
gmm_ft = fitgmdist(ft_train, 4, 'RegularizationValue', 1e-0, ...
    Options=statset('Display', 'final', 'MaxIter', 2000, 'TolFun', 1e-6), Replicates=10);
disp(gmm_ft.mu)
disp(vecnorm(gmm_ft.mu'))
%%
% TODO: change indices as referencing the fitting result
ft_indicator.z = 1; % near zero
ft_indicator.s = 2; % small
ft_indicator.m = 4; % medium
ft_indicator.l = 3; % large

[~, ~, ~, ~] = disIndicator(ft_train, gmm_ft, ft_indicator, true);
% This script is for obtaining "Foot Height Indicator"

clc
clear

addpath("utils/")

% load training data
p_n = load("data/training/p_n_train.txt"); % nominal
p_i = load("data/training/p_i_train.txt"); % insignificant
p_c = load("data/training/p_c_train.txt"); % cautious
p_f = load("data/training/p_f_train.txt"); % falling


samples = length(p_f);
p_c = datasample(p_c, samples, Replace=false);
p_i = datasample(p_i, samples, Replace=false);
p_n = datasample(p_n, samples, Replace=false);

% Except p_f since it has large variance
p_train = [p_n; p_i; p_c];

% clip position data since the maxinum magnitude of debris is 2 cm
p_train(p_train > 0.02) = []; 

% add noise
noise = normrnd(0, 0.001, [length(p_train),1]);
p_train = abs(p_train + noise);

figure(1)
cla reset
histogram(p_train)
%%
% following parameters are default values for the fh indicator
gmm_p = fitgmdist(p_train, 2, 'RegularizationValue', 1e-8, ...
    Options=statset('Display', 'final', 'MaxIter', 2000, 'TolFun', 1e-6), Replicates=10);
disp(gmm_p.mu)

%%
% TODO: change indices as referencing the fitting result
p_indicator.s = 1; % samll
p_indicator.l = 2; % large

[~, ~] = fhIndicator(p_train, gmm_p, p_indicator, true);
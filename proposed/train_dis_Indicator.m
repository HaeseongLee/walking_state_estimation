clc
clear 

addpath("data/training/")

% F = |F_l + F_r|
f_add = load("f_add.txt");

% load data from nominal walking
nominal_mean = load("data/nominal_walking/nominal_mean.mat");
nominal_mean= nominal_mean.nominal_mean;

nominal_cov = load("data/nominal_walking/nominal_cov.mat");
nominal_cov = nominal_cov.nominal_cov;

%%
f_train = zeros(length(f_add),1);
cov_inv = (nominal_cov)^-1;

% compute mahalanobis distance from the nominal walking
for i = 1:length(f_add)
    f_train(i) = (f_add(i,:)-nominal_mean)*cov_inv*(f_add(i,:)-nominal_mean)';
end
f_train = sqrt(f_train);

%%
% GMM & EM algorithm
% RegularizationValue = 1e-4 -> for simulation
gmm_f = fitgmdist(f_train, 4, 'RegularizationValue', 1e-4, ...
    Options=statset('Display', 'final', 'MaxIter', 2000, 'TolFun', 1e-6), Replicates=5);
%%
% rendering each cluster
% change each number according to the result of fitgmdist
DisturbanceIndicator.Fn = 2; % near zero
DisturbanceIndicator.Fs = 4; % small
DisturbanceIndicator.Fl = 1; % medium
DisturbanceIndicator.Ff = 3; % large

% plot result
[~, ~, ~, ~] = disturbanceIndicator(f_train, gmm_f, DisturbanceIndicator, true);
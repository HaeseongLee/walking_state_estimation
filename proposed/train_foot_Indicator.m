clc
clear all

addpath("data/training/")

p_raw = load("support_foot_p.txt"); % data for simulation walking.
% p_raw = load("support_foot_p_real.txt"); % data for real robot walking.

% add gaussian noise for the real robot implementation
% noise = normrnd(0, 0.0025, [length(p_raw),1]);
% p_raw = p_raw + noise;

p_train = abs(p_raw);

figure(1)
histogram(p_train)
%%
% RegularizationValue = 1e-8 -> for simulation
% RegularizationValue = 1e-6 -> for real robot walking
gmm_p = fitgmdist(p_train, 3, 'RegularizationValue', 1e-8, ...
    Options=statset('Display', 'final', 'MaxIter', 500, 'TolFun', 1e-6), Replicates=5);
disp(gmm_p.mu)

%%

% relative distance betwee the current and previous footstep
FootHeightIndicator.Zn = 1; % n : near zero
FootHeightIndicator.Zs = 3; % s : small
FootHeightIndicator.Zl = 2; % l : large

[Zn, Zs, Zl] = footHeightPredict(p_train, gmm_p, FootHeightIndicator, true);
% This function is for referencing the disturbance indicator

function [z, s, m, l] = disIndicator(X, G, I, vis)
% Input
%     X : input data to be estimated
%     G : trained GMM model for the disturbance indicator
%     I : index information

% Output
% A binary vector for each state
% Example, z = [1, 0, 0, 0] means that the only first input is correspoding
% to tau_z

mu = G.mu;
sigma = G.Sigma;
w = G.ComponentProportion;
K = G.NumComponents; % number of clusters

% compute probability of X
N = length(X);
prob = zeros(N,K);
for i = 1:K
    prob(:,i) = mvnpdf(X, mu(i,:), sigma(:,:,i));
end

% compute responsibility for each input 
resp = zeros(N,K); % responsibility
den = zeros(N,1);  % sum of all weighted responsibility
for i = 1:K
    den = den + w(i)*prob(:,i);
end
for i = 1:K
    resp(:,i) = w(i)*prob(:,i)./den;
end
r = resp';
r = max(r);

% find indices
z_index = find(resp(:,I.z) == r');
s_index = find(resp(:,I.s) == r');
m_index = find(resp(:,I.m) == r');
l_index = find(resp(:,I.l) == r');

z = zeros(N,1);
s = zeros(N,1);
m = zeros(N,1);
l = zeros(N,1);

% set each corresponding element as "1"
z([z_index]) = 1;
s([s_index]) = 1; 
m([m_index]) = 1; 
l([l_index]) = 1; 

if vis == true
    figure(5)
    cla reset
        scatter(X(z_index,1), X(z_index,2), 0.5, 'r')
    hold on
        scatter(X(s_index,1), X(s_index,2), 0.5, 'g')
        scatter(X(m_index,1), X(m_index,2), 0.5, 'b')
        scatter(X(l_index,1), X(l_index,2), 0.5, 'm')
    hold off
    grid on 
end
end
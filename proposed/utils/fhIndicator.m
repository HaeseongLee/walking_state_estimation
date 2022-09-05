% This function is for referencing the foot height indicator

function [s, l] = fhIndicator(X, G, I, vis)
% Input
%     X : input data to be estimated
%     G : trained GMM model for foot height indicator
%     I : index information

% Output
% A binary vector for each state
% Example, s = [1, 0, 0, 0] means that the only first input is correspoding
% to Z_s


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
s_index = find(resp(:,I.s) == r');
l_index = find(resp(:,I.l) == r');

s = zeros(N,1);
l = zeros(N,1);

% set each corresponding element as "1"
s([s_index]) = 1; 
l([l_index]) = 1; 

if vis == true
    figure(4)
    plot(s_index, X(s_index), 'or', MarkerSize=0.5)
    hold on
    plot(l_index, X(l_index), 'ob', MarkerSize=0.5)
    hold off
    grid on 
end
end
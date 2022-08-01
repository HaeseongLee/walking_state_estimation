function [Fn, Fs, Fl, Ff] = disturbanceIndicator(X, G, I, vis)
% Input
%     X : input data to be estimated
%     G : disturbance indicator
%     I : index information
% Output
% physical meaning of the output: mahalanobis distance from the nominal walking
%     Fn : The distance is "near zero"
%     Fs : The distance is "small"
%     Fm : The distance is "medium"
%     Fl : The distance is "large"

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

% estimation
% TODO: change index according to the pyshcial observation
Fn_index = find(resp(:,I.Fn) == r');
Fs_index = find(resp(:,I.Fs) == r');
Fl_index = find(resp(:,I.Fl) == r');
Ff_index = find(resp(:,I.Ff) == r');

Fn = zeros(N,1);
Fs = zeros(N,1);
Fl = zeros(N,1);
Ff = zeros(N,1);

Fn([Fn_index]) = 1;
Fs([Fs_index]) = 1;
Fl([Fl_index]) = 1; 
Ff([Ff_index]) = 1; 

if vis == true
    figure(4)
    plot(Fn_index, X(Fn_index), 'or', MarkerSize=0.5)
    hold on
    plot(Fs_index, X(Fs_index), 'og', MarkerSize=0.5)
    plot(Fl_index, X(Fl_index), 'ob', MarkerSize=0.5)
    plot(Ff_index, X(Ff_index), 'om', MarkerSize=0.5)
    hold off
    grid on 
end
end
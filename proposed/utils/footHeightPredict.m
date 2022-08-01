function [Zn, Zs, Zl] = footHeightPredict(X, G, I, vis)
% Input
%     X : input data to be estimated
%     G : trained GMM model for foot height indicator
%     I : index information
% Output
% physical meaning of the output: relative distance betwee the current and previous footstep
%     Zn : relative distance is "near zero"
%     Zs : relative distance is "small"
%     Zl : relative distance is "large"


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
Zn_index = find(resp(:,I.Zn) == r');
Zs_index = find(resp(:,I.Zs) == r');
Zl_index = find(resp(:,I.Zl) == r');

Zn = zeros(N,1);
Zs = zeros(N,1);
Zl = zeros(N,1);

Zn([Zn_index]) = 1;
Zs([Zs_index]) = 1;
Zl([Zl_index]) = 1; 

if vis == true
    figure(4)
    plot(Zn_index, X(Zn_index), 'or', MarkerSize=0.5)    
    hold on
    plot(Zs_index, X(Zs_index), 'og', MarkerSize=0.5)
    plot(Zl_index, X(Zl_index),'ob', MarkerSize=0.5)
    hold off
    grid on 
end 
end
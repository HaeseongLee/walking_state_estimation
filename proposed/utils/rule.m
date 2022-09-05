% This function is for the rule of the discriminator.

function ws = rule(P, F, p_info, f_info)
% Input
%     P : result from foot height indicator, [Zn, Zl]
%     F : result from disturbance indicator, [Fz, Fs, Fm, Fl]
%     p_info : description of states of P
%     f_info : description of states of F

% Output 
%   "n"ominal
%   disturbed, but "i"nsignificant
%   disturbed, and "c"autious
%   "f"alling

% rule
%    | Fz | Fs | Fm | Fl
% -----------------------
% Zs | n  | i  | c  | f
% Zl | i  | c  | f  | f 

    nonimal = 0;
    insignificant = 1;
    cautious = 2;
    falling = 3;
    
    Zs = P == p_info.s;
    Zl = P == p_info.l;

    Fz = F == f_info.z;
    Fs = F == f_info.s;
    Fm = F == f_info.m;
    Fl = F == f_info.l;

    n_index_1 = Zs.*Fz == 1;

    i_index_1 = Zs.*Fs == 1;
    i_index_2 = Zl.*Fz == 1;

    c_index_1 = Zs.*Fm == 1;    
    c_index_2 = Zl.*Fs == 1;


    f_index_1 = Zs.*Fl == 1;    
    f_index_2 = Zl.*Fm == 1;
    f_index_3 = Zl.*Fl == 1;

    % set result
    ws(n_index_1) = nonimal;
    
    ws(i_index_1) = insignificant;
    ws(i_index_2) = insignificant;   

    ws(c_index_1) = cautious;     
    ws(c_index_2) = cautious; 

    ws(f_index_1) = falling;
    ws(f_index_2) = falling; 
    ws(f_index_3) = falling;
    
end
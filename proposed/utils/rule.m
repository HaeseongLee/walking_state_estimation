function WS = rule(z, f, z_info, f_info)
% Input
%     z : result from foot height indicator, [Zn, Zs, Zl]
%     f : result from disturbance indicator, [Fn, Fs, Fl, Ff]
%     z_info : description of states of z
%     z_info : description of states of f

% Output
%   "n"ominal
%   disturbed, but "i"nsignificant
%   disturbed, and "c"autious
%   "f"alling

% Rule
%    | Fn | Fs | Fl | Ff
% -----------------------
% Zn | n  | n  | i  | c
% Zs | i  | i  | c  | f
% Zl | i  | c  | c  | f 

    nominal = 0;
    insignificant = 1;
    cautious = 2;
    falling = 3;

    Zn = z == z_info.Zn;
    Zs = z == z_info.Zs;
    Zl = z == z_info.Zl;

    Fn = f == f_info.Fn;
    Fs = f == f_info.Fs;
    Fl = f == f_info.Fl;
    Ff = f == f_info.Ff;

    % define steady walking
    n_index_1 = Zn.*Fn == 1;
    n_index_2 = Zn.*Fs == 1;
    
    % define disturbed walking
    i_index_1 = Zs.*Fn == 1; % considered as disturbed cases
    i_index_2 = Zn.*Fl == 1;
    i_index_3 = Zs.*Fs == 1;    
    i_index_4 = Zl.*Fn == 1; % may be hazard!!

    c_index_1 = Zl.*Fl == 1;
    c_index_2 = Zs.*Fl == 1;
    c_index_3 = Zn.*Ff == 1;
    c_index_4 = Zl.*Fs == 1;

    % define falling    
    f_index_1 = Zs.*Ff == 1;
    f_index_2 = Zl.*Ff == 1;


    % set result
    WS(n_index_1) = nominal;
    WS(n_index_2) = nominal;
    
    WS(i_index_1) = insignificant;
    WS(i_index_2) = insignificant;
    WS(i_index_3) = insignificant;
    WS(i_index_4) = insignificant;

    WS(c_index_1) = cautious;
    WS(c_index_2) = cautious;
    WS(c_index_3) = cautious;
    WS(c_index_4) = cautious;


    WS(f_index_1) = falling;
    WS(f_index_2) = falling;
   
end
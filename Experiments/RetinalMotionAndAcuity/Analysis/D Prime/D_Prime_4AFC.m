% Values to convert from d' from % correct 4 AFC from
% Hacker and Ratliff 1979, A revised table of d’ for
% M-alternative forced choice

input_percent = .9; % input % target out of 1

P = 0.01:.01:0.99; % for % correct
D = [-2.02, -1.69, -1.48, -1.32, -1.19, -1.08, -0.98, -0.90, -0.82, -0.75,...
     -0.68, -0.62, -0.56, -0.50, -0.45, -0.39, -0.35, -0.30, -0.25, -0.21,...
     -0.16, -0.12, -0.08, -0.04,  0.00,  0.04,  0.08,  0.11,  0.15,  0.19,...
      0.22,  0.26,  0.29,  0.32,  0.36,  0.39,  0.42,  0.46,  0.49,  0.52,...
      0.55,  0.59,  0.62,  0.65,  0.68,  0.71,  0.74,  0.77,  0.81,  0.84,...
      0.87,  0.90,  0.93,  0.96,  0.99,  1.02,  1.06,  1.09,  1.12,  1.15,...
      1.19,  1.22,  1.25,  1.29,  1.32,  1.35,  1.39,  1.42,  1.46,  1.49,...
      1.53,  1.57,  1.60,  1.64,  1.68,  1.72,  1.76,  1.81,  1.85,  1.89,...
      1.94,  1.99,  2.04,  2.09,  2.14,  2.20,  2.25,  2.32,  2.38,  2.45,...
      2.53,  2.61,  2.70,  2.80,  2.92,  3.05,  3.22,  3.44,  3.80];

pcorr_dprime = table(P, D);

idx = strfind(pcorr_dprime.P, input_percent);

answer = pcorr_dprime.D(idx)
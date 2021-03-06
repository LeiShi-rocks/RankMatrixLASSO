%% test APGLplus
clear;clc;
niter = 40;
nr = 40;
nc = 40;
% N = 2000;
r = 5;
N_Cand = ceil(linspace(5*max(nr,nc)*r, 2*nr*nc, 6));

noise(1).type = 'Gaussian';
noise(1).para = 0.25;
noise(1).scale = 1;

N = N_Cand(3);
[X, y, Theta_star] = DataGen(nr, nc, N, r, noise(1), 'MR', 'small');


lambda = 0.15 * sqrt( log(max(nr,nc))*max(nr,nc)/N );
yVec = reshape(y', [], 1);
[Theta_hat1, ~, ~, sd, ~] = APGL(nr, nc, 'NNLS', @(Theta) Amap(Theta, X), @(bb) ATmap(bb, X), yVec, lambda, 0);
disp(norm(Theta_hat1-Theta_star, 'fro')^2/(nr*nc));


Theta_init = zeros(nr, nc);
f_init     = 0.5 * sum(sum( (yVec - Amap(Theta_init, X)).^2 ));
grad_init  = ATmap(Amap(Theta_init, X) - yVec, X);
Bk         = @(Theta) ATmap(Amap( Theta , X), X);
Theta_hat_plus = APGLplus(f_init, grad_init, Bk, Theta_init, lambda, []);
disp(norm(Theta_hat_plus-Theta_star, 'fro')^2/(nr*nc));

%% test Hessian Generation function
clear; clc;
SS = randn(40, 50, 1);
YY = randn(40, 50, 1);
for ind = 1:1
    SS(:,:,ind) = SS(:,:,ind) / norm( SS(:,:,ind) , 'fro');
    YY(:,:,ind) = YY(:,:,ind) / norm( YY(:,:,ind) , 'fro');
end

de = 1;

Bk_LSR1  =  MVPQN_Hessian(SS, YY, de, 'LSR1');
Bk_LBFGS =  MVPQN_Hessian(SS, YY, de, 'LBFGS');


%% test MVPQN on multivariate regression with Gaussian noise
clear; clc;
niter  =  40;
nr     =  40;
nc     =  40;
% N = 2000;
r      =  5;
N_Cand =  ceil(linspace(5*max(nr,nc)*r, 2*nr*nc, 6));

noise(1).type  = 'Gaussian';
noise(1).para  = 0.25;
noise(1).scale = 1;

N = N_Cand(3);
[X, y, Theta_star] = DataGen(nr, nc, N, r, noise(1), 'MR', 'small');

alpha      = 0.90;
Qtype.name = 'V';
Qtype.nr   = nr;
Qtype.nc   = nc;
Qtype.N    = N;

[lambdaHat, ~] =   PivotalTuning(X, alpha, Qtype);
lambdaRun      =   0.15 * lambdaHat;


% initialization of opts parameters
opts.type     = struct(...
    'name', 'L2', ...
    'para', '1.0');

opts.Hessian  = struct(...
    'name', 'LSR1', ...
    'para'  , 1);
% opts.Hessian  = struct(...
%     'name', 'const_diag',...
%     'Lf'  , 2e4);

opts.t_search = struct(...
    'name' , 'trivial',...
    'para' , 1);
% opts.t_search = struct(...
%     'name' , 'line_search',...
%     'para' , 0.3);

opts.lambda    =  lambdaRun;
opts.eta       =  0.8;
opts.Lf        =  2e4;

Theta_hat = MVPQN(y, X, opts);

disp(norm(Theta_hat-Theta_star, 'fro')^2/(nr*nc));



%% test MVPQN on multivariate regression with Cauchy noise
clear; clc;
niter  =  40;
nr     =  40;
nc     =  40;
% N = 2000;
r      =  5;
N_Cand =  ceil(linspace(5*max(nr,nc)*r, 2*nr*nc, 6));

noise(2).type = 'Cauchy';
noise(2).para = 1;
noise(2).scale = 1/64;

N = N_Cand(3);
[X, y, Theta_star] = DataGen(nr, nc, N, r, noise(2), 'MR', 'small');

alpha      = 0.90;
Qtype.name = 'V';
Qtype.nr   = nr;
Qtype.nc   = nc;
Qtype.N    = N;

[lambdaHat, ~] =   PivotalTuning(X, alpha, Qtype);
lambdaRun      =   0.2 * lambdaHat;

% initialization of opts parameters
opts.type     = struct(...
    'name', 'Wilcoxon', ...
    'para', '1.0');

opts.Hessian  = struct(...
    'name', 'LBFGS', ...
    'para'  , 1);
% opts.Hessian  = struct(...
%     'name', 'const_diag',...
%     'Lf'  , 5e4);

% opts.t_search = struct(...
%     'name' , 'trivial',...
%     'para' , 1);
opts.t_search = struct(...
    'name' , 'line_search',...
    'para' , 0.4);

opts.lambda    =  lambdaRun;
opts.eta       =  0.8;
opts.Lf        =  5e4;

Theta_hat = MVPQN(y, X, opts);

disp(norm(Theta_hat-Theta_star, 'fro')^2/(nr*nc));


%% test MVPQN on multivariate regression with Cauchy noise
clear; clc;
nr     =  40;
nc     =  40;
% N = 2000;
r      =  5;
N_Cand =  ceil(linspace(5*max(nr,nc)*r, 2*nr*nc, 6));

noise(3).type = 'Lognormal';
noise(3).para = 9;
noise(3).scale = 1/400;

N = N_Cand(3);
[X, y, Theta_star] = DataGen(nr, nc, N, r, noise(3), 'MR', 'small');

alpha      = 0.90;
Qtype.name = 'V';
Qtype.nr   = nr;
Qtype.nc   = nc;
Qtype.N    = N;

[lambdaHat, ~] =   PivotalTuning(X, alpha, Qtype);
lambdaRun      =   0.2 * lambdaHat;

% initialization of opts parameters
opts.type     = struct(...
    'name', 'Wilcoxon', ...
    'para', '1.0');

opts.Hessian  = struct(...
    'name', 'LBFGS', ...
    'para'  , 1);
% opts.Hessian  = struct(...
%     'name', 'const_diag',...
%     'Lf'  , 5e5);

% opts.t_search = struct(...
%     'name' , 'trivial',...
%     'para' , 1);
opts.t_search = struct(...
    'name' , 'line_search',...
    'para' , 0.4);

opts.lambda    =  lambdaRun;
opts.eta       =  0.8;
opts.Lf        =  5e5;

Theta_hat = MVPQN(y, X, opts);

disp(norm(Theta_hat-Theta_star, 'fro')^2/(nr*nc));

%% test MVPQN on multivariate regression with Cauchy noise
clear; clc;
nr     =  80;
nc     =  80;
% N = 2000;
r      =  5;
N_Cand =  ceil(linspace(5*max(nr,nc)*r, 2*nr*nc, 6));

noise(3).type = 'Lognormal';
noise(3).para = 9;
noise(3).scale = 1/400;

N = N_Cand(3);
[X, y, Theta_star] = DataGen(nr, nc, N, r, noise(3), 'MR', 'small');

alpha      = 0.90;
Qtype.name = 'V';
Qtype.nr   = nr;
Qtype.nc   = nc;
Qtype.N    = N;

[lambdaHat, ~] =   PivotalTuning(X, alpha, Qtype);
lambdaRun      =   0.2 * lambdaHat;

% initialization of opts parameters
opts.type     = struct(...
    'name', 'Wilcoxon', ...
    'para', '1.0');

opts.Hessian  = struct(...
    'name', 'LBFGS', ...
    'Lf'  , 5e5, ...
    'para'  , 1);
% opts.Hessian  = struct(...
%     'name', 'const_diag',...
%     'Lf'  , 5e5);

% opts.t_search = struct(...
%     'name' , 'trivial',...
%     'para' , 1);
opts.t_search = struct(...
    'name' , 'line_search',...
    'para' , 0.4);

opts.lambda    =  lambdaRun;
opts.eta       =  0.8;

Theta_hat = MVPQN(y, X, opts);

disp(norm(Theta_hat-Theta_star, 'fro')^2/(nr*nc));





% Compressed Sensing
save_flag = false; % If doing trials please set this to 'false'.

niter = 40;
nr = 40;
nc = 40;
% N = 2000;
r = 5;
N_Cand = ceil(linspace(3200, 6400, 6));


tol = 1e-4; maxiter = 100;

Record = zeros(4, 3, niter, 3, 6); % method, record(loss, rank, time), niter, noise(G, C, L), 10 N

gauge = 1;


noise(1).type = 'Gaussian';
noise(1).para = 0.25;
noise(1).scale = 1;

noise(2).type = 'Cauchy';
noise(2).para = 1;
noise(2).scale = 1/64;

noise(3).type = 'Lognormal';
noise(3).para = 9;
noise(3).scale = 1/400;



% Para_l2.Clambda = [1.5, 1.5, 1.5];

Para_shrink.Clambda = [1.4, 1.4, 1.4];
Para_shrink.Ctau = [1, 1, 1];

% Para_l1.Clambda = [1.2, 0.5, 1.2];


running = [1 1 1 1];


rng(10, 'twister');

%%
for noiseInd = 1 : 3
    for N_count = 1 : 6
        
        N = N_Cand(N_count);
        
        for trial = 1 : niter
            
            [X, y, Theta_star] = DataGen(nr, nc, N, r, noise(noiseInd), 'CS', 'small');
            
            alpha = 0.20;
            Qtype.name = 'M';
            Qtype.nr = nr;
            Qtype.nc = nc;
            Qtype.N = N;
            %% L2 loss
            if running(1)
                type.name = 'L2';
                type.eta = 0.8;
                type.Lf = 3e6;
                %                 Clambda = Para_l2.Clambda(noiseInd);
                %                 lambdaRun = Clambda * sqrt(N*(nr+nc));
                
                yw = y;
                Xw = X;
                
                
                Qtype.loss = 'L2';
                
                [lambdaHat, ~] = PivotalTuning(Xw, alpha, Qtype, noise(noiseInd));
                if noiseInd == 1
                    lambdaRun =  lambdaHat;
                else
                    lambdaRun =  0.05*lambdaHat;
                end
                
                %                 alpha = 0.1;
                %                 Qtype.name = 'M';
                %                 Qtype.nr = nr;
                %                 Qtype.nc = nc;
                %                 Qtype.N = N;
                %                 normalTuning(X, alpha, Qtype)
                %                 [lambdaHat, ~] = normalTuning(X, alpha, Qtype);
                
                tic;
                [Theta_hat1, rank] = MMAPG(y, X, type, lambdaRun, tol, maxiter, zeros(nr,nc));
                elapsedTime = toc;
                
                Record(1, 1, trial, noiseInd, N_count) = norm(Theta_hat1-Theta_star, 'fro')^2/(nr*nc);
                Record(1, 2, trial, noiseInd, N_count) = rank;
                Record(1, 3, trial, noiseInd, N_count) = elapsedTime;
                
                
                
                gauge = 1;
                disp(' ');
                disp(['noiseInd: ', num2str(noiseInd), ' N_count: ', num2str(N_count),' Trial: ', num2str(trial)]);
                disp(['L2 log error: ', num2str(log(norm(Theta_hat1-Theta_star, 'fro')))]);
                disp(' ');
            end
            
            
            
            %% Robust Shrinkage
            
            if running(2)
                type.name = 'L2';
                type.eta = 0.8;
                type.Lf = 3e6;
                Clambda = Para_shrink.Clambda(noiseInd);
                lambdaRun = Clambda * sqrt((nr+nc)*N);
                Ctau = Para_shrink.Ctau(noiseInd);
                shrinkLevel = Ctau * sqrt(N/(nr+nc));
                
                ys = sign(y) .* min(abs(y), shrinkLevel);
                Xs = X;
                
                tic;
                [Theta_hat2, rank] = MMAPG(ys, Xs, type, lambdaRun, tol, maxiter, zeros(nr,nc));
                elapsedTime = toc;
                
                Record(2, 1, trial, noiseInd, N_count) = norm(Theta_hat2-Theta_star, 'fro')^2/(nr*nc);
                Record(2, 2, trial, noiseInd, N_count) = rank;
                Record(2, 3, trial, noiseInd, N_count) = elapsedTime;
                
                disp(' ');
                disp(['noiseInd: ', num2str(noiseInd), ' N_count: ', num2str(N_count), ' Trial: ', num2str(trial)]);
                disp(['RL2 log error: ', num2str(log(norm(Theta_hat2-Theta_star, 'fro')))]);
                disp(' ');
            end
            
            %% L1 loss
            
            if running(3)
                type.name = 'L1';
                type.eta = 0.8;
                type.Lf = 3e7;
                %                 Clambda = Para_l1.Clambda(noiseInd);
                %                 lambdaRun = Clambda * sqrt(N*(nr+nc));
                
                yw = y;
                Xw = X;
                
                
                
                Qtype.loss = 'L1';
                
                [lambdaHat, ~] = PivotalTuning(Xw, alpha, Qtype, noise(noiseInd));
                lambdaRun =  lambdaHat;
                
                tic;
                [Theta_hat3, rank] = MMAPG(y, X, type, lambdaRun, tol, maxiter, zeros(nr,nc));
                elapsedTime = toc;
                
                Record(3, 1, trial, noiseInd, N_count) = norm(Theta_hat3-Theta_star, 'fro')^2/(nr*nc);
                Record(3, 2, trial, noiseInd, N_count) = rank;
                Record(3, 3, trial, noiseInd, N_count) = elapsedTime;
                
                disp(' ');
                disp(['noiseInd: ', num2str(noiseInd), ' N_count: ', num2str(N_count), ' Trial: ', num2str(trial)]);
                disp(['L1 log error: ', num2str(log(norm(Theta_hat3-Theta_star, 'fro')))]);
                disp(' ');
            end
            
            
            
            %% Wilcoxon loss
            
            if running(4)
                type.name = 'Wilcoxon';
                type.eta = 0.9;
                type.Lf = 3e5;
                
                yw = y;
                Xw = X;
                
                
                Qtype.loss = 'wilcoxon';
                
                [lambdaHat, ~] = PivotalTuning(Xw, alpha, Qtype, noise(noiseInd));
                lambdaRun =  lambdaHat;
                
                tic;
                [Theta_hat4, rank] = MMAPG(yw, Xw, type, lambdaRun, tol, maxiter, zeros(nr,nc));
                elapsedTime = toc;
                
                Record(4, 1, trial, noiseInd, N_count) = norm(Theta_hat4-Theta_star, 'fro')^2/(nr*nc);
                Record(4, 2, trial, noiseInd, N_count) = rank;
                Record(4, 3, trial, noiseInd, N_count) = elapsedTime;
                
                disp(' ');
                disp(['noiseInd: ', num2str(noiseInd), ' N_count: ', num2str(N_count), ' Trial: ', num2str(trial)]);
                disp(['Wilcoxon log error: ', num2str(log(norm(Theta_hat4-Theta_star, 'fro')))]);
                disp(' ');
            end
            
            %%
            
            % if sum(Error(trial, :)>0.05)>0
            %     break;
            % end
            
            
        end
    end
end
% options.tol   = 1e-6;
% options.issym = true;
% options.disp  = 0;
% options.v0    = randn(N,1);
% vvv = eigs(@(y)AAmap(AATmap(y, X, ones(N,1)), X, ones(N,1)),N,1,'LM',options);

if save_flag
    Record_CS_small_d40 = Record;
    save('Record_CS_small_d40.mat', 'Record_CS_small_d40');
end

%disp(num2str(log(Record(:,1,:,1,6)*1600)/2))
%disp(num2str(log(Record(:,1,1,3,:)*1600)/2))
%disp(num2str(log(Record(:,1,2,2,:)*1600)/2))
%disp(num2str(log(Record(:,1,3,2,:)*1600)/2))

% method, record(loss, rank, time), niter, noise(G, C, L), 10 N
% sv=svd(Theta_hat1);sv(sv>1e-4)
% sv=svd(Theta_hat2);sv(sv>1e-4)
% sv=svd(Theta_hat3);sv(sv>1e-4)
% sv=svd(Theta_hat4);sv(sv>1e-4)
% sv=svd(Theta_hat5);sv(sv>1e-4)
% sv=svd(Theta_hat4);sv(sv>1e-4)



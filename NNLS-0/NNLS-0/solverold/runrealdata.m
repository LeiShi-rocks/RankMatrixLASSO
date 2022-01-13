
  clear;
  warning off
  path(path,'/users/mattohkc/YunSW/apg/myPROPACK/'); 
  path(path,'/users/mattohkc/tohkc/YunSW/apg/solver/'); 
  path(path,'/users/mattohkc/tohkc/YunSW/apg/jester-data/'); 
  path(path,'/users/mattohkc/tohkc/YunSW/apg/ml-data/'); 

  rundate  = '07-Apr-2009'; 
  saveyes  = 1; 
  runyes   = 1; 

  if isempty(rundate); rundate = date; end
  datadir = ['datareal',rundate];
  if ~exist(datadir,'dir'); mkdir(datadir); end
  eval(['diary runreal',rundate]); 

for scenario = [7]

  if (scenario == 1)
     exfile = 'jester-data-1';
     Dt     = xlsread(exfile);
     fname = 'jester-1';
  elseif (scenario == 2)
     exfile = 'jester-data-2';
     Dt     = xlsread(exfile);
     fname = 'jester-2';
  elseif (scenario == 3)
     exfile = 'jester-data-3';
     Dt     = xlsread(exfile);
     fname = 'jester-3';
  elseif (scenario == 4)
     %%
     %% jester dataset
     %%
     exfile1 = 'jester-data-1';
     Dt1     = xlsread(exfile1);    
     exfile2 = 'jester-data-2';
     Dt2     = xlsread(exfile2); 
     exfile3 = 'jester-data-3';
     Dt3     = xlsread(exfile3);    
     Dt = [Dt1;Dt2;Dt3];
     fname = 'jester-all';
  elseif (scenario == 5) 
     %%
     %% MovieLens Dataset: 943x1682 (usersxmovies)
     %%
     tM = dlmread('u100K.data',''); 
     M  = spconvert(tM);
     fname = 'moive-100K'; 
  elseif (scenario == 6) 
     %%
     %% MovieLens Dataset: 6040x3900 (usersxmovies)
     %%
     tM = dlmread('u1M.data',''); 
     M  = spconvert(tM); 
     fname = 'moive-1M'; 
  elseif (scenario == 7) 
     %%
     %% MovieLens Dataset: 71567x10681 (usersxmovies)
     %%
     tM = dlmread('u10M.data',''); 
     M  = spconvert(tM); 
     fname = 'moive-10M'; 
  end
  if (scenario <= 4)
     %%
     %% jester data set
     %%
     nrealdata = Dt(1:end,1);
     fprintf('\n num. sam = %d',sum(nrealdata));
     M = Dt(1:end,2:end);      
     [nr,nc] = size(M);
     %%
     %% make zero ratings slightly non-zero. 
     %%
     [ii,jj] = find(M==0); 
     M = M + spconvert([ii,jj,1e-8*ones(length(ii),1);nr,nc,0]);
     %% 
     %% set non-rated entries (currently equal to 99) to 0. 
     %%
     [ii,jj] = find(M==99); 
     M = M - spconvert([ii,jj,99*ones(length(ii),1); nr,nc,0]);
     %%
     NumPerRow = 10; 
     Msub = zeros(nr,nc);
     for i=1:nr
        rand('state',i);
        Mrow = M(i,:); 
        truerow = find( abs(Mrow) > 1e-13 );
        len     = length(truerow); 
        rp      = randperm(len);
        chrow   = truerow(rp(1:min(NumPerRow,len)));
        Msub(i,chrow) = Mrow(chrow);
     end         
     colnorm = sum(Msub.*Msub); 
     colnormidx = find(colnorm == 0); 
     if ~isempty(colnormidx)       
        for j = 1:length(colnormidx)
           rand('state',j); 
           jcol = colnormidx(j); 
           Mcol = M(:,jcol); 
           truecol = find( abs(Mcol) > 1e-13 );
           len     = length(truecol); 
           rp      = randperm(len);
           chcol   = truecol(rp(1:min(NumPerRow,len)));
           Msub(chcol,jcol) = Mcol(chcol);  
        end
     end     
  else
     %%
     %% MovieLens data set
     %%
     normM = sum(M.*M); 
     idx = find(normM == 0); 
     M = M(:,setdiff([1:size(M,2)],idx));  %% removed zero columns. 
     fprintf('\n***** removed %2.1d zero columns in M',length(idx)); 
     Mt = M';
     [nr,nc] = size(M);
     nnzM = nnz(M); 
     NumElement = 10;
     if (NumElement > 0)  
        rr = zeros(nnzM,1); 
        cc = zeros(nnzM,1);
        vv = zeros(nnzM,1); 
        count = 0; 
        for i=1:nr
           rand('state',i);
           Mrow = full(Mt(:,i))'; 
           truerow = find( abs(Mrow) > 1e-13);
           len     = length(truerow); 
           rp      = randperm(len);
           NumPerRow = min(max(NumElement,floor(len*0.5)),len); 
           %% NumPerRow = min(NumElement,len);  
           chrow = truerow(rp(1:NumPerRow));
           idx = [1:NumPerRow];
           rr(count+idx) = i*ones(NumPerRow,1); 
           cc(count+idx) = chrow;  
           vv(count+idx) = Mrow(chrow); 
           count = count + NumPerRow; 
           if (rem(i,1000)==0); fprintf('\n i = %2.1d',i); end
        end
        rr = rr(1:count); cc = cc(1:count); vv = vv(1:count); 
        Msub = spconvert([rr,cc,vv; nr,nc,0]);   
        colnorm = sum(Msub.*Msub); 
        colnormidx = find(colnorm == 0); 
        if ~isempty(colnormidx) 
           rr = zeros(nnzM,1); 
           cc = zeros(nnzM,1);
           vv = zeros(nnzM,1);
           count = 0;  
           for j = 1:length(colnormidx)
              rand('state',j); 
              jcol = colnormidx(j); 
              Mcol = full(M(:,jcol)); 
              truecol = find( abs(Mcol) > 1e-13 );
              len     = length(truecol); 
              rp      = randperm(len);
              NumPerCol = min(max(NumElement,floor(len*0.5)),len); 
              %% NumPerCol = min(NumElement,len);
              chcol = truecol(rp(1:NumPerCol));
              idx = [1:NumPerCol]; 
              rr(count+idx) = chcol;  
              cc(count+idx) = jcol*ones(NumPerCol,1); 
              vv(count+idx) = Mcol(chcol); 
              count = count + NumPerCol; 
           end
           rr = rr(1:count); cc = cc(1:count); vv = vv(1:count); 
           Msub = Msub + spconvert([rr,cc,vv; nr,nc,0]); 
        end
     else
        Msub = M; 
     end 
  end
  B     = sparse(Msub); 
  normB = sqrt(sum(B.*B)); 
  zerocolidx = find(normB==0); 
  if ~isempty(zerocolidx) 
     error('***** B has zero columns'); 
  end
  nnzB = nnz(B);
%%
%% evaluate the regularization parameter mu
%% 
   options = []; 
   [Umax,Smax,Vmax] = lansvd(sparse(B),1,'L',options);
   mumax    = max(diag(Smax)); 
   const    = 1e-3;  
   mutarget = const*mumax;
   rho = 0; 
%%
   fprintf('\n---------------APG-------------------\n')
   par.tol     = 1e-3;
   par.maxiter = 100;  
   par.verbose = 1;
   par.plotyes = 1; 
   par.truncation = 1; 
   tstart = clock;
   [X,iter,time,sd,hist] = APGL(const,B,mutarget,rho,par);
   runhist.nr     = nr; 
   runhist.nc     = nc; 
   runhist.nnzB   = nnz(B); 
   runhist.nnzM   = nnz(M); 
   runhist.time   = etime(clock,tstart);
   runhist.iter   = iter;
   runhist.obj    = hist.obj(end);
   runhist.mu     = mutarget; 
   runhist.mumax  = mumax;
   runhist.svp    = hist.svp(end); 
   runhist.maxsvp = max(hist.svp); 
   runhist.maxsig = max(sd); 
   runhist.minsig = min(sd(find(sd>0)));
   [nr,nc]      = size(M); 
   [II,JJ,Mvec] = find(M.*(spones(M)-spones(B))); 
   if isstruct(X)
      Xvec = ProjOmega(X.U,X.V,II,JJ);
   end  
   Rvec = Mvec-Xvec; 
   runhist.pMAE  = mean(abs(Rvec));    
   runhist.pRMSE = sqrt(mean(Rvec.*Rvec)); 
   [II,JJ,Mvec] = find(M); 
   if isstruct(X)
      Xvec = ProjOmega(X.U,X.V,II,JJ);
   end  
   Rvec = Mvec-Xvec; 
   range = max(Mvec)-min(Mvec);
   runhist.MAE  = mean(abs(Rvec));    
   runhist.RMSE = sqrt(mean(Rvec.*Rvec)); 
   runhist.range  = range; 
   runhist.pNMAE  = runhist.pMAE/range; 
   runhist.pNRMSE = runhist.pRMSE/range; 
   runhist.NMAE   = runhist.MAE/range; 
   runhist.NRMSE  = runhist.RMSE/range; 
   if (saveyes)
      eval(['save ',datadir,'/',fname,'.mat runhist nr nc nnzB par']); 
   end   
%%
%% report results in a table
%%
   fprintf('\nProblem: nr = %d, nc = %d, nnz(B) = %d, nnz(B)/nr*nc = %2.1f%%',...
              nr,nc,nnzB,nnzB/(nr*nc)*100)
   fprintf('\nParameters: mu = %g, rho = %g',mutarget,rho)
   fprintf('\n-----------------------------------------------');
   fprintf('------------------------------')
   fprintf('\n iterations         :  %5.0d',runhist.iter);
   fprintf('\n # singular         :  %5.0d',runhist.svp);
   fprintf('\n obj  value         :  %5.3e',runhist.obj);
   fprintf('\n cpu   time         :  %5.2e',runhist.time);
   fprintf('\n MAE, pMAE, NMAE, pNMAE     :  %5.3e, %5.3e, %5.3e, %5.3e',...
               runhist.MAE,runhist.pMAE,runhist.NMAE,runhist.pNMAE);
   fprintf('\n RMSE, pRMSE, NRMSE, pNRMSE :  %5.3e, %5.3e, %5.3e, %5.3e',...
               runhist.RMSE,runhist.pRMSE,runhist.NRMSE,runhist.pNRMSE);
   fprintf('\n-----------------------------------------------');
   fprintf('------------------------------\n')
end
   diary off
%%*************************************************************************
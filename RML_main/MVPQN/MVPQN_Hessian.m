function [Bk, Lf] = MVPQN_Hessian(S, Y, de, method)

dimS = size(S);
ls  = size(S, 3); % dimension of the saved components
nr  = size(S, 1);
nc  = size(S, 2);

% sanity check: S Y should have the same dimension
dimY = size(Y);
if dimY ~= dimS
    error("Y and S have unmatched sizes!")
end

SS  = reshape(S, [nr * nc, ls]);
YY  = reshape(Y, [nr * nc, ls]);

switch method
    case 'LSR1' % highly instable with more than one storage. So do 1 update as Becker2019
        V   =  Y - 0.4 * de .* S;
        VS =  sum(sum( V.*S ));
        
        Bk = @(Theta) 0.4 * de .* Theta + ((sum(sum(V.*Theta)))./VS) .* V;
%         for k = 1:ls
%             L(k+1:ls,k) = SS(:,k+1:ls)' * YY(:,k);
%         end
%         d1  = sum( SS .* YY );
%         
%         de_scaled = de * 0.6;  
%         R   = d1 + L + L' - de_scaled * (SS' * SS);
%         YdS = YY - de_scaled * SS;
%         Bk  = @(Theta) reshape(de_scaled * Theta(:) + YdS * (R\(YdS' * Theta(:))), [nr, nc]);
%         Lf  = de_scaled;
        % This is a nice reminder: use \ instead of inv whenever possible
        % since inv() might not be accurate
        
    case 'LBFGS'
        L = zeros( ls );
        for k = 1:ls
            L(k+1:ls,k) = SS(:,k+1:ls)' * YY(:,k);
        end
        d1 = sum( SS .* YY );
        d2 = sqrt( d1 );
        
        R    = chol( de * ( SS' * SS ) + L * ( diag( 1 ./ d1 ) * L' ), 'lower' );
        R1   = [ diag( d2 ), zeros(ls); - L*diag( 1 ./ d2 ), R ];
        R2   = [- diag( d2 ), diag( 1 ./ d2 ) * L'; zeros( ls ), R' ];
        YdS  = [ YY, de * SS ];
        Bk  = @(Theta) reshape(de * Theta(:) - YdS * ( R2 \ ( R1 \ ( YdS' * Theta(:) ) ) ), [nr, nc]);
        Lf  = de; 
        
    otherwise
        error("This method is not defined. Please modify the code if you want.");
end
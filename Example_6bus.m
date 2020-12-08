%% load 6-bus microgrid case in MATPOWER format
% If you have installed MATPOWER, you can use function "loadcase" instead
% to read the case data
mpc = loadcase('case6_microgrid'); % input full model in MATPOWER case format
Y   = makeYbus(mpc);
[mpcreduced,Link,BCIRCr]=MPReduction(mpc,[4,5,6]',0);
%% Kron Reduction
ExBus=1; % input list of external buses (buses to be eliminated)
Y=KronReduction(Y,ExBus);
ExBus=1; % input list of external buses (buses to be eliminated)
Y=KronReduction(Y,ExBus);
ExBus=1; % input list of external buses (buses to be eliminated)
Y=KronReduction(Y,ExBus)
%% Display
z_br = [-1/Y(1,2);-1/Y(1,3);-1/Y(2,3)];
disp('     Zeq12                   Zeq13                  Zeq23');

disp(z_br');
Zeq1 = 1/sum(Y(1,:))
Zeq2 = 1/sum(Y(2,:))
Zeq3 = 1/sum(Y(3,:))
%% Third order system solution
f_nom = 50;
% Define w_nom for all 3 identical inverters
w_nom= 2*pi*f_nom*ones(3,1);
m_p  = 9.4e-5;
Rc   = 0.03;
V_nom = 220*ones(3,1);
n_Q   = 1.3e-3;
wc = 31.41*ones(3,1);


%% Solution of DAEs
syms del1(t) del2(t) del3(t) u1(t) u2(t) u3(t) S1(t) S2(t) S3(t);

del = [del1(t);del2(t);del3(t)];
S = [S1(t);S2(t);S3(t)];
u = [u1(t);u2(t);u3(t)];

wcom = w_nom(1)-m_p*real(S1(t));
wcom = wcom*ones(3,1);
ode1 = diff(del) == w_nom-m_p.*real(S)-wcom;
ode2 = diff(S) == -wc.*S+wc.*(V_nom-n_Q.*real(S)).*conj((V_nom-n_Q.*real(S)-u)./Rc);
T = diag([1 exp(del2(t)*1i) exp(del3(t)*1i)]);
v0_ref  = [V_nom(1)-n_Q.*real(S1(t));V_nom(2)-n_Q.*real(S2(t));V_nom(3)-n_Q.*real(S3(t))];
ode3 = u  == inv(T)*inv(Y)*T*(v0_ref-u)./Rc;

daes = [ode1(2) ode1(3) ode2(1) ode2(2) ode2(3) ode3(1) ode3(2) ode3(3)];
vars = [del2(t) del3(t) u1(t) u2(t) u3(t) S1(t) S2(t) S3(t)];
origVars = length(vars);
% Check if first order
isLowIndexDAE(daes,vars);

[DAEs,DAEvars] = reduceDAEIndex(daes,vars);
isLowIndexDAE(DAEs,DAEvars)

%Create the function handle by using daeFunction. 
f = daeFunction(DAEs,DAEvars);
% create the function handle for ode15i.
F = @(t,Y,YP) f(t,Y,YP);

%%
y0est = [zeros(2,1); ones(3,1); zeros(3,1)];
yp0est = zeros(8,1);
opts.Reltol=.001;
opts.AbsTol=.001;
[tSol,ySol] = ode15i(F,[0 0.5],y0est,yp0est,opts);
plot(tSol,ySol(:,1:2).*10,'LineWidth',2)
xlabel('Time(s)')
legend('\delta_2','\delta_3')
figure;
plot(tSol,ySol(:,6:8),'LineWidth',2)
xlabel('Time(s)')
legend('P_1','P_2','P_3')


%% Kron Reduction function
function Y_Reduced=KronReduction(Y,p)
[row,col]=size(Y);
Y_new=zeros(row,col);  %Produces 4 by 4 matrixes of zeros

%In this loop all p colum and row is replaced by 0 and other 
%by respective value
for k=1 :row
    for l=1 : col
        if k==p || l==p
            Y_new(k,l)=0;
        else
           Y_new(k,l)=Y(k,l)-((Y(k,p)*Y(p,l))/(Y(p,p)));

        end
    end
end
% To remove p row and colum
Y_new(:, p) = [];
Y_new(p, :) = [];
Y_Reduced=Y_new;
end




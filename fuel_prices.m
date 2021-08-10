%MatLab code for fuel prices: Random log-normally distributed fuel prices

%When using this code, please cite as:
%Avagyan V., 2017. "Essays on Risk and Profitability in the Future British Electricity Industry". PhD Thesis, Imperial College London.
%you can copy the whole code (ctrl A) and paste (ctrl V) in the MatLab Command Window 

%Gas & Oil & Coal
%Gaussian copula
%Gaussian copula produces better transformed correlations %than t-copula

M=[14.94518 11 30 44.90526];
SD=[3.087988 1.040284 3 5.984014];
for i=1:length(M)
myu(i)=log(M(i)^2/sqrt(SD(i)^2+M(i)^2));
sigma(i)=sqrt(log((SD(i)^2)/M(i)^2+1));
end
subplot(1,1,1)
set(gca,'FontSize',15);
n = 1000;
Rho = [1 0.94 0.84; 0.94 1 0.86; 0.84 0.86 1]; 
Z = mvnrnd([0 0 0], Rho, n);
U = normcdf(Z,0,1);
X = [logninv(U(:,1),myu(1),sigma(1)) logninv(U(:,2),myu(4),sigma(4)) logninv(U(:,3),myu(2),sigma(2)) ];
plot3(X(:,1),X(:,2),X(:,3), '.');
set(gca,'FontSize',15);
grid on;
view([-55, 15]);
xlabel('Gas price (£/MWh)');
ylabel('Oil price (£/MWh)');
zlabel('Coal price (£/MWh)');
corr(X(:,1),X(:,2))
corr(X(:,1),X(:,3))
corr(X(:,2),X(:,3))
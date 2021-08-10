% MatLab code for k-means cluster creation: k-means UK electricity demand cluster creation

%When using this code, please cite as:
%Avagyan V., 2017. "ENERGY STORAGE PROFIT RISK UNDER STOCHASTIC FUEL PRICES". Chapter 5, PhD Thesis, Imperial College London.

%you can copy the whole code (ctrl A) and paste (ctrl V) in the MatLab Command Window (you should have at least MatLab 2015 to run this code)
%import excel data from Days.xlsx into MatLab
%change Range to B2:Y6210 and import as Numeric Matrix
%or you can do it automatically in the command line
Days=xlsread('Days.xlsx','high','B2:Y6210');%change sheet name to 'high' or 'low' for low/high renewable case
%define cluster size, say 150. We want to aggregate 17*365+4 days into 150 days, i.e. 17 years of data that contain 4 leap years.

cluster_size=150; % specify as many clusters as needed
number_years=17;
figure('Name','unclustered','NumberTitle','off');
plot(transpose(Days)); %plot the data to make sure it looks right
title('All Days','FontSize', 20');
xlabel('Hours','FontSize', 20');
ylabel('GW','FontSize', 20');
axis([1 24 0 63]);
set(gca,'FontSize',20);

[idx,CC]=kmeans(Days,cluster_size); %where idx is cluster number and CC is the clustered centroid location
S=[idx Days];

%create a vector of years: 1995->1,1996->2...2011->17
y=1:number_years;
%First 365 days belong to 1995, second 366 days belong to 1996 etc.
r=365*ones(1,number_years);

%adjust for leap years
for t=0:3
    r(1,2+4*t)=366;
end

rep=repelem(y,r);
U= [idx transpose(rep)]; %combine idx and rep vectors into a matrix

%calculate how many unique rows we have for each cluster-year pair
[C,ia,ic] = unique(U,'rows');
T=histc(ic,unique(ic)); %to get repetitions of each cluster-year:

%to make two dimensional matrix of years and clusters with repetitions inside:
M=zeros(number_years,cluster_size);
for j=1:length(T)
M(C(j,2),C(j,1))=T(j);
end

SS=sort(S,1); %sort days in terms of clusters
SS_1=SS(:,2:length(SS(1,:))); %dropping first coloumn of SS
n0=histc(SS(:,1),unique(SS(:,1))); %count of each cluster
n1=[1;n0];  %modifying n for computational purposes n1=[1;n(2:length(n))] was before
cn=cumsum(n1); %calculating cumulative sum of array n

%calculating means of each cluster
for i=1:cluster_size
    myu(i,:)=mean(SS_1(cn(i):(cn(i+1)-1),:));
end

figure('Name','mean clusters','NumberTitle','off');
plot(transpose(myu)); %plot to see if clusters look reasonable.
title('Mean Clusters','FontSize', 20');
xlabel('Hours','FontSize', 20');
ylabel('GW','FontSize', 20');
axis([1 24 0 63]);
set(gca,'FontSize',20);

figure('Name','centroid clusters','NumberTitle','off');
plot(transpose(CC)); %compare mean with centroids
title('Centroid Clusters','FontSize', 20');
xlabel('Hours','FontSize', 20');
ylabel('GW','FontSize', 20');
title('Centroid Clusters','FontSize', 20');
xlabel('Hours','FontSize', 20');
ylabel('GW','FontSize', 20');
axis([1 24 0 63]);
set(gca,'FontSize',20);

%calculating hourly differences in each day
for i=1:cluster_size
    dd(cn(i):(cn(i+1)-1),:)=diff(SS_1(cn(i):(cn(i+1)-1),:),1,2);
end

%calculating mean change in each hour
for i=1:cluster_size
    m_ch(i,:)=mean(dd(cn(i):(cn(i+1)-1),:));
end

%finding hour changes that are the same as mean change
for dt=1:23
   for i=1:cluster_size
      for row =cn(i):(cn(i+1)-1)
         if sign(dd(row,dt))==sign(m_ch(i,dt))
          g(row,dt)=1;
         end
      end
   end
end

%calculating dominant sign average
ddT=transpose(dd); 
for i=1:cluster_size
    domin(i,:)= ddT(:,cn(i):(cn(i+1)-1))*g(cn(i):(cn(i+1)-1),:)/sum(g(cn(i):(cn(i+1)-1),:));
end

cal=[myu(:,1) domin];
rho_dominant=cumsum(cal,2);
v=cumsum(rho_dominant-myu,2);

for i=1:length(v(1,:))
    v1(:,i)=v(:,i)./i;
end

%dominant profile
rho_dominant=rho_dominant+v1;
figure('Name','dominant clusters','NumberTitle','off');
plot(transpose(rho_dominant));
title('Dominant Clusters','FontSize', 20');
xlabel('Hours','FontSize', 20');
ylabel('GW','FontSize', 20');
axis([1 24 0 63]);
set(gca,'FontSize',20);
%to get common profile, substitute word 'mean' with 'median' in row 61 and continue the process as follows...  
%calculating median change in each hour
for i=1:cluster_size
    m_ch(i,:)=median(dd(cn(i):(cn(i+1)-1),:));
end

%finding hour changes that are the same as median change
for dt=1:23
   for i=1:cluster_size
      for row =cn(i):(cn(i+1)-1)
         if sign(dd(row,dt))==sign(m_ch(i,dt))
          g(row,dt)=1;
         end
      end
   end
end

%calculating common sign average
ddT=transpose(dd); 
for i=1:cluster_size
    common(i,:)= ddT(:,cn(i):(cn(i+1)-1))*g(cn(i):(cn(i+1)-1),:)/sum(g(cn(i):(cn(i+1)-1),:));
end

cal=[myu(:,1) common];
rho_hat=cumsum(cal,2);
v=cumsum(rho_hat-myu,2);

for i=1:length(v(1,:))
    v1(:,i)=v(:,i)./i;
end

%common profile
rho_common=rho_hat+v1;
figure('Name','common clusters','NumberTitle','off');
plot(transpose(rho_common));
title('Common Clusters','FontSize', 20');
xlabel('Hours','FontSize', 20');
ylabel('GW','FontSize', 20');
axis([1 24 0 63]);
set(gca,'FontSize',20);

%we can also sort centroids along the first hour and plot
sCC=sort(CC,1);
figure('Name','sorted centroid clusters','NumberTitle','off');
plot(transpose(sCC));
title('Sorted Centroid Clusters','FontSize', 20');
xlabel('Hours','FontSize', 20');
ylabel('GW','FontSize', 20');
axis([1 24 0 63]);
set(gca,'FontSize',20);

%export all results to excel
filename = 'profiles_clustering_methods.xlsx';
xlswrite(filename,CC,'centroid')
xlswrite(filename,sCC,'sorted centroid')
xlswrite(filename,myu,'mean')
xlswrite(filename,rho_dominant,'dominant')
xlswrite(filename,rho_common,'common')
xlswrite(filename,M,'cluster_year')
%this new excel file is created in matlab directory

%to put dominant, common and mean together for comparison
figure('units','normalized','outerposition',[0 0 1 1]);
subplot(1,3,1);
plot(transpose(rho_dominant));
title('dominant','FontSize', 20');
ylabel('GW','FontSize', 20');
axis([1 24 0 63]);
set(gca,'FontSize',20);
subplot(1,3,2);
plot(transpose(rho_common));
title('common','FontSize', 20');
axis([1 24 0 63]);
set(gca,'FontSize',20);
subplot(1,3,3);
plot(transpose(myu));
title('mean','FontSize', 20');
xlabel('Hours','FontSize', 20');
axis([1 24 0 63]);
set(gca,'FontSize',20);
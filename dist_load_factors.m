%MatLab functions for generating general distributions for solar and wind LFs

%When using this code, please cite as Avagyan V., 2017. "Optimal Portfolios for Risk-Averse Generators". Chapter 3, PhD Thesis, Imperial College London.
%Function names should be called in the command window after input arguments are loaded

function [ solar_hh_adj ] = general_dist_solar( solar_cf,solar_hh )
%If wind_cf and wind_hh are already in the expanded form as below, then
%proceed, otherwise activate two following two rows
%wind_cf=[0 wind_cf 1];
%wind_hh=[0 wind_hh 0];
i=1:(length(solar_hh)-1);
diff=solar_hh(i)-solar_hh(i+1);
diff(1)=-diff(1);
c_diff=0.5*[solar_cf(2) (solar_cf(3)-solar_cf(2))*ones(1,(length(diff)-2)) solar_cf(2)];
a=c_diff*diff';
b=0.1*sum(solar_hh);
x=1/(a+b);
solar_hh_adj=x*solar_hh;
line(solar_cf,solar_hh_adj);
xh=xlabel(' Load factor');
set(xh,'Fontsize',15);
set(xh,'Fontangle');
set(xh,'Fontname','Timesnewroman');
th=title('Distribution of Solar LF (Load of 44500 MW) ');
set(th,'Fontsize',15);
set(th,'Fontangle');
set(th,'Fontname','Timesnewroman');
set(gca,'fontsize',20)
end
%
function [ wind_hh_adj ] = general_dist_wind( wind_cf,wind_hh )
%If wind_cf and wind_hh are already in the expanded form as below, then
%proceed, otherwise activate two following rows
%wind_cf=[0 wind_cf 1];
%wind_hh=[0 wind_hh 0];
i=1:(length(wind_hh)-1);
diff=wind_hh(i)-wind_hh(i+1);
diff(1)=-diff(1);
c_diff=0.5*[wind_cf(2) (wind_cf(3)-wind_cf(2))*ones(1,(length(diff)-2)) wind_cf(2)];
a=c_diff*diff';
b=0.1*sum(wind_hh);
x=1/(a+b);
wind_hh_adj=x*wind_hh;
line(wind_cf,wind_hh_adj);
xh=xlabel(' Load factor');
set(xh,'Fontsize',15);
set(xh,'Fontangle');
set(xh,'Fontname','Timesnewroman');
th=title('Distribution of Wind LF (Load of 44500 MW) ');
set(th,'Fontsize',15);
set(th,'Fontangle');
set(th,'Fontname','Timesnewroman');
set(gca,'fontsize',20)
end
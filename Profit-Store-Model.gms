*GAMS Profit-Store Model
*When using this code, please cite as Avagyan V., 2017. "ENERGY STORAGE PROFIT RISK UNDER STOCHASTIC FUEL PRICES". Chapter 5, PhD Thesis, Imperial College London.

$offlisting
$offsymxref offsymlist

option
 limrow = 0,
 limcol = 0,
 solprint = off,
 sysout = off
;

*******************************************************************************
** define our options: global definitions for data input & output

* set the filename and cell range where plant data are read from
$set plantsFile          "capacity_data_vitali_low.xlsx"
$set plantsRange         Data!A3:P44

* set the filename and cell ranges where demand data are read from
$set demandFile          "profiles_clustering_methods_low.xlsx"
$set demandRange         dominantT!A1:EU151
$set weightRange         cluster_year!A1:EU18

* set the filename and cell ranges where fuel data are read from
$set fuelFile            "Fuel spreadsheet.xlsx"
*first coloumn is expected fuel price
$set runfuelRange         running_fuel_data!A1:ALN28
$set startfuelRange       starting_fuel_data!A1:ALN28

* set the name of the results files we will produce
$set xlsResultsFile      results_storage_VA.xlsx
$set txtResultsFile      results_storage_VA.txt

* decide whether we will produce xls files  (1 = yes, 0 = no)
$set xlsResults          1

* scale factor for demand data - set to 1 if demand is given in GW, or 1000 if it is in MW
$set demandScale         1

* set the carbon tax - in £/T
$set carbonCost  80
*76.20 was before

* set the capacity of storage technologies (GW)
$set fastStorageCap      5.0
$set slowStorageCap      0.0

* set the identifier for temporary (.gdx, .txt, ..) files
* if you want to run multiple programs in parallel, this must be unique!
$set tmpid                 F1

* set a description for this run to be listed in the results
$set idString              "%slowStorageCap% GW slow and %fastStorageCap% GW fast storage"
*******************************************************************************
** define all the data for our system
Sets

 d     demand profiles (clustered days)                 /C1*C150/

 dd(d) dynamic version of d

 y     years considered                                 /y1*y17/

 t     demand periods (hours)                           /1*24/

 f     index of random fuel                             /f1*f1001/

 g     generator types                                  /Nuclear_1, Nuclear_2, Nuclear_3,
                                                         Coal_CCS_1, Coal_CCS_2, Coal_CCS_3,
                                                         CCGT_1, CCGT_2, CCGT_3, CCGT_4, CCGT_5, CCGT_6, CCGT_7, CCGT_8, CCGT_9, CCGT_10, CCGT_11, CCGT_12, CCGT_13, CCGT_14, CCGT_15,
                                                         Other_1, Other_2, Other_3,
                                                         OCGT_1, OCGT_2, OCGT_3,
                                                         FastStorage, SlowStorage,
                                                         WindSpilling,
                                                         Scarcity1, Scarcity2, Scarcity3, Scarcity4, Scarcity5, Scarcity6, Scarcity7, Scarcity8, Scarcity9, Scarcity10,
                                                         LoadShedding/

 rg(g)  generators that physically exist                /Nuclear_1, Nuclear_2, Nuclear_3,
                                                         Coal_CCS_1, Coal_CCS_2, Coal_CCS_3,
                                                         CCGT_1, CCGT_2, CCGT_3, CCGT_4, CCGT_5, CCGT_6, CCGT_7, CCGT_8, CCGT_9, CCGT_10, CCGT_11, CCGT_12, CCGT_13, CCGT_14, CCGT_15,
                                                         Other_1, Other_2, Other_3,
                                                         OCGT_1, OCGT_2, OCGT_3,
                                                         FastStorage, SlowStorage/

 pg(g)  pure generators i.e. excluding storage          /Nuclear_1, Nuclear_2, Nuclear_3,
                                                         Coal_CCS_1, Coal_CCS_2, Coal_CCS_3,
                                                         CCGT_1, CCGT_2, CCGT_3, CCGT_4, CCGT_5, CCGT_6, CCGT_7, CCGT_8, CCGT_9, CCGT_10, CCGT_11, CCGT_12, CCGT_13, CCGT_14, CCGT_15,
                                                         Other_1, Other_2, Other_3,
                                                         OCGT_1, OCGT_2, OCGT_3/

 sg(g)  generators with energy storage                  /FastStorage, SlowStorage/

 cg(g)  pseudo generators on the consumer-side          /WindSpilling,
                                                         Scarcity1, Scarcity2, Scarcity3, Scarcity4, Scarcity5, Scarcity6, Scarcity7, Scarcity8, Scarcity9, Scarcity10,
                                                         LoadShedding/
;
* storage duration (in hours)
* this gets multiplied by the number of GW of storage to give GWh of capacity
Parameters
 storageCap(sg)  GWh of energy storage in reservoirs    /FastStorage 20.00, SlowStorage 24.00/
 storageEff(sg)  Round trip efficiency of storage       /FastStorage 0.90, SlowStorage 0.90/
;
* reserve margins
Scalars
 opReserve      spinning reserve requirement (GW)       /3.00/
 sysReserve     system margin (% of demand)             /0.20/
;
Parameter
 plant(g,*)   data for each generator type
 rfuel(g,f)   simulated running fuel prices for each type of fuel
 sfuel(g,f)   simulated starting fuel prices for each type of fuel
;
$CALL GDXXRW.EXE input="%plantsFile%" output="gdx.%tmpid%.plants.gdx" par=plant rng="%plantsRange%"
$GDXIN gdx.%tmpid%.plants.gdx
$LOAD plant
$GDXIN

$CALL GDXXRW.EXE input="%fuelFile%" output="gdx.%tmpid%.fuel.gdx" par=rfuel rng="%runfuelRange%" par=sfuel rng="%startfuelRange%"
$GDXIN gdx.%tmpid%.fuel.gdx
$LOAD rfuel
$LOAD sfuel
$GDXIN

*display plant,rfuel,sfuel;

* recalculate the no-load, inc and start costs to factor in the cost of carbon
 plant(g,"noLoadCost") = plant(g,"noLoadCost") + %carbonCost% * plant(g,"noLoadCarbon") / 1000;
 plant(g,"incCost") = plant(g,"incCost") + %carbonCost% * plant(g,"incCost") / 1000;
 plant(g,"startCost") = plant(g,"startCost")  + %carbonCost% * plant(g,"startCarbon") / 1000;

*comparing with the previous plant data
*display plant;

Parameter demand(t,d)   GW - national electricity demand;
Parameter weight(y,d)   numbers of days represented;

$CALL GDXXRW.EXE input="%demandFile%" output="gdx.%tmpid%.demand.gdx" par=demand rng="%demandRange%" par=weight rng="%weightRange%" CDim=1 RDim=1
$GDXIN gdx.%tmpid%.demand.gdx
$LOAD demand
$LOAD weight
$GDXIN

* convert from MW to GW if necessary..
if (%demandScale% <> 1, demand(t,d) = demand(t,d) / %demandScale%);

*display weight,demand;

 plant("FastStorage", "minPower") = 0;
 plant("FastStorage", "Plant_capacity") = %fastStorageCap%;
 plant("SlowStorage", "minPower") = 0;
 plant("SlowStorage", "Plant_capacity") = %slowStorageCap%;
*******************************************************************************************************
* final parameters that make it into the aggregated results
parameters
 myTotalCapacity(g)                MW

 myTotalDemand(y)                  TWh
 myDuration(y)                     hours

 myTotalCost(f,y)                  £m
 myTotalPayment(f,y)               £m
 myTotalCarbon(f,y)                MT

 myAverageCost(f,y)                £ per MWh
 myAveragePrice(f,y)               £ per MWh

 myCarbonInc(f,y)                  MT CO2 from power generation
 myCarbonStart(f,y)                MT CO2 from plant start-ups

 myAverageCarbon(f,y)              kg per MWh
 myMarginalCarbon(f,y)             kg per MWh
 myAverageCarbonSU(f,y)            kg per MWh (w starts)
*This is not being used
*myMarginalCarbonSU(y)              kg per MWh (w starts)

 myAverageGridMix(f,y,g)           percent of total generation
 myMarginalGridMix(f,y,g)          percent of time marginal

 myAverageUptime(f,y,g)            average plant up-time (based on # online)
 myAverageLoadFactor(f,y,g)        average load factor (based on MWh)

 myStartsPerYear(f,y,g)            average number of start-ups per year

 myGenCost(f,y,g)                  average cost of generation per plant type (£ per MWh)
 myRevenue(f,y,g)                  total revenue for plant type g (£m)
 myProfit(f,y,g)                   total profit for plant type g (£m)

 myExcessProfit(f,y,g)             excess profit for plant type g (net of capital costs) (£m)
;
* intermediate parameters that need to be calculated
parameters
 pTotalOutput(f,y,g)        total output from each plant type (TWh)

 pTotalStarts(f,y,g)        number of start ups for each plant type

 pHoursOnline(f,y,g)        number of plant-hours online

 pHoursMarginal(f,y,g)      time that each plant type was marginal (hours)
;
*******************************************************************************
** calculate some statistics about the demand and available supply
Parameters
 peakDemand     GW - maximum demand
 troughDemand   GW - minimum demand
 peakSupply     GW - maximum generation capacity

 totalDemand(y)    GWh - total energy demand in year y
 loadFactorD(y)    load factor of the demand (relative to peak)
 loadFactorS(y)    load factor of the demand (relative to maximum supply)

 mySysReserve   peak supply relative to peak demand
;
 peakDemand   = smax((t, d), demand(t, d));
 troughDemand = smin((t, d), demand(t, d));
 peakSupply   = sum(rg, plant(rg, "Plant_capacity"));

 totalDemand(y)  = sum(d, (weight(y,d) * sum(t, demand(t, d))));
 loadFactorD(y)  = totalDemand(y) / (peakDemand * sum(d, weight(y,d)) * card(t));
 loadFactorS(y) = totalDemand(y) / (peakSupply * sum(d, weight(y,d)) * card(t));

 mySysReserve = peakSupply / peakDemand;

*display peakDemand, peakSupply, mySysReserve;
*******************************************************************************
** define the model equations
Variables
 output(g,t,d)            GW - generator output

 Capacity_Online(g,t,d)   GW - capacity of generators in use
 Capacity_Started(g,t,d)  GW - capacity of generators that started up for this period
 Capacity_Stopped(g,t,d)  GW - capacity of generators that stopped for this period

 storageInput(sg,t,d)     GW - generator consumption
 storageLevel(sg,t,d)     GWh - available storage in each energy reservoir

 cost(g,t,d)              £m - total operating cost for each plant type and period
 dailyCost(d)             £m - total operating cost for each demand cluster (day)
 totalCost                £m - total operating cost over the entire set
;
* limit the amount of operating capacity to be a number between 0 and the
* capacity of plants that are specified to be in each group

 Capacity_Online.up(g,t,d) = plant(g,"Plant_capacity");

Positive Variable Capacity_Started;
Positive Variable Capacity_Stopped;

* limit the storage level to be between 0 and the capacity limit
 storageLevel.lo(sg,t,d) = 0;
 storageLevel.up(sg,t,d) = storageCap(sg);

 storageInput.lo(sg,t,d) = 0;
 storageInput.up(sg,t,d) = plant(sg,"Plant_capacity");

*average of day-end storage level across all clusters
* storageLevel.fx('FastStorage','24',d)=2.405181799;

Equations
 eqDemandMet(t,d)               the sum of output from all plant types must be greater or equal to demand at all times
 eqSpinningMet(t,d)             the maximum possible output from all the plants online must exceed the requirement for spinning reserve at all times

 eqMinLimit(g,t,d)              each plant’s output must exceed its minimum rated power at all times
 eqMaxLimit(g,t,d)              each plant’s output must not exceed its maximum rated power at any time

 eqStorage_available(sg,t,d)    storage plants can only provide spinning reserve if they have energy in storage

 calcStarts(g,t,d)              define the number of generators that started up for this period
 calcStops(g,t,d)               define the number of generators that stopped for this period

 calcStorage(sg,t,d)            calculate the storage level of the energy reservoirs

 calcCost(g,t,d)                calculate the cost of generation from each group in each period
 calcDayCost(d)                 calculate the cost of generation for each day
 calcTotalCost                  the objective function - define total cost
;
* the output of all types of plant (physical, consumer-side and storage) must equal demand plus the power used for recharging storage
 eqDemandMet(t,dd)..     sum(g,output(g,t,dd)) =E= demand(t,dd) + sum(sg,storageInput(sg,t,dd));
* the physical capacity available must exceed demand... demand will be reduced by consumer-side
* load shedding, so we must reduce demand by their combined output
 eqSpinningMet(t,dd)..   sum(rg,Capacity_Online(rg,t,dd)) =G= demand(t,dd) + opReserve - sum(cg, output(cg, t, dd));

 eqMinLimit(g,t,dd)..   output(g,t,dd) =G= plant(g,"minPower") * Capacity_Online(g,t,dd);
 eqMaxLimit(g,t,dd)..   output(g,t,dd) =L= Capacity_Online(g,t,dd);

 eqStorage_available(sg,t,dd)..  Capacity_online(sg,t,dd) =L= storageLevel(sg,t--1,dd);

 calcStarts(g,t,dd)..   Capacity_Started(g,t,dd) =G= Capacity_Online(g,t,dd) - Capacity_Online(g,t--1,dd);
 calcStops(g,t,dd)..    Capacity_Stopped(g,t,dd) =G= Capacity_Online(g,t--1,dd) - Capacity_Online(g,t,dd);

*GWh=GWh-GW+GW*number?(VA) It's okay since it runs for an hour (RG)
 calcStorage(sg,t,dd).. storageLevel(sg,t,dd) =E= storageLevel(sg,t--1,dd) - output(sg,t,dd) + storageInput(sg,t,dd)*storageEff(sg);

 calcCost(g,t,dd)..     cost(g,t,dd) =E= ((plant(g,"noLoadCost")*Capacity_Online(g,t,dd)) +
                                               (plant(g,"startCost")*Capacity_Started(g,t,dd)) +
                                               (plant(g,"incCost") * output(g,t,dd)))/1000;

*  this uses costs per MWh or per MW-start, implying thousands per GW; as our units are in GW, divide by 1000 to get millions
 calcDayCost(dd)..       dailyCost(dd) =E= sum((g,t), cost(g,t,dd));
 calcTotalCost..         totalCost =E= sum(dd, dailyCost(dd));
*******************************************************************************
** model solvers
* primary model
Model vitali /all/;
 vitali.optcr = 0;
Parameters
 MIPmarginals(f,t,d)
 LINmarginals(f,t,d)
 costResults(f,g,t,d)
 outputResults(f,g,t,d)
 Capacity_StartedResults(f,g,t,d)
 Capacity_StoppedResults(f,g,t,d)
 Capacity_OnlineResults(f,g,t,d)
 dailyCostResults(f,d)
 storageInputResults(f,sg,t,d)
 storageLevelResults(f,sg,t,d)
 storageEndAverage(f,sg)
 storageEndAverage2(f,sg)
 sL(sg,d)
;

* we loop over our clustered days, setting each element of dd to yes in turn
* so that all of the above equations focus on one day at a time...

 dd(d) = no;
loop(f,
 plant(pg,"incCost")$(ord(pg) > 3) = plant(pg,"variableOM") + rfuel(pg,f)/plant(pg,"incrementalEfficiency") + %carbonCost% * plant(pg,"incCarbon") / 1000;
 plant(pg,"noLoadCost")= rfuel(pg,f)/plant(pg,"AverageEfficiency")*plant(pg,"NoLoadFraction")+%carbonCost% * plant(pg,"noLoadCarbon") / 1000;
 plant(pg,"startCost")$(ord(pg) > 3) = 1/plant(pg,"AverageEfficiency")*plant(pg,"StartTime")*sfuel(pg,f)+ %carbonCost% * plant(pg,"startCarbon") / 1000;
  loop(d,
   dd(d) = yes;
   Solve vitali minimising totalCost using lp;
   sL(sg,d)= storageLevel.l(sg,'24',d);
   dd(d) = no;
  );
storageEndAverage(f,sg)= sum(d,sL(sg,d))/card(d);

*display storageLevel.l,storageEndAverage,rfuel,sfuel;

 storageLevel.fx(sg,'24',d)=storageEndAverage(f,sg);
*plant(pg,"incCost")$(ord(pg) > 3) = plant(pg,"variableOM") + rfuel(pg,f)/plant(pg,"incrementalEfficiency") + %carbonCost% * plant(pg,"incCarbon") / 1000;
*plant(pg,"noLoadCost")= rfuel(pg,f)/plant(pg,"AverageEfficiency")*plant(pg,"NoLoadFraction")+%carbonCost% * plant(pg,"noLoadCarbon") / 1000;
*plant(pg,"startCost")$(ord(pg) > 3) = 1/plant(pg,"AverageEfficiency")*plant(pg,"StartTime")*sfuel(pg,f)+ %carbonCost% * plant(pg,"startCarbon") / 1000;
dd(d) = no;
 loop(d,

  dd(d) = yes;
* solve the integer problem to get the primary solution..
* solve william minimising totalCost using lp;
  Solve vitali minimising totalCost using lp;
* store the integer shadow prices for meeting just demand
  MIPmarginals(f,t,d) = eqDemandMet.m(t,d) ;
* store the shadow prices for energy plus reserve - which we take to be electricity price
  LINmarginals(f,t,d) = (eqDemandMet.m(t,d) + eqSpinningMet.m(t,d)) ;
  costResults(f,g,t,d)=cost.l(g,t,d);
  outputResults(f,g,t,d)=output.l(g,t,d);
  Capacity_StartedResults(f,g,t,d)=Capacity_Started.l(g,t,d);
  Capacity_StoppedResults(f,g,t,d)=Capacity_Stopped.l(g,t,d);
  Capacity_OnlineResults(f,g,t,d)=Capacity_Online.l(g,t,d);
  dailyCostResults(f,d)=dailyCost.l(d);
  storageInputResults(f,sg,t,d)=storageInput.l(sg,t,d);
  storageLevelResults(f,sg,t,d)=storageLevel.l(sg,t,d);

  dd(d) = no;
  );
* end the d loop
 storageLevel.lo(sg,'24',d) = 0;
 storageLevel.up(sg,'24',d) = storageCap(sg);
*******************************************************************************
** generate some output for GAMS

* total capacity of each plant type (MW)
 myTotalCapacity(g) = plant(g, "Plant_capacity") * 1000;

*loop(y,
* total output from each plant type (TWh)
 pTotalOutput(f,y,g) = sum((t,d), weight(y,d) * outputResults(f,g,t,d)) / 1000;
*display pTotalOutput;

* number of start ups for each plant type
 pTotalStarts(f,y,g) = sum((t,d), weight(y,d) * Capacity_StartedResults(f,g,t,d));
*display pTotalStarts;

* number of plant-hours online
 pHoursOnline(f,y,g) = sum((t,d), weight(y,d) * Capacity_OnlineResults(f,g,t,d));
*display pHoursOnline;

* time that each plant type was marginal (hours)
* if the incremental cost of an hour equals the generator's incremental cost, it was marginal...
 pHoursMarginal(f,y,g) = 0;
loop(d,
  loop(t,
   loop(g,
         pHoursMarginal(f,y,g) $ (abs((MIPmarginals(f, t, d) * 1000) - plant(g, "incCost")) < 0.01) = pHoursMarginal(f,y,g) + weight(y,d);
   );
  );
 );

*display pHoursMarginal;

 myTotalDemand(y) = sum((t,d), weight(y,d) * demand(t,d)) / 1000;
 myDuration(y) = sum(d, weight(y,d)) * card(t);

*display myTotalDemand, myDuration;

 myStartsPerYear(f,y,g) $ (plant(g, "Plant_capacity") > 0) = pTotalStarts(f,y,g) / plant(g, "Plant_capacity") * 8760 / myDuration(y);

*display myStartsPerYear;

 myTotalCost(f,y) = sum(d, weight(y,d) * dailyCostResults(f,d));
 myTotalPayment(f,y) = sum((t,d), weight(y,d) * demand(t,d) * LINmarginals(f,t,d));

*display myTotalCost, myTotalPayment;

 myAverageCost(f,y) = myTotalCost(f,y) / myTotalDemand(y);
 myAveragePrice(f,y) = myTotalPayment(f,y) / myTotalDemand(y);

*display myAverageCost, myAveragePrice;

*                          TWh       *         kg/MWh         / 1000  =  billions of kg = MT
 myCarbonInc(f,y) = sum(g, pTotalOutput(f,y,g) * plant(g, "incCarbon")) / 1000;
*                           #          *             T            / 1e6  = MT
 myCarbonStart(f,y) = sum(g, pTotalStarts(f,y,g) * plant(g, "startCarbon")) / 1e6;
 myTotalCarbon(f,y) = myCarbonInc(f,y) + myCarbonStart(f,y);

*display myCarbonInc, myCarbonStart;

 myAverageCarbon(f,y) = 1000 * myCarbonInc(f,y) / myTotalDemand(y);

 myMarginalCarbon(f,y) = sum(g, pHoursMarginal(f,y,g) * plant(g, "incCarbon")) / myDuration(y);
 myAverageCarbonSU(f,y) = 1000 * (myCarbonInc(f,y) + myCarbonStart(f,y)) / myTotalDemand(y);


*display myAverageCarbon, myMarginalCarbon, myAverageCarbonSU;


 myAverageGridMix(f,y,g) = pTotalOutput(f,y,g) / myTotalDemand(y);
 myMarginalGridMix(f,y,g) = pHoursMarginal(f,y,g) / myDuration(y);

*display myAverageGridMix, myMarginalGridMix;

 myAverageUptime(f,y,g) $ (plant(g, "Plant_capacity") > 0) = pHoursOnline(f,y,g) / plant(g, "Plant_capacity") / myDuration(y);

loop(g,
  myAverageLoadFactor(f,y,g) = 0;
  if (plant(g, "Plant_capacity") > 0,
    myAverageLoadFactor(f,y,g) = (pTotalOutput(f,y,g) * 1000) / (plant(g, "Plant_capacity") * myDuration(y));
  );
);

*display myAverageUptime, myAverageLoadFactor;

* calculate generating cost for plants with non-zero output.
* (cost * 1000) gives cost in £k, output * time is in GWh, £k/GWh = £/MWh...
loop(g,
 loop(y,
  if (sum(d, weight(y,d) * sum(t, outputResults(f,g,t,d))) <> 0,
     myGenCost(f,y,g) = 1000 * sum(d, weight(y,d) * sum(t, costResults(f,g,t,d))) / sum(d, weight(y,d) * sum(t, outputResults(f,g,t,d)));
  );
 );
);

* (output * time) is in GWh, marginals are in £/kWh, the result is in £m
 myRevenue(f,y,g) = sum(d, weight(y,d) * sum(t, outputResults(f,g,t,d) * LINmarginals(f,t,d)));
 myRevenue(f,y,sg)= sum(d, weight(y,d) * sum(t, (outputResults(f,sg,t,d)-storageInputResults(f,sg,t,d)) * LINmarginals(f,t,d)+(LINmarginals(f,t,d)-MIPmarginals(f,t,d))*storageLevelResults(f,sg,t,d)));
 myProfit(f,y,g) = myRevenue(f,y,g) - sum(d, weight(y,d) * sum(t, costResults(f,g,t,d)));

* plant fixedCost was in £/kW-year but that is also £m/GW...
* super-profit = revenue - variable costs - (fixed cost x amount of capacity x duration in years)
 myExcessProfit(f,y,g) = myProfit(f,y,g) - (plant(g, "fixedCost") * plant(g, "Plant_capacity") * myDuration(y) / 8760);

*display myGenCost, myRevenue, myProfit, myExcessProfit,eqDemandMet.m,eqSpinningMet.m;

);
* end of the f loop

*display storageLevelResults;

storageEndAverage2(f,sg)=sum(d,storageLevelResults(f,sg,"24",d))/card(d);
*******************************************************************************
** generate some output for excel
* stats files
Parameter stats1 summary of supply and demand;
Parameter stats2 summary of load factors;
Parameter stats3 summary of total demand;
Parameter stats4 summary of total cost;
Parameter stats5 summary of general parameters per time period;
Parameter statsOnline summary of plants online per time period;
Parameter statsStarts summary of plant start-ups per time period;
Parameter statsOutput summary of plant output per time period;
Parameter statsInput summary of storage input per time period;
Parameter statsStorage summary of storage energy per time period;
Parameter stats6 summary of profit and revenue for each plant type;
Parameter stats7 average storage level at the end of the day;

if (%xlsResults% = 1,

 stats1("Min Demand","(GW)")                       = troughDemand;
 stats1("Peak Demand","(GW)")                      = peakDemand;
 stats1("Peak Supply","(GW)")                      = peakSupply;
 stats2(y,"Relative to Peak Demand","Load Factor") = loadFactorD(y);
 stats2(y,"Relative to Supply","Load Factor")      = loadFactorS(y);

 stats3(y,"Total Demand","(TWh)")                  = totalDemand(y) / 1000;

 stats4(f,y,"Cost of Supply","(£m)")               = myTotalCost(f,y);
 stats4(f,y,"Payment of Supply","(£m)")            = myTotalPayment(f,y);

 stats6(f,y,g,"Revenue (£m)")                      = myRevenue(f,y,g);
 stats6(f,y,g,"Profit (£m)")                       = myProfit(f,y,g);
 stats6(f,y,g,"Super Profit(£m)")                  = myExcessProfit(f,y,g);
 stats6(f,y,g,"Gen Cost (£/MWh)")                  = myGenCost(f,y,g);

 stats5(f,d,t,"Demand (GW)")                       = demand(t,d);
 stats5(f,d,t,"Output (GW)")                       = sum(rg, outputResults(f,rg,t,d));

* available spinning capacity is the sum of all physical generators online, plus any output from load shedding
 stats5(f,d,t,"Spinning Capacity (GW)")    = sum(rg,Capacity_OnlineResults(f,rg,t,d)) + sum(cg,outputResults(f,cg,t,d));
 stats5(f,d,t,"Storage Spinning (GW)")     = sum(sg,Capacity_OnlineResults(f,sg,t,d));
 stats5(f,d,t,"Start ups")                 = sum(rg,Capacity_StartedResults(f,rg,t,d)) - sum(sg,Capacity_StartedResults(f,sg,t,d));
 stats5(f,d,t,"Shut downs")                = sum(rg,Capacity_StoppedResults(f,rg,t,d)) - sum(sg,Capacity_StoppedResults(f,sg,t,d));
 stats5(f,d,t,"Storage Output")            = sum(sg,outputResults(f,sg,t,d));
 stats5(f,d,t,"Storage Input")             = sum(sg,storageInputResults(f,sg,t,d));
 stats5(f,d,t,"Storage Level")             = sum(sg,storageLevelResults(f,sg,t,d));
 stats5(f,d,t,"Total Cost (£m)")           = sum(g,costResults(f,g,t,d));
 stats5(f,d,t,"Incremental Cost (£/MWh)")  = MIPmarginals(f,t,d) * 1000;
 stats5(f,d,t,"Marginal Cost (£/MWh)")     = LINmarginals(f,t,d) * 1000;

* convert all zeros into epsilon values, so that they
* can be passed into the gdx file and on into excel...
 Capacity_OnlineResults(f,g,t,d) $ (Capacity_OnlineResults(f,g,t,d) = 0) = eps;

 Capacity_StartedResults(f,g,t,d) $ (Capacity_StartedResults(f,g,t,d) = 0) = eps;

 outputResults(f,g,t,d) $ (outputResults(f,g,t,d) = 0) = eps;

 storageInputResults(f,sg,t,d) $ (storageInputResults(f,sg,t,d) = 0) = eps;

 storageLevelResults(f,sg,t,d) $ (storageLevelResults(f,sg,t,d) = 0) = eps;

 statsOnline(f,d,t,g) = Capacity_OnlineResults(f,g,t,d);
 statsStarts(f,d,t,g) = Capacity_StartedResults(f,g,t,d);
 statsOutput(f,d,t,g) = outputResults(f,g,t,d);
 statsInput(f,d,t,sg) = storageInputResults(f,sg,t,d);
 statsStorage(f,d,t,sg) = storageLevelResults(f,sg,t,d);
 stats7(f,sg,"First Method")=storageEndAverage(f,sg);
 stats7(f,sg,"Second Method")=storageEndAverage2(f,sg);
* generate a call to gdxxrw to send all these to excel
$onecho > gdx.%tmpid%.results.txt
text="General stats"             rng=Year!A1
par=stats1                       rng=Year!A3
par=stats2                       rng=Year!C3
par=stats3                       rng=Year!F3
par=stats4                       rng=Year!K3

epsout=0    par=stats6           rng=Year!P3

text="Stats per period"          rng=Stats!A1
epsout=0    par=stats5           rng=Stats!A3

text="Number of plants online"   rng=Plants!A1
epsout=0    par=statsOnline      rng=Plants!A3

text="Number of start ups"       rng=Starts!A1
epsout=0    par=statsStarts      rng=Starts!A3

text="Total generation (GW)"     rng=Output!A1
epsout=0    par=statsOutput      rng=Output!A3

text="Total consumption (GW)"    rng=Input!A1
epsout=0    par=statsInput       rng=Input!A3

text="Amount in storage (GWh)"   rng=Stored!A1
epsout=0    par=statsStorage     rng=Stored!A3

text="Average end-day level (GWh)"  rng=Stored!G1
epsout=0    par=stats7           rng=Stored!G3
$offecho

execute_unload "gdx.%tmpid%.results.gdx"
execute 'gdxxrw.exe input="gdx.%tmpid%.results.gdx" output="%xlsResultsFile%" @"gdx.%tmpid%.results.txt"';
);
* end %xlsResults% condition...
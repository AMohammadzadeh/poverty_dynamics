*******************************************************************
*This file calculates the lower bound & upper bound estimates of 
*poverty dynamics using synthetic panel data from IFLS 1997-2000
*for Figure 1 for Indonesia in Dang, Lanjouw, Luoto and McKenzie paper 
*Author: Hai-Anh Dang (hdang@worldbank.org) (July 2013)
*******************************************************************

*change directory
cd "D:\Ahmad\Thesis\DrKeshavarz\Poverty Dynamics DLLM\data"

log using "y9899_figure 1", replace text
*1- PREDICT EPSILON USING 1997 & 2000 DATA 
global hdage "HAge>= 25 & HAge<= 55" 
global hdage98 "HAge>= 25 & HAge<= 55" 
global hdage99 "HAge>= 25 & HAge<= 55" 

global depvar "lcpc_"
global depvar_98 "lcpc_98"
global depvar_99 "lcpc_99"
global indvar "HAge i.HSex HEduYears HLiterate NKids i.Region i.ProvinceCode Size HEmployed HMarritalState" 

use Y98_99_final, clear
xi: reg $depvar_98 $indvar if $hdage & samp== 1, cluster(strata_98)
predict double eh1 if e(sample), res

xi: reg $depvar_99 $indvar if $hdage & samp== 2, cluster(strata_99)
predict double eh2 if e(sample), res

keep if eh1<.| eh2<.
keep HHID* strata* eh* Year samp

sort strata_98 HHID strata_99 
compress
save eh_orig, replace

*2- PREDICT UPPER BOUNDS OF POVERTY USING 2000 DATA
use Y98_99_final, clear

*2.0 SIMULATE POVERTY LINES
local snper= 50 // define no of percentiles
local k= `snper'- 1
_pctile lcpc_99 [aw= Weight], n(`snper') 

forval l= 1/`k' {
scalar lpoverty_line98`l'= r(r`l')
scalar lpoverty_line99`l'= r(r`l')
}

***NOW RUN THE LOOPS
forval l= 1/`k' {
*2.1- predict xb
use Y98_99_final, clear
qui xi: reg $depvar_98 $indvar if $hdage & samp== 1, cluster(strata_98)
scalar r1= e(r2)
scalar sige1= e(rmse) 

predict double bh1x2 if $hdage & samp== 2, xb
predict double bh1x1 if e(sample), xb

qui xi: reg $depvar_99 $indvar if $hdage & samp== 2, cluster(strata_99)
scalar r2= e(r2)
scalar sige2= e(rmse) 
predict double bh2x1 if $hdage & samp== 1, xb
predict double bh2x2 if e(sample), xb

scalar rmin= min(r1, r2)
scalar rmax= max(r1, r2)

keep if bh1x2<.| bh2x1<.

keep bh* HHID* lcpc* HAge HSex HEduYears Year Weight *poverty* samp strata*

su HAge if samp== 1
scalar obid98= r(N)

su HAge if samp== 2
scalar obid99= r(N)

scalar obidy= max(obid98, obid99) // THIS IS FOR RANDOM SAMPLING
scalar list obidy

sort strata_98 strata_99 HHID
bys samp: gen obid= _n // THIS IS FOR RANDOM SAMPLING

sort obid
compress
save bh1x2_bh2x1, replace

*2.2- bootstrap the sample of error terms
forval i= 1/ 500 {
use eh_orig, clear
set seed `i'

*2.2.1- GET BOOTSTRAPPED ERRORS FROM 2000 DATA
qui keep if samp== 2 & eh2<.
qui keep eh2 samp

if obid98> obid99 {
   expand 2
}

bsample obid98
ren eh2 eth2 // bootstrapped errors
qui gen obid= _n
qui replace samp= 1 // change the samp to match with bh2x1

sort samp obid 
qui merge 1:1 samp obid using bh1x2_bh2x1
qui drop _m

sort obid
qui compress

tempfile stsec70 //declare temp file name
save "`stsec70'"

*2.2.2- GET BOOTSTRAPPED ERRORS FROM 1997 DATA
use eh_orig, clear
qui keep if samp== 1
qui keep if eh1<.
qui keep eh1 samp

if obid99> obid98 {
   expand 2
}

bsample obid99
ren eh1 eth1 // bootstrapped errors
qui gen obid= _n
qui replace samp= 2 // change the samp to match with bh1x2

sort samp obid 
qui merge 1:1 samp obid using "`stsec70'"
qui drop _m

sort obid

*2.3-GET PREDICTED VALUES IN PANEL DATA STRUCTURE
qui gen double yu_99= bh2x1+ eth2 
qui gen double yu_98= bh1x2+ eth1

*REPLACE MISSING VALUES WITH OBSERVED VALUES OR STACKING DATA
qui replace yu_98= lcpc_98 if yu_98==. & samp== 1
qui replace yu_99= lcpc_99 if yu_99==. & samp== 2

*2.4- KEEP A SINGLE YEAR HERE IF DO NOT WANT STACKED ESTIMATES
qui keep if samp== 2 

*2.5- POVERTY LINE IS 2559.85 IN 1997, & 3358.18 IN 2000
qui gen povub98= (yu_98> lpoverty_line98`l' ) if yu_98<.
qui gen povub99= (yu_99> lpoverty_line99`l' ) if yu_99<.

qui tab povub98 povub99 [aw= Weight], matcell(povub`i'_all)
mat povub`i'_all= 100* povub`i'_all/ r(N) // get percentage
}

*2.6- GET THE AVERAGE
local i= 2
while `i'<= 500 {
    local j= `i' - 1 
    mat povub`i'_all= povub`i'_all + povub`j'_all
    local i= `i' + 1 
}

local j= `i' - 1 
local char "_all"
foreach x of local char {
mat povub`j'`x'= povub`j'`x'/`j'
mat rown povub`j'`x'= poor98 nonpoor98
mat coln povub`j'`x'= poor99 nonpoor99
}

mat povub98povub99_all`l'= povub`j'_all

*2.7- GET NO OF OBSERVATIONS
qui ta  povub98 povub99 [aw= Weight], cell nofr matcell(povub`i')
scalar npovub98povub99_all`l'= r(N)

*3- GET LOWER BOUND ESTIMATES OF POVERTY
use Y98_99_final, clear
qui xi: reg $depvar_98 $indvar if $hdage & samp== 1, cluster(strata_98)
est store reg98
scalar r1= e(r2)

predict double bh1x2 if $hdage & samp== 2, xb
predict double bh1x1 if e(sample), xb
predict double eh1 if e(sample), res

qui xi: reg $depvar_99 $indvar if $hdage & samp== 2, cluster(strata_99)
est store reg99
scalar r2= e(r2)

predict double bh2x1 if $hdage & samp== 1, xb
predict double bh2x2 if e(sample), xb
predict double eh2 if e(sample), res

scalar rmin= min(r1, r2)
scalar ormin= 1- rmin

scalar rmax= max(r1, r2)
scalar ormax= 1- rmax

keep if bh1x2<.| bh2x1<.
keep bh* strata* lcpc* eh* $depvar_98 $depvar_99 HAge HSex HEduYears Year Weight *poverty* samp 
 
*3.1- DEFINE LOWER BOUNDS & STACK DATA
gen double yl2= bh2x1+ (sige2/sige1)* eh1
gen double yl1= bh1x2+ (sige1/sige2)* eh2
la var yl1 "lower bound of y, first period"
la var yl2 "lower bound of y, second period"

ren yl1 yl_98
ren yl2 yl_99

replace yl_98= lcpc_98 if yl_98==. & samp== 1
replace yl_99= lcpc_99 if yl_99==. & samp== 2

qui gen povlb98= (yl_98> lpoverty_line98`l' ) if yl_98<.
qui gen povlb99= (yl_99> lpoverty_line99`l' ) if yl_99<.

*3.2- KEEP A SINGLE YEAR HERE IF DO NOT WANT STACKED ESTIMATES
qui keep if samp== 2 

*3.3- CALCULATE POVERTY RATES
la def pstat2 1 "nonpoor" 0 "poor"
qui for var povlb98 povlb99: la val X pstat2

ta povlb98 povlb99 [aw= Weight], cell nofr matcell(povlb98povlb99_all)
mat povlb98povlb99_all`l'= 100* povlb98povlb99_all/ r(N) // do this to get the percentage
mat rown povlb98povlb99_all`l'= poor98 nonpoor98
mat coln povlb98povlb99_all`l'= poor99 nonpoor99
scalar npovlb98povlb99_all`l'= r(N)

*4- COMPARE WITH REAL DATA, USE FULL PANEL 
use Y98_99_final, clear
keep if HAge>= 25 & HAge<= 55 // keep data if heads are 25-55 yrs old in 1997

*KEEP SAME OBS AS WITH ESTIMATES
qui reg $depvar_98 $indvar if $hdage
keep if e(sample)

qui gen pov98= (lcpc_98> lpoverty_line98`l' ) if lcpc_98<.
qui gen pov99= (lcpc_99> lpoverty_line99`l' ) if lcpc_99<. 

la def pstat2 1 "nonpoor" 0 "poor"
qui for var pov98 pov99: la val X pstat2
ta pov98 pov99, cell nofr 

qui gen  p98p99= (lcpc_98<= lpoverty_line98`l' & lcpc_99<= lpoverty_line99`l' ) if lcpc_98<. & lcpc_99<. 
qui gen  p98np99= (lcpc_98<= lpoverty_line98`l' & lcpc_99> lpoverty_line99`l' ) if lcpc_98<. & lcpc_99<. 
qui gen  np98p99= (lcpc_98> lpoverty_line98`l' & lcpc_99<= lpoverty_line99`l' ) if lcpc_98<. & lcpc_99<. 
qui gen  np98np99= (lcpc_98> lpoverty_line98`l' & lcpc_99> lpoverty_line99`l' ) if lcpc_98<. & lcpc_99<. 

tabstat p98p99 p98np99 np98p99 np98np99 [aw= Weight], by(pov98) stat(mean sem) save 
mat li r(StatTotal)
mat tpov9899_all`l'= r(StatTotal)*100
qui ta p98p99 p98np99 [aw= Weight]
scalar ntpov9899_all`l'= r(N)
}

*5- GRAPH IT
gen lb1= .
gen ub1= .
gen trate=.
gen pctile= .

forval l= 1/`k' {
replace lb1= povlb98povlb99_all`l'[1,2] in `l'
replace trate= tpov9899_all`l'[1,2] in `l'
replace ub1= povub98povub99_all`l'[1,2] in `l'
replace pctile= `l' in `l'
}

local k= 49
gen pctile2= pctile* (100/50) // scale to 100%
li lb1 trate ub1 pctile in 1/`k'
la var lb1 "lower bounds"
la var ub1 "upper bounds"
la var trate "true rates"
scatter lb1 trate ub1 pctile2 in 1/`k', xti(Poverty Lines (Percentiles)) yti(Percentage (%)) ///
        msymb(t c d) xline(10.1) saving(fig1, replace)
graph export "fig1.eps", as(eps) preview(off) replace


log close
stop

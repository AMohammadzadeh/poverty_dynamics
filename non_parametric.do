cd "D:\Ahmad\Thesis\DrKeshavarz\Poverty Dynamics DLLM\data"
use Y98_99_final,clear
*Generate log of consumption per capita
destring strata*,replace

global hdage "HAge>= 25 & HAge<= 55" 
global depvar "lcpc_98"
global depvar_99 "lcpc_99"

*for now, we have only one model. I will expand the models and will use 
* a for loop instead of the following variable
global m 1 

*Define independent vars
*HAge: age
*HSex: sex
local indvar1 "HAge HSex HEduYears"


*2- PREDICT UPPER BOUNDS OF POVERTY USING 99 DATA
*2.1- predict xb


*KEEP SAME NO OF OBSERVATIONS	
xi: reg $depvar `indvar`m'' if $hdage & samp == 1, cluster(strata_98)
scalar r1`m'= round(e(r2), 0.001)
scalar r1`m'a= round(e(r2_a), 0.001)
scalar sige1= e(rmse)
est store reg98_ub`m'
predict double eh1 if e(sample), res
predict double bh1x2 if $hdage & samp == 2, xb
predict double bh1x1 if e(sample), xb

xi: reg $depvar_99 `indvar`m'' if $hdage & samp == 2, cluster(strata_99)
scalar r2`m'= round(e(r2), 0.001)
scalar r2`m'a= round(e(r2_a), 0.001)
predict double eh2 if e(sample), res
scalar sige2= e(rmse)
est store reg99_ub`m' 
predict double bh2x1 if $hdage & samp == 1, xb
predict double bh2x2 if e(sample), xb

*GET CORRELATION HERE
// qui reg $depvar `indvar`m'' if $hdage & samp == 2, cluster(strata_99)
// predict double feh2 if e(sample), res
// corr eh2 feh2
// scalar rho`m'= r(rho)

preserve
keep if eh1<.| eh2<.
keep HHID* strata* eh* Year samp

*sort hidn 
compress
save eh_orig, replace
restore

keep if bh1x2<.| bh2x1<.
keep bh* strata* $depvar $depvar_99 HAge HSex HEduYears Year Weight *poverty* samp 

su HAge if samp == 1
scalar obid98= r(N)

su HAge if samp == 2
scalar obid99= r(N)

scalar obidy= max(obid98, obid99) // THIS IS FOR RANDOM SAMPLING
scalar list obidy

*sort hidn
bys Year: gen obid= _n // THIS IS FOR RANDOM SAMPLING

sort obid
compress
save bh1x2_bh2x1, replace

*2.2- bootstrap the sample of error terms
forval i= 1/ 500 {

use eh_orig, clear
set seed `i'

*2.2.1- GET BOOTSTRAPPED ERRORS FROM 99 DATA
qui keep if samp == 2 & eh2<.
qui keep eh2 samp

if obid98> obid99 {
   expand 2
}

bsample obid98
ren eh2 eth2 // bootstrapped errors
qui gen obid= _n
qui replace samp= 1 // change the Year to match with bh2x1

sort samp obid 
qui merge 1:1 samp obid using bh1x2_bh2x1
qui drop _m

sort obid
qui compress

tempfile stsec70 //declare temp file name
save "`stsec70'"

*2.2.2- GET BOOTSTRAPPED ERRORS FROM 98 DATA
use eh_orig, clear
qui keep if samp == 1
qui keep if eh1<.
qui keep eh1 samp

if obid99> obid98 {
   expand 2
}

bsample obid99
ren eh1 eth1 // bootstrapped errors
qui gen obid= _n
qui replace samp= 2 // change the Year to match with bh1x2

sort samp obid 
qui merge 1:1 samp obid using "`stsec70'"
qui drop _m

sort obid

*2.3-GET PREDICTED VALUES IN PANEL DATA STRUCTURE
qui gen double yu_99= bh2x1+ eth2 
qui gen double yu_98= bh1x2+ eth1

*REPLACE MISSING VALUES WITH OBSERVED VALUES OR STACKING DATA
qui replace yu_98= lcpc_98 if yu_98==. & samp == 1
qui replace yu_99= lcpc_99 if yu_99==. & samp == 2

*2.4- KEEP A SINGLE Year HERE IF DO NOT WANT STACKED ESTIMATES
qui keep if samp == 2 

*2.5- POVERTY LINE 
qui gen povub98= (yu_98> lpoverty_line98 ) if yu_98<.
qui gen povub99= (yu_99> lpoverty_line99 ) if yu_99<.

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

mat povub98povub99_all`m'= povub`j'_all

mat li povub1_all
mat li povub`j'_all

*2.7- GET NO OF OBSERVATIONS
qui ta  povub98 povub99, cell nofr matcell(povub`i')
scalar npovub98povub99_all`m'= r(N)

*3- GET LOWER BOUND ESTIMATES OF POVERTY
use Y98_99_final, clear

qui xi: reg $depvar `indvar`m'' if $hdage & samp == 1, cluster(strata_98)
est store reg98_lb`m'
scalar r1= e(r2)
scalar sige1= e(rmse)

predict double bh1x2 if $hdage & samp == 2, xb
predict double bh1x1 if e(sample), xb
predict double eh1 if e(sample), res

qui xi: reg $depvar_99 `indvar`m'' if $hdage & samp == 2, cluster(strata_99)
est store reg99_lb`m'
scalar r2= e(r2)
scalar sige2= e(rmse)

predict double bh2x1 if $hdage & samp == 1, xb
predict double bh2x2 if e(sample), xb
predict double eh2 if e(sample), res

scalar rmin= min(r1, r2)
scalar ormin= 1- rmin

scalar rmax= max(r1, r2)
scalar ormax= 1- rmax

keep if bh1x2<.| bh2x1<.
keep bh* strata* lcpc* eh* $depvar $depvar_99 HAge HSex HEduYears Year Weight *poverty* samp 

*3.1- DEFINE LOWER BOUNDS & STACK DATA
gen double yl2= bh2x1+ (sige2/sige1)* eh1
gen double yl1= bh1x2+ (sige1/sige2)* eh2

la var yl1 "lower bound of y, first period"
la var yl2 "lower bound of y, second period"

ren yl1 yl_98
ren yl2 yl_99

replace yl_98= lcpc_98 if yl_98==. & samp == 1
replace yl_99= lcpc_99 if yl_99==. & samp == 2

qui gen povlb98= (yl_98> lpoverty_line98 ) if yl_98<.
qui gen povlb99= (yl_99> lpoverty_line99 ) if yl_99<.

*3.2- KEEP A SINGLE Year HERE IF DO NOT WANT STACKED ESTIMATES
qui keep if samp == 2 

*3.3- CALCULATE POVERTY RATES
la def pstat2 1 "nonpoor" 0 "poor"
qui for var povlb98 povlb99: la val X pstat2

ta povlb98 povlb99[aw= Weight], cell nofr matcell(povlb98povlb99_all`m')
mat povlb98povlb99_all`m'= 100* povlb98povlb99_all`m'/ r(N) // do this to get the percentage
mat rown povlb98povlb99_all`m'= poor98 nonpoor98
mat coln povlb98povlb99_all`m'= poor99 nonpoor99
scalar npovlb98povlb99_all`m'= r(N)


*change directory
cd "E:\my_papers\poverty_dynamics\poverty_line_data"
use Y98_99_urban, clear
destring strata*, replace
destring HHID, replace


log using "parametric", replace text
global hdage "HAge>= 25 & HAge<= 55" 

global depvar "lcpc_"
global depvar_98 "lcpc_98"
global depvar_99 "lcpc_99"
global indvar "HAge i.HSex HEduYears HLiterate NKids i.Region i.ProvinceCode Size HEmployed HMarritalState" 

// use Y98_99_urban, clear
xi: reg $depvar_98 $indvar if $hdage & samp== 1, cluster(strata_98)
predict double eh1 if e(sample), res

xi: reg $depvar_99 $indvar if $hdage & samp== 2, cluster(strata_99)
predict double eh2 if e(sample), res

keep if eh1<.| eh2<.
keep HHID* strata* eh* Year samp

// sort strata_98 hid97 strata_99 HHID 
sort strata_98 HHID strata_99 
compress
save eh_orig, replace

*2- PREDICT UPPER BOUNDS OF POVERTY USING 2000 DATA
*2.1- predict xb
use Y98_99_urban, clear
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

mat povub98povub99_all= povub`j'_all

*2.7- GET NO OF OBSERVATIONS
qui ta  povub98 povub99 [aw= Weight], cell nofr matcell(povub`i')
scalar npovub98povub99_all= r(N)

*3- GET LOWER BOUND ESTIMATES OF POVERTY
use Y98_99_urban, clear
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

qui gen povlb98= (yl_98> lpoverty_line98 ) if yl_98<.
qui gen povlb99= (yl_99> lpoverty_line99 ) if yl_99<.

*3.2- KEEP A SINGLE YEAR HERE IF DO NOT WANT STACKED ESTIMATES
qui keep if samp== 2 

*3.3- CALCULATE POVERTY RATES
la def pstat2 1 "nonpoor" 0 "poor"
qui for var povlb98 povlb99: la val X pstat2

ta povlb98 povlb99 [aw= Weight], cell nofr matcell(povlb98povlb99_all)
mat povlb98povlb99_all= 100* povlb98povlb99_all/ r(N) // do this to get the percentage
mat rown povlb98povlb99_all= poor98 nonpoor98
mat coln povlb98povlb99_all= poor99 nonpoor99
scalar npovlb98povlb99_all= r(N)

*4- DIRECT ESTIMATES OF POVERTY DYNAMICS 
*4.0- DEFINE PROGRAM 
local char "_all"
foreach x of local char {
  gen double p98p99e`x'= .
  gen double p98np99e`x'= .
  gen double np98p99e`x'= .
  gen double np98np99e`x'= .
}

cap program drop mypovdy
program mypovdy 
*4.0a- ALL POPULATION
mat p98p99e_all= J(2, 2, .)
mat rown p98p99e_all= poor98 nonpoor98
mat coln p98p99e_all= poor99 nonpoor99

replace p98p99e_all= $pp99 if samp== 2
qui su p98p99e_all [aw= Weight]
mat p98p99e_all[1,1]= r(mean)*100

replace p98np99e_all= $pnp99 if samp== 2
qui su p98np99e_all [aw= Weight] 
mat p98p99e_all[1,2]= r(mean)*100

replace np98p99e_all= $npp99 if samp== 2
qui su np98p99e_all [aw= Weight] 
mat p98p99e_all[2,1]= r(mean)*100

replace np98np99e_all= $npnp99 if samp== 2
qui su np98np99e_all [aw= Weight] 
mat p98p99e_all[2,2]= r(mean)*100
end


*4.1- DEFINE THE MACROS BY SURVEY YEAR FOR OLS REGRESSIONS
***define the globals for predicting on 2000 data
global pp99 "binormal((lpoverty_line98- bh1x2)/sige1, (lpoverty_line99- bh2x2)/sige2, rho)"
global pnp99 "binormal((lpoverty_line98- bh1x2)/sige1, -(lpoverty_line99- bh2x2)/sige2, -rho)"
global npp99 "binormal(-(lpoverty_line98- bh1x2)/sige1, (lpoverty_line99- bh2x2)/sige2, -rho)"
global npnp99 "binormal(-(lpoverty_line98- bh1x2)/sige1, -(lpoverty_line99- bh2x2)/sige2, rho)"

*4.1.1- LOWER BOUND
*rho= 1 
scalar rho= 1
mypovdy
local char "_all"
foreach x of local char {
        mat p98p99e1`x'= p98p99e`x'
}

*rho= 0.8 
scalar rho= 0.8
mypovdy
local char "_all"
foreach x of local char {
        mat p98p99e2`x'= p98p99e`x'
}

*rho= 0.7
scalar rho= 0.7
mypovdy
local char "_all"
foreach x of local char {
        mat p98p99e3`x'= p98p99e`x'
}

*4.1.2- UPPER BOUND
*rho= 0.3
scalar rho= 0.3
mypovdy
local char "_all"
foreach x of local char {
        mat p98p99e4`x'= p98p99e`x'
}

*rho= 0.2
scalar rho= 0.2
mypovdy
local char "_all"
foreach x of local char {
        mat p98p99e5`x'= p98p99e`x'
}

***rho= 0 
scalar rho= 0
mypovdy
local char "_all"
foreach x of local char {
        mat p98p99e6`x'= p98p99e`x'
}

*5- COMPARE WITH REAL DATA, USE FULL PANEL
*get estimates for Table 2 & Appendix Table 2.2
use Y98_99_urban_long, clear
destring HHID, replace
xtreg $depvar $indvar, i(HHID) cluster(strata_99)
est store iran_9899
estout iran_9899 ///
   using idn_tab2.2_rho, starlevels(* 0.10 ** 0.05 *** 0.01) ///   
   style(tab) cells("b(star fmt(3))" "se(par)") stats(sigma_u sigma_e rho r2_o N_g N, fmt(2 2 2 2 0 0) ) replace

use Y98_99_urban, clear
keep if HAge>= 25 & HAge<= 55 // keep data if heads are 25-55 yrs old in 1997

*KEEP SAME OBS AS WITH ESTIMATES
qui reg $depvar_98 $indvar if $hdage
keep if e(sample)

qui gen pov98= (lcpc_98> lpoverty_line98 ) if lcpc_98<.
qui gen pov99= (lcpc_99> lpoverty_line99 ) if lcpc_99<. 

la def pstat2 1 "nonpoor" 0 "poor"
qui for var pov98 pov99: la val X pstat2
ta pov98 pov99, cell nofr 

qui gen  p98p99= (lcpc_98<= lpoverty_line98 & lcpc_99<= lpoverty_line99 ) if lcpc_98<. & lcpc_99<. 
qui gen  p98np99= (lcpc_98<= lpoverty_line98 & lcpc_99> lpoverty_line99 ) if lcpc_98<. & lcpc_99<. 
qui gen  np98p99= (lcpc_98> lpoverty_line98 & lcpc_99<= lpoverty_line99 ) if lcpc_98<. & lcpc_99<. 
qui gen  np98np99= (lcpc_98> lpoverty_line98 & lcpc_99> lpoverty_line99 ) if lcpc_98<. & lcpc_99<. 

tabstat p98p99 p98np99 np98p99 np98np99 [aw= Weight], by(pov98) stat(mean sem) save 
mat li r(StatTotal)
mat tpov9899_all= r(StatTotal)*100
qui ta p98p99 p98np99 [aw= Weight]
scalar ntpov9899_all= r(N)

*6- PUT THIS IN THE FINAL MATRIX
local char "_all"
foreach x of local char {
mat pov70`x'= J(9, 9, .)
mat pov70`x'[1,1]= round(povlb98povlb99`x'[1,1], 0.1)
mat pov70`x'[3,1]= round(povlb98povlb99`x'[1,2], 0.1)
mat pov70`x'[5,1]= round(povlb98povlb99`x'[2,1], 0.1)
mat pov70`x'[7,1]= round(povlb98povlb99`x'[2,2], 0.1)
mat pov70`x'[9,1]= npovlb98povlb99`x'

mat pov70`x'[1,2]= round(p98p99e1`x'[1,1], 0.1)
mat pov70`x'[3,2]= round(p98p99e1`x'[1,2], 0.1)
mat pov70`x'[5,2]= round(p98p99e1`x'[2,1], 0.1)
mat pov70`x'[7,2]= round(p98p99e1`x'[2,2], 0.1)
mat pov70`x'[9,2]= npovlb98povlb99`x'

mat pov70`x'[1,3]= round(p98p99e2`x'[1,1], 0.1)
mat pov70`x'[3,3]= round(p98p99e2`x'[1,2], 0.1)
mat pov70`x'[5,3]= round(p98p99e2`x'[2,1], 0.1)
mat pov70`x'[7,3]= round(p98p99e2`x'[2,2], 0.1)
mat pov70`x'[9,3]= npovlb98povlb99`x'

mat pov70`x'[1,4]= round(p98p99e3`x'[1,1], 0.1)
mat pov70`x'[3,4]= round(p98p99e3`x'[1,2], 0.1)
mat pov70`x'[5,4]= round(p98p99e3`x'[2,1], 0.1)
mat pov70`x'[7,4]= round(p98p99e3`x'[2,2], 0.1)
mat pov70`x'[9,4]= npovlb98povlb99`x'

mat pov70`x'[1,5]= round(tpov9899`x'[1,1], 0.1)
mat pov70`x'[2,5]= round(tpov9899`x'[2,1], 0.1)
mat pov70`x'[3,5]= round(tpov9899`x'[1,2], 0.1)
mat pov70`x'[4,5]= round(tpov9899`x'[2,2], 0.1)
mat pov70`x'[5,5]= round(tpov9899`x'[1,3], 0.1)
mat pov70`x'[6,5]= round(tpov9899`x'[2,3], 0.1)
mat pov70`x'[7,5]= round(tpov9899`x'[1,4], 0.1)
mat pov70`x'[8,5]= round(tpov9899`x'[2,4], 0.1)
mat pov70`x'[9,5]= ntpov9899`x'

mat pov70`x'[1,6]= round(p98p99e4`x'[1,1], 0.1)
mat pov70`x'[3,6]= round(p98p99e4`x'[1,2], 0.1)
mat pov70`x'[5,6]= round(p98p99e4`x'[2,1], 0.1)
mat pov70`x'[7,6]= round(p98p99e4`x'[2,2], 0.1)
mat pov70`x'[9,6]= npovub98povub99`x'

mat pov70`x'[1,7]= round(p98p99e5`x'[1,1], 0.1)
mat pov70`x'[3,7]= round(p98p99e5`x'[1,2], 0.1)
mat pov70`x'[5,7]= round(p98p99e5`x'[2,1], 0.1)
mat pov70`x'[7,7]= round(p98p99e5`x'[2,2], 0.1)
mat pov70`x'[9,7]= npovub98povub99`x'

mat pov70`x'[1,8]= round(p98p99e6`x'[1,1], 0.1)
mat pov70`x'[3,8]= round(p98p99e6`x'[1,2], 0.1)
mat pov70`x'[5,8]= round(p98p99e6`x'[2,1], 0.1)
mat pov70`x'[7,8]= round(p98p99e6`x'[2,2], 0.1)
mat pov70`x'[9,8]= npovub98povub99`x'

mat pov70`x'[1,9]= round(povub98povub99`x'[1,1], 0.1)
mat pov70`x'[3,9]= round(povub98povub99`x'[1,2], 0.1)
mat pov70`x'[5,9]= round(povub98povub99`x'[2,1], 0.1)
mat pov70`x'[7,9]= round(povub98povub99`x'[2,2], 0.1)
mat pov70`x'[9,9]= npovub98povub99`x'

mat rown pov70`x'= poor98_poor99 se poor98_Nonpoor99 se Nonpoor98_poor99 se Nonpoor98_Nonpoor99 se N
mat coln pov70`x'= nonpar_LB "rho_1" "rho_p8" "rho_p7" "truth" "rho_p3" "rho_p2" "rho_0" nonpar_UB 

mat li pov70`x'
}

log close
// stop


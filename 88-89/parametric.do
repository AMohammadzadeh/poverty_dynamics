
*change directory
cd "D:\Ahmad\Thesis\DrKeshavarz\Poverty Dynamics DLLM\data"
use Y88_89_final, clear
destring strata*, replace
destring HHID, replace


log using "parametric", replace text
global hdage "HAge>= 25 & HAge<= 55" 

global depvar "lcpc_"
global depvar_88 "lcpc_88"
global depvar_89 "lcpc_89"
global indvar "HAge i.HSex HEduYears HLiterate NKids i.Region i.ProvinceCode Size HEmployed HMarritalState" 

// use Y88_89_final, clear
xi: reg $depvar_88 $indvar if $hdage & samp== 1, cluster(strata_88)
predict double eh1 if e(sample), res

xi: reg $depvar_89 $indvar if $hdage & samp== 2, cluster(strata_89)
predict double eh2 if e(sample), res

keep if eh1<.| eh2<.
keep HHID* strata* eh* Year samp

// sort strata_88 hid97 strata_89 HHID 
sort strata_88 HHID strata_89 
compress
save eh_orig, replace

*2- PREDICT UPPER BOUNDS OF POVERTY USING 2000 DATA
*2.1- predict xb
use Y88_89_final, clear
qui xi: reg $depvar_88 $indvar if $hdage & samp== 1, cluster(strata_88)
scalar r1= e(r2)
scalar sige1= e(rmse) 

predict double bh1x2 if $hdage & samp== 2, xb
predict double bh1x1 if e(sample), xb

qui xi: reg $depvar_89 $indvar if $hdage & samp== 2, cluster(strata_89)
scalar r2= e(r2)
scalar sige2= e(rmse) 
predict double bh2x1 if $hdage & samp== 1, xb
predict double bh2x2 if e(sample), xb

scalar rmin= min(r1, r2)
scalar rmax= max(r1, r2)

keep if bh1x2<.| bh2x1<.

keep bh* HHID* lcpc* HAge HSex HEduYears Year Weight *poverty* samp strata*

su HAge if samp== 1
scalar obid88= r(N)

su HAge if samp== 2
scalar obid89= r(N)

scalar obidy= max(obid88, obid89) // THIS IS FOR RANDOM SAMPLING
scalar list obidy

sort strata_88 strata_89 HHID
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

if obid88> obid89 {
   expand 2
}

bsample obid88
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

*2.2.2- GET BOOTSTRAPPED ERRORS FROM 1897 DATA
use eh_orig, clear
qui keep if samp== 1
qui keep if eh1<.
qui keep eh1 samp

if obid89> obid88 {
   expand 2
}

bsample obid89
ren eh1 eth1 // bootstrapped errors
qui gen obid= _n
qui replace samp= 2 // change the samp to match with bh1x2

sort samp obid 
qui merge 1:1 samp obid using "`stsec70'"
qui drop _m

sort obid

*2.3-GET PREDICTED VALUES IN PANEL DATA STRUCTURE
qui gen double yu_89= bh2x1+ eth2 
qui gen double yu_88= bh1x2+ eth1

*REPLACE MISSING VALUES WITH OBSERVED VALUES OR STACKING DATA
qui replace yu_88= lcpc_88 if yu_88==. & samp== 1
qui replace yu_89= lcpc_89 if yu_89==. & samp== 2

*2.4- KEEP A SINGLE YEAR HERE IF DO NOT WANT STACKED ESTIMATES
qui keep if samp== 2 

*2.5- POVERTY LINE IS 2559.85 IN 1897, & 3358.18 IN 2000
qui gen povub88= (yu_88> lpoverty_line88 ) if yu_88<.
qui gen povub89= (yu_89> lpoverty_line89 ) if yu_89<.

qui tab povub88 povub89 [aw= Weight], matcell(povub`i'_all)
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
mat rown povub`j'`x'= poor88 nonpoor88
mat coln povub`j'`x'= poor89 nonpoor89
}

mat povub88povub89_all= povub`j'_all

*2.7- GET NO OF OBSERVATIONS
qui ta  povub88 povub89 [aw= Weight], cell nofr matcell(povub`i')
scalar npovub88povub89_all= r(N)

*3- GET LOWER BOUND ESTIMATES OF POVERTY
use Y88_89_final, clear
qui xi: reg $depvar_88 $indvar if $hdage & samp== 1, cluster(strata_88)
est store reg88
scalar r1= e(r2)

predict double bh1x2 if $hdage & samp== 2, xb
predict double bh1x1 if e(sample), xb
predict double eh1 if e(sample), res

qui xi: reg $depvar_89 $indvar if $hdage & samp== 2, cluster(strata_89)
est store reg89
scalar r2= e(r2)

predict double bh2x1 if $hdage & samp== 1, xb
predict double bh2x2 if e(sample), xb
predict double eh2 if e(sample), res

scalar rmin= min(r1, r2)
scalar ormin= 1- rmin

scalar rmax= max(r1, r2)
scalar ormax= 1- rmax

keep if bh1x2<.| bh2x1<.
keep bh* strata* lcpc* eh* $depvar_88 $depvar_89 HAge HSex HEduYears Year Weight *poverty* samp 
 
*3.1- DEFINE LOWER BOUNDS & STACK DATA
gen double yl2= bh2x1+ (sige2/sige1)* eh1
gen double yl1= bh1x2+ (sige1/sige2)* eh2
la var yl1 "lower bound of y, first period"
la var yl2 "lower bound of y, second period"

ren yl1 yl_88
ren yl2 yl_89

replace yl_88= lcpc_88 if yl_88==. & samp== 1
replace yl_89= lcpc_89 if yl_89==. & samp== 2

qui gen povlb88= (yl_88> lpoverty_line88 ) if yl_88<.
qui gen povlb89= (yl_89> lpoverty_line89 ) if yl_89<.

*3.2- KEEP A SINGLE YEAR HERE IF DO NOT WANT STACKED ESTIMATES
qui keep if samp== 2 

*3.3- CALCULATE POVERTY RATES
la def pstat2 1 "nonpoor" 0 "poor"
qui for var povlb88 povlb89: la val X pstat2

ta povlb88 povlb89 [aw= Weight], cell nofr matcell(povlb88povlb89_all)
mat povlb88povlb89_all= 100* povlb88povlb89_all/ r(N) // do this to get the percentage
mat rown povlb88povlb89_all= poor88 nonpoor88
mat coln povlb88povlb89_all= poor89 nonpoor89
scalar npovlb88povlb89_all= r(N)

*4- DIRECT ESTIMATES OF POVERTY DYNAMICS 
*4.0- DEFINE PROGRAM 
local char "_all"
foreach x of local char {
  gen double p88p89e`x'= .
  gen double p88np89e`x'= .
  gen double np88p89e`x'= .
  gen double np88np89e`x'= .
}

cap program drop mypovdy
program mypovdy 
*4.0a- ALL POPULATION
mat p88p89e_all= J(2, 2, .)
mat rown p88p89e_all= poor88 nonpoor88
mat coln p88p89e_all= poor89 nonpoor89

replace p88p89e_all= $pp89 if samp== 2
qui su p88p89e_all [aw= Weight]
mat p88p89e_all[1,1]= r(mean)*100

replace p88np89e_all= $pnp89 if samp== 2
qui su p88np89e_all [aw= Weight] 
mat p88p89e_all[1,2]= r(mean)*100

replace np88p89e_all= $npp89 if samp== 2
qui su np88p89e_all [aw= Weight] 
mat p88p89e_all[2,1]= r(mean)*100

replace np88np89e_all= $npnp89 if samp== 2
qui su np88np89e_all [aw= Weight] 
mat p88p89e_all[2,2]= r(mean)*100
end


*4.1- DEFINE THE MACROS BY SURVEY YEAR FOR OLS REGRESSIONS
***define the globals for predicting on 2000 data
global pp89 "binormal((lpoverty_line88- bh1x2)/sige1, (lpoverty_line89- bh2x2)/sige2, rho)"
global pnp89 "binormal((lpoverty_line88- bh1x2)/sige1, -(lpoverty_line89- bh2x2)/sige2, -rho)"
global npp89 "binormal(-(lpoverty_line88- bh1x2)/sige1, (lpoverty_line89- bh2x2)/sige2, -rho)"
global npnp89 "binormal(-(lpoverty_line88- bh1x2)/sige1, -(lpoverty_line89- bh2x2)/sige2, rho)"

*4.1.1- LOWER BOUND
*rho= 1 
scalar rho= 1
mypovdy
local char "_all"
foreach x of local char {
        mat p88p89e1`x'= p88p89e`x'
}

*rho= 0.8 
scalar rho= 0.8
mypovdy
local char "_all"
foreach x of local char {
        mat p88p89e2`x'= p88p89e`x'
}

*rho= 0.7
scalar rho= 0.7
mypovdy
local char "_all"
foreach x of local char {
        mat p88p89e3`x'= p88p89e`x'
}

*4.1.2- UPPER BOUND
*rho= 0.3
scalar rho= 0.3
mypovdy
local char "_all"
foreach x of local char {
        mat p88p89e4`x'= p88p89e`x'
}

*rho= 0.2
scalar rho= 0.2
mypovdy
local char "_all"
foreach x of local char {
        mat p88p89e5`x'= p88p89e`x'
}

***rho= 0 
scalar rho= 0
mypovdy
local char "_all"
foreach x of local char {
        mat p88p89e6`x'= p88p89e`x'
}

*5- COMPARE WITH REAL DATA, USE FULL PANEL
*get estimates for Table 2 & Appendix Table 2.2
use Y88_89_final_long, clear
destring HHID, replace
xtreg $depvar $indvar, i(HHID) cluster(strata_89)
est store iran_8889
estout iran_8889 ///
   using idn_tab2.2_rho, starlevels(* 0.10 ** 0.05 *** 0.01) ///   
   style(tab) cells("b(star fmt(3))" "se(par)") stats(sigma_u sigma_e rho r2_o N_g N, fmt(2 2 2 2 0 0) ) replace

use Y88_89_final, clear
keep if HAge>= 25 & HAge<= 55 // keep data if heads are 25-55 yrs old in 1897

*KEEP SAME OBS AS WITH ESTIMATES
qui reg $depvar_88 $indvar if $hdage
keep if e(sample)

qui gen pov88= (lcpc_88> lpoverty_line88 ) if lcpc_88<.
qui gen pov89= (lcpc_89> lpoverty_line89 ) if lcpc_89<. 

la def pstat2 1 "nonpoor" 0 "poor"
qui for var pov88 pov89: la val X pstat2
ta pov88 pov89, cell nofr 

qui gen  p88p89= (lcpc_88<= lpoverty_line88 & lcpc_89<= lpoverty_line89 ) if lcpc_88<. & lcpc_89<. 
qui gen  p88np89= (lcpc_88<= lpoverty_line88 & lcpc_89> lpoverty_line89 ) if lcpc_88<. & lcpc_89<. 
qui gen  np88p89= (lcpc_88> lpoverty_line88 & lcpc_89<= lpoverty_line89 ) if lcpc_88<. & lcpc_89<. 
qui gen  np88np89= (lcpc_88> lpoverty_line88 & lcpc_89> lpoverty_line89 ) if lcpc_88<. & lcpc_89<. 

tabstat p88p89 p88np89 np88p89 np88np89 [aw= Weight], by(pov88) stat(mean sem) save 
mat li r(StatTotal)
mat tpov8889_all= r(StatTotal)*100
qui ta p88p89 p88np89 [aw= Weight]
scalar ntpov8889_all= r(N)

*6- PUT THIS IN THE FINAL MATRIX
local char "_all"
foreach x of local char {
mat pov70`x'= J(9, 9, .)
mat pov70`x'[1,1]= round(povlb88povlb89`x'[1,1], 0.1)
mat pov70`x'[3,1]= round(povlb88povlb89`x'[1,2], 0.1)
mat pov70`x'[5,1]= round(povlb88povlb89`x'[2,1], 0.1)
mat pov70`x'[7,1]= round(povlb88povlb89`x'[2,2], 0.1)
mat pov70`x'[9,1]= npovlb88povlb89`x'

mat pov70`x'[1,2]= round(p88p89e1`x'[1,1], 0.1)
mat pov70`x'[3,2]= round(p88p89e1`x'[1,2], 0.1)
mat pov70`x'[5,2]= round(p88p89e1`x'[2,1], 0.1)
mat pov70`x'[7,2]= round(p88p89e1`x'[2,2], 0.1)
mat pov70`x'[9,2]= npovlb88povlb89`x'

mat pov70`x'[1,3]= round(p88p89e2`x'[1,1], 0.1)
mat pov70`x'[3,3]= round(p88p89e2`x'[1,2], 0.1)
mat pov70`x'[5,3]= round(p88p89e2`x'[2,1], 0.1)
mat pov70`x'[7,3]= round(p88p89e2`x'[2,2], 0.1)
mat pov70`x'[9,3]= npovlb88povlb89`x'

mat pov70`x'[1,4]= round(p88p89e3`x'[1,1], 0.1)
mat pov70`x'[3,4]= round(p88p89e3`x'[1,2], 0.1)
mat pov70`x'[5,4]= round(p88p89e3`x'[2,1], 0.1)
mat pov70`x'[7,4]= round(p88p89e3`x'[2,2], 0.1)
mat pov70`x'[9,4]= npovlb88povlb89`x'

mat pov70`x'[1,5]= round(tpov8889`x'[1,1], 0.1)
mat pov70`x'[2,5]= round(tpov8889`x'[2,1], 0.1)
mat pov70`x'[3,5]= round(tpov8889`x'[1,2], 0.1)
mat pov70`x'[4,5]= round(tpov8889`x'[2,2], 0.1)
mat pov70`x'[5,5]= round(tpov8889`x'[1,3], 0.1)
mat pov70`x'[6,5]= round(tpov8889`x'[2,3], 0.1)
mat pov70`x'[7,5]= round(tpov8889`x'[1,4], 0.1)
mat pov70`x'[8,5]= round(tpov8889`x'[2,4], 0.1)
mat pov70`x'[9,5]= ntpov8889`x'

mat pov70`x'[1,6]= round(p88p89e4`x'[1,1], 0.1)
mat pov70`x'[3,6]= round(p88p89e4`x'[1,2], 0.1)
mat pov70`x'[5,6]= round(p88p89e4`x'[2,1], 0.1)
mat pov70`x'[7,6]= round(p88p89e4`x'[2,2], 0.1)
mat pov70`x'[9,6]= npovub88povub89`x'

mat pov70`x'[1,7]= round(p88p89e5`x'[1,1], 0.1)
mat pov70`x'[3,7]= round(p88p89e5`x'[1,2], 0.1)
mat pov70`x'[5,7]= round(p88p89e5`x'[2,1], 0.1)
mat pov70`x'[7,7]= round(p88p89e5`x'[2,2], 0.1)
mat pov70`x'[9,7]= npovub88povub89`x'

mat pov70`x'[1,8]= round(p88p89e6`x'[1,1], 0.1)
mat pov70`x'[3,8]= round(p88p89e6`x'[1,2], 0.1)
mat pov70`x'[5,8]= round(p88p89e6`x'[2,1], 0.1)
mat pov70`x'[7,8]= round(p88p89e6`x'[2,2], 0.1)
mat pov70`x'[9,8]= npovub88povub89`x'

mat pov70`x'[1,9]= round(povub88povub89`x'[1,1], 0.1)
mat pov70`x'[3,9]= round(povub88povub89`x'[1,2], 0.1)
mat pov70`x'[5,9]= round(povub88povub89`x'[2,1], 0.1)
mat pov70`x'[7,9]= round(povub88povub89`x'[2,2], 0.1)
mat pov70`x'[9,9]= npovub88povub89`x'

mat rown pov70`x'= poor88_poor89 se poor88_Nonpoor89 se Nonpoor88_poor89 se Nonpoor88_Nonpoor89 se N
mat coln pov70`x'= nonpar_LB "rho_1" "rho_p8" "rho_p7" "truth" "rho_p3" "rho_p2" "rho_0" nonpar_UB 

mat li pov70`x'
}

log close
// stop


*change directory
cd "E:\my_papers\poverty_dynamics\poverty_line_data"
use Y98_99_final, clear
destring strata*, replace
destring HHID, replace

log using "parametric_simulated", replace text

* --- CHANGE 1: AGE COHORT FIX ---
* Assuming a 1-year gap (98-99). If 98 is base (25-55), 99 should be (26-56).
global hdage98 "HAge>= 25 & HAge<= 55" 
global hdage99 "HAge>= 26 & HAge<= 56" 

global depvar "lcpc_"
global depvar_98 "lcpc_98"
global depvar_99 "lcpc_99"
global indvar "HAge i.HSex HEduYears HLiterate NKids i.Region i.ProvinceCode Size HEmployed HMarritalState" 

* 1- PREDICT EPSILON USING 98 & 99 DATA
* Note: Use hdage98 for samp=1 and hdage99 for samp=2
xi: reg $depvar_98 $indvar if $hdage98 & samp== 1, cluster(strata_98)
predict double eh1 if e(sample), res

xi: reg $depvar_99 $indvar if $hdage99 & samp== 2, cluster(strata_99)
predict double eh2 if e(sample), res

keep if eh1<.| eh2<.
keep HHID* strata* eh* Year samp
sort strata_98 HHID strata_99 
compress
save eh_orig, replace

* 2- PREDICT UPPER BOUNDS OF POVERTY
* 2.1- predict xb
use Y98_99_final, clear

* Regression on 98 data
qui xi: reg $depvar_98 $indvar if $hdage98 & samp== 1, cluster(strata_98)
scalar r1= e(r2)
scalar sige1= e(rmse) 

* Predict on 99 data using 98 coeffs (Use 99 age filter)
predict double bh1x2 if $hdage99 & samp== 2, xb
predict double bh1x1 if e(sample), xb

* Regression on 99 data
qui xi: reg $depvar_99 $indvar if $hdage99 & samp== 2, cluster(strata_99)
scalar r2= e(r2)
scalar sige2= e(rmse) 

* Predict on 98 data using 99 coeffs (Use 98 age filter)
predict double bh2x1 if $hdage98 & samp== 1, xb
predict double bh2x2 if e(sample), xb

scalar rmin= min(r1, r2)
scalar rmax= max(r1, r2)

keep if bh1x2<.| bh2x1<.

* Ensure we keep poverty lines and weights here
keep bh* HHID* lcpc* HAge HSex HEduYears Year Weight *poverty* samp strata*

su HAge if samp== 1
scalar obid98= r(N)

su HAge if samp== 2
scalar obid99= r(N)

scalar obidy= max(obid98, obid99) 
scalar list obidy

sort strata_98 strata_99 HHID
bys samp: gen obid= _n 

sort obid
compress
save bh1x2_bh2x1, replace

* 2.2- bootstrap the sample of error terms
forval i= 1/ 500 {
    use eh_orig, clear
    set seed `i'

    * 2.2.1- GET BOOTSTRAPPED ERRORS FROM 99 DATA
    qui keep if samp== 2 & eh2<.
    qui keep eh2 samp

    if obid98> obid99 {
       expand 2
    }

    bsample obid98
    ren eh2 eth2 
    qui gen obid= _n
    qui replace samp= 1 

    sort samp obid 
    qui merge 1:1 samp obid using bh1x2_bh2x1
    qui drop _m

    sort obid
    qui compress
    tempfile stsec70 
    save "`stsec70'"

    * 2.2.2- GET BOOTSTRAPPED ERRORS FROM 98 DATA
    use eh_orig, clear
    qui keep if samp== 1
    qui keep if eh1<.
    qui keep eh1 samp

    if obid99> obid98 {
       expand 2
    }

    bsample obid99
    ren eh1 eth1 
    qui gen obid= _n
    qui replace samp= 2 

    sort samp obid 
    qui merge 1:1 samp obid using "`stsec70'"
    qui drop _m
    sort obid

    * 2.3-GET PREDICTED VALUES
    qui gen double yu_99= bh2x1+ eth2 
    qui gen double yu_98= bh1x2+ eth1

    * REPLACE MISSING 
    qui replace yu_98= lcpc_98 if yu_98==. & samp== 1
    qui replace yu_99= lcpc_99 if yu_99==. & samp== 2

    * 2.4- KEEP SINGLE YEAR
    qui keep if samp== 2 

    * 2.5- POVERTY LINES
    qui gen povub98= (yu_98> lpoverty_line98 ) if yu_98<.
    qui gen povub99= (yu_99> lpoverty_line99 ) if yu_99<.

    qui tab povub98 povub99 [aw= Weight], matcell(povub`i'_all)
    mat povub`i'_all= 100* povub`i'_all/ r(N) 
}

* 2.6- GET THE AVERAGE
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

* 2.7- GET NO OF OBSERVATIONS
qui ta  povub98 povub99 [aw= Weight], cell nofr matcell(povub`i')
scalar npovub98povub99_all= r(N)


* 3- GET LOWER BOUND ESTIMATES OF POVERTY
use Y98_99_final, clear
qui xi: reg $depvar_98 $indvar if $hdage98 & samp== 1, cluster(strata_98)
est store reg98
scalar r1= e(r2)

predict double bh1x2 if $hdage99 & samp== 2, xb
predict double bh1x1 if e(sample), xb
predict double eh1 if e(sample), res

qui xi: reg $depvar_99 $indvar if $hdage99 & samp== 2, cluster(strata_99)
est store reg99
scalar r2= e(r2)

predict double bh2x1 if $hdage98 & samp== 1, xb
predict double bh2x2 if e(sample), xb
predict double eh2 if e(sample), res

scalar rmin= min(r1, r2)
scalar ormin= 1- rmin
scalar rmax= max(r1, r2)
scalar ormax= 1- rmax

keep if bh1x2<.| bh2x1<.
keep bh* strata* lcpc* eh* $depvar_98 $depvar_99 HAge HSex HEduYears Year Weight *poverty* samp 
 
* 3.1- DEFINE LOWER BOUNDS & STACK DATA
gen double yl2= bh2x1+ (sige2/sige1)* eh1
gen double yl1= bh1x2+ (sige1/sige2)* eh2

ren yl1 yl_98
ren yl2 yl_99

replace yl_98= lcpc_98 if yl_98==. & samp== 1
replace yl_99= lcpc_99 if yl_99==. & samp== 2

qui gen povlb98= (yl_98> lpoverty_line98 ) if yl_98<.
qui gen povlb99= (yl_99> lpoverty_line99 ) if yl_99<.

* 3.2- KEEP A SINGLE YEAR
qui keep if samp== 2 

* 3.3- CALCULATE POVERTY RATES
la def pstat2 1 "nonpoor" 0 "poor"
qui for var povlb98 povlb99: la val X pstat2

ta povlb98 povlb99 [aw= Weight], cell nofr matcell(povlb98povlb99_all)
mat povlb98povlb99_all= 100* povlb98povlb99_all/ r(N) 
mat rown povlb98povlb99_all= poor98 nonpoor98
mat coln povlb98povlb99_all= poor99 nonpoor99
scalar npovlb98povlb99_all= r(N)


* 4- DIRECT ESTIMATES OF POVERTY DYNAMICS 
* 4.0- DEFINE PROGRAM 
local char "_all"
foreach x of local char {
  gen double p98p99e`x'= .
  gen double p98np99e`x'= .
  gen double np98p99e`x'= .
  gen double np98np99e`x'= .
}

cap program drop mypovdy
program mypovdy 
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

* 4.1- DEFINE THE MACROS
global pp99 "binormal((lpoverty_line98- bh1x2)/sige1, (lpoverty_line99- bh2x2)/sige2, rho)"
global pnp99 "binormal((lpoverty_line98- bh1x2)/sige1, -(lpoverty_line99- bh2x2)/sige2, -rho)"
global npp99 "binormal(-(lpoverty_line98- bh1x2)/sige1, (lpoverty_line99- bh2x2)/sige2, -rho)"
global npnp99 "binormal(-(lpoverty_line98- bh1x2)/sige1, -(lpoverty_line99- bh2x2)/sige2, rho)"

* LOWER BOUNDS
scalar rho= 1
mypovdy
local char "_all"
foreach x of local char {
        mat p98p99e1`x'= p98p99e`x'
}

scalar rho= 0.8
mypovdy
local char "_all"
foreach x of local char {
        mat p98p99e2`x'= p98p99e`x'
}

scalar rho= 0.7
mypovdy
local char "_all"
foreach x of local char {
        mat p98p99e3`x'= p98p99e`x'
}

* UPPER BOUNDS
scalar rho= 0.3
mypovdy
local char "_all"
foreach x of local char {
        mat p98p99e4`x'= p98p99e`x'
}

scalar rho= 0.2
mypovdy
local char "_all"
foreach x of local char {
        mat p98p99e5`x'= p98p99e`x'
}

scalar rho= 0
mypovdy
local char "_all"
foreach x of local char {
        mat p98p99e6`x'= p98p99e`x'
}


* 5- GET REAL RHO AND ACTUAL OBSERVED STATISTICS
* ------------------------------------------------

* 5.1 - Get Rho from the Panel (Long Format)
use Y98_99_final_long, clear
destring HHID, replace
xtreg $depvar $indvar, i(HHID) cluster(strata_99)
scalar real_rho = e(rho) 
est store iran_9899

* 5.2 - Calculate Actual Transitions (Requires WIDE format)
* We must reconstruct the Wide format to check: "Poor in 98 AND Poor in 99"
use Y98_99_final, clear
keep HHID samp lcpc* Weight strata* HAge* lpoverty*
* Note: We use the logic that they must satisfy the age criteria in their respective years
keep if ($hdage98 & samp==1) | ($hdage99 & samp==2)

* Reshape to Wide so we have 98 and 99 on one row
* Assuming 'samp' is the time variable (1=98, 2=99)
keep HHID samp lcpc_98 lcpc_99 lpoverty_line98 lpoverty_line99 Weight
* If lcpc variables are already specific (lcpc_98 only has data in samp 1), we can collapse
collapse (max) lcpc_98 lcpc_99 lpoverty_line98 lpoverty_line99 Weight, by(HHID)
 
* Now calculate the ACTUAL observed poverty status
qui gen pov98_real= (lcpc_98 > lpoverty_line98) if lcpc_98<.
qui gen pov99_real= (lcpc_99 > lpoverty_line99) if lcpc_99<. 

la def pstat_real 1 "nonpoor" 0 "poor"
qui for var pov98_real pov99_real: la val X pstat_real

* Calculate Actual Transitions (The "Real Truth")
qui gen  p98p99_real  = (lcpc_98<= lpoverty_line98 & lcpc_99<= lpoverty_line99) if lcpc_98<. & lcpc_99<. 
qui gen  p98np99_real = (lcpc_98<= lpoverty_line98 & lcpc_99>  lpoverty_line99) if lcpc_98<. & lcpc_99<. 
qui gen  np98p99_real = (lcpc_98>  lpoverty_line98 & lcpc_99<= lpoverty_line99) if lcpc_98<. & lcpc_99<. 
qui gen  np98np99_real= (lcpc_98>  lpoverty_line98 & lcpc_99>  lpoverty_line99) if lcpc_98<. & lcpc_99<. 

* 5.3 - Save the Sample Size (N) and Real Stats
* We need the N of valid transitions for the final table
qui ta pov98_real pov99_real
scalar ntpov9899_all= r(N)

* Optional: If you ever want to peek at the "Real" stats vs "Simulated"
tabstat p98p99_real p98np99_real np98p99_real np98np99_real [aw= Weight], by(pov98_real) stat(mean sem)

* --- CHANGE 2: RESTORED SECTION 6 (TRUTH SIMULATION) ---
* 6- GET THE SIMULATED ERRORS 
* 6.1- DEFINE THE SIMULATION PROGRAM 
cap program drop mysim_trate
program mysim_trate, rclass

clear
* Define Covariance Matrix using the Real Rho saved earlier
mat C= (sige1^2, real_rho*sige1*sige2\ real_rho*sige1*sige2, sige2^2)

* Draw errors (using N=sample size of bh1x2_bh2x1)
drawnorm seh1 seh2, n($N_sim) cov(C)
gen obid= _n

* Merge with prediction data to get XB and Poverty Lines
sort obid
merge 1:1 obid using bh1x2_bh2x1_sim
* Note: We expect perfect match or master only if N is set correctly
drop if _m==2
drop _m

* Create Simulated Income
gen double lny12h= bh1x2+ seh1
gen double lny22h= bh2x2+ seh2

* Calculate Poverty Status using Variable Poverty Lines
qui gen pov98= (lny12h> lpoverty_line98 ) if lny12h<.
qui gen pov99= (lny22h> lpoverty_line99 ) if lny22h<. 

la def pstat2 1 "nonpoor" 0 "poor"
qui for var pov98 pov99: la val X pstat2

qui gen  p98p99= (lny12h<= lpoverty_line98 & lny22h<= lpoverty_line99 ) if lny12h<. & lny22h<. 
qui gen  p98np99= (lny12h<= lpoverty_line98 & lny22h> lpoverty_line99 ) if lny12h<. & lny22h<. 
qui gen  np98p99= (lny12h> lpoverty_line98 & lny22h<= lpoverty_line99 ) if lny12h<. & lny22h<. 
qui gen  np98np99= (lny12h> lpoverty_line98 & lny22h> lpoverty_line99 ) if lny12h<. & lny22h<. 

qui tabstat p98p99 p98np99 np98p99 np98np99 [aw= Weight], by(pov98) stat(mean sem) save
mat stpov9899_all= r(StatTotal)*100

return scalar pp= stpov9899_all[1,1]
return scalar pnp= stpov9899_all[1,2]
return scalar npp= stpov9899_all[1,3]
return scalar npnp= stpov9899_all[1,4]
end 

* PREPARE DATA FOR SIMULATION
use bh1x2_bh2x1, clear
keep if samp== 2
count
global N_sim = r(N) // Store sample size for drawnorm
sort obid
save bh1x2_bh2x1_sim, replace

* CALL THE SIMULATION
simulate spp= r(pp) spnp= r(pnp) snpp= r(npp) snpnp= r(npnp), seed(10101) reps(500) nodots ///
         saving(Y98_99_boot_se, replace): mysim_trate

* PUT BOOTSTRAP ESTIMATES IN A MATRIX
use Y98_99_boot_se, clear
mat stpov9899_all = J(2,4,.)

su spp
mat stpov9899_all[1,1]= r(mean)
mat stpov9899_all[2,1]= r(sd)

su spnp
mat stpov9899_all[1,2]= r(mean)
mat stpov9899_all[2,2]= r(sd)

su snpp
mat stpov9899_all[1,3]= r(mean)
mat stpov9899_all[2,3]= r(sd)

su snpnp
mat stpov9899_all[1,4]= r(mean)
mat stpov9899_all[2,4]= r(sd)       


* 7- PUT THIS IN THE FINAL MATRIX
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

* --- UPDATED COLUMN 5: USING SIMULATED TRUTH ---
mat pov70`x'[1,5]= round(stpov9899`x'[1,1], 0.1)
mat pov70`x'[2,5]= round(stpov9899`x'[2,1], 0.1)
mat pov70`x'[3,5]= round(stpov9899`x'[1,2], 0.1)
mat pov70`x'[4,5]= round(stpov9899`x'[2,2], 0.1)
mat pov70`x'[5,5]= round(stpov9899`x'[1,3], 0.1)
mat pov70`x'[6,5]= round(stpov9899`x'[2,3], 0.1)
mat pov70`x'[7,5]= round(stpov9899`x'[1,4], 0.1)
mat pov70`x'[8,5]= round(stpov9899`x'[2,4], 0.1)
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
mat coln pov70`x'= nonpar_LB "rho_1" "rho_p8" "rho_p7" "truth_sim" "rho_p3" "rho_p2" "rho_0" nonpar_UB 

mat li pov70`x'
}

log close
clear all
set more off
capture log close

/* ========================================================================== */
/* PART 1: USER CONFIGURATION                           */
/* (CHANGE ONLY THIS SECTION FOR NEW DATASETS/YEARS)                */
/* ========================================================================== */

* 1. DIRECTORIES AND FILES
global working_dir  "E:\my_papers\poverty_dynamics\poverty_line_data"
global file_cross   "Y98_99_rural"      // Cross-section file (Wide or Long format setup)
global file_panel   "Y98_99_rural_long" // Panel file (Long format) for Section 5
global output_log   "parametric_results" // Name of the log file

* 2. DEFINE YEARS
global yr1 "98"  // Suffix for the first year (e.g., 98, 05, 2010)
global yr2 "99"  // Suffix for the second year (e.g., 99, 10, 2015)

* 3. VARIABLE NAMES (STUBS)
* The code assumes variables are named like lcpc_98, strata_98, etc.
global hh_id        "HHID"           // Household ID variable
global dep_stub     "lcpc_"          // Dependent variable prefix (e.g. lcpc_)
global povline_stub "lpoverty_line"  // Poverty line variable prefix
global strat_stub   "strata_"        // Strata variable prefix

* 4. INDEPENDENT VARIABLES
* List controls here (ensure they exist in the dataset)
global indvar "HAge HEduYears HLiterate NKids i.Region i.ProvinceCode Size HEmployed HMarritalState"

* 5. SAMPLE SELECTION CRITERIA (Age filters, etc.)
* Define the logic for the specific years
global age_cond_1 "HAge>= 25 & HAge<= 55"
global age_cond_2 "HAge>= 26 & HAge<= 56"

/* ========================================================================== */
/* PART 2: AUTOMATED SETUP                              */
/* (DO NOT CHANGE BELOW UNLESS MODIFYING LOGIC)                */
/* ========================================================================== */

cd "$working_dir"
log using "$output_log", replace text

* Construct full variable names based on years
global depvar_y1 "${dep_stub}${yr1}"
global depvar_y2 "${dep_stub}${yr2}"
global strata_y1 "${strat_stub}${yr1}"
global strata_y2 "${strat_stub}${yr2}"
global pline_y1  "${povline_stub}${yr1}"
global pline_y2  "${povline_stub}${yr2}"

/* ========================================================================== */
/* PART 3: MAIN EXECUTION                               */
/* ========================================================================== */

* 1. PREPARE DATA & FIRST STAGE REGRESSION
use "$file_cross", clear
destring strata*, replace
destring $hh_id, replace

* Run Regressions
* Year 1 Model
xi: reg $depvar_y1 $indvar if $age_cond_1 & samp== 1, cluster($strata_y1)
predict double eh1 if e(sample), res

* Year 2 Model
xi: reg $depvar_y2 $indvar if $age_cond_2 & samp== 2, cluster($strata_y2)
predict double eh2 if e(sample), res

* Keep valid residuals
keep if eh1<. | eh2<.
keep ${hh_id}* strata* eh* Year samp

sort $strata_y1 $hh_id $strata_y2
compress
save eh_orig, replace

* 2. PREDICT UPPER BOUNDS
* 2.1 Predict XB (Cross-Prediction)
use "$file_cross", clear

* Regress Year 1
qui xi: reg $depvar_y1 $indvar if $age_cond_1 & samp== 1, cluster($strata_y1)
scalar r1 = e(r2)
scalar sige1 = e(rmse)

* Predict Year 1 model on Year 2 data (Cross) and Year 1 data (Own)
predict double bh1x2 if $age_cond_2 & samp== 2, xb
predict double bh1x1 if e(sample), xb

* Regress Year 2
qui xi: reg $depvar_y2 $indvar if $age_cond_2 & samp== 2, cluster($strata_y2)
scalar r2 = e(r2)
scalar sige2 = e(rmse)

* Predict Year 2 model on Year 1 data (Cross) and Year 2 data (Own)
predict double bh2x1 if $age_cond_1 & samp== 1, xb
predict double bh2x2 if e(sample), xb

scalar rmin = min(r1, r2)
scalar rmax = max(r1, r2)

keep if bh1x2<. | bh2x1<.
keep bh* ${hh_id}* ${dep_stub}* HAge HSex HEduYears Year Weight *poverty* samp strata*

* Get sample sizes for bootstrapping
su HAge if samp== 1
scalar obid_y1 = r(N)

su HAge if samp== 2
scalar obid_y2 = r(N)

scalar obidy = max(obid_y1, obid_y2)
sort $strata_y1 $strata_y2 $hh_id
bys samp: gen obid= _n 

sort obid
compress
save bh1x2_bh2x1, replace

* 2.2 BOOTSTRAP ERROR TERMS
forval i= 1/500 {
    use eh_orig, clear
    set seed `i'

    * 2.2.1 Get errors from Year 2
    qui keep if samp== 2 & eh2<.
    qui keep eh2 samp
    if obid_y1 > obid_y2 {
        expand 2
    }
    bsample obid_y1
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

    * 2.2.2 Get errors from Year 1
    use eh_orig, clear
    qui keep if samp== 1
    qui keep if eh1<.
    qui keep eh1 samp
    if obid_y2 > obid_y1 {
        expand 2
    }
    bsample obid_y2
    ren eh1 eth1
    qui gen obid= _n
    qui replace samp= 2 
    sort samp obid 
    qui merge 1:1 samp obid using "`stsec70'"
    qui drop _m
    sort obid

    * 2.3 Get Predicted Values
    qui gen double yu_y2 = bh2x1 + eth2 
    qui gen double yu_y1 = bh1x2 + eth1

    * Replace missing with observed
    qui replace yu_y1 = $depvar_y1 if yu_y1==. & samp== 1
    qui replace yu_y2 = $depvar_y2 if yu_y2==. & samp== 2

    * 2.4 Keep single year for stacked estimates
    qui keep if samp== 2 

    * 2.5 Calculate Poverty (Upper Bound)
    qui gen povub_y1 = (yu_y1 > $pline_y1) if yu_y1<.
    qui gen povub_y2 = (yu_y2 > $pline_y2) if yu_y2<.

    qui tab povub_y1 povub_y2 [aw= Weight], matcell(povub`i'_all)
    mat povub`i'_all = 100 * povub`i'_all / r(N) 
}

* 2.6 AVERAGE THE BOOTSTRAPS
local i= 2
while `i' <= 500 {
    local j= `i' - 1 
    mat povub`i'_all = povub`i'_all + povub`j'_all
    local i= `i' + 1 
}

local j= `i' - 1 
mat povub_final_all = povub`j'_all / `j'
mat rown povub_final_all = poor${yr1} nonpoor${yr1}
mat coln povub_final_all = poor${yr2} nonpoor${yr2}

* 2.7 GET OBSERVATION COUNT
qui ta povub_y1 povub_y2 [aw= Weight], cell nofr matcell(povub_cnt)
scalar npovub_all = r(N)

* 3. LOWER BOUND ESTIMATES
use "$file_cross", clear
qui xi: reg $depvar_y1 $indvar if $age_cond_1 & samp== 1, cluster($strata_y1)
est store reg_y1
scalar r1= e(r2)

predict double bh1x2 if $age_cond_2 & samp== 2, xb
predict double bh1x1 if e(sample), xb
predict double eh1 if e(sample), res

qui xi: reg $depvar_y2 $indvar if $age_cond_2 & samp== 2, cluster($strata_y2)
est store reg_y2
scalar r2= e(r2)

predict double bh2x1 if $age_cond_1 & samp== 1, xb
predict double bh2x2 if e(sample), xb
predict double eh2 if e(sample), res

scalar rmin = min(r1, r2)
scalar ormin = 1 - rmin
scalar rmax = max(r1, r2)
scalar ormax = 1 - rmax

keep if bh1x2<. | bh2x1<.
keep bh* strata* ${dep_stub}* eh* HAge HSex HEduYears Year Weight *poverty* samp 

* 3.1 Define Lower Bounds
gen double yl2 = bh2x1 + (sige2/sige1)* eh1
gen double yl1 = bh1x2 + (sige1/sige2)* eh2

ren yl1 yl_y1
ren yl2 yl_y2

replace yl_y1 = $depvar_y1 if yl_y1==. & samp== 1
replace yl_y2 = $depvar_y2 if yl_y2==. & samp== 2

qui gen povlb_y1 = (yl_y1 > $pline_y1) if yl_y1<.
qui gen povlb_y2 = (yl_y2 > $pline_y2) if yl_y2<.

* 3.2 Keep single year
qui keep if samp== 2 

* 3.3 Calculate Poverty Rates
la def pstat2 1 "nonpoor" 0 "poor"
qui for var povlb_y1 povlb_y2: la val X pstat2

ta povlb_y1 povlb_y2 [aw= Weight], cell nofr matcell(povlb_final_all)
mat povlb_final_all = 100 * povlb_final_all / r(N)
mat rown povlb_final_all = poor${yr1} nonpoor${yr1}
mat coln povlb_final_all = poor${yr2} nonpoor${yr2}
scalar npovlb_all = r(N)

* 4. DIRECT ESTIMATES (PARAMETRIC)
local char "_all"
foreach x of local char {
    capture drop p_est_*
    gen double p_est_pp`x' = .
    gen double p_est_pnp`x' = .
    gen double p_est_npp`x' = .
    gen double p_est_npnp`x' = .
}

cap program drop mypovdy
program mypovdy 
    mat p_est_all = J(2, 2, .)
    mat rown p_est_all = poor${yr1} nonpoor${yr1}
    mat coln p_est_all = poor${yr2} nonpoor${yr2}

    replace p_est_pp_all = $pp_term if samp== 2
    qui su p_est_pp_all [aw= Weight]
    mat p_est_all[1,1] = r(mean)*100

    replace p_est_pnp_all = $pnp_term if samp== 2
    qui su p_est_pnp_all [aw= Weight] 
    mat p_est_all[1,2] = r(mean)*100

    replace p_est_npp_all = $npp_term if samp== 2
    qui su p_est_npp_all [aw= Weight] 
    mat p_est_all[2,1] = r(mean)*100

    replace p_est_npnp_all = $npnp_term if samp== 2
    qui su p_est_npnp_all [aw= Weight] 
    mat p_est_all[2,2] = r(mean)*100
end

* 4.1 Define Macros for Bi-Normal Probabilities
* Note: using dynamic variable names inside the macros
global pp_term   "binormal(($pline_y1 - bh1x2)/sige1, ($pline_y2 - bh2x2)/sige2, rho)"
global pnp_term  "binormal(($pline_y1 - bh1x2)/sige1, -($pline_y2 - bh2x2)/sige2, -rho)"
global npp_term  "binormal(-($pline_y1 - bh1x2)/sige1, ($pline_y2 - bh2x2)/sige2, -rho)"
global npnp_term "binormal(-($pline_y1 - bh1x2)/sige1, -($pline_y2 - bh2x2)/sige2, rho)"

* 4.1.1 Parametric Runs (Varying Rho)
scalar rho = 1
mypovdy
mat p_est_1_all = p_est_all

scalar rho = 0.8
mypovdy
mat p_est_2_all = p_est_all

scalar rho = 0.7
mypovdy
mat p_est_3_all = p_est_all

scalar rho = 0.3
mypovdy
mat p_est_4_all = p_est_all

scalar rho = 0.2
mypovdy
mat p_est_5_all = p_est_all

scalar rho = 0
mypovdy
mat p_est_6_all = p_est_all

* 5. GET REAL RHO FROM PANEL DATA
use "$file_panel", clear
destring $hh_id, replace
xtreg ${dep_stub}* $indvar, i($hh_id) cluster($strata_y2)
scalar real_rho = e(rho) 
est store panel_reg

* 5.2 Calculate Actual Transitions (Reconstruct Wide Format)
use "$file_cross", clear
keep $hh_id samp ${dep_stub}* Weight strata* HAge* ${povline_stub}*

* Filter logic
keep if ($age_cond_1 & samp==1) | ($age_cond_2 & samp==2)

* Reshape to Wide (Assuming samp is the time differentiator)
keep $hh_id samp $depvar_y1 $depvar_y2 $pline_y1 $pline_y2 Weight
collapse (max) $depvar_y1 $depvar_y2 $pline_y1 $pline_y2 Weight, by($hh_id)

qui gen pov_y1_real = ($depvar_y1 > $pline_y1) if $depvar_y1<.
qui gen pov_y2_real = ($depvar_y2 > $pline_y2) if $depvar_y2<. 

la def pstat_real 1 "nonpoor" 0 "poor"
qui for var pov_y1_real pov_y2_real: la val X pstat_real

* Transitions
qui gen pp_real   = ($depvar_y1 <= $pline_y1 & $depvar_y2 <= $pline_y2) if $depvar_y1<. & $depvar_y2<. 
qui gen pnp_real  = ($depvar_y1 <= $pline_y1 & $depvar_y2 >  $pline_y2) if $depvar_y1<. & $depvar_y2<. 
qui gen npp_real  = ($depvar_y1 >  $pline_y1 & $depvar_y2 <= $pline_y2) if $depvar_y1<. & $depvar_y2<. 
qui gen npnp_real = ($depvar_y1 >  $pline_y1 & $depvar_y2 >  $pline_y2) if $depvar_y1<. & $depvar_y2<. 

qui ta pov_y1_real pov_y2_real
scalar ntpov_all = r(N)

* 6. SIMULATE ERRORS ("TRUTH")
cap program drop mysim_trate
program mysim_trate, rclass
    clear
    mat C = (sige1^2, real_rho*sige1*sige2 \ real_rho*sige1*sige2, sige2^2)
    drawnorm seh1 seh2, n($N_sim) cov(C)
    gen obid = _n
    sort obid
    merge 1:1 obid using bh1x2_bh2x1_sim
    drop if _m==2
    drop _m

    gen double lny12h = bh1x2 + seh1
    gen double lny22h = bh2x2 + seh2

    qui gen pov_sim_y1 = (lny12h > $pline_y1) if lny12h<.
    qui gen pov_sim_y2 = (lny22h > $pline_y2) if lny22h<. 

    qui gen sim_pp   = (lny12h <= $pline_y1 & lny22h <= $pline_y2) if lny12h<. & lny22h<. 
    qui gen sim_pnp  = (lny12h <= $pline_y1 & lny22h >  $pline_y2) if lny12h<. & lny22h<. 
    qui gen sim_npp  = (lny12h >  $pline_y1 & lny22h <= $pline_y2) if lny12h<. & lny22h<. 
    qui gen sim_npnp = (lny12h >  $pline_y1 & lny22h >  $pline_y2) if lny12h<. & lny22h<. 

    qui tabstat sim_pp sim_pnp sim_npp sim_npnp [aw= Weight], by(pov_sim_y1) stat(mean sem) save
    mat stpov_all = r(StatTotal)*100

    return scalar pp   = stpov_all[1,1]
    return scalar pnp  = stpov_all[1,2]
    return scalar npp  = stpov_all[1,3]
    return scalar npnp = stpov_all[1,4]
end 

* Prepare Data for Simulation
use bh1x2_bh2x1, clear
keep if samp== 2
count
global N_sim = r(N)
sort obid
save bh1x2_bh2x1_sim, replace

* Call Simulation
simulate spp= r(pp) spnp= r(pnp) snpp= r(npp) snpnp= r(npnp), seed(10101) reps(500) nodots ///
         saving(Y_boot_se, replace): mysim_trate

use Y_boot_se, clear
mat stpov_sim_all = J(2,4,.)

foreach v of varlist spp spnp snpp snpnp {
    local col = 1
    if "`v'"=="spnp" local col = 2
    if "`v'"=="snpp" local col = 3
    if "`v'"=="snpnp" local col = 4
    su `v'
    mat stpov_sim_all[1,`col'] = r(mean)
    mat stpov_sim_all[2,`col'] = r(sd)
}

* 7. FINAL OUTPUT MATRIX
mat pov_final = J(9, 9, .)

* Column 1: Non-parametric Lower Bound
mat pov_final[1,1] = round(povlb_final_all[1,1], 0.1)
mat pov_final[3,1] = round(povlb_final_all[1,2], 0.1)
mat pov_final[5,1] = round(povlb_final_all[2,1], 0.1)
mat pov_final[7,1] = round(povlb_final_all[2,2], 0.1)
mat pov_final[9,1] = npovlb_all

* Column 2: Rho = 1
mat pov_final[1,2] = round(p_est_1_all[1,1], 0.1)
mat pov_final[3,2] = round(p_est_1_all[1,2], 0.1)
mat pov_final[5,2] = round(p_est_1_all[2,1], 0.1)
mat pov_final[7,2] = round(p_est_1_all[2,2], 0.1)
mat pov_final[9,2] = npovlb_all

* Column 3: Rho = 0.8
mat pov_final[1,3] = round(p_est_2_all[1,1], 0.1)
mat pov_final[3,3] = round(p_est_2_all[1,2], 0.1)
mat pov_final[5,3] = round(p_est_2_all[2,1], 0.1)
mat pov_final[7,3] = round(p_est_2_all[2,2], 0.1)
mat pov_final[9,3] = npovlb_all

* Column 4: Rho = 0.7
mat pov_final[1,4] = round(p_est_3_all[1,1], 0.1)
mat pov_final[3,4] = round(p_est_3_all[1,2], 0.1)
mat pov_final[5,4] = round(p_est_3_all[2,1], 0.1)
mat pov_final[7,4] = round(p_est_3_all[2,2], 0.1)
mat pov_final[9,4] = npovlb_all

* Column 5: Truth Simulation
mat pov_final[1,5] = round(stpov_sim_all[1,1], 0.1)
mat pov_final[2,5] = round(stpov_sim_all[2,1], 0.1)
mat pov_final[3,5] = round(stpov_sim_all[1,2], 0.1)
mat pov_final[4,5] = round(stpov_sim_all[2,2], 0.1)
mat pov_final[5,5] = round(stpov_sim_all[1,3], 0.1)
mat pov_final[6,5] = round(stpov_sim_all[2,3], 0.1)
mat pov_final[7,5] = round(stpov_sim_all[1,4], 0.1)
mat pov_final[8,5] = round(stpov_sim_all[2,4], 0.1)
mat pov_final[9,5] = ntpov_all

* Column 6: Rho = 0.3
mat pov_final[1,6] = round(p_est_4_all[1,1], 0.1)
mat pov_final[3,6] = round(p_est_4_all[1,2], 0.1)
mat pov_final[5,6] = round(p_est_4_all[2,1], 0.1)
mat pov_final[7,6] = round(p_est_4_all[2,2], 0.1)
mat pov_final[9,6] = npovub_all

* Column 7: Rho = 0.2
mat pov_final[1,7] = round(p_est_5_all[1,1], 0.1)
mat pov_final[3,7] = round(p_est_5_all[1,2], 0.1)
mat pov_final[5,7] = round(p_est_5_all[2,1], 0.1)
mat pov_final[7,7] = round(p_est_5_all[2,2], 0.1)
mat pov_final[9,7] = npovub_all

* Column 8: Rho = 0
mat pov_final[1,8] = round(p_est_6_all[1,1], 0.1)
mat pov_final[3,8] = round(p_est_6_all[1,2], 0.1)
mat pov_final[5,8] = round(p_est_6_all[2,1], 0.1)
mat pov_final[7,8] = round(p_est_6_all[2,2], 0.1)
mat pov_final[9,8] = npovub_all

* Column 9: Non-parametric Upper Bound
mat pov_final[1,9] = round(povub_final_all[1,1], 0.1)
mat pov_final[3,9] = round(povub_final_all[1,2], 0.1)
mat pov_final[5,9] = round(povub_final_all[2,1], 0.1)
mat pov_final[7,9] = round(povub_final_all[2,2], 0.1)
mat pov_final[9,9] = npovub_all

mat rown pov_final = "Poor${yr1}_Poor${yr2}" "se" "Poor${yr1}_NonP${yr2}" "se" "NonP${yr1}_Poor${yr2}" "se" "NonP${yr1}_NonP${yr2}" "se" "N"
mat coln pov_final = "LB" "r1" "r0.8" "r0.7" "TruthSim" "r0.3" "r0.2" "r0" "UB"

mat li pov_final
log close
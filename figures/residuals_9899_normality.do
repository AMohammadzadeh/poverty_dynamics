*******************************************************************
* Residual normality check for the 1398-1399 all-household model
*
* Purpose:
*   Visualize residuals from the exact OLS consumption regressions
*   used in the main 1398-1399 parametric synthetic-panel workflow.
*
* Design:
*   - Residual-generating regressions are unweighted, matching
*     parametric.do and the Dang et al. replication code pattern.
*   - Displayed residual histograms are weighted by HIES Weight.
*   - Each year is plotted separately with a fitted normal density.
*******************************************************************

clear all
set more off
capture log close

global working_dir "E:\my_papers\poverty_dynamics\poverty_line_data"
global output_dir  "E:\my_papers\poverty_dynamics\figures"

cd "$working_dir"
log using "$output_dir\residuals_9899_normality.log", replace text

global hdage98 "HAge>= 25 & HAge<= 55"
global hdage99 "HAge>= 26 & HAge<= 56"

global depvar_98 "lcpc_98"
global depvar_99 "lcpc_99"
global indvar "HAge i.HSex HEduYears HLiterate NKids i.Region i.ProvinceCode Size HEmployed HMarritalState"

use Y98_99_final, clear
destring strata*, replace
destring HHID, replace

* Residuals from the exact all-household prediction regressions.
xi: reg $depvar_98 $indvar if $hdage98 & samp==1, cluster(strata_98)
gen byte esamp98 = e(sample)
predict double eh98 if esamp98, res

xi: reg $depvar_99 $indvar if $hdage99 & samp==2, cluster(strata_99)
gen byte esamp99 = e(sample)
predict double eh99 if esamp99, res

tempfile r98 r99 residuals h98 h99

preserve
    keep if esamp98 == 1 & eh98 < . & Weight < . & Weight > 0
    gen int year = 1398
    gen double residual = eh98
    keep year residual Weight
    save "`r98'", replace
restore

preserve
    keep if esamp99 == 1 & eh99 < . & Weight < . & Weight > 0
    gen int year = 1399
    gen double residual = eh99
    keep year residual Weight
    save "`r99'", replace
restore

use "`r98'", clear
append using "`r99'"
save "`residuals'", replace

* Common binning and x-axis range across panels.
quietly summarize residual
local xmin = floor(r(min) * 10) / 10
local xmax = ceil(r(max) * 10) / 10
local nbins = 40
local width = (`xmax' - `xmin') / `nbins'

if `width' <= 0 {
    display as error "Residual range is invalid; cannot construct histogram bins."
    exit 498
}

gen int bin = floor((residual - `xmin') / `width') + 1 if residual >= `xmin' & residual <= `xmax'
replace bin = `nbins' if bin > `nbins' & bin < .
gen double bin_mid = `xmin' + (bin - 0.5) * `width'

preserve
    keep if year == 1398 & bin < .
    quietly summarize residual [aw=Weight]
    local mu98 = r(mean)
    local sd98 = r(sd)
    egen double total_w = total(Weight)
    collapse (sum) bin_w=Weight (first) total_w, by(bin bin_mid)
    gen double density = bin_w / (total_w * `width')
    save "`h98'", replace
restore

preserve
    keep if year == 1399 & bin < .
    quietly summarize residual [aw=Weight]
    local mu99 = r(mean)
    local sd99 = r(sd)
    egen double total_w = total(Weight)
    collapse (sum) bin_w=Weight (first) total_w, by(bin bin_mid)
    gen double density = bin_w / (total_w * `width')
    save "`h99'", replace
restore

use "`h98'", clear
twoway ///
    (bar density bin_mid, barwidth(`width') color(navy%40) lcolor(navy%20)) ///
    (function y=normalden((x-(`mu98'))/(`sd98'))/(`sd98'), range(`xmin' `xmax') ///
        lcolor(maroon) lwidth(medthick)), ///
    title("A. 1398 residuals", size(medsmall)) ///
    xtitle("OLS residual") ///
    ytitle("Weighted density") ///
    xscale(range(`xmin' `xmax')) ///
    legend(order(1 "Weighted histogram" 2 "Fitted normal density") rows(2) region(lstyle(none))) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(resid98, replace)
graph export "$output_dir\residuals_1398_normality.pdf", replace
graph export "$output_dir\residuals_1398_normality.png", width(1800) replace
graph save "$output_dir\residuals_1398_normality.gph", replace

use "`h99'", clear
twoway ///
    (bar density bin_mid, barwidth(`width') color(navy%40) lcolor(navy%20)) ///
    (function y=normalden((x-(`mu99'))/(`sd99'))/(`sd99'), range(`xmin' `xmax') ///
        lcolor(maroon) lwidth(medthick)), ///
    title("B. 1399 residuals", size(medsmall)) ///
    xtitle("OLS residual") ///
    ytitle("Weighted density") ///
    xscale(range(`xmin' `xmax')) ///
    legend(order(1 "Weighted histogram" 2 "Fitted normal density") rows(2) region(lstyle(none))) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(resid99, replace)
graph export "$output_dir\residuals_1399_normality.pdf", replace
graph export "$output_dir\residuals_1399_normality.png", width(1800) replace
graph save "$output_dir\residuals_1399_normality.gph", replace


log close

version 16
clear all
set more off

capture log close

global repo "E:\my_papers\poverty_dynamics"
global data_dir "$repo\poverty_line_data"
global out_dir "$repo\figures"

log using "$out_dir\population_stability_9899.log", replace text

display as text "Population stability robustness check: all households, 1398-1399"
display as text "Base year: 1398; 1399 head age is aligned by subtracting one year."

use "$data_dir\Y98_99_final", clear

capture destring strata*, replace
capture destring HHID, replace

gen byte sample98 = samp == 1 & HAge >= 25 & HAge <= 55 & Weight > 0 & Weight < .
gen byte sample99 = samp == 2 & HAge >= 26 & HAge <= 56 & Weight > 0 & Weight < .
keep if sample98 | sample99

gen int survey_year = .
replace survey_year = 1398 if sample98
replace survey_year = 1399 if sample99

gen double base_age = HAge
replace base_age = HAge - 1 if sample99
label var base_age "Head age aligned to 1398 cohort"

display as text "Unweighted sample counts after age alignment:"
tab survey_year

preserve
collapse (count) unweighted_n=Weight (sum) weighted_n=Weight, by(survey_year)
format weighted_n %16.0fc
list, noobs
restore

gen byte age_25_34 = inrange(base_age, 25, 34) if !missing(base_age)
gen byte age_35_44 = inrange(base_age, 35, 44) if !missing(base_age)
gen byte age_45_55 = inrange(base_age, 45, 55) if !missing(base_age)

gen byte female_head = HSex == 2 if !missing(HSex)
gen byte hliterate_1 = HLiterate == 1 if !missing(HLiterate)
gen byte rural = Region == 2 if !missing(Region)

gen byte edu_none = HEduYears == 0 if !missing(HEduYears)
gen byte edu_1_5 = inrange(HEduYears, 1, 5) if !missing(HEduYears)
gen byte edu_6_11 = inrange(HEduYears, 6, 11) if !missing(HEduYears)
gen byte edu_12 = HEduYears == 12 if !missing(HEduYears)
gen byte edu_13plus = HEduYears >= 13 if !missing(HEduYears)

gen byte kids_0 = NKids == 0 if !missing(NKids)
gen byte kids_1 = NKids == 1 if !missing(NKids)
gen byte kids_2 = NKids == 2 if !missing(NKids)
gen byte kids_3plus = NKids >= 3 if !missing(NKids)

capture confirm numeric variable HEmployed
if !_rc {
    gen byte employed_1 = HEmployed == 1 if !missing(HEmployed)
}

levelsof ProvinceCode if !missing(ProvinceCode), local(province_levels)
foreach p of local province_levels {
    gen byte province_`p' = ProvinceCode == `p' if !missing(ProvinceCode)
}

capture confirm numeric variable HMarritalState
if !_rc {
    levelsof HMarritalState if !missing(HMarritalState), local(marital_levels)
    foreach m of local marital_levels {
        gen byte marital_`m' = HMarritalState == `m' if !missing(HMarritalState)
    }
}

tempfile balance
postfile balancepost str40 variable str96 label str32 group byte core ///
    double n98 n99 mean98 mean99 diff sd98 sd99 smd abs_smd ///
    using "`balance'", replace

capture program drop add_balance
program define add_balance
    syntax varname(numeric), Label(string) Group(string) [Core(integer 1)]

    quietly summarize `varlist' [aw=Weight] if sample98 & Weight > 0 & Weight < . & !missing(`varlist')
    scalar N98 = r(N)
    scalar M98 = r(mean)
    scalar V98 = r(Var)
    scalar SD98 = r(sd)

    quietly summarize `varlist' [aw=Weight] if sample99 & Weight > 0 & Weight < . & !missing(`varlist')
    scalar N99 = r(N)
    scalar M99 = r(mean)
    scalar V99 = r(Var)
    scalar SD99 = r(sd)

    scalar DIFF = M99 - M98
    scalar DEN = sqrt((V98 + V99) / 2)
    scalar SMD = .
    if DEN > 0 & DEN < . {
        scalar SMD = DIFF / DEN
    }
    scalar ABS_SMD = abs(SMD)

    post balancepost ("`varlist'") (`"`label'"') (`"`group'"') (`core') ///
        (N98) (N99) (M98) (M99) (DIFF) (SD98) (SD99) (SMD) (ABS_SMD)
end

add_balance base_age, label("Head age, aligned to 1398") group("Age") core(1)
add_balance age_25_34, label("Age 25-34") group("Age group") core(1)
add_balance age_35_44, label("Age 35-44") group("Age group") core(1)
add_balance age_45_55, label("Age 45-55") group("Age group") core(1)

add_balance female_head, label("Female head (HSex = 2)") group("Demographic") core(1)
add_balance hliterate_1, label("HLiterate = 1") group("Education") core(1)
add_balance HEduYears, label("Education years") group("Education") core(1)
add_balance edu_none, label("Education: 0 years") group("Education group") core(1)
add_balance edu_1_5, label("Education: 1-5 years") group("Education group") core(1)
add_balance edu_6_11, label("Education: 6-11 years") group("Education group") core(1)
add_balance edu_12, label("Education: 12 years") group("Education group") core(1)
add_balance edu_13plus, label("Education: 13+ years") group("Education group") core(1)

add_balance rural, label("Rural (Region = 2)") group("Location") core(1)

foreach p of local province_levels {
    add_balance province_`p', label("Province share (code `p')") group("Province, not plotted") core(0)
}

capture confirm variable Size
if !_rc {
    add_balance Size, label("Household size") group("Supplementary model covariate") core(0)
}

capture confirm variable NKids
if !_rc {
    add_balance NKids, label("Number of children") group("Supplementary model covariate") core(0)
    add_balance kids_0, label("Children: 0") group("Children group") core(0)
    add_balance kids_1, label("Children: 1") group("Children group") core(0)
    add_balance kids_2, label("Children: 2") group("Children group") core(0)
    add_balance kids_3plus, label("Children: 3+") group("Children group") core(0)
}

capture confirm variable employed_1
if !_rc {
    add_balance employed_1, label("HEmployed = 1") group("Supplementary model covariate") core(0)
}

capture confirm variable HMarritalState
if !_rc {
    foreach m of local marital_levels {
        add_balance marital_`m', label("HMarritalState = `m'") group("Supplementary model covariate") core(0)
    }
}

postclose balancepost

use "`balance'", clear
format mean98 mean99 diff sd98 sd99 smd abs_smd %9.4f
gsort -abs_smd

display as text "Largest weighted absolute standardized differences:"
list group label mean98 mean99 diff abs_smd in 1/15, noobs abbreviate(24)

export delimited using "$out_dir\population_stability_9899_balance.csv", replace

preserve
keep if core == 1
gsort -abs_smd
local keepN = min(_N, 25)
keep in 1/`keepN'
gsort abs_smd
gen plot_order = _n

label define plot_order_lbl 0 "blank", replace
forvalues i = 1/`=_N' {
    local rank = plot_order[`i']
    local lab = label[`i']
    label define plot_order_lbl `rank' "`lab'", add
}
label values plot_order plot_order_lbl

twoway ///
    (scatter plot_order abs_smd, msymbol(circle) msize(medsmall) mcolor(navy)), ///
    ylab(1(1)`=_N', valuelabel angle(0) labsize(vsmall)) ///
    ytitle("") ///
    xtitle("Absolute standardized mean difference") ///
    xline(0.10, lpattern(dash) lcolor(maroon)) ///
    xlabel(0(.05).20, labsize(small) format(%03.2f)) ///
    title("Weighted Composition Stability, 1398-1399", size(medsmall)) ///
    subtitle("All households; age-aligned synthetic cohort; province codes omitted", size(small)) ///
    note("Dashed line marks the conventional 0.10 descriptive balance threshold.", size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(pop_stability_love, replace)

graph export "$out_dir\population_stability_9899_love_plot.pdf", replace
graph export "$out_dir\population_stability_9899_love_plot.png", width(2400) replace
restore

preserve
keep if inlist(variable, "age_25_34", "age_35_44", "age_45_55")
gen order = .
replace order = 1 if variable == "age_25_34"
replace order = 2 if variable == "age_35_44"
replace order = 3 if variable == "age_45_55"
gen x98 = order - 0.17
gen x99 = order + 0.17
gen share98 = 100 * mean98
gen share99 = 100 * mean99

twoway ///
    (bar share98 x98, barwidth(0.30) color(navy%75)) ///
    (bar share99 x99, barwidth(0.30) color(maroon%70)), ///
    xlabel(1 "25-34" 2 "35-44" 3 "45-55", labsize(small)) ///
    ytitle("Weighted share (%)") xtitle("") ///
    title("Aligned Head Age, 1398-1399", size(medsmall)) ///
    legend(order(1 "1398" 2 "1399") rows(1) size(small)) ///
    note("1399 head age is shifted back by one year to align cohorts.", size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(pop_stability_age, replace)

graph export "$out_dir\population_stability_9899_age_barplot.pdf", replace
graph export "$out_dir\population_stability_9899_age_barplot.png", width(2400) replace
restore

preserve
keep if inlist(variable, "edu_none", "edu_1_5", "edu_6_11", "edu_12", "edu_13plus")
gen order = .
replace order = 1 if variable == "edu_none"
replace order = 2 if variable == "edu_1_5"
replace order = 3 if variable == "edu_6_11"
replace order = 4 if variable == "edu_12"
replace order = 5 if variable == "edu_13plus"
gen x98 = order - 0.17
gen x99 = order + 0.17
gen share98 = 100 * mean98
gen share99 = 100 * mean99

twoway ///
    (bar share98 x98, barwidth(0.30) color(navy%75)) ///
    (bar share99 x99, barwidth(0.30) color(maroon%70)), ///
    xlabel(1 "0" 2 "1-5" 3 "6-11" 4 "12" 5 "13+", labsize(small)) ///
    ytitle("Weighted share (%)") xtitle("Education years") ///
    title("Head Education, 1398-1399", size(medsmall)) ///
    legend(order(1 "1398" 2 "1399") rows(1) size(small)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(pop_stability_edu, replace)

graph export "$out_dir\population_stability_9899_education_barplot.pdf", replace
graph export "$out_dir\population_stability_9899_education_barplot.png", width(2400) replace
restore

preserve
keep if inlist(variable, "kids_0", "kids_1", "kids_2", "kids_3plus")
gen order = .
replace order = 1 if variable == "kids_0"
replace order = 2 if variable == "kids_1"
replace order = 3 if variable == "kids_2"
replace order = 4 if variable == "kids_3plus"
gen x98 = order - 0.17
gen x99 = order + 0.17
gen share98 = 100 * mean98
gen share99 = 100 * mean99

twoway ///
    (bar share98 x98, barwidth(0.30) color(navy%75)) ///
    (bar share99 x99, barwidth(0.30) color(maroon%70)), ///
    xlabel(1 "0" 2 "1" 3 "2" 4 "3+", labsize(small)) ///
    ytitle("Weighted share (%)") xtitle("Number of children") ///
    title("Children in Household, 1398-1399", size(medsmall)) ///
    legend(order(1 "1398" 2 "1399") rows(1) size(small)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(pop_stability_kids, replace)

graph export "$out_dir\population_stability_9899_children_barplot.pdf", replace
graph export "$out_dir\population_stability_9899_children_barplot.png", width(2400) replace
restore

display as text "Outputs written to $out_dir"
log close
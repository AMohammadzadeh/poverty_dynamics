clear all
macro drop _all

* ------------------------------------------------------------------------------
* 1. SETUP & PARAMETERS
* ------------------------------------------------------------------------------
global data "E:\my_papers\poverty_dynamics\poverty_line_data"



* ------------------------------------------------------------------------------
* 2. DEFINE LOOPS
* ------------------------------------------------------------------------------

* A. Years
local starts  98 99   1400 1401 1402
local ends    99 1400 1401 1402 1403

* POVERTY LINES
local pl_98  26361483
local pl_99  46464060
local pl_1400 54221850
local pl_1401 72518992
local pl_1402 106303008
local pl_1403 141539385


* B. Subgroup Names (Simple names only, no symbols)
local sub_names female educ have_educ urban rural

* Count pairs
local n_pairs : word count `starts'

* ------------------------------------------------------------------------------
* 3. PROCESSING
* ------------------------------------------------------------------------------
forvalues i = 1/`n_pairs' {
    
    local y1 : word `i' of `starts'
    local y2 : word `i' of `ends'
    
    display as text _n "=========================================="
    display as text "Processing Pair: `y1' - `y2'"
    display as text "=========================================="

    foreach s_name of local sub_names {
        
        * --- DEFINE CONDITION MANUALLY ---
        * This avoids the "too many ) or ]" error caused by list parsing
        if "`s_name'" == "female"    local s_cond "HSex==2"
        if "`s_name'" == "educ"      local s_cond "HEduYears<16"
        if "`s_name'" == "have_educ" local s_cond "HEduYears>=16"
        if "`s_name'" == "urban"     local s_cond "Region==1"
        if "`s_name'" == "rural"     local s_cond "Region==2"
        
        display as result "  -> Generating subgroup: `s_name'"

        * 1. Load Data
        use "${data}/Y`y1'_`y2'.dta", clear
        
        * 2. Filter
        keep if `s_cond'
        
        * 3. Clean old variables
        capture drop poverty_line* lcpc* lpoverty* samp hidn
		
		gen poverty_line`y1' = `pl_`y1''
        gen poverty_line`y2' = `pl_`y2''

        * 5. Logs
        gen lcpc_`y1' = log(Total_Exp_Month_Per_`y1')
        gen lcpc_`y2' = log(Total_Exp_Month_Per_`y2')
        gen lpoverty_line`y1' = log(poverty_line`y1')
        gen lpoverty_line`y2' = log(poverty_line`y2')

        * 6. Sampling
        g hidn = _n
        set seed 1234
        generate samp = floor(2 * runiform() + 1)

        * 7. Save Subgroup File
        save "${data}/Y`y1'_`y2'_`s_name'.dta", replace
        
        * 8. Reshape Long
        reshape long lcpc_, i(HHID) j(year)
        
        capture drop Year
        rename year Year
        
        save "${data}/Y`y1'_`y2'_`s_name'_long.dta", replace
    }
}

display as text "All processing complete."
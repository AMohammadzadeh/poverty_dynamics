
* ------------------------------------------------------------------------------
* 1. SETUP & PARAMETERS
* ------------------------------------------------------------------------------
global data "E:\my_papers\shared_resources\Poverty Dynamics DLLM\data"
global save "E:\my_papers\poverty_dynamics\poverty_line_data"
cd "E:\my_papers\shared_resources\Poverty Line\IRHEIS\DataProcessed"
* POVERTY LINES 
local pl_98  26361483
local pl_99  46464060
local pl_1400 54221850
local pl_1401 72518992
local pl_1402 106303008
local pl_1403 141539385



* ------------------------------------------------------------------------------
* 2. INDIVIDUAL YEAR PROCESSING
* ------------------------------------------------------------------------------
local all_years 98 99 1400 1401 1402 1403

foreach y of local all_years {
    
    * Determine source filename suffix (98->98, 99->99, 1400->100)
    if `y' < 100 {
        local suf = `y'
    }
    else {
        local suf = `y' - 1300
    }

    display as text "Processing Year: `y' (Source suffix: `suf')"
    
    use "Y`suf'Merged4CBN1", clear

    * Standardize names
    capture rename Total_Expenditure_Month Total_Exp_Month
    capture rename Total_Expenditure_Month_per Total_Exp_Month_Per
    
    rename Total_Exp_Month Total_Exp_Month_`y'
    rename Total_Exp_Month_Per Total_Exp_Month_Per_`y'

    tostring HHID, replace format(%17.0g)
    gen strata_`y' = substr(HHID, 6, 4)

    save "${data}/Y`y'.dta", replace
}

* ------------------------------------------------------------------------------
* 3. MERGING (PARALLEL LIST METHOD)
* ------------------------------------------------------------------------------
* We define two lists. The loop grabs the 1st item from both, then 2nd, etc.
local starts  98 99   1400 1401 1402
local ends    99 1400 1401 1402 1403

* Count how many pairs we have
local n_pairs : word count `starts'

forvalues i = 1/`n_pairs' {
    
    * Extract the i-th year from each list
    local y1 : word `i' of `starts'
    local y2 : word `i' of `ends'
    
    display as text "Merging pair `i': `y1' and `y2'..."

    use "${data}/Y`y1'.dta", clear
    merge 1:1 HHID using "${data}/Y`y2'.dta"
    
    keep if _merge == 3 
    save "${save}\Y`y1'_`y2'.dta", replace

    * --- ADDING POVERTY LINES ---
    * Note: We use double quotes inside the log function to handle potential missing values cleanly, 
    * though strictly mathematical logs don't use quotes. 
    
    gen poverty_line`y1' = `pl_`y1''
    gen poverty_line`y2' = `pl_`y2''
    
    gen lcpc_`y1' = log(Total_Exp_Month_Per_`y1')
    gen lcpc_`y2' = log(Total_Exp_Month_Per_`y2')
    
    gen lpoverty_line`y1' = log(poverty_line`y1')
    gen lpoverty_line`y2' = log(poverty_line`y2')
	g hidn=_n
	set seed 1234
	generate samp = floor((2)*runiform() + 1)

    save "${save}/Y`y1'_`y2'_final.dta", replace
	
	use "${save}\Y`y1'_`y2'_final.dta", clear
	reshape long lcpc_, i(HHID) j(year)
	drop Year
	rename year Year

	save "${save}\Y`y1'_`y2'_final_long.dta", replace
}

display as text "All processing complete."
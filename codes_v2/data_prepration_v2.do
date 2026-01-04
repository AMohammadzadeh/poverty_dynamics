* ------------------------------------------------------------------------------
* 1. SETUP & PARAMETERS
* ------------------------------------------------------------------------------
global data "E:\my_papers\shared_resources\Poverty Dynamics DLLM\data"
global save "E:\my_papers\poverty_dynamics\poverty_line_data"
global weights "E:\my_papers\poverty_dynamics\irheis_weights" 

cd "E:\my_papers\shared_resources\Poverty Line\IRHEIS\DataProcessed"

* POVERTY LINES 
local pl_98    5863711 
local pl_99    8205691
local pl_1400   12571554
local pl_1401   17671052
local pl_1402   22258561
local pl_1403   29175368

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
    
    * --- STEP A: PREPARE WEIGHT FILE ---
    * We preserve the current state, load the weight file to rename Address->HHID, 
    * save it as a tempfile, and then restore to load the main data.
//     preserve
//         capture use "${weights}/weight`y'.dta", clear
//         if _rc == 0 {
//             * Rename Address to HHID for merging
//             capture rename Address HHID 
//            
//             * Ensure HHID is string and trimmed of spaces to match main file
//             capture tostring HHID, replace
//             replace HHID = trim(HHID)
//            
//             * Save tempfile for merging
//             tempfile w_data
//             save `w_data'
//         }
//         else {
//             display as error "Warning: Weight file for year `y' not found."
//         }
//     restore

    * --- STEP B: PROCESS MAIN FILE ---
    use "Y`suf'Merged4CBN1", clear

    * Standardize names
    capture rename Total_Expenditure_Month Total_Exp_Month
    capture rename Total_Expenditure_Month_per Total_Exp_Month_Per
    
    rename Total_Exp_Month Total_Exp_Month_`y'
    rename Total_Exp_Month_Per Total_Exp_Month_Per_`y'

    * Format HHID
    tostring HHID, replace format(%17.0g)
    replace HHID = trim(HHID) // Safety trim
    gen strata_`y' = substr(HHID, 6, 4)

//     * --- STEP C: MERGE WEIGHTS ---
//     * Merge using the tempfile created in Step A
//     capture confirm file `w_data'
//     if _rc == 0 {
//         merge 1:1 HHID using `w_data'
//        
//         * Keep only matched records (Change to 'keep if _merge==3 | _merge==1' if you want to keep households without weights)
//         keep if _merge == 3 
//         drop _merge
//        
//         * IMPORTANT: Rename the weight variable (assuming it's named 'weight') 
//         * to 'weight_YEAR' so it survives the pairing loop later.
//         capture rename weight weight_`y'
//         capture rename Weight weight_`y'
//     }

    save "${data}/Y`y'.dta", replace
}

* ------------------------------------------------------------------------------
* 3. MERGING (PARALLEL LIST METHOD)
* ------------------------------------------------------------------------------
local starts  98 99   1400 1401 1402
local ends    99 1400 1401 1402 1403

local n_pairs : word count `starts'

forvalues i = 1/`n_pairs' {
    
    local y1 : word `i' of `starts'
    local y2 : word `i' of `ends'
    
    display as text "Merging pair `i': `y1' and `y2'..."

    use "${data}/Y`y1'.dta", clear
    merge 1:1 HHID using "${data}/Y`y2'.dta"
    
    keep if _merge == 3 
    save "${save}\Y`y1'_`y2'.dta", replace

    * --- ADDING POVERTY LINES ---
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
    
    * --- RESHAPE TO LONG ---
    use "${save}\Y`y1'_`y2'_final.dta", clear
    
    * Added 'weight_' to the stub list so weights are also reshaped properly
//     reshape long lcpc_ weight_, i(HHID) j(year)
reshape long lcpc_ , i(HHID) j(year)
    drop Year
    rename year Year

    save "${save}\Y`y1'_`y2'_final_long.dta", replace
}

display as text "All processing complete."
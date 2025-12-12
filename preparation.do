clear all

global data "D:\Ahmad\Thesis\DrKeshavarz\Poverty Dynamics DLLM\data"

cd "D:\Ahmad\Thesis\DrKeshavarz\Poverty Line\IRHEIS\DataProcessed"

use Y98Merged4CBN1, clear
rename Total_Exp_Month Total_Exp_Month_98
rename Total_Exp_Month_Per Total_Exp_Month_Per_98
tostring HHID, replace format(%17.0g)
gen strata_98 = substr(HHID,6,4)


save "${data}\Y98.dta",replace


use Y99Merged4CBN1, clear
rename Total_Exp_Month Total_Exp_Month_99
rename Total_Exp_Month_Per Total_Exp_Month_Per_99
tostring HHID, replace  format(%17.0g)
 gen strata_99 = substr(HHID,6,4)
save "${data}\Y99.dta",replace

use "${data}\Y98.dta", clear

merge 1:1 HHID using "${data}\Y99.dta"

keep if _merge ==3
// rename _merge samp


save "${data}\Y98_99.dta", replace

***************

*****************
use "${data}\Y98_99.dta", clear

*gen poverty_line98 = 8248972.66
*gen poverty_line99 = 10857318.1542

gen poverty_line98 = 9060000
gen poverty_line99 = 12540000


gen  lcpc_98 = log(Total_Exp_Month_Per_98)
gen  lcpc_99 = log(Total_Exp_Month_Per_99)

gen lpoverty_line98 = log(poverty_line98)
gen lpoverty_line99 = log(poverty_line99)

g hidn=_n
set seed 1234
generate samp = floor((2)*runiform() + 1)

save "${data}\Y98_99_final.dta", replace

save sum98-99_final, replace


******
*Create long panel

use "${data}\Y98_99_final.dta", clear
reshape long lcpc_, i(HHID) j(year)
drop Year
rename year Year

save "${data}\Y98_99_final_long.dta", replace
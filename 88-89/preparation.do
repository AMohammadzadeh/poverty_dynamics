clear all

global data "D:\Ahmad\Thesis\DrKeshavarz\Poverty Dynamics DLLM\data"

cd "D:\Ahmad\Thesis\DrKeshavarz\Poverty Line\IRHEIS\DataProcessed"

use Y88Merged4CBN1, clear
rename Total_Exp_Month Total_Exp_Month_88
rename Total_Exp_Month_Per Total_Exp_Month_Per_88
tostring HHID, replace format(%17.0g)
gen strata_88 = substr(HHID,6,4)


save "${data}\Y88.dta",replace


use Y89Merged4CBN1, clear
rename Total_Exp_Month Total_Exp_Month_89
rename Total_Exp_Month_Per Total_Exp_Month_Per_89
tostring HHID, replace  format(%17.0g)
 gen strata_89 = substr(HHID,6,4)
save "${data}\Y89.dta",replace

use "${data}\Y88.dta", clear

merge 1:1 HHID using "${data}\Y89.dta"

keep if _merge ==3
// rename _merge samp


save "${data}\Y88_89.dta", replace

***************

*****************
use "${data}\Y88_89.dta", clear

*gen poverty_line88 = 8248972.66
*gen poverty_line89 = 10857318.1542

gen poverty_line88 = 1000000
gen poverty_line89 = 2000000


gen  lcpc_88 = log(Total_Exp_Month_Per_88)
gen  lcpc_89 = log(Total_Exp_Month_Per_89)

gen lpoverty_line88 = log(poverty_line88)
gen lpoverty_line89 = log(poverty_line89)

g hidn=_n
set seed 1234
generate samp = floor((2)*runiform() + 1)

save "${data}\Y88_89_final.dta", replace

save sum88-89_final, replace


******
*Create long panel

use "${data}\Y88_89_final.dta", clear
reshape long lcpc_, i(HHID) j(year)
drop Year
rename year Year

save "${data}\Y88_89_final_long.dta", replace
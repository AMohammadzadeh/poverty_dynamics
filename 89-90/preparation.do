clear all

global data "D:\Ahmad\Thesis\DrKeshavarz\Poverty Dynamics DLLM\data"

cd "D:\Ahmad\Thesis\DrKeshavarz\Poverty Line\IRHEIS\DataProcessed"

use Y89Merged4CBN1, clear
rename Total_Exp_Month Total_Exp_Month_89
rename Total_Exp_Month_Per Total_Exp_Month_Per_89
tostring HHID, replace format(%17.0g)
gen strata_89 = substr(HHID,6,4)


save "${data}\Y89.dta",replace


use Y90Merged4CBN1, clear
rename Total_Exp_Month Total_Exp_Month_90
rename Total_Exp_Month_Per Total_Exp_Month_Per_90
tostring HHID, replace  format(%17.0g)
 gen strata_90 = substr(HHID,6,4)
save "${data}\Y90.dta",replace

use "${data}\Y89.dta", clear

merge 1:1 HHID using "${data}\Y90.dta"

keep if _merge ==3
// rename _merge samp


save "${data}\Y89_90.dta", replace

***************

*****************
use "${data}\Y89_90.dta", clear

*gen poverty_line89 = 8249072.66
*gen poverty_line90 = 10857318.1542

gen poverty_line89 = 1000000
gen poverty_line90 = 2000000


gen  lcpc_89 = log(Total_Exp_Month_Per_89)
gen  lcpc_90 = log(Total_Exp_Month_Per_90)

gen lpoverty_line89 = log(poverty_line89)
gen lpoverty_line90 = log(poverty_line90)

g hidn=_n
set seed 1234
generate samp = floor((2)*runiform() + 1)

save "${data}\Y89_90_final.dta", replace

save sum89-90_final, replace


******
*Create long panel

use "${data}\Y89_90_final.dta", clear
reshape long lcpc_, i(HHID) j(year)
drop Year
rename year Year

save "${data}\Y89_90_final_long.dta", replace
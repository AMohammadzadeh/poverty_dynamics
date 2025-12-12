clear all

global data "D:\Ahmad\Thesis\DrKeshavarz\Poverty Dynamics DLLM\data"

cd "D:\Ahmad\Thesis\DrKeshavarz\Poverty Line\IRHEIS\DataProcessed"


use "${data}\Y98_99.dta", clear

*Keep female households
keep if HSex==2


gen poverty_line98 = 9060000
gen poverty_line99 = 12540000


gen  lcpc_98 = log(Total_Exp_Month_Per_98)
gen  lcpc_99 = log(Total_Exp_Month_Per_99)

gen lpoverty_line98 = log(poverty_line98)
gen lpoverty_line99 = log(poverty_line99)

g hidn=_n
set seed 1234
generate samp = floor((2)*runiform() + 1)

save "${data}\Y98_99_female.dta", replace

**Create long panel

use "${data}\Y98_99_female.dta", clear
reshape long lcpc_, i(HHID) j(year)
drop Year
rename year Year

save "${data}\Y98_99_female_long.dta", replace


*Keep not have university educ

use "${data}\Y98_99.dta", clear
keep if HEduYears<16


gen poverty_line98 = 9060000
gen poverty_line99 = 12540000


gen  lcpc_98 = log(Total_Exp_Month_Per_98)
gen  lcpc_99 = log(Total_Exp_Month_Per_99)

gen lpoverty_line98 = log(poverty_line98)
gen lpoverty_line99 = log(poverty_line99)

g hidn=_n
set seed 1234
generate samp = floor((2)*runiform() + 1)

save "${data}\Y98_99_educ.dta", replace

**Create long panel

use "${data}\Y98_99_educ.dta", clear
reshape long lcpc_, i(HHID) j(year)
drop Year
rename year Year

save "${data}\Y98_99_educ_long.dta", replace

*Keep urban

use "${data}\Y98_99.dta", clear
keep if Region==1


gen poverty_line98 = 9060000
gen poverty_line99 = 12540000


gen  lcpc_98 = log(Total_Exp_Month_Per_98)
gen  lcpc_99 = log(Total_Exp_Month_Per_99)

gen lpoverty_line98 = log(poverty_line98)
gen lpoverty_line99 = log(poverty_line99)

g hidn=_n
set seed 1234
generate samp = floor((2)*runiform() + 1)

save "${data}\Y98_99_urban.dta", replace

**Create long panel

use "${data}\Y98_99_urban.dta", clear
reshape long lcpc_, i(HHID) j(year)
drop Year
rename year Year

save "${data}\Y98_99_urban_long.dta", replace

*Keep rural

use "${data}\Y98_99.dta", clear
keep if Region==2


gen poverty_line98 = 9060000
gen poverty_line99 = 12540000


gen  lcpc_98 = log(Total_Exp_Month_Per_98)
gen  lcpc_99 = log(Total_Exp_Month_Per_99)

gen lpoverty_line98 = log(poverty_line98)
gen lpoverty_line99 = log(poverty_line99)

g hidn=_n
set seed 1234
generate samp = floor((2)*runiform() + 1)

save "${data}\Y98_99_rural.dta", replace

**Create long panel

use "${data}\Y98_99_rural.dta", clear
reshape long lcpc_, i(HHID) j(year)
drop Year
rename year Year

save "${data}\Y98_99_rural_long.dta", replace



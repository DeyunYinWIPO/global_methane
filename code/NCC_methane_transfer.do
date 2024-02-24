cd "./Jiang_Mechane/data/"


* Technological transfer between countries 

use famid_y02_2022a_V3,clear 
keep if fam_size >1 
keep famid_docdb
gduplicates drop 
gdistinct famid_docdb
compress 
save famid_y02_trans,replace 


export delimited using "temp_ch4_highQ.csv", replace

import delimited using "../V1/ch4_famid_highQ.csv",clear 
gen is_granted=(is_grant=="Y")
drop is_grant
ren is_granted is_grant
gduplicates drop famid_docdb app_auth,force 
// keep if inlist(app_kind,"A","W","U","D")
keep if inlist(app_kind,"A","W")
bysort famid_docdb: gen x=_N
drop if x==1
drop x 
drop if origin==app_auth 
// drop if app_auth=="WO"
tab app_auth,sort
tab is_grant

foreach v in app_date{
	gen `v'1=date(`v',"YMD")
	format %tdCCYY-NN-DD `v'1
	drop `v'
	ren `v'1 `v'
}
sencode rel_type,replace 
drop appln_id 
gduplicates drop 
compress 
save ch4_trans,replace 

use famid_y02_2022a_V3,clear 
keep if fam_size >1 

keep famid_docdb tec* is_methan
gduplicates drop 
joinby famid_docdb using ch4_trans
order famid_docdb origin- app_date
drop rel_type 
gduplicates drop 

gsort app_date famid_docdb 
gen x1=(tec!=.)
bysort famid_docdb: gegen x2=max(x1)
gsort famid_docdb -is_methan
by famid_docdb: carryforward tec,replace  
by famid_docdb: carryforward tec_subid,replace 
by famid_docdb: carryforward tec_id,replace 
by famid_docdb: carryforward tec_sub,replace 
drop is_methan x1 x2 
gen is_methan=(tec!=.)

ren origin ctry_code
merge m:1 ctry_code using "F:\Dropbox\Github\Novelty_Patent\data\sc_patstat\2022a\pat_ctrycode.dta",keep(3)nogen 
gsort is_methan app_year famid_docdb app_date 
gduplicates drop 

gen year_dmy ="1990-2004" if app_year>=1990 & app_year <=2004
replace year_dmy="2005-2010" if  app_year>=2005 & app_year <=2010
replace year_dmy ="2011-2016" if app_year>=2011 & app_year <=2016
replace year_dmy ="2017-2019" if app_year>=2017 & app_year <=2019

keep if year_dmy !=""  
gsort is_methan app_year famid_docdb app_date 
gduplicates drop 

gduplicates drop 
gsort is_methan app_year famid_docdb app_date tec 

compress 
save famid_trans_ctry,replace 


* ctry_unstatus 
import excel "development_status.xlsx", sheet("Sheet2") firstrow clear 
renvarlab *, lower
replace status2="Developing-Emerging" if status2=="Emerging economies"
replace status2="Developing-excluding emerging" if regexm(status,"ing") & status2==""
replace status2=status if status2=="" 
sencode status,replace 
sencode status2,replace 
gduplicates drop 
compress 
ren country name
merge 1:1 name using "ft_ctry_tb_memberstates.dta",keep(1 3) nogen 
drop if ctry==""
compress 
save ctry_unstatus,replace 


use famid_trans_ctry,clear 
gsort ctry_code app_year app_auth 
ren (ctry_code app_auth)(from to)
drop if from==""
format %25.0g tec
format %27.0g tec_sub
compress 
save famid_trans_ctry,replace 


use famid_trans_ctry,clear 
ren from ctry 
merge m:1 ctry using ctry_unstatus,keepusing(name status2) keep(3) nogen 
ren status2 status
gsort ctry app_year 
ren (ctry name status) (from from_ctry from_status)
ren to ctry 
merge m:1 ctry using ctry_unstatus,keepusing(name status2)keep(3) nogen 
ren (ctry name status) (to to_ctry to_status)
gsort is_methan from to app_year  

gen from_s = "LDCs" if from_status==1 
replace from_s = "Developing-excluding emerging" if from_status==2
replace from_s = "Developing-emerging" if from_status==3
replace from_s = "Developed" if from_status==4

gen to_s = "LDCs" if to_status==1 
replace to_s = "Developing-excluding emerging" if to_status==2
replace to_s = "Developing-emerging" if to_status==3
replace to_s = "Developed" if to_status==4

compress 
save famid_trans_ctryf,replace 


* by year 
use famid_trans_ctryf,clear 
keep famid_docdb is_methan app_year year_dmy
gduplicates drop 
gcollapse (count)patQ  = famid_docdb,by(is_methan app_year year_dmy)
save temp1,replace 

use famid_trans_ctryf,clear 
keep famid_docdb is_methan to app_year year_dmy
gduplicates drop 
gcollapse (count)transQ  = famid_docdb,by(is_methan app_year)
merge 1:1 is_methan app_year using temp1,nogen  
gen trans_avg = transQ/patQ 
order is_methan app_year patQ transQ trans_avg

export excel using "..\Jiang_Mechane\indicator\iv_trans_year.xlsx", sheet("1y") sheetmodify firstrow(variables)

* by tec 
use famid_trans_ctryf,clear 
keep famid_docdb is_methan app_year year_dmy tec tec_sub
gduplicates drop 
gcollapse (count)patQ  = famid_docdb ,by(is_methan app_year year_dmy tec tec_sub)
save temp1,replace 

use famid_trans_ctryf,clear 
keep famid_docdb is_methan to app_year year_dmy tec tec_sub
gduplicates drop 
gcollapse (count)transQ  = famid_docdb,by(is_methan app_year tec_sub)
merge 1:1 is_methan app_year tec_sub using temp1,nogen  
gen trans_avg = transQ/patQ 
order is_methan app_year patQ transQ trans_avg

export excel using "..\Jiang_Mechane\indicator\iv_trans_year.xlsx", sheet("2y_tec") sheetmodify firstrow(variables)


use famid_trans_ctryf,clear 
keep famid_docdb is_methan year_dmy
gduplicates drop 
gcollapse (count)patQ  = famid_docdb,by(is_methan year_dmy)
save temp1,replace 

use famid_trans_ctryf,clear 
keep famid_docdb is_methan year_dmy to 
gduplicates drop 
gcollapse (count)transQ  = famid_docdb,by(is_methan year_dmy)
merge 1:1 is_methan year_dmy using temp1,nogen  
gen trans_avg = transQ/patQ 
order is_methan year_dmy patQ transQ trans_avg
export excel using "..\Jiang_Mechane\indicator\iv_trans_year.xlsx", sheet("3ydmy") sheetmodify firstrow(variables)

shellout "..\Jiang_Mechane\indicator\iv_trans_year.xlsx"


cap rm "..\Jiang_Mechane\indicator\iv_trans_ctry.xlsx"

* In total 
use iv_ch4_trans_ctryf,clear 
drop tec* 
gduplicates drop 
gcollapse (count)patQ= famid_docdb,by(is_methan from_s to_s year_dmy)
order is_methan year_dmy 
bysort is_methan year_dmy: gegen pat_tot=sum(patQ)
gen pat_ratio= patQ/pat_tot*100
bysort is_methan year_dmy from_s: gegen share_from=sum(pat_ratio)
bysort is_methan year_dmy to_s: gegen share_to=sum(pat_ratio)
gsort is_methan year_dmy from_s to_s 
save "../../indicator/iv_trans_ctry",replace 
export excel using "../../indicator\iv_trans_ctry.xlsx", sheet("1ctry") firstrow(variables)


* by tec 
use iv_ch4_trans_ctryf,clear 
drop tec_sub*  
gduplicates drop 
gcollapse (count)patQ= famid_docdb,by(is_methan from_s to_s year_dmy tec)
order is_methan year_dmy 
gsort is_methan year_dmy from_s to_s
bysort is_methan year_dmy: gegen pat_tot=sum(patQ)
gen pat_ratio= patQ/pat_tot*100
bysort is_methan year_dmy from_s tec: gegen share_from=sum(pat_ratio)
bysort is_methan year_dmy to_s tec: gegen share_to=sum(pat_ratio)
gsort is_methan year_dmy from_s to_s tec 
save "../../indicator/iv_trans_ctrytec",replace 
export excel using "../../indicator\iv_trans_ctry.xlsx", sheet("2ctry_tec") sheetmodify firstrow(variables)


* by country 
use iv_ch4_trans_ctryf,clear 
keep famid_docdb is_methan from_s to_s year_dmy from to 
gduplicates drop 
gcollapse (count)patQ= famid_docdb,by(is_methan from_s to_s year_dmy from to)
order is_methan year_dmy 

bysort is_methan year_dmy: gegen pat_tot=sum(patQ)
gen pat_ratio= patQ/pat_tot*100

bysort is_methan year_dmy from: gegen from_tot = sum(patQ)
bysort is_methan year_dmy to: gegen to_tot = sum(patQ)
bysort is_methan year_dmy from: gegen share_from=sum(pat_ratio)
bysort is_methan year_dmy to: gegen share_to=sum(pat_ratio)
gsort is_methan year_dmy -patQ

// bysort is_methan year_dmy from to_s: gegen share_from_type=sum(pat_ratio)
// bysort is_methan year_dmy to from_s: gegen share_to_type=sum(pat_ratio)

gsort is_methan year_dmy -pat_ratio
save "../../indicator/iv_trans_ctrytec",replace 
export excel using "../../indicator\iv_trans_ctry.xlsx", sheet("3ctry_tec") sheetmodify firstrow(variables)


shellout "..\Jiang_Mechane\indicator\iv_trans_ctry.xlsx"


* Tec transfer rate 
use iv_ch4_trans_ctryf,clear 
drop tec_sub*  
gduplicates drop 
gcollapse (count)patQ= famid_docdb,by(is_methan from_s to_s year_dmy tec)
order is_methan year_dmy 
gsort is_methan year_dmy from_s to_s
bysort is_methan year_dmy: gegen pat_tot=sum(patQ)
gen pat_ratio= patQ/pat_tot*100
bysort is_methan year_dmy from_s tec: gegen share_from=sum(pat_ratio)
bysort is_methan year_dmy to_s tec: gegen share_to=sum(pat_ratio)
gsort is_methan year_dmy from_s to_s tec 
save "../../indicator/iv_trans_ctrytec",replace 
export excel using "../../indicator\iv_trans_ctry.xlsx", sheet("2ctry_tec") sheetmodify firstrow(variables)



*#############################
*     Transfer rate
*#############################
use famid_y02_2022a_V3,clear 
keep famid_docdb tec app_year 
gduplicates drop 
drop if app_year==9999
bysort famid_docdb : gen x1=_N
gen x2=(tec !=.)
bysort famid_docdb: gegen x3=max(x2)
drop if tec==. & x1>=2 & x3==1
drop x*
bysort famid_docdb : gen dup=_N
tab dup
compress 
save ch4_trans_tec,replace 

use ch4_trans,clear 
keep famid_docdb
gduplicates drop 
merge 1:m famid_docdb using ch4_trans_tec,keep(2 3)
gen is_trans=(_mer==3)
drop _mer 

gen year_dmy ="1990-2004" if app_year>=1990 & app_year <=2004
replace year_dmy="2005-2010" if  app_year>=2005 & app_year <=2010
replace year_dmy ="2011-2016" if app_year>=2011 & app_year <=2016
replace year_dmy ="2017-2019" if app_year>=2017 & app_year <=2019

keep if year_dmy !=""  

format %25.0g tec
compress 
save ch4_trans_tec,replace 

* absolute counting 
use ch4_trans_tec,clear 
drop app_year dup 
gduplicates drop 
gcollapse (count)patQ=famid_docdb,by(year_dmy tec is_trans)
bysort year_dmy tec: gegen pat_totQ =sum(patQ)
gen pat_ratio=patQ/pat_totQ*100
drop if is_trans==0
drop is_trans 
compress 
save "../../indicator/iv_trans_tec",replace 


* fractional counting 
use ch4_trans_tec,clear 
drop app_year 
gduplicates drop 
gen wgt=1/dup 
gsort famid_docdb
gcollapse (sum)patQ_frac=wgt,by(year_dmy tec is_trans)
bysort year_dmy tec: gegen pat_totQ_frac =sum(patQ)
gen pat_ratio_frac=patQ/pat_totQ*100
drop if is_trans==0
drop is_trans

merge 1:1 year_dmy tec using "../../indicator/iv_trans_tec",nogen 
order year_dmy tec patQ pat_totQ pat_ratio patQ_frac pat_totQ_frac pat_ratio_frac 
save "../../indicator/iv_trans_tec",replace 

export excel using "..\Jiang_Mechane\indicator\iv_trans_year.xlsx", sheet("4trans_tec") sheetmodify firstrow(variables)

shellout "..\Jiang_Mechane\indicator\iv_trans_year.xlsx"



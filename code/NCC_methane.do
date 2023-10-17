cd "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\data\V2\"

/*
- famid_y02_2022a
- famid_y02_2022a_V2: V1: is_noA4S & ipr_type =="PI"  & inrange(app_year,1990, 2019)
- famid_y02_2022a_V3: V2+ is_ctry_select: excluding patent offices and countries lacking data: only 134 countries left. 
*/

*#####################################################
*           Version 4
*#####################################################

* Date: August 31, 2023
import delimited "ch4_famid_y02_2022a.csv",clear 
gduplicates drop famid_docdb cpc,force  
bysort famid_docdb: gen cpcQ=_N 
foreach v in app_date cpc_version cpc_action_date {
	gen `v'1=date(`v',"YMD")
	format %tdCCYY-NN-DD `v'1
	drop `v'
	ren `v'1 `v'
}
compress 
save famid_y02_2022a,replace 


use famid_y02_2022a,clear 
cap drop tec_subid
gen tec_subid =111 if cpc=="Y02P  60/22"
replace tec_subid =112 if cpc=="Y02P  60/30"
replace tec_subid =113 if cpc=="Y02P  60/40"
replace tec_subid =114 if cpc=="Y02P  60/50"|cpc=="Y02P  60/52" 
replace tec_subid =121 if cpc=="Y02W  10/10"|cpc=="Y02W  10/20"|cpc=="Y02W  10/30"|cpc=="Y02W  10/33"|cpc=="Y02W  10/37"|cpc=="Y02W  10/40"
replace tec_subid =122 if cpc=="Y02W  30/30"
replace tec_subid =123 if cpc=="Y02E  20/12"|cpc=="Y02E  50/30"
replace tec_subid =124 if cpc=="Y02W  30/40"
replace tec_subid =125 if cpc=="Y02W  30/80"|cpc=="Y02W  90/10"
replace tec_subid =126 if cpc=="Y02W  30/62"|cpc=="Y02W  30/64"|cpc=="Y02W  30/66"|cpc=="Y02W  30/74"|cpc=="Y02W  30/78"

replace tec_subid =141 if cpc=="Y02E  50/10"
replace tec_subid =151 if cpc=="Y02P  90/80"|cpc=="Y02P  90/82"|cpc=="Y02P  90/84"|cpc=="Y02P  90/845"
replace tec_subid =152 if cpc=="Y02P  90/90"|cpc=="Y02P  90/95"


gen is_A4S= (regexm(cpc,"Y02A"))
gen is_noA4S=(is_A4S==0)
* V2 note: a tec both Y02A and not Y02A 
drop is_A4S
compress
save,replace 

count if cpc=="Y02C  20/20" //1858 
count if regexm(cpc,"Y02E") //1,705,256 

* Miss1: cpc=="Y02C  20/20" belongs to A and not A 
* Miss2: "Y02E  20/12" and with biomass, "Y02  E20/30" and with biomass
// import delimited "ch4_famid_cpc_miss_2022a.csv", clear 
import delimited "ch4_famid_miss_2022a_v2.csv", clear
// replace tec_subid=114 if tec_subid ==113
drop cpc 
gduplicates drop
gsort famid_docdb

tab tec_subid
gdistinct famid_docdb 
gdistinct famid_docdb if tec_subid==132 
gdistinct famid_docdb if tec_subid==142 

gduplicates t famid_docdb,gen(x)
tab x 
tab tec_subid if x>0 
* has 142 
bysort famid_docdb: gen has_142=(tec_subid==142) & x>0
bysort famid_docdb: gegen having_142=max(has_142)
drop has_142 
drop if having_142 & tec_subid!=142 
drop x having_142

gduplicates t famid_docdb,gen(x)
tab x 
tab tec_subid if x>0 

* for duplicates, keep the smallest one 
bysort famid_docdb: gegen xtec=min(tec_subid)
drop if x>0 & tec_subid> xtec 
drop x xtec 
gdistinct famid_docdb


merge 1:m famid_docdb using famid_y02_2022a,nogen 
gsort famid_docdb

cap drop is_methan 
gen is_methan=(tec_subid!=.)
compress 
save famid_y02_2022a,replace 

import excel "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\code\CH4_search.xlsx", sheet("Sheet1") firstrow clear
drop tec_ipc 
drop if tec_id==.
replace tec_sub=proper(tec_sub)
order tec_id tec tec_subid tec_sub
sencode tec,replace 
sencode tec_sub,replace 
compress
save ch4_tec_labels,replace  

use famid_y02_2022a,clear 
// replace tec_subid =131 if tec_subid ==132
merge m:1 tec_subid using ch4_tec_labels
drop _mer 
order famid_docdb appln_id cpc tec_subid app_auth ctry_code ipr_type app_year app_date 

gen is_granted=(is_grant=="Y")
drop is_grant
ren is_granted is_grant

compress 
save,replace


*####################################
* Add subfields for fossil engergy  
*#################################### 
use famid_y02_2022a,clear 
keep if tec==2
keep famid_docdb
gduplicates drop
drop if famid_docdb==. 
export delimited using "ch4_fossil_famid.csv", replace


import delimited "ch4_fossil_abst.csv",encoding(UTF-8) clear 
* Do not combine 131 & 132 
format %39s appln_title
format %59s appln_abstract
gen titabst= lower(appln_title)+"||" + lower(appln_abstract)
keep if appln_title_lg=="en"|appln_abstract_lg=="en" 
keep famid_docdb titabst
gduplicates drop 
gsort famid_docdb
bysort famid: gen fam_dupQ=_N 
compress 
save temp,replace 


use famid_y02_2022a,clear 
keep if tec==2
keep famid_docdb cpc tec*
gduplicates drop 
joinby famid_docdb using temp

format %15.0g tec
format %27.0g tec_sub
format %49s titabst

*###############################
* Step1: Excluding false positive 
* Reclassifying to livestock 
// gdistinct famid_docdb if regexm(cpc,"Y02C  20/20")
//1,978  1,078

replace tec_subid= 114 if (regexm(titabst, "livestock")|regexm(titabst, "poultry")|regexm(titabst, "animal")|regexm(titabst, "husbandry")|regexm(titabst, "farm")|regexm(titabst, "manure")|regexm(titabst, "enteric")|regexm(titabst, "fermentat")|regexm(titabst, "rumen")|regexm(titabst, "ruminant")|regexm(titabst, "rumination")|regexm(titabst, "regurgitation")|regexm(titabst, "fowl")|regexm(titabst, "breeding")|regexm(titabst, "forag")|regexm(titabst, "cattle")|regexm(titabst, "beef")|regexm(titabst, "cow")|regexm(titabst, "bestial")|regexm(titabst, "goat")|regexm(titabst, "sheep")|regexm(titabst, "pig")|regexm(titabst, "chicken")|regexm(titabst, "horse")|regexm(titabst, "buck")|regexm(titabst, "goose")|regexm(titabst, "faec")|regexm(titabst, "excrement")|regexm(titabst, "excreta")) & regexm(cpc,"Y02C  20/20")

* Reclassifying to Biomass   Abandoned
// replace tec_subid= 142 if (regexm(titabst, "biomass")|regexm(titabst, "crop")|regexm(titabst, "straw")|regexm(titabst, "farm plant")) & regexm(cpc,"Y02C  20/20")


*###############################
* Step2: Reclassification  
replace tec_subid= 1311 if ((regexm(titabst,"coal") & (regexm(titabst,"mine")| regexm(titabst,"well")|regexm(titabst,"dress")))| regexm(titabst,"cmm")) & tec_subid==131
// "coal mine", "coal well", "coalbed methane", "coal mine methane", "CMM", "coal mine and low-concentration gas", "coal mine and ventilation gas", "coal min", "coal dress")

replace tec_subid= 1312 if ((regexm(titabst,"pneumatic device")|regexm(titabst,"pneumatic controller")|regexm(titabst,"pneumatic pump")|regexm(titabst,"electrical pump")|regexm(titabst, "valve")|regexm(titabst,"compressor seal")|regexm(titabst,"valve rod")|regexm(titabst, "electric motor")|regexm(titabst, "instrument air system")) & (regexm(titabst,"oil" )|regexm(titabst,"gas"))) & tec_subid==131

replace tec_subid= 1312 if (regexm(titabst,"vapour recovery unit")|regexm(titabst,"vrus")|regexm(titabst, "gas blowdown")|regexm(titabst, "blowdown")|regexm(titabst, "flar")|regexm(titabst, "plunger")|regexm(titabst,"liquid unload")) & tec_subid==131 

replace tec_subid= 1313 if ((regexm(titabst,"leak detection")|regexm(titabst,"ldar")|regexm(titabst, "infrared camera")|regexm(titabst,  "monitoring")|regexm(titabst, "detecting")|regexm(titabst, "sensor")) & (regexm(titabst,"oil")|regexm(titabst,"gas"))) & tec_subid==131  

replace tec_subid= 1314 if (regexm(titabst,"methane-reducing catalyst")|regexm(titabst,"methane reducing catalyst")|regexm(titabst,  "microturbine")|regexm(titabst,  "pipeline pump")|regexm(titabst,  "green completion")) & tec_subid==131
* pipeline pump-down? pipeline pump? 

replace tec_subid=153 if tec_subid==131 

replace tec_subid= 1321 if ((regexm(titabst,"coal") & (regexm(titabst,"mine")| regexm(titabst,"well")|regexm(titabst,"dress")))| regexm(titabst,"cmm")) & tec_subid==132
// "coal mine", "coal well", "coalbed methane", "coal mine methane", "CMM", "coal mine and low-concentration gas", "coal mine and ventilation gas", "coal min", "coal dress")

replace tec_subid= 1322 if ((regexm(titabst,"pneumatic device")|regexm(titabst,"pneumatic controller")|regexm(titabst,"pneumatic pump")|regexm(titabst,"electrical pump")|regexm(titabst, "valve")|regexm(titabst,"compressor seal")|regexm(titabst,"valve rod")|regexm(titabst, "electric motor")|regexm(titabst, "instrument air system")) & (regexm(titabst,"oil" )|regexm(titabst,"gas"))) & tec_subid==132


replace tec_subid= 1322 if (regexm(titabst,"vapour recovery unit")|regexm(titabst,"vrus")|regexm(titabst, "gas blowdown")|regexm(titabst, "blowdown")|regexm(titabst, "flar")|regexm(titabst, "plunger")|regexm(titabst,"liquid unload")) & tec_subid==132

replace tec_subid= 1323 if ((regexm(titabst,"leak detection")|regexm(titabst,"ldar")|regexm(titabst, "infrared camera")|regexm(titabst,  "monitoring")|regexm(titabst, "detecting")|regexm(titabst, "sensor")) & (regexm(titabst,"oil")|regexm(titabst,"gas"))) & tec_subid==132 

replace tec_subid= 1324 if (regexm(titabst,"methane-reducing catalyst")|regexm(titabst,"methane reducing catalyst")|regexm(titabst,  "microturbine")|regexm(titabst,  "pipeline pump")|regexm(titabst,  "green completion")) & tec_subid==132

tab tec_subid 
tab tec_subid if tec_subid >1300

gdistinct famid_docdb if regexm(cpc,"Y02E  20") 
gdistinct famid_docdb if tec_subid >1300 

replace tec_subid=. if tec_subid==132 
replace tec_subid=131 if tec_subid==1311|tec_subid==1321
replace tec_subid=132 if tec_subid==1312|tec_subid==1322
replace tec_subid=133 if tec_subid==1313|tec_subid==1323
replace tec_subid=134 if tec_subid==1314|tec_subid==1324

replace tec=1 if tec_subid==114
replace tec_id=11 if tec_subid==114
replace tec_sub=4 if tec_subid==114

replace tec=5 if tec_subid==153
replace tec_id=15 if tec_subid==153
replace tec_sub=19 if tec_subid==153

gdistinct famid_docdb if tec_subid==153


compress 
save fossil,replace 


use fossil,clear 
* Step 3: Excluding false positive like nuclear power, batteries, etc.  
drop if tec_subid==.
drop if tec_subid >130 & tec_subid <140 & (regexm(titabst, "unclear")|regexm(titabst,  "batter")|regexm(titabst,  "fuel cell")|regexm(titabst,  "energy storage")|regexm(titabst,  "power generation")|regexm(titabst,  "grid")|regexm(titabst,  "power plant"))

count if tec_subid ==153 & (regexm(titabst, "unclear")|regexm(titabst,  "batter")|regexm(titabst,  "fuel cell")|regexm(titabst,  "energy storage")|regexm(titabst,  "power generation")|regexm(titabst,  "grid")|regexm(titabst,  "power plant")) 

drop tec tec_sub tec_id

tab tec_subid,sort 
compress 
save fossil_v2,replace 


* Checking 
gdistinct famid_docdb if tec_subid!=113|tec_subid!=142
gdistinct famid_docdb if tec_subid >1300
count if regexm(cpc,"Y02E  20") & tec_subid==131
count if regexm(cpc,"Y02E  20/00")



use famid_y02_2022a,clear 
keep if tec==2
drop tec* 
gduplicates drop 
compress 
save temp1,replace 

use fossil_v2,clear
keep famid_docdb cpc tec_subid 
gduplicates drop 
merge m:1 famid_docdb cpc using temp1,nogen
merge m:1 tec_subid using ch4_tec_labels,nogen 
drop if famid_docdb==.
tab tec_sub,sort 
// ed if tec_sub==14| tec_sub==12
gdistinct famid_docdb
compress 
save temp1,replace 

use famid_y02_2022a,clear 
gdistinct famid_docdb
drop if tec==2
append using temp1
drop tec tec_id tec_sub
label drop tec_sub
label drop tec 
merge m:1 tec_subid using ch4_tec_labels, nogen 
gduplicates drop 
tab tec_sub,sort
gdistinct famid_docdb

* update is_methan 
cap drop is_methan 
gen is_methan=(tec_subid!=.)

compress 
save famid_y02_2022a,replace 

gdistinct famid_docdb if tec_subid==153


*#######################################
* update selected countries 
* Cleaning of country
use famid_y02_2022a,clear
replace ctry_code=app_auth if ctry_code=="" & app_auth!=""
replace ctry_code="GB" if ctry_code=="UK"
replace ctry_code="VG" if ctry_code=="VI"
replace ctry_code="TR" if ctry_code=="TK"

merge m:1 ctry_code using "F:\Dropbox\Github\Novelty_Patent\data\sc_patstat\2022a\pat_ctrycode.dta",keep(1 3)keepusing(isnot_ctry iso_alph3 st3_name)
gen is_ctry_select=(_mer==3 & isnot_ctry==0)
drop _mer isnot_ctry 

compress 
save famid_y02_2022a,replace 

*Note: There are 134 selected countries 
gdistinct ctry_code if tec_subid!=. & is_noA4S & ipr_type =="PI" & inrange(app_year,1990, 2019)  & is_ctry_select



*#################################
*     Statistics 
*#################################

* Step 2: SQL: Y02C  20/20 

* Step 3: 
* Step 3.1: 
* Step 3.2: fossil: Y02E + Keywords 

*####################################################
* Selection process 

/*
use famid_y02_2022a,clear 
keep if is_noA4S & ipr_type=="PI"
keep if inrange(app_year,1990, 2019)
keep famid_docdb tec* app_year fam_size is_methan
gduplicates drop 

gdistinct famid_docdb if is_methan

* 去重处理 
bysort famid_docdb : gen x1=_N
gen x2=(tec !=.)
bysort famid_docdb: gegen x3=max(x2)
drop if tec==. & x1>=2 & x3==1
drop x*
bysort famid_docdb : gen dup=_N
tab dup
gsort famid_docdb 

compress 
save famid_y02_2022a_V2,replace 


count if app_auth=="WO"|app_auth=="EP"
count if ctry_code=="WO"|ctry_code=="EP"

gdistinct famid_docdb if is_methan & app_auth=="WO"
gdistinct famid_docdb if is_methan & fam_size >1 
gdistinct famid_docdb if tec!=. & fam_size >1  & app_year==2019 
gdistinct famid_docdb if is_methan & fam_size >1  & app_year==2018

gdistinct famid_docdb if is_methan & fam_size >1  & app_year==2019 & app_auth!="WO"&  app_auth!="EP"   
gdistinct famid_docdb if is_methan & fam_size >1  & app_year==2019 & (ctry_code!="WO" &ctry_code!="EP") 
*/


*####################################################
*          Statistics 
*####################################################


*#############################
*     By tec
*#############################
* Only PI 

use famid_y02_2022a,clear 
keep if is_noA4S & ipr_type =="PI"  & inrange(app_year,1990, 2019)

drop cpc* appln_id app_date
gduplicates drop 

* Drop families both being a methane and non-methane patent 
bysort famid_docdb : gen x1=_N
gen x2=(tec !=.)
bysort famid_docdb: gegen x3=max(x2)
drop if tec==. & x1>=2 & x3==1
drop x*

* fractional counting  
bysort famid_docdb : gen x=_N
gen wgt=1/x
drop x 
gen is_hq=(fam_size>1)

drop is_noA4S

compress 
save famid_y02_2022a_V2,replace 


use famid_y02_2022a_V2,clear
keep if is_ctry_select
compress 
save famid_y02_2022a_V3,replace 

*####################################################
*    High Quality 
*####################################################
use famid_y02_2022a_V2,clear
keep if tec_sub !=. 
gsort app_year famid_docdb 

local pctiles 99.9 99 95 90	
foreach p in `pctiles' {
	local curlab = regexr("`p'","[^0-9]","")
	bysort app_year tec_sub: gegen top`curlab'=pctile(famdoc_cite_forwq ), p(`p')
	gen byte tmp=cond(famdoc_cite_forwq >=top`curlab',1,0)  
	drop top*
	bysort famid_docdb: gegen is_top`curlab'=max(tmp)
	drop tmp
}

ren is_hq is_hq_famsize
compress 

save methane_HQ,replace 

export delimited using "methane_HQ", replace
*####################################################
* Export 
use famid_y02_2022a_V2,clear
export delimited using "famid_y02_2022a_noA4S", replace

keep if tec_subid!=.
gduplicates drop 
format %37.0g tec_sub
format %35.0g tec
compress 
save ch4_base_famid_cpc,replace

export delimited using "ch4_base_famid_cpc.csv", replace


*####################################################

*##########################################
cap rm "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\indicator\stats_methane_V2.xlsx"

* All applications 
use famid_y02_2022a_V2,clear 
keep famid_docdb app_year is_hq 
gduplicates drop 
gcollapse (count)patQ=famid_docdb,by(app_year is_hq)
reshape wide patQ,i(app_year)j(is_hq)
gen pat_tot=patQ0+patQ1
gen hq_share=patQ1/pat_tot*100 
ren (patQ0 patQ1)(patQ_nohq patQ_hq)
export excel using "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\indicator\stats_methane_V2.xlsx",sheet("allpatQ") firstrow(variables)


*##################################
* Methane only
use famid_y02_2022a_V2,clear 
keep if is_methan 
keep famid_docdb app_year is_hq wgt 
gduplicates drop 
gcollapse (count)patQ=famid_docdb (sum)patQ_frac=wgt,by(app_year is_hq)
reshape wide patQ patQ_frac,i(app_year)j(is_hq)
gen pat_totQ=patQ0+patQ1
gen hq_share=patQ1/pat_totQ*100 
gen pat_totQ_frac = patQ_frac0+patQ_frac1 
gen hq_share_frac=patQ_frac1/pat_totQ_frac*100 
drop patQ0 patQ_frac0
ren (patQ1 patQ_frac1)(patQ_hq patQ_hq_frac)
order app_year pat_totQ patQ_hq hq_share pat_totQ_frac patQ_hq_frac 
export excel using "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\indicator\stats_methane_V2.xlsx", sheet("1ch4_year") sheetmodify firstrow(variables)


use famid_y02_2022a_V2,clear 
keep if is_methan 
keep famid_docdb tec app_year is_hq wgt 
gduplicates drop 
gcollapse (count)patQ=famid_docdb (sum)patQ_frac=wgt,by(app_year tec is_hq)
reshape wide patQ patQ_frac,i(app_year tec)j(is_hq)
gen pat_totQ=patQ0+patQ1
gen hq_share=patQ1/pat_totQ*100 
gen pat_totQ_frac = patQ_frac0+patQ_frac1 
gen hq_share_frac=patQ_frac1/pat_totQ_frac*100 
drop patQ0 patQ_frac0
ren (patQ1 patQ_frac1)(patQ_hq patQ_hq_frac)
order app_year tec pat_totQ patQ_hq hq_share pat_totQ_frac patQ_hq_frac 
gsort app_year tec 
export excel using "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\indicator\stats_methane_V2.xlsx", sheet("2ch4_tec") sheetmodify firstrow(variables)


use famid_y02_2022a_V2,clear 
keep if is_methan 
keep famid_docdb tec tec_sub app_year is_hq wgt 
gduplicates drop 
gcollapse (count)patQ=famid_docdb (sum)patQ_frac=wgt,by(app_year tec tec_sub is_hq)
reshape wide patQ patQ_frac,i(app_year tec tec_sub)j(is_hq)
gen pat_totQ=patQ0+patQ1
gen hq_share=patQ1/pat_totQ*100 
gen pat_totQ_frac = patQ_frac0+patQ_frac1 
gen hq_share_frac=patQ_frac1/pat_totQ_frac*100 
drop patQ0 patQ_frac0
ren (patQ1 patQ_frac1)(patQ_hq patQ_hq_frac)
order app_year tec tec_sub pat_totQ patQ_hq hq_share pat_totQ_frac patQ_hq_frac 
gsort app_year tec_sub 
export excel using "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\indicator\stats_methane_V2.xlsx", sheet("3ch4_tecsub") sheetmodify firstrow(variables)


use famid_y02_2022a_V2,clear 
keep if is_methan 
keep famid_docdb app_year ctry_code
gduplicates drop 
gcollapse (count)patQ=famid_docdb,by(app_year ctry_code)
export excel using "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\indicator\stats_methane_V2.xlsx", sheet("4ch4_ctry") sheetmodify firstrow(variables)

*##########################################
* Granted only 
* All applications 
use famid_y02_2022a_V2,clear 
keep if is_grant
keep famid_docdb app_year is_hq wgt 
gduplicates drop 
gcollapse (count)patQ=famid_docdb,by(app_year is_hq)
reshape wide patQ,i(app_year)j(is_hq)
gen pat_tot=patQ0+patQ1
gen hq_share=patQ1/pat_tot*100 
ren (patQ0 patQ1)(patQ_nohq patQ_hq)
export excel using "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\indicator\stats_methane_V2.xlsx",sheet("granted_allpatQ")sheetmodify firstrow(variables)

*##################################
* Methane only
use famid_y02_2022a_V2,clear 
keep if is_grant & is_methan 
keep famid_docdb app_year is_hq wgt 
gduplicates drop 
gcollapse (count)patQ=famid_docdb (sum)patQ_frac=wgt,by(app_year is_hq)
reshape wide patQ patQ_frac,i(app_year)j(is_hq)
gen pat_totQ=patQ0+patQ1
gen hq_share=patQ1/pat_totQ*100 
gen pat_totQ_frac = patQ_frac0+patQ_frac1 
gen hq_share_frac=patQ_frac1/pat_totQ_frac*100 
drop patQ0 patQ_frac0
ren (patQ1 patQ_frac1)(patQ_hq patQ_hq_frac)
order app_year pat_totQ patQ_hq hq_share pat_totQ_frac patQ_hq_frac 
export excel using "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\indicator\stats_methane_V2.xlsx", sheet("granted_1ch4_year") sheetmodify firstrow(variables)


use famid_y02_2022a_V2,clear 
keep if is_grant & is_methan 
keep famid_docdb tec app_year is_hq wgt 
gduplicates drop 
gcollapse (count)patQ=famid_docdb (sum)patQ_frac=wgt,by(app_year tec is_hq)
reshape wide patQ patQ_frac,i(app_year tec)j(is_hq)
gen pat_totQ=patQ0+patQ1
gen hq_share=patQ1/pat_totQ*100 
gen pat_totQ_frac = patQ_frac0+patQ_frac1 
gen hq_share_frac=patQ_frac1/pat_totQ_frac*100 
drop patQ0 patQ_frac0
ren (patQ1 patQ_frac1)(patQ_hq patQ_hq_frac)
order app_year tec pat_totQ patQ_hq hq_share pat_totQ_frac patQ_hq_frac 
gsort app_year tec 
export excel using "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\indicator\stats_methane_V2.xlsx", sheet("granted_2ch4_tec") sheetmodify firstrow(variables)


use famid_y02_2022a_V2,clear 
keep if is_grant & is_methan 
keep famid_docdb tec tec_sub app_year is_hq wgt 
gduplicates drop
gcollapse (count)patQ=famid_docdb (sum)patQ_frac=wgt,by(app_year tec tec_sub is_hq)
reshape wide patQ patQ_frac,i(app_year tec tec_sub)j(is_hq)
gen pat_totQ=patQ0+patQ1
gen hq_share=patQ1/pat_totQ*100 
gen pat_totQ_frac = patQ_frac0+patQ_frac1 
gen hq_share_frac=patQ_frac1/pat_totQ_frac*100 
drop patQ0 patQ_frac0
ren (patQ1 patQ_frac1)(patQ_hq patQ_hq_frac)
order app_year tec tec_sub pat_totQ patQ_hq hq_share pat_totQ_frac patQ_hq_frac 
gsort app_year tec_sub 
export excel using "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\indicator\stats_methane_V2.xlsx", sheet("granted_3ch4_tecsub") sheetmodify firstrow(variables)


use famid_y02_2022a_V2,clear 
keep if is_grant & is_methan 
keep famid_docdb app_year ctry_code  
gduplicates drop 
gcollapse (count)patQ=famid_docdb,by(app_year ctry_code)
export excel using "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\indicator\stats_methane_V2.xlsx", sheet("granted_4ch4_ctry") sheetmodify firstrow(variables)

shellout "F:\Dropbox\Yin-Collab\Jiang_Yin\Jiang_Mechane\indicator\stats_methane_V2.xlsx"



*############################################
*    Robust check: forward citation 
*############################################


// count if app_auth=="WO"|app_auth=="EP"
// count if is_methan & (app_auth=="WO"|app_auth=="EP")   
// count if is_methan & (ctry_code=="WO"|ctry_code=="EP")
// drop if app_auth=="WO"|app_auth=="EP" 
// drop if ctry_code=="WO"|ctry_code=="EP"

//keep famid_docdb tec app_year is_methan
gduplicates drop 
format %25.0g tec

bysort famid_docdb : gen x1=_N
gen x2=(tec !=.)
bysort famid_docdb: gegen x3=max(x2)
drop if tec==. & x1>=2 & x3==1
drop x*
bysort famid_docdb : gen dup=_N
tab dup
compress 



gen year_dmy="2005-2010" if  app_year>=2005 & app_year <=2010
replace year_dmy ="2011-2016" if app_year>=2011 & app_year <=2016
replace year_dmy ="2017-2019" if app_year>=2017 & app_year <=2019
replace year_dmy ="1980-2004" if app_year>=1980 & app_year <=2004
keep if year_dmy !="" 

drop app_year dup 
gduplicates drop 

gcollapse (count)patQ=famid_docdb,by(year_dmy tec is_methan)
gsort is_methan year_dmy 

 






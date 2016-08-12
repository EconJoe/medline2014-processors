
clear
set more off

**************************************************************************************************
**************************************************************************************************
* User must set the outpath and the inpath.
* The outpath should point to Data_Replication-->Processed-->Dates
* The inpath should point to Data_Replication-->Parsed-->Dates

global inpath="B:\Research\HITS\HITS1\TextReplication\TextReplication2\Data_Replication\Parsed\Dates"
global outpath="B:\Research\HITS\HITS1\TextReplication\TextReplication2\Data_Replication\Processed\Dates"
**************************************************************************************************


local startfile 1
local endfile 746

tempfile hold
gen filenum=.
save "`hold'", replace 

set more off
forvalues i=`startfile'/`endfile' {

	display in red "-------- Medline File: `i' out of `endfile' ---------"
	
	cd $inpath
	import delimited "medline14_`i'_dates.txt", clear varnames(1)

	gen medlinedateyear=""

	* Impute PubYear from MedlineDate
	replace medlinedateyear = regexs(1) if regexm(medlinedate, "^([0-9][0-9][0-9][0-9]) ") & medlinedateyear==""

	* Impute PubYear RANGE from MedlineDate
	replace medlinedateyear = regexs(1) if regexm(medlinedate, "^([0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9])") & medlinedateyear==""

	* Manual PubYear from MedlineDate cleanup
	replace medlinedateyear = "1948-1949" if medlinedate=="1948-49"
	replace medlinedateyear = "1963-1964" if medlinedate=="1963-4"
	replace medlinedateyear = "1964-1965" if medlinedate=="1964-5"
	replace medlinedateyear = "1970" if medlinedate=="1970Mar 25"
	replace medlinedateyear = "1972-1973" if medlinedate=="1972-3"
	replace medlinedateyear = "1976" if medlinedate=="1976(issued Feb 80)"
	replace medlinedateyear = "1975-1977" if medlinedate=="1975, 1977"
	replace medlinedateyear = "1977-1980" if medlinedate=="1977, reçu 1980"
	replace medlinedateyear = "1979-1980" if medlinedate=="1979, reçu 1980"
	replace medlinedateyear = "1981-1982" if medlinedate=="1981, reçu 1982"
	replace medlinedateyear = "1982-1983" if medlinedate=="1982-23"
	replace medlinedateyear = "1989" if medlinedate=="1989-89 Winter"
	replace medlinedateyear = "1992" if medlinedate=="1992-92"
	replace medlinedateyear = "1994" if medlinedate=="1994-94 Winter"
	replace medlinedateyear = "1995-1996" if medlinedate=="1995-96"
	replace medlinedateyear = "1996" if medlinedate=="1996-96"
	replace medlinedateyear = "1996-1997" if medlinedate=="1997-96"
	replace medlinedateyear = "1998-1999" if medlinedate=="1998-9"
	replace medlinedateyear = "1999-2000" if medlinedate=="1999-00"
	replace medlinedateyear = "1999-2000" if medlinedate=="1999-00 Winter"
	replace medlinedateyear = "2000" if medlinedate=="2000Jun 8-21"
	replace medlinedateyear = "2000-2001" if medlinedate=="2000-01"
	replace medlinedateyear = "2001-2002" if medlinedate=="2001-02"
	replace medlinedateyear = "2001-2003" if medlinedate=="2001-03"
	
	replace medlinedateyear="null" if medlinedateyear==""
	
	tostring pubyear articyear, replace
	
	gen medlinedateyear_imp=""
	replace medlinedateyear_imp=regexs(1) if regexm(medlinedateyear, "^([0-9][0-9][0-9][0-9])$")
	replace medlinedateyear_imp=regexs(1) if regexm(medlinedateyear, "^([0-9][0-9][0-9][0-9])-[0-9][0-9][0-9][0-9]$")

	destring medlinedateyear_imp pubyear articyear, force replace
	gen year=min(pubyear, articyear, medlinedateyear_imp)
	
	if (`i'!=746) { 
		qui tab year
		if (`r(N)'!=30000) {
			gen error="ERROR"
		}
	}
	
	compress
	cd $outpath
	save medline14_`i'_dates, replace
}



clear
gen filenum=.
tempfile hold
cd $outpath
save medline14_dates, replace

set more off
forvalues i=1/746 {

	display in red "------ File `i' -----"

	cd $outpath
	use medline14_`i'_dates, clear
	append using medline14_dates
	save medline14_dates, replace
}

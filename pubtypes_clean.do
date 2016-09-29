
clear
gen filenum=.
cd B:\Research\RAWDATA\MEDLINE\2014\Processed\PubTypes
save medline14_pubtypes_all, replace

local initialfiles 1 101 201 301 401 501 601 701
local terminalfile=746
local fileinc=99

clear
set more off
foreach h in `initialfiles' {

	local startfile=`h'
	local endfile=`startfile'+`fileinc'
	if (`endfile'>`terminalfile') {
		local endfile=`terminalfile'
	}
	clear
	gen filenum=.
	cd B:\Research\RAWDATA\MEDLINE\2014\Processed\PubTypes
	save medline14_pubtypes_`startfile'_`endfile', replace

	set more off
	forvalues i=`startfile'/`endfile' {

		display in red "---------- File `i' ----------"

		cd B:\Research\RAWDATA\MEDLINE\2014\Parsed\PubTypes
		import delimited "medline14_`i'_pubtypes.txt", clear delimiter(tab) varnames(1)
		keep filenum pmid version pubtype

		compress
		cd B:\Research\RAWDATA\MEDLINE\2014\Processed\PubTypes
		append using medline14_pubtypes_`startfile'_`endfile'
		save medline14_pubtypes_`startfile'_`endfile', replace
	}
	
	cd B:\Research\RAWDATA\MEDLINE\2014\Processed\PubTypes
	use medline14_pubtypes_all, clear
	append using medline14_pubtypes_`startfile'_`endfile'
	compress
	sort filenum pmid version pubtype
	save medline14_pubtypes_all, replace
	erase medline14_pubtypes_`startfile'_`endfile'.dta
}



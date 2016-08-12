
local startfile=1
local endfile=50

clear
set more off
forvalues i=`startfile'/`endfile' {

	display in red "------ File `i' --------"

	cd B:\Research\RAWDATA\MEDLINE\2014\Parsed\NGrams
	import delimited "medline14_`i'_ngrams.txt", clear delimiter(tab) varnames(1) bindquotes(nobind)
	
	compress
	cd B:\Research\RAWDATA\MEDLINE\2014\Parsed\NGrams\dtafiles
	save medline14_`i'_ngrams.dta, replace
}

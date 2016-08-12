clear
gen filenum=.
cd B:\Research\RAWDATA\MEDLINE\2014\Processed\NGrams\Vintage
save ngrams_vintage_3, replace

local initialfiles 1 26 51 76 101 126 151 176 201 226 251 276 301 326 351 376 401 426 451 476 501 526 551 576 601 626 651 676 701 726
local terminalfile=746
local fileinc=24

clear
set more off
foreach h in `initialfiles' {

	local startfile=`h'
	local endfile=`startfile'+`fileinc'
	if (`endfile'>`terminalfile') {
		local endfile=`terminalfile'
	}

	clear
	set more off
	gen ngram=""
	cd B:\Research\RAWDATA\MEDLINE\2014\Processed\NGrams\Vintage
	save ngrams_vintage_`startfile'_`endfile'_3, replace

	forvalues i=`startfile'/`endfile' {

		display in red "------ File `i' --------"

		cd B:\Research\RAWDATA\MEDLINE\2014\Parsed\NGrams\dtafiles
		use medline14_`i'_ngrams, clear
		keep if status=="MEDLINE"
		keep if version==1
		keep pmid ngram
		tempfile hold
		save `hold', replace

		cd B:\Research\RAWDATA\MEDLINE\2014\Processed
		use medline_wos_intersection if filenum==`i'
		merge 1:m pmid using `hold'
		keep if _merge==3
		drop if meshid4_ind==0
		drop if retraction_ind==1
		keep pmid ngram pubyear
		rename pubyear vintage

		if (_N>0) {
			collapse (min) vintage, by(ngram)
			compress
			cd B:\Research\RAWDATA\MEDLINE\2014\Processed\NGrams\Vintage
			append using ngrams_vintage_`startfile'_`endfile'_3
			collapse (min) vintage, by(ngram)
			save ngrams_vintage_`startfile'_`endfile'_3, replace
		}
	}

	cd B:\Research\RAWDATA\MEDLINE\2014\Processed\NGrams\Vintage
	use ngrams_vintage_3, clear
	append using ngrams_vintage_`startfile'_`endfile'_3
	collapse (min) vintage, by(ngram)
	compress
	sort ngram
	save ngrams_vintage_3, replace
	*erase ngrams_vintage_`startfile'_`endfile'.dta
}

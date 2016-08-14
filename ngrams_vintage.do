
**************************************************************************************************
**************************************************************************************************
* User must set the outpath and the inpath.
global inpath1="B:\Research\RAWDATA\MEDLINE\2014\Parsed\NGrams\dtafiles"
global inpath2="B:\Research\RAWDATA\MEDLINE\2014\Processed"
global outpath="B:\Research\RAWDATA\MEDLINE\2014\Processed"
**************************************************************************************************

clear
gen ngram=""
gen vintage=.
cd $outpath
save ngrams_vintage, replace

local initialfiles 1 26 76 101 126 176 201 226 251 276 301 326 351 376 401 426 451 476 501 526 551 576 601 626 651 676 701 726
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
	cd $outpath
	save ngrams_vintage_`startfile'_`endfile', replace

	forvalues i=`startfile'/`endfile' {

		display in red "------ File `i' --------"

		cd $inpath1
		use medline14_`i'_ngrams, clear
		keep if status=="MEDLINE"
		keep if version==1
		keep pmid ngram
		tempfile hold
		save `hold', replace

		cd $inpath2
		use medline_wos_intersection if filenum==`i'
		merge 1:m pmid using `hold'
		keep if _merge==3
		keep pmid pubyear ngram
		rename pubyear vintage

		if (_N>0) {
			collapse (min) vintage, by(pmid ngram) fast
			
			compress
			cd $outpath
			append using ngrams_vintage_`startfile'_`endfile'
			collapse (min) vintage, by(ngram) fast
			save ngrams_vintage_`startfile'_`endfile', replace
		}
	}
	
	cd $outpath
	use ngrams_vintage_`startfile'_`endfile', clear
	if (_N>0) {
		cd $outpath
		use ngrams_vintage, clear
		append using ngrams_vintage_`startfile'_`endfile'
		collapse (min) vintage, by(ngram) fast
		compress
		sort ngram
		save ngrams_vintage, replace
	}
	erase ngrams_vintage_`startfile'_`endfile'.dta
}

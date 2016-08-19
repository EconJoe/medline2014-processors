
* This dofile computes the total number of times that each n-gram in the MEDLINE-WOS corpus is mentioned.

**************************************************************************************************
**************************************************************************************************
* User must set the outpath and the inpath.
global inpath1="B:\Research\RAWDATA\MEDLINE\2014\Parsed\NGrams\dtafiles"
global inpath2="B:\Research\RAWDATA\MEDLINE\2014\Processed"
global outpath="B:\Research\RAWDATA\MEDLINE\2014\Processed"
**************************************************************************************************

clear
gen ngram=""
gen mentions_wi=.
gen mentions_bt=.
cd $outpath
save ngrams_mentions, replace

* Break the files that we work with into multiples of 50. This prevents RAM from being exhausted.
local initialfiles 1 26 51 76 101 151 126 176 201 226 251 276 301 326 351 376 401 426 451 476 501 526 551 576 601 626 651 676 701 726
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
	save ngrams_mentions_`startfile'_`endfile', replace

	forvalues i=`startfile'/`endfile' {

		display in red "------ File `i' --------"

		cd $inpath1
		use medline14_`i'_ngrams, clear
		keep if status=="MEDLINE"
		keep if version==1
		keep pmid ngram
		tempfile hold
		save `hold', replace
		
		* Only keep the intersection with WOS
		cd $inpath2
		use medline_wos_intersection if filenum==`i'
		merge 1:m pmid using `hold'
		keep if _merge==3
		keep pmid ngram

		if (_N>0) {
		
			* Compute the number of "within" mentions. These are mentions that include multiple mentions within the same article.
			gen mentions_wi=1
			collapse (sum) mentions_wi, by(pmid ngram) fast
			
			* Compute the number of "between" mentions. These are mentions that only count at most one mention per article.
			gen mentions_bt=1
			collapse (sum) mentions_wi mentions_bt, by(ngram) fast

			compress
			cd $outpath
			append using ngrams_mentions_`startfile'_`endfile'
			collapse (sum) mentions_wi mentions_bt, by(ngram) fast
			save ngrams_mentions_`startfile'_`endfile', replace
		}
	}
	
	cd $outpath
	use ngrams_mentions_`startfile'_`endfile', clear
	if (_N>0) {
		cd $outpath
		use ngrams_mentions, clear
		append using ngrams_mentions_`startfile'_`endfile'
		collapse (sum) mentions_wi mentions_bt, by(ngram) fast
		compress
		sort ngram
		save ngrams_mentions, replace
	}
	erase ngrams_mentions_`startfile'_`endfile'.dta
}

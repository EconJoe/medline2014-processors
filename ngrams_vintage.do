
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
cd $outpath
save ngrams_vintage, replace

* Break the files that we work with into multiples of 25. This prevents RAM from being exhausted.
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
	cd $outpath
	save ngrams_vintage_`startfile'_`endfile', replace

	forvalues i=`startfile'/`endfile' {

		display in red "------ File `i' --------"
		
		clear
		gen ngram=""
		cd $outpath
		save ngrams_vintage_`i', replace
		
		* Compute mentions for all articles (No restrictions)
		cd $inpath1
		use medline14_`i'_ngrams, clear
		cd $inpath2
		merge m:1 pmid version using medline14_dates_clean
		drop if _merge==2
		drop _merge
		compress
		cd $outpath
		save ngrams_vintage_`i'_temp, replace
		
		rename year vintage
		* Keep only first version to avoid double coutning. This affects very few articles.
		keep if version==1
		* Drop if there was no n-gram
		drop if dim=="null"
		
		if (_N>0) {
		
			collapse (min) vintage, by(ngram) fast
			compress
			cd $outpath
			save ngrams_vintage_`i', replace
		}
		
		* Compute mentions restricted to status=="MEDLINE" articles
		cd $outpath
		use ngrams_vintage_`i'_temp, clear
		
		rename year vintage_med
		* Keep only first version to avoid double coutning. This affects very few articles.
		keep if version==1
		* Drop if there was no n-gram
		drop if dim=="null"
		keep if status=="MEDLINE"
		
		if (_N>0) {
		
			collapse (min) vintage_med, by(ngram) fast
			compress

			if (_N>0) {
				cd $outpath
				merge 1:1 ngram using ngrams_vintage_`i'
				drop _merge
				
				compress
				cd $outpath
				save ngrams_vintage_`i', replace
			}
		}
		
		* Compute mentions restricted to status=="MEDLINE" articles also contained in WOS (MEDLINE-WOS intersection)
		cd $outpath
		use ngrams_vintage_`i'_temp, clear
		
		rename year vintage_medwos
		* Keep only first version to avoid double coutning. This affects very few articles.
		keep if version==1
		* Drop if there was no n-gram--THIS IS DIFFERENT THAN PREVIOUS CODE--HELPS DISTINGUISH BETWEEN THE N-GRAM "null" and null (missing) values.
		drop if dim=="null"
		keep if status=="MEDLINE"
		tempfile hold
		save `hold', replace
		
		* Only keep the intersection with WOS
		cd $inpath2
		display in red "--- MEDLINE-WOS MERGE ----"
		use medline_wos_intersection if filenum==`i'
		merge 1:m pmid using `hold'
		keep if _merge==3
		rename pubyear vintagepy_medwos
		keep pmid ngram vintage_medwos vintagepy_medwos
		
		if (_N>0) {

			collapse (min) vintage_medwos vintagepy_medwos, by(ngram) fast
			compress
			
			if (_N>0) {
				cd $outpath
				merge 1:1 ngram using ngrams_vintage_`i'
				drop _merge

				compress
				save ngrams_vintage_`i', replace
			}
				
		}
		
		cd $outpath
		use ngrams_vintage_`i', clear
		append using ngrams_vintage_`startfile'_`endfile'
		collapse (min) vintage*, by(ngram) fast
		save ngrams_vintage_`startfile'_`endfile', replace
		erase ngrams_vintage_`i'.dta
		erase  ngrams_vintage_`i'_temp.dta
	}
		
	cd $outpath
	use ngrams_vintage_`startfile'_`endfile', clear
	if (_N>0) {
		cd $outpath
		append using ngrams_vintage
		collapse (min) vintage*, by(ngram) fast
		compress
		sort ngram
		save ngrams_vintage, replace
	}
	erase ngrams_vintage_`startfile'_`endfile'.dta
}




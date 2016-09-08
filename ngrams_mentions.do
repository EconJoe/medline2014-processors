
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
	save ngrams_mentions_`startfile'_`endfile', replace

	forvalues i=`startfile'/`endfile' {

		display in red "------ File `i' --------"
		
		clear
		gen ngram=""
		cd $outpath
		save ngrams_mentions_`i', replace
		
		* Compute mentions for all articles (No restrictions)
		cd $inpath1
		use medline14_`i'_ngrams, clear
		* I used to keep only the first version of each article (i.e. version==1). This resulted in some n-grams being eliminated because they
		*   were used in a version after 1, but not in 1 itself.
		* Drop if there was no n-gram.
		* Note that this step if different from previous versions of this code. In previous versions "null" values were treated as just another n-gram.
		* This is incorrect, though it only affects the "null" n-gram counts.
		drop if dim=="null"
		
		if (_N>0) {
		
			* Compute the number of "within" mentions. These are mentions that include multiple mentions within the same article.
			gen mentions_wi=1
			collapse (sum) mentions_wi, by(pmid ngram) fast
			
			* Compute the number of "between" mentions. These are mentions that only count at most one mention per article.
			gen mentions_bt=1
			collapse (sum) mentions_wi mentions_bt, by(ngram) fast

			compress
			cd $outpath
			save ngrams_mentions_`i', replace
		}
		
		* Compute mentions restricted to status=="MEDLINE" articles
		cd $inpath1
		use medline14_`i'_ngrams, clear
		* Drop if there was no n-gram
		drop if dim=="null"
		keep if status=="MEDLINE"
		
		if (_N>0) {
		
			* Compute the number of "within" mentions. These are mentions that include multiple mentions within the same article.
			gen mentions_wi_med=1
			collapse (sum) mentions_wi_med, by(pmid ngram) fast
			
			* Compute the number of "between" mentions. These are mentions that only count at most one mention per article.
			gen mentions_bt_med=1
			collapse (sum) mentions_wi_med mentions_bt_med, by(ngram) fast
			
			if (_N>0) {
				cd $outpath
				merge 1:1 ngram using ngrams_mentions_`i'
				drop _merge
				
				compress
				cd $outpath
				save ngrams_mentions_`i', replace
			}
		}
		
		* Compute mentions restricted to status=="MEDLINE" articles also contained in WOS (MEDLINE-WOS intersection)
		cd $inpath1
		use medline14_`i'_ngrams, clear

		* Drop if there was no n-gram--THIS IS DIFFERENT THAN PREVIOUS CODE--HELPS DISTINGUISH BETWEEN THE N-GRAM "null" and null (missing) values.
		drop if dim=="null"
		keep if status=="MEDLINE"
		tempfile hold
		save `hold', replace
		* I used to keep only the first version of each article (i.e. version==1). This resulted in some n-grams being eliminated because they
		*   were used in a version after 1, but not in 1 itself.
		* Only keep the intersection with WOS
		cd $inpath2
		display in red "--- MEDLINE-WOS MERGE ----"
		use medline_wos_intersection if filenum==`i'
		merge 1:m pmid using `hold'
		keep if _merge==3
		keep pmid ngram
		
		if (_N>0) {
		
			* Compute the number of "within" mentions. These are mentions that include multiple mentions within the same article.
			gen mentions_wi_medwos=1
			collapse (sum) mentions_wi_medwos, by(pmid ngram) fast
			
			* Compute the number of "between" mentions. These are mentions that only count at most one mention per article.
			gen mentions_bt_medwos=1
			collapse (sum) mentions_wi_medwos mentions_bt_medwos, by(ngram) fast
			
			if (_N>0) {
				cd $outpath
				merge 1:1 ngram using ngrams_mentions_`i'
				drop _merge

				compress
				save ngrams_mentions_`i', replace
			}
				
		}
		
		cd $outpath
		use ngrams_mentions_`i', clear
		append using ngrams_mentions_`startfile'_`endfile'
		collapse (sum) mentions_*, by(ngram) fast
		save ngrams_mentions_`startfile'_`endfile', replace
		erase ngrams_mentions_`i'.dta
	}
		
	cd $outpath
	use ngrams_mentions_`startfile'_`endfile', clear
	if (_N>0) {
		cd $outpath
		use ngrams_mentions, clear
		append using ngrams_mentions_`startfile'_`endfile'
		collapse (sum) mentions_*, by(ngram) fast
		compress
		sort ngram
		save ngrams_mentions, replace
	}
	erase ngrams_mentions_`startfile'_`endfile'.dta
}


* This dofile identifies the vintage of every n-gram in the MEDLINE-WOS corpus
* Vintage is defined as the publication year of the first article in the MEDLINE-WOS corpus that uses the n-gram.


**************************************************************************************************
**************************************************************************************************
* User must set the outpath and the inpath.
global inpath="B:\Research\RAWDATA\MEDLINE\2014\Parsed\NGrams\dtafiles"
global outpath="B:\Research\RAWDATA\MEDLINE\2014\Processed"
**************************************************************************************************

clear
gen ngram=""
cd $outpath
save ngrams_id, replace

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
	save ngrams_id_`startfile'_`endfile', replace

	forvalues i=`startfile'/`endfile' {

		display in red "------ File `i' --------"

		cd $inpath
		use medline14_`i'_ngrams, clear
		keep ngram
		duplicates drop
		
		cd $outpath
		append using ngrams_id_`startfile'_`endfile'
		duplicates drop
		compress
		sort ngram
		save ngrams_id_`startfile'_`endfile', replace
	}
	
	cd $outpath
	append using ngrams_id
	duplicates drop
	save ngrams_id, replace
	erase ngrams_id_`startfile'_`endfile'.dta
}

sort ngram
gen double ngramid=_n
order ngramid ngram
compress
save ngrams_id, replace




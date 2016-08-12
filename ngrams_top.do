


clear
cd B:\Research\RAWDATA\MEDLINE\2014\Processed\NGrams\Mentions
use ngrams_mentions_3, replace

cd B:\Research\RAWDATA\MEDLINE\2014\Processed\NGrams\Vintage
merge 1:1 ngram using ngrams_vintage_3
drop _merge

gsort vintage -mentions_bt ngram
by vintage, sort: gen rank_=_n
by vintage mentions_bt, sort: egen rank=min(rank_)
gsort vintage -mentions_bt ngram
by vintage, sort: gen total=_N
gen pct=rank/total
gen top_001=0
replace top_001=1 if pct<0.001
gen top_0001=0
replace top_0001=1 if pct<0.0001

keep if top_001==1

* Give each ngram a numeric identifier. This dramatically decreases storage requirements
sort vintage ngram
gen double ngramid=_n
order ngramid ngram

compress
cd B:\Research\RAWDATA\MEDLINE\2014\Processed\NGrams\Top
save ngrams_top_3, replace




************************************************************************************
*************************************************************************************

************************************************************************************
*************************************************************************************
clear
gen filenum=.
cd B:\Research\RAWDATA\MEDLINE\2014\Processed\NGrams\Top
save ngrams_top_pmids_001_3, replace

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
	set more off
	gen ngramid=.
	cd B:\Research\RAWDATA\MEDLINE\2014\Processed\NGrams\Top
	save ngrams_top_pmids_001_`startfile'_`endfile'_3, replace

	cd B:\Research\RAWDATA\MEDLINE\2014\Processed\NGrams\Top
	use ngrams_top_3, clear
	keep if top_001==1
	keep ngram ngramid vintage
	tempfile hold1
	save `hold1', replace

	forvalues i=`startfile'/`endfile' {

		display in red "------ File `i' --------"

		cd B:\Research\RAWDATA\MEDLINE\2014\Parsed\NGrams\dtafiles
		use medline14_`i'_ngrams, clear
		keep if status=="MEDLINE"
		keep if version==1
		merge m:1 ngram using `hold1'
		keep if _merge==3
		drop _merge
		keep filenum pmid version ngramid vintage
		tempfile hold2
		save `hold2', replace
		
		cd B:\Research\RAWDATA\MEDLINE\2014\Processed
		use medline_wos_intersection if filenum==`i'
		merge 1:m pmid using `hold2'
		keep if _merge==3
		drop if meshid4_ind==0
		drop if retraction_ind==1
		keep filenum pmid pubyear year version ngramid vintage ngram
		
		if (_N>0) {
			compress
			duplicates drop

			cd B:\Research\RAWDATA\MEDLINE\2014\Processed\NGrams\Top
			append using ngrams_top_pmids_001_`startfile'_`endfile'_3
			save ngrams_top_pmids_001_`startfile'_`endfile'_3, replace
		}
	}
	
	cd B:\Research\RAWDATA\MEDLINE\2014\Processed\NGrams\Top
	use ngrams_top_pmids_001_3, clear
	append using ngrams_top_pmids_001_`startfile'_`endfile'_3
	compress
	sort ngram
	save ngrams_top_pmids_001_3, replace
	*erase ngrams_top_pmids_001_`startfile'_`endfile'.dta
}

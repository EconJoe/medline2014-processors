
clear

set more off
forvalues i=1/746 {

	display in red "------ File `i' ------"
	
	cd B:\Research\RAWDATA\MeSH\2014\Parsed
	import delimited using "desc2014_meshtreenumbers.txt", clear delimiter(tab) varnames(1)
	* The only MeSH terms without a tree number are "Male" and "Female". Thus, we just assign the MeSH terms as the tree number. 
	replace treenumber="Male" if mesh=="Male"
	replace treenumber="Female" if mesh=="Female"
	tempfile hold
	save `hold', replace
	
	* Eliminate articles that are retractions of other articles. These have no MeSH terms.
	cd B:\Research\RAWDATA\MEDLINE\2014\Parsed\PubTypes
	import delimited using "medline14_`i'_pubtypes.txt", clear delimiter(tab) varnames(1)
	keep if status=="MEDLINE"
	keep if pubtype=="Retraction of Publication"
	keep pmid version
	tempfile retraction
	save `retraction', replace

	cd B:\Research\RAWDATA\MEDLINE\2014\Parsed\MeSH
	import delimited using "medline14_`i'_mesh.txt", clear delimiter(tab) varnames(1)
	merge m:1 pmid version using `retraction'
	drop if _merge==3
	drop _merge
	
	keep if status=="MEDLINE"

	if (_N>0) {
		* Keep only "Descriptor" MeSH terms. Eliminate "Qualifiers"
		drop if type=="Qualifier"
		
		*keep pmid version mesh
		* Observations in the master file are uniquely identified by a pmid, version and MeSH term
		* Observations in the using file are uniquely identified by a MeSH term and tree number
		* We want to generate all treenumbers with which each article is associated
		joinby mesh using `hold', unmatched(master)
		drop _merge
		
		* When _merge==1, the MEDLINE article has no MeSH terms to match on. That is, the MeSH column has a value of "null" for this article.
		* Most of these articles have status "PubMed-not-Medline" articles and so haven't been indexed. 
		* However, some have statuss "MEDLINE", but still have "null" values. These are typically retractions.	
		
		* Transform all tree numbers into their 4-digit equivalents
		gen _4digit=regexs(1) if regexm(treenumber, "([A-Z][0-9][0-9]\.[0-9][0-9][0-9]\.[0-9][0-9][0-9])")
		drop if _4digit==""
		
		gen count=1
		by pmid mesh, sort: egen total=total(count)
		gen withinmesh_weight=count/total
		
		drop treenumber
		rename _4digit treenumber
		rename mesh mesh_raw
		rename meshid meshid_raw
		* Attach the MeSH names/ID of the 4-digit tree branches
		merge m:1 treenumber using `hold'
		drop if _merge==2
		drop _merge
		
		by pmid, sort: egen acrossmesh_weight=total(withinmesh_weight)
		gen weight_=withinmesh_weight/acrossmesh_weight
		by pmid mesh, sort: egen weight=total(weight_)
		keep filenum owner status versionid versiondate pmid version meshid mesh weight
		duplicates drop

		sort filenum pmid version meshid
		order filenum owner status versionid versiondate pmid version weight
		
		rename mesh mesh4
		rename meshid meshid4
		rename weight mesh4_weight
	}

	compress
	cd B:\Research\RAWDATA\MEDLINE\2014\Processed\MeSHAgg
	save medline14_`i'_mesh_4digit, replace
}




clear
gen filenum=.
cd B:\Research\RAWDATA\MEDLINE\2014\Processed\MeSHAgg
save medline14_mesh_4digit_2, replace

local initialfiles 1 51 101 151 201 251 301 351 401 451 501 551 601 651 701
local terminalfile=746
local fileinc=49

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
	tempfile hold
	cd B:\Research\RAWDATA\MEDLINE\2014\Processed\MeSHAgg
	save medline14_mesh_`startfile'_`endfile'_4digit_2, replace

	set more off
	forvalues i=`startfile'/`endfile' {

		display in red "------ File `i' -----"

		cd B:\Research\RAWDATA\MEDLINE\2014\Processed\MeSHAgg
		use medline14_`i'_mesh_4digit, clear
		if (_N>0) {
			keep filenum pmid version weight meshid4
			append using medline14_mesh_`startfile'_`endfile'_4digit_2
			save medline14_mesh_`startfile'_`endfile'_4digit_2, replace
		}
	}
	compress
	cd B:\Research\RAWDATA\MEDLINE\2014\Processed\MeSHAgg
	save medline14_mesh_`startfile'_`endfile'_4digit_2, replace
	
	cd B:\Research\RAWDATA\MEDLINE\2014\Processed\MeSHAgg
	use medline14_mesh_4digit_2, clear
	append using medline14_mesh_`startfile'_`endfile'_4digit_2
	compress
	sort filenum pmid version meshid4
	save medline14_mesh_4digit_2, replace
	*erase medline14_mesh_`startfile'_`endfile'_4digit.dta
}




cd B:\Research\RAWDATA\MEDLINE\2014\Processed\MeSHAgg
use medline14_mesh_1_100_4digit
append using medline14_mesh_101_150_4digit
append using medline14_mesh_151_200_4digit
append using medline14_mesh_201_250_4digit
append using medline14_mesh_251_300_4digit
append using medline14_mesh_301_350_4digit
append using medline14_mesh_351_400_4digit
append using medline14_mesh_401_450_4digit
append using medline14_mesh_451_500_4digit
append using medline14_mesh_501_550_4digit
append using medline14_mesh_551_600_4digit
append using medline14_mesh_601_650_4digit
append using medline14_mesh_651_700_4digit
append using medline14_mesh_701_746_4digit

sort filenum pmid version meshid4

compress
save medline14_mesh_4digit, replace












clear
set more off

**************************************************************************************************
**************************************************************************************************
* User must set the outpath and the inpath.
global inpath1="B:\Research\RAWDATA\MEDLINE\2014\Parsed"
global inpath2="B:\Research\RAWDATA\MeSH\2014\Parsed"
global outpath="B:\Research\RAWDATA\MEDLINE\2014\Processed"

**************************************************************************************************

**************************************************
cd $inpath1\MeSH
import delimited "medline14_mesh.txt", clear delimiter(tab) varnames(1)
* Keep only articles that are actually tagged with a raw MeSH term
drop if mesh=="null"
* Keep only "Descriptor" MeSH terms. Eliminate "Qualifiers"
drop if type=="Qualifier"
keep filenum pmid version mesh
sort pmid version
compress
cd $outpath\Data
save medline14_mesh_clean, replace
**************************************************

**************************************************
clear
* Create temp file to eliminate "Retraction of Publication Articles" and articles that do not have "MEDLINE" status
cd $inpath1\PubTypes
import delimited "medline14_pubtypes.txt", clear delimiter(tab) varnames(1)
keep if pubtype=="Retraction of Publication"
keep pmid version
tempfile elim
save `elim', replace
cd $inpath1\Header
import delimited "medline14_header.txt", clear delimiter(tab) varnames(1)
drop if status=="MEDLINE"
keep pmid version
append using `elim'
duplicates drop
sort pmid version
save `elim', replace
**************************************************

**************************************************
cd $inpath2
import delimited using "desc2014_meshtreenumbers.txt", clear delimiter(tab) varnames(1)
* The only MeSH terms without a tree number are "Male" and "Female". Thus, we just assign the MeSH terms as the tree number. 
replace treenumber="Male" if mesh=="Male"
replace treenumber="Female" if mesh=="Female"
tempfile mesh
save `mesh', replace
**************************************************

**************************************************
* Create a temporary file to hold the aggregated MeSH terms. This will be deleted in the end.
clear
gen filenum=.
cd $outpath\Data
save medline14_mesh_clean_temp, replace
**************************************************

local startfile=1
local endfile=746
local increment=100

set more off
forvalues i=`startfile'(`increment')`endfile' {
	
	local file1=`i'
	local file2=`i'+`increment'-1
	
	display in red "------- Aggregating MeSH terms from MEDLINE files `file1'-`file2' -----"
	
	cd $outpath\Data
	use medline14_mesh_clean if filenum>=`file1' & filenum<=`file2', clear
	
	* Eliminate retractions and non-MEDLINE status articles
	merge m:1 pmid version using `elim'
	keep if _merge==1
	drop _merge
	
	*keep pmid version mesh
	* Observations in the master file are uniquely identified by a pmid, version and MeSH term
	* Observations in the using file are uniquely identified by a MeSH term and tree number
	* We want to generate all treenumbers with which each article is associated
	joinby mesh using `mesh', unmatched(master)
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
	merge m:1 treenumber using `mesh'
	drop if _merge==2
	drop _merge
	
	by pmid, sort: egen acrossmesh_weight=total(withinmesh_weight)
	gen weight_=withinmesh_weight/acrossmesh_weight
	by pmid mesh, sort: egen weight=total(weight_)
	keep filenum pmid version meshid mesh weight
	duplicates drop
	
	sort filenum pmid version meshid
	order filenum pmid version weight
	
	drop mesh
	rename meshid meshid4
	rename weight mesh4_weight
	
	cd $outpath\Data
	append using medline14_mesh_clean_temp
	save medline14_mesh_clean_temp, replace
}

sort filenum pmid version meshid4
compress
cd $outpath\Data
save medline14_mesh_clean, replace
erase medline14_mesh_clean_temp.dta
********************************************************************************************************************

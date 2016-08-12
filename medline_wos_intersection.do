
********************************************************************************
********************************************************************************
* Eligible MEDLINE articles
*   * status=="MEDLINE"
*   * version==1
*   * Not a retraction
*   * Has a 4-digit MeSH term
*   * Year between 1983 and 2012

* The meshagg dofile ensures that all articles have status=="MEDLINE" and are not a retraction notice

* Import columns 1 through 3 of the wos_summary.csv file. 
*   The first column gives the wos_uid, which uniquely identifies articles in WOS
*   The second column gives the publication year
*cd path to WOS data
import delimited "wos_summary.csv", clear delimiter(comma) varnames(1) colrange(1:3)
keep wos_uid pubyear
drop if regex(wos_uid, "(15085762 rows)")
compress
tempfile hold
save `hold', replace

* Import the wod_medline_bridge.csv file
*   The first column is an internal ID created by Huifeng
*   The second column is the PMID
*   The third column gives the wos_uid, which uniquely identifies articles in WOS*
*cd path to WOS data
import delimited "wos_medline_bridge.csv", clear delimiter(comma) varnames(1)
drop if regex(id, "(15085943 rows)")
destring id, replace
merge 1:1 wos_uid using `hold'
* For some reason, there are 181 observations from the wos_medline_bridge.csv that are not contained
*   in the wos_summary file. This means that we do not have a publication date for these articles.
*   We opt to drop them.
drop if _merge==1
drop _merge
* Since we only need the PMID to merge with MEDLINE and obtain the WOS-MEDLINE intersection, we
*   keep only the PMID and the pubilcation year. Thus, we drop th wos_uid. Since the same PMID
*   can be matched to multiple wos_uid, we drop the duplicates by taking the minimum of the publication
*   year.
keep pmid pubyear
by pmid, sort: egen minpubyear=min(pubyear)
keep if pubyear==minpubyear
keep pmid pubyear
duplicates drop
tempfile hold
save `hold', replace

save temp, replace

*cd path to WOS data
use temp, clear
tempfile hold
save `hold', replace

cd B:\Research\RAWDATA\MEDLINE\2014\Processed\Dates
use medline14_dates, clear
keep if version==1
keep filenum pmid year
merge 1:1 pmid using `hold'
* There are 7,875,894 articles in MEDLINE that are not in the WOS file
drop if _merge==1
* There are 579,311 articles in the WOS file that are not in MEDLINE
drop if _merge==2
drop _merge
save `hold', replace

* Attach only articles with 4-digit MeSH terms
cd B:\Research\RAWDATA\MEDLINE\2014\Processed\MeSHAgg
use medline14_mesh_4digit, clear
keep if version==1
keep version pmid
duplicates drop
merge 1:1 pmid using `hold'
drop if _merge==1
gen meshid4_ind=0
replace meshid4_ind=1 if _merge==3
drop _merge
tempfile hold
save `hold', replace

cd B:\Research\RAWDATA\MEDLINE\2014\Processed\PubTypes
use medline14_pubtypes_all, clear
keep if pubtype=="Retraction of Publication"
keep pmid
merge 1:1 pmid using `hold'
drop if _merge==1
gen retraction_ind=0
replace retraction_ind=1 if _merge==3
drop _merge

drop version
order filenum pmid pubyear
sort filenum pmid
compress
cd B:\Research\RAWDATA\MEDLINE\2014\Processed
save medline_wos_intersection, replace
********************************************************************************

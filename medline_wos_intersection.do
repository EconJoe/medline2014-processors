
clear
set more off

**************************************************************************************************
**************************************************************************************************
* User must set the outpath and the inpath.
global inpath1="Path to WOS data"
global inpath2="B:\Research\RAWDATA\MEDLINE\2014\Processed"
global outpath="B:\Research\RAWDATA\MEDLINE\2014\Processed"
**************************************************************************************************

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
cd $inpath1
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
cd $inpath1
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

*Note that the following restrictions have already been put in place in the mesh_aggregation file:
*   * status=="MEDLINE"
*   * Not a retraction
*   * Has a 4-digit MeSH term

cd $inpath2
use medline14_mesh_clean, clear
keep filenum pmid
duplicates drop

merge 1:1 pmid using `hold'
tab _merge
keep if _merge==3
drop _merge
keep if pubyear>=1983 & pubyear<=2012

sort filenum pmid pubyear
compress
cd $outpath
save medline_wos_intersection, replace





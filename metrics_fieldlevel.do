

**************************************************************************************************
**************************************************************************************************
* User must set the outpath and the inpath.
global inpath="B:\Research\RAWDATA\MEDLINE\2014\Processed"
global inpath2="B:\Research\RAWDATA\MeSH\2014\Parsed"
global outpath="B:\Research\Projects\HITS\HITS5\FieldLevel\Data"
**************************************************************************************************


*******************************************************************
*******************************************************************
* CREATE CORE TEMP FILES

* Obtain just the top 0.01 percent of concepts and the PMIDs that use them.
cd $inpath
use ngrams_top, clear
keep if top_0001==1
keep ngramid
merge 1:m ngramid using ngrams_top_pmids_001
drop if _merge==2
drop _merge

* Restrict concepts to those born between 1983 and 2012.
local startvintage=1983
local endvintage=2012
drop if vintage<`startvintage' | vintage>`endvintage'

* Restrict articles to those published between 1983 and 2012.
local startpubyear=1983
local endpubyear=2012
drop if pubyear<`startpubyear' | pubyear>`endpubyear'

keep ngramid pmid pubyear version vintage
order ngramid vintage pmid version pubyear
sort vintage ngramid pmid version
compress
* Observations are uniquely identified by a top ngram and a PMID that uses that top ngram.
cd $outpath
save temp1_ngrampmid, replace

* Attach the 4-digit MeSH terms and their weights to each article
cd $inpath
joinby pmid version using medline14_mesh_clean, unmatched(master)

keep ngramid pmid pubyear version vintage meshid4 mesh4_weight
order ngramid vintage pmid version pubyear meshid4 mesh4_weight
sort vintage ngramid pmid version
compress
* Observations are uniquely identified by a top ngram, a PMID that uses that top ngram, and the mesh4 fields that tag the PMID
cd $outpath
save temp2_ngrampmidmesh4, replace
*******************************************************************
*******************************************************************

set more off
cd $outpath

*******************************************************************
*******************************************************************
* TOP CONCEPT BIRTHS

* Import tempfile. Recall that concept vintages range from 1973-2012 and there is no restriction on pubyear.
use temp2_ngrampmidmesh4, clear

* Keep only articles that are published in the concept's vintage year.
* These are the "originators" of the concept.
keep if pubyear==vintage

* Compute the total number of articles that originate each ngram
* Recall that the meshid4_weights sum to 1 within each article. Thus, by summing the weight over the
*  Ngrams, we get the total count of articles that used each n-gram.
by ngramid, sort: egen articlecount=total(mesh4_weight)

* Normalize the number of fractionalized articles that belong to each ngram-yearbin-meshid cell by the total number
*  of articles that originate each ngram.
* This ensures that the total weight sums to 1 for each ngram. We distribute this normalized weight across meshids.
* This will ensure that the sum of top concept births across yearbins and meshids
*  equal the actual total number of top concepts (10,128 in our case).
gen concepts=mesh4_weight/articlecount

* Transform the concept vintages into 5-year period year bins
gen yearbin=""
replace yearbin="1983-1987" if vintage>=1983 & vintage<=1987
replace yearbin="1988-1992" if vintage>=1988 & vintage<=1992
replace yearbin="1993-1997" if vintage>=1993 & vintage<=1997
replace yearbin="1998-2002" if vintage>=1998 & vintage<=2002
replace yearbin="2003-2007" if vintage>=2003 & vintage<=2007
replace yearbin="2008-2012" if vintage>=2008 & vintage<=2012

* Compute the number of fractionalized articles that belong each ngram-yearbin-meshid cell.
collapse (sum) concepts, by(yearbin meshid)

sort meshid yearbin
compress
save metrics_concepts, replace
export delimited using "metrics_concepts.csv", replace
*******************************************************************



*******************************************************************
*******************************************************************
* TOP CONCEPT TOTAL MENTIONS

* Import tempfile. Recall that concept vintages range from 1973-2012 and there is no restriction on pubyear.
use temp2_ngrampmidmesh4, clear

* Identify articles that use a top concept within `i' years of the concept's vintage.
local vals 0 3 5 10
foreach i in `vals' {
	gen bment_`i'_total_frac=0
	replace bment_`i'_total_frac=mesh4_weight if pubyear<=vintage+`i'
	
	gen bment_`i'_total_raw=0
	replace bment_`i'_total_raw=1 if pubyear<=vintage+`i'
}
gen bment_all_total_frac=mesh4_weight
gen bment_all_total_raw=1

* Transform the article publication years into 5-year period year bins.
* Note that when we are computing mentions we assign **publication years** to the yearbin. This is
*  in contrast to when we assign the **concept vintage years** to the yearbin when computing concept
*  births above.
gen yearbin=""
replace yearbin="1983-1987" if pubyear>=1983 & pubyear<=1987
replace yearbin="1988-1992" if pubyear>=1988 & pubyear<=1992
replace yearbin="1993-1997" if pubyear>=1993 & pubyear<=1997
replace yearbin="1998-2002" if pubyear>=1998 & pubyear<=2002
replace yearbin="2003-2007" if pubyear>=2003 & pubyear<=2007
replace yearbin="2008-2012" if pubyear>=2008 & pubyear<=2012

* For each meshid4 field and yearbin, compute the total number of (weight and unweighted) mentions of a top concept
* This can be thought of as being computed in two different, but equivalent ways:
*   1) A) Fix a ngram. Determine the number of PMIDs belonging to each meshid4-yearbin that mention the ngram. 
*         collapse (sum) mentions_*, by(yearbin meshid4 ngramid vintage)
*      B) Sum the number of fractionalized mentions over all ngrams 
*         collapse (sum) mentions_*, by(yearbin meshid4)
*
*   2) A) Fix a PMID. Determine the number of ngrams it uses in each mesh4id and yearbin. 
*         collapse (sum) mentions_*, by(yearbin meshid4 pmid pubyear)
*      B) Sum the number of fractionalized mentions over all PMIDs 
*         collapse (sum) mentions_*, by(yearbin meshid4)
* Obviously this can all be combined into a single equivalent step: collapse (sum) mentions_*, by(yearbin meshid4)

collapse (sum) bment_*, by(yearbin meshid4)

sort meshid4 yearbin
compress
save metrics_bment_total, replace
export delimited using "metrics_bment_total.csv", replace
*******************************************************************************




*************************************************************************************
*************************************************************************************
* HERFINDAHL (Forward-looking)

* This section computes several version of a forward-looking Herfindahl index. The purpose
*   of these metrics is to measure the level of dispersion of n-grams that are born in
*   particular fields in particular time periods.

* Computation of these metrics proceeds in two steps.
*  Step 1: Compute how n-grams born in a particular year are distributed across fields in that same year.
*          This step is exactly the same as computing concept births.
*  Step 2: Compute how dispersed the n-grams from step 1 are across fields. These dispersion metrics can be
*          weighted by the distribution computed in step 1 or not.


******************** STEP 1 ***************************
* Import tempfile. Recall that concept vintages range from 1973-2012 and there is no restriction on pubyear.
use temp2_ngrampmidmesh4, clear

* Keep only articles that are published in the concept's vintage year.
* These are the "originators" of the concept.
keep if pubyear==vintage

* Compute the total number of articles that originate each ngram
* Recall that the meshid4_weights sum to 1 within each article.
by ngramid, sort: egen articlecount=total(mesh4_weight)

* Normalize the number of fractionalized articles that belong to each ngram-yearbin-meshid cell by the total number
*  of articles that originate each ngram.
* This ensures that the total weight sums to 1 for each ngram.
* This will ensure that the sum of top concept births across yearbins and meshids
*  equal the total number of top concepts (10,128 in our case).
gen weight_vintage=mesh4_weight/articlecount

* Transform the concept vintages into 5-year period year bins
gen yearbin=""
replace yearbin="1983-1987" if vintage>=1983 & vintage<=1987
replace yearbin="1988-1992" if vintage>=1988 & vintage<=1992
replace yearbin="1993-1997" if vintage>=1993 & vintage<=1997
replace yearbin="1998-2002" if vintage>=1998 & vintage<=2002
replace yearbin="2003-2007" if vintage>=2003 & vintage<=2007
replace yearbin="2008-2012" if vintage>=2008 & vintage<=2012

* Compute the number of fractionalized articles that belong each ngram-yearbin-meshid cell.
collapse (sum) weight_vintage, by(ngramid yearbin meshid)

rename meshid4 meshid4_vintage
order meshid4_vintage yearbin weight_vintage ngramid
sort meshid4_vintage yearbin ngramid
compress

save metrics_fherfment, replace
*******************************************************


*******************************************************
* STEP 2: Compute the dispersion of NGrams going foward.
set more off

* Import tempfile. Recall that concept vintages range from 1973-2012 and there is no restriction on pubyear.
use temp2_ngrampmidmesh4, clear

* These commented out commmads simply represent how best to view data in a human-readable form
*keep ngramid pmid meshid4 pubyear vintage weight
*order ngramid pmid meshid4
*sort ngramid pmid meshid4

* Identify articles that EVER mention a top concept
* Compute both fractionalized (across fields) and non-fractionalized (raw) mentions.
gen bment_all_total_frac=mesh4_weight
gen bment_all_total_raw=1

* Sum the mentions (both fractionalized and non-fractionalized (raw)) across all ngrams and fields
keep ngramid meshid4 bment_*
compress
collapse (sum) bment_*, by(ngramid meshid4)

* Compute the herfindhals for both  the fractionalized and non-fractionalized (raw) mentions.
by ngramid, sort: egen total=total(bment_all_total_frac)
gen fherf_frac_un=(bment_all_total_frac/total)^2
drop total
by ngramid, sort: egen total=total(bment_all_total_raw)
gen fherf_raw_un=(bment_all_total_raw/total)^2
drop total
keep ngramid fherf_*
compress
collapse (sum) fherf_*, by(ngramid)

merge 1:m ngramid using metrics_fherfment
order ngram meshid yearbin weight_v fherf_*

* Weight the fractionalized and raw herfindahls by their vintage weight across fields.
gen fherf_frac_w=fherf_frac_un*weight_vintage
gen fherf_raw_w=fherf_raw_un*weight_vintage

* Compute the mean herfindhals over ngrams for each field and year bin
collapse (mean) fherf_*, by(meshid4_vintage yearbin)
rename meshid4_vintage meshid4

sort meshid yearbin
compress
save metrics_fherfment, replace
export delimited using "metrics_fherfment.csv", replace
*******************************************************







*************************************************************************************
*************************************************************************************
* HERFINDAHL (Backward-looking)

* Import tempfile. Recall that concept vintages range from 1973-2012 and there is no restriction on pubyear.
use temp2_ngrampmidmesh4, clear
keep ngramid pmid meshid4 pubyear vintage mesh4_weight

* Identify articles that use a top concept within `i' years of the concept's vintage.
local vals 0 3 5 10
foreach i in `vals' {
	gen mentions_total_frac_`i'=0
	replace mentions_total_frac_`i'=mesh4_weight if pubyear<=vintage+`i'
	
	gen mentions_total_raw_`i'=0
	replace mentions_total_raw_`i'=1 if pubyear<=vintage+`i'
}
gen mentions_total_frac_all=mesh4_weight
gen mentions_total_raw_all=1

compress
* Transform the article publication years into 5-year period year bins
gen yearbin=""
replace yearbin="1983-1987" if pubyear>=1983 & pubyear<=1987
replace yearbin="1988-1992" if pubyear>=1988 & pubyear<=1992
replace yearbin="1993-1997" if pubyear>=1993 & pubyear<=1997
replace yearbin="1998-2002" if pubyear>=1998 & pubyear<=2002
replace yearbin="2003-2007" if pubyear>=2003 & pubyear<=2007
replace yearbin="2008-2012" if pubyear>=2008 & pubyear<=2012

* Note that unlike when computing the mentions metrics, we cannot directly collapse to the field yearbin.
* To compute the backward Herfindahls, we need to take the intermediate step of collapsing to the ngram-field-yearbin. At this
*  level we compute the Herfindahls.
collapse (sum) mentions_*, by(ngram meshid4 yearbin)

*save test1, replace
*use test1, clear

* These commented out commmads simply represent how best to view data in a human-readable form
*order meshid4 yearbin ngram
*sort meshid4 yearbin ngram

* Within a field-yearbin:
*   1) Compute the total number of (fractionalized and raw) top n-gram mentions
*   2) Compute each n-gram's proportion of the total
*   3) Square each n-gram's proportion
* Note that if a given field-yearbin does not mention any top n-gram, then the
*   total computed in step 1 is 0, and and the proportion computed in step 2
*   is undefined for all n-grams in that field-yearbin.
set more off
local vals 0 3 5 10
foreach i in `vals' {
	by meshid4 yearbin, sort: egen total=total(mentions_total_frac_`i')
	gen bherf_frac_`i'=(mentions_total_frac_`i'/total)^2
	drop total
	
	by meshid4 yearbin, sort: egen total=total(mentions_total_raw_`i')
	gen bherf_raw_`i'=(mentions_total_raw_`i'/total)^2
	drop total
}

by meshid4 yearbin, sort: egen total=total(mentions_total_frac_all)
gen bherf_frac_all=(mentions_total_frac_all/total)^2
drop total

by meshid4 yearbin, sort: egen total=total(mentions_total_raw_all)
gen bherf_raw_all=(mentions_total_raw_all/total)^2
drop total

* In this set up, a field-yearbin is analagous to an industry and an n-gram is analogous to a firm within
*   the industry. We are computing how "concentrated" an "industry" (i.e. field-yearbin) is. A higher number
*   indicates more concentration and a lower number indicates less concentration. 
* These metrics can be thought of as measuring how dependent a field-year is on relatively few n-grams. If the
*   field-year is very "concentrated", then it is highly dependent on just a few n-grams. If the field-year is
*   very "unconcentrated", then it uses a wide variety of n-grams.
* HOW TO HANDLE UNDEFINED FIELDS?? COLLAPSE MAKES THEM ZERO.
collapse (sum) bherf_*, by(meshid4 yearbin)

set more off
local vals 0 3 5 10
foreach i in `vals' {
	replace bherf_frac_`i'=. if bherf_frac_`i'==0
	replace bherf_raw_`i'=. if bherf_raw_`i'==0
}
replace bherf_frac_all=. if bherf_frac_all==0
replace bherf_raw_all=. if bherf_raw_all==0

* The Herfindahl Index (H) ranges from 1/N to one, where N is the number of firms in the market.
* Note that if we subtract each metric from 1, we obtain measures of dispersion rather than measures of concentration.

sort meshid yearbin
compress
save metrics_bherfment, replace
export delimited using "metrics_bherfment.csv", replace
*******************************************************


use metrics_concepts, clear
merge 1:1 meshid4 yearbin using metrics_bment_total
drop _merge
sort meshid yearbin
replace concept=0 if concept==.
drop *_raw
rename bment_0_total_frac bment_0
rename bment_3_total_frac bment_3
rename bment_5_total_frac bment_5
rename bment_10_total_frac bment_10
rename bment_all_total_frac bment_all
merge 1:1 meshid4 yearbin using metrics_fherfment
drop _merge
sort meshid yearbin
keep meshid4 yearbin concepts bment_* fherf_frac_w
rename fherf_frac_w fherf_ment
merge 1:1 meshid4 yearbin using metrics_bherfment
keep meshid4 yearbin concepts bment_* fherf_ment bherf_frac*
rename bherf_frac_0 bherf_ment_0
rename bherf_frac_3 bherf_ment_3
rename bherf_frac_5 bherf_ment_5
rename bherf_frac_10 bherf_ment_10
rename bherf_frac_all bherf_ment_all

save metrics_topconcept_fieldlevel, replace

cd $inpath2
import delimited using "desc2014_meshtreenumbers.txt", clear delimiter(tab) varnames(1)
keep if regexm(treenumber, "^([A-Z][0-9][0-9]\.[0-9][0-9][0-9]\.[0-9][0-9][0-9])$")
keep meshid
duplicates drop
tempfile hold
save `hold', replace

clear
set obs 6
gen yearbin_=_n
gen yearbin=""
replace yearbin="1983-1987" if yearbin_==1
replace yearbin="1988-1992" if yearbin_==2
replace yearbin="1993-1997" if yearbin_==3
replace yearbin="1998-2002" if yearbin_==4
replace yearbin="2003-2007" if yearbin_==5
replace yearbin="2008-2012" if yearbin_==6
drop yearbin_

cross using `hold'

sort meshid yearbin
keep yearbin meshid mesh
rename meshid meshid4

cd $outpath
merge 1:1 meshid4 yearbin using metrics_topconcept_fieldlevel
replace concepts=0 if concepts==.
replace bment_0=0 if  bment_0==.
replace bment_3=0 if  bment_3==.
replace bment_5=0 if  bment_5==.
replace bment_10=0 if  bment_10==.
replace bment_all=0 if  bment_all==.

save metrics_topconcept_fieldlevel, replace
export delimited using "metrics_topconcept_fieldlevel.csv", replace


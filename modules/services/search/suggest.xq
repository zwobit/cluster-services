xquery version "3.0";

import module namespace cluster-persons="http://exist-db.org/xquery/biblio/services/search/local/names/cluster-persons" at "local/names/cluster-persons.xqm";
import module namespace cluster-organisations="http://exist-db.org/xquery/biblio/services/search/local/names/cluster-organisations" at "local/names/cluster-organisations.xqm";

import module namespace local-viaf="http://exist-db.org/xquery/biblio/services/search/local/names/local-viaf" at "local/names/local-viaf.xqm";

import module namespace cluster-subjects="http://exist-db.org/xquery/biblio/services/search/local/subjects/cluster-subjects" at "local/subjects/cluster-subjects.xqm";
import module namespace local-aat="http://exist-db.org/xquery/biblio/services/search/local/subjects/local-aat" at "local/subjects/local-aat.xqm";

declare option exist:serialize "method=json media-type=text/javascript";

declare function local:suggestNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer) as item()* {
    let $persons := cluster-persons:searchNames($query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestNames: Count persons: " || count(subsequence($persons, 2))) 
    
    let $oStartRecord := $startRecord - $persons[1]
    let $oStartRecord := if( $oStartRecord = 0 ) then ( 1 ) else ( $oStartRecord )
    let $oPage_limit := $page_limit - count(subsequence($persons, 2))
    let $log := util:log("INFO", "suggestNames: oStartRecord: " || $oStartRecord || " oPage_limit: " || $oPage_limit)
    let $organisations := cluster-organisations:searchNames($query, $oStartRecord, $oPage_limit)
    let $log := util:log("INFO", "suggestNames: Count organisations: " || count(subsequence($organisations, 2))) 
    
    let $vStartRecord := $startRecord - ( $persons[1] + $organisations[1] )
    let $vStartRecord := if( $vStartRecord = 0 ) then ( 1 ) else ( $vStartRecord )
    let $vPage_limit := $page_limit - ( count(subsequence($persons, 2)) + count(subsequence($organisations, 2)) )
    let $log := util:log("INFO", "suggestNames: vStartRecord: " || $vStartRecord || " vPage_limit: " || $vPage_limit)    
    let $viaf := local-viaf:searchNames($query, $vStartRecord, $vPage_limit, (data(subsequence($persons, 2)//@internalID), data(subsequence($organisations, 2)//@internalID)))
    let $log := util:log("INFO", "suggestNames: Count viaf: " || count(subsequence($viaf, 2)))
    return 
        <result>
            <total>{ $persons[1] + $organisations[1] + $viaf[1]}</total>
            { ( subsequence($persons, 2), subsequence($organisations, 2), subsequence($viaf, 2) ) }
        </result>
};

declare function local:suggestPersons($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer) as item()* {
    let $persons := cluster-persons:searchNames($query, $startRecord, $page_limit)
    let $viaf := local-viaf:searchPersonsNames($query, (data(subsequence($persons, 2)//@internalID)))

    return 
        <result>
            <total>{ $persons[1] + $viaf[1]}</total>
            {subsequence( (subsequence($persons, 2), subsequence($viaf, 2)), $startRecord, $page_limit ) }
        </result>
};

declare function local:suggestOrganisations($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer) as item()* {
    let $organisations := cluster-organisations:searchNames($query, $startRecord, $page_limit)
    let $viaf := local-viaf:searchOrganisationsNames($query, (data(subsequence($organisations, 2)//@internalID)))

    return 
        <result>
            <total>{ $organisations[1] + $viaf[1]}</total>
            {subsequence( ( subsequence($organisations, 2), subsequence($viaf, 2)), $startRecord, $page_limit ) }
        </result>
};

declare function local:suggestSubjects($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer) as item()* {
    let $subjects := cluster-subjects:searchSubjects($query)
    let $aat := local-aat:searchSubjects($query)

    return 
        <result>
            <total>{ $subjects[1] + $aat[1]}</total>
            {subsequence( ( subsequence($subjects, 2), subsequence($aat, 2)), $startRecord, $page_limit ) }
        </result>
};


let $query := replace(request:get-parameter("query", "arx"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $type := replace(request:get-parameter("type", "names"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $page_limit := xs:integer(replace(request:get-parameter("page_limit", "10"), "[^0-9 ]", "")) 
let $startRecord := (xs:integer(replace(request:get-parameter("page", "1"), "[^0-9 ]", "")) * $page_limit) - ($page_limit -1)
let $cors := response:set-header("Access-Control-Allow-Origin", "*")
return
    switch ($type)
        case "names"
            return local:suggestNames($query, $startRecord, $page_limit) 
        case "subjects"
            return local:suggestSubjects($query, $startRecord, $page_limit)
        case "persons"
            return local:suggestPersons($query, $startRecord, $page_limit)
        case "organisations"
            return local:suggestOrganisations($query, $startRecord, $page_limit)
        default 
            return 
                <result><total>0</total></result>
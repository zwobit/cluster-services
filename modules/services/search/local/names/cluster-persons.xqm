xquery version "3.0";

module namespace cluster-persons="http://exist-db.org/xquery/biblio/services/search/local/names/cluster-persons";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../../app.xqm";
import module namespace viaf-utils="http://exist-db.org/xquery/biblio/services/search/local/viaf-utils" at "../viaf-utils.xqm";

(: TEI namesspace :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: VIAF Terms :)
declare namespace ns2= "http://viaf.org/viaf/terms#";

declare function cluster-persons:searchNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer) as item()* {
    (: let $persons :=  doc($app:local-persons-repositories)//tei:listPerson/tei:person[ngram:contains(tei:persName, $query)] :)
    let $persons :=  collection($app:local-persons-repositories-collection)//tei:listPerson/tei:person[ngram:contains(tei:persName, $query)]
    let $sorted-persons :=
        for $item in $persons
        order by upper-case(string(if (exists($item/tei:persName[@type = "preferred"])) then ($item/tei:persName[@type = "preferred"]) else ($item/tei:persName[1])))
        return $item
    let $countPersons := count($sorted-persons)
    return
        (
            $countPersons,
            if($startRecord = 1 or $countPersons > $startRecord)
            then (
                for $person in subsequence($sorted-persons, $startRecord, $page_limit)
                let $persName := if (exists($person/tei:persName[@type = "preferred"])) then ($person/tei:persName[@type = "preferred"]) else ($person/tei:persName[1])
                let $name := if (exists($persName/tei:forename) and exists($persName/tei:surname))
                             then ( normalize-space( $persName/tei:surname/text() || ", " || $persName/tei:forename/text() ) )
                             else (
                                 if ( exists($persName/tei:surname) )
                                 then ( normalize-space( $persName/tei:surname/text() ))
                                 else (
                                     if ( exists($persName/tei:forename) )
                                        then ( normalize-space( $persName/tei:forename/text() ))
                                        else ( $persName/text() )
                                 )
                             )
                let $viafID := if( exists($person/tei:persName/@ref[contains(., 'http://viaf.org/viaf/')]) ) then (substring-after($person/tei:persName/@ref[contains(., 'http://viaf.org/viaf/')], "http://viaf.org/viaf/")) else ()
                let $viafCluster := if($viafID) then ( collection($app:local-viaf-xml-repositories)//ns2:VIAFCluster[ns2:viafID = $viafID] ) else ()
                let $mainHeadingElement := if($viafID) then (  viaf-utils:getBestMatch($viafCluster//ns2:mainHeadingEl) ) else ()
                let $sources := if($viafID) then (  viaf-utils:getSources($mainHeadingElement) ) else ()
                let $bio := if($viafID) then ( if($mainHeadingElement) then ( $mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'd']) else () ) else ()
                return
                    element term {
                            attribute uuid {data($person/@xml:id)},
                            attribute type {'personal'},
                            attribute value {$name},
                            attribute authority {'local'},
                            attribute src {'EXC'},
                            if($viafID) then (
                                attribute id {$viafID},
                                attribute sources {$sources},
                                if($bio) then (
                                    attribute bio {$bio},
                                    attribute earliestDate {viaf-utils:extractEarliestDate($bio)},
                                    attribute latestDate {viaf-utils:extractLatestDate($bio)}
                                ) else ()
                            ) else ()
                        }
            ) else ( () )
        )
};
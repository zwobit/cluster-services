module namespace rosids-utils="http://exist-db.org/xquery/biblio/services/rosids/rosids-utils";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../app.xqm";

declare function rosids-utils:getCollection($type as xs:string, $collection as xs:string) {
    if($collection eq '')
    then(
        switch ($type)
            case "organisations"
                return $app:global-organisations-repositories-collection
            case "persons"
                return $app:global-persons-repositories-collection
            case "subjects"
                return $app:global-subjects-repositories-collection
            default 
                return $app:global-persons-repositories-collection
    ) else (
        $collection
    )
};
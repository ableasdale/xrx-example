(:~
: The core logic for the tix application all stored in a "common" module 
:
: @author Alex Bleasdale
: @version 1.0
:)

xquery version "1.0-ml";

module namespace tix-common="http://www.alexbleasdale.co.uk/tix-common";
import module "http://marklogic.com/xdmp/security" at "security.xqy";

declare function tix-common:getDocCount($collection as xs:string){
    let $count := fn:count(fn:collection($collection))
    return $count
};

declare function tix-common:createFileName($projectId as xs:string, $collection as xs:string){
    let $filename := fn:concat($projectId, (1 + tix-common:getDocCount($collection)), ".xml")
    return $filename
};

declare function tix-common:updateNode(){
    let $form-data := xdmp:get-request-body()/node()
    return $form-data
};



(: Added login functions below :)
declare function tix-common:registerUser (
    $user as xs:string,
    $desc as xs:string,
    $password as xs:string) as xs:boolean
{
    if (xdmp:eval-in(fn:concat('import module "http://marklogic.com/xdmp/security" at "/xq/modules/security.xqy"; sec:create-user("',$user,'","',$desc,'","',$password,'", "app-user",(),())'),xdmp:security-database())) then
       fn:true()
    else
       fn:false()
};

declare function tix-common:validateLogin ($user as xs:string, $password as xs:string)
    as xs:boolean
{
    if (xdmp:login ($user,$password)) then
        fn:true()
    else
        fn:false()
};

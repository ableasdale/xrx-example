(:
    Returns a Code Table of all currently registered users.  Future feature?  
    Create proper user administration page for admin
:)
xquery version "1.0-ml";

import module "http://marklogic.com/xdmp/security" at "/xq/modules/security.xqy";
import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";

(:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
 TODO - there MUST be a better way to do this?
declare function local:getUsers(){
let $node := for $user in /sec:user
      return <p>user</p>
return $node
}; :)

(: TODO - check for admin rights?? prob not as this will generate code tables :)
(:
let $doc := if (exists(doc("tix-users.xml") = true) then
    <users>we got</users>
    else
    <users>no users</users>
return 
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::)



(:
::  Check to see whether there is a user code table
:)
let $doc := if(not(doc("tix-users.xml"))) then
    (: Create User file for the first time :)
     tix-common:createInitDocuments()
    else
    doc("tix-users.xml")/CodeTable/*
return
<CodeTable>{$doc}</CodeTable>
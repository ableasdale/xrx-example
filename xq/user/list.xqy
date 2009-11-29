(:
    Returns a Code Table of all currently registered users.  Future feature?  
    Create proper user administration page for admin
:)
xquery version "1.0-ml";

import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";

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
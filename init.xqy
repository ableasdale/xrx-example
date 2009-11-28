(: 

        TODO - this needs to be run once to ensure the correct file is created on first run()
        
        This will be replaced in a later version
    
:)
import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";

let $doc := if(not(doc("tix-projects.xml"))) then
    (: Create User and projects for the first time :)
     tix-common:createInitDocuments()
    else
    doc("tix-projects.xml")/CodeTable/*  
    return xdmp:redirect-response ("/")
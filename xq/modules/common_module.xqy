(:~
: The core logic for the TiX application all stored in the TiX "common" module 
:
: @author Alex Bleasdale
: @version 1.0
:)
xquery version "1.0-ml";
module namespace tix-common="http://www.alexbleasdale.co.uk/tix-common";
import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

(:
:: Summary:
::
::      Returns the current number of Documents within a given collection 
::
:: Parameters:
::
::      $collection 
::            The name of the collection  
:)
declare function tix-common:getDocCount($collection as xs:string, $id as xs:string){
    let $count := fn:count(fn:collection($collection)//id[text() = $id])
    return $count
};


(:
:: Summary:
::
::      Performs a code table lookup (getting the Value from a Label in an XML code table 
::
:: Parameters:
::
::      $docname 
::            The name of the doc in the xmldb
::
::      $node-value
::            The "value" to match to return the corresponding label  
:)
declare function tix-common:getCodeTableLabelFromValue($docname as xs:string, $node-value as xs:string){
    let $label := fn:doc($docname)/CodeTable/EnumeratedValues/Item/Value[text() = $node-value]/preceding-sibling::*[1]/text()
    return $label
};

(:
:: Summary:
::
::      Generates a filename for the xml document with this pattern:
::      XXX-0.xml where 'XXX' denotes the project identifier and '0'
::      represents the current document number (based on a count of)
::      all documents in the collection (+1) 
::
:: Parameters:
::
::      $projectId 
::            The identifier for the project 
::
::      $collection 
::            The name of the collection  
:)
declare function tix-common:createFileName($projectId as xs:string, $collection as xs:string) as xs:string {
    let $filename := fn:concat($projectId, "-", (1 + tix-common:getDocCount($collection, $projectId)), ".xml")
    return $filename
};

(:
:: Summary:
::
::      Extracts the XML element(s) from an http request (the body) and returns them for
::      persistence to a collection / validation etc.
::
:)
declare function tix-common:updateNode(){
    let $form-data := xdmp:get-request-body()/node()
    return $form-data
};

(:
:: Summary:
::
::      Extracts the XML element(s) from an http request (the body) and returns them for
::      persistence to a collection / validation etc.
::
::      The design pattern for this method is based a method found in this document:
::      <strong>http://xqzone.marklogic.com/svn/userlogin/trunk/user-lib.xqy</strong>
::      although it needed significant refactoring in order to stop 
::      MarkLogic throwing a stack trace.
::
:: Parameters:
::
::      $user 
::            A unique username / identifier 
::
::      $desc
::            A brief description of the user  
::
::      $password
::            The password  
:)
declare function tix-common:registerUser (
    $user as xs:string,
    $desc as xs:string,
    $password as xs:string) as xs:boolean
{
 
    if (xdmp:eval-in(fn:concat('import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy"; sec:create-user("',$user,'","',$desc,'","',$password,'", "app-user",(),())'),xdmp:security-database())) then
       fn:true()
    else
       fn:false()
};


(:
:: Summary:
::
::      Passes a username and password to xdmp:login and returns a boolean based on 
::      whether the login request was successful (or not).
::
:: Parameters:
::
::      $user 
::            A unique username / identifier 
::
::      $password
::            The password  
:)
declare function tix-common:validateLogin ($user as xs:string, $password as xs:string)
    as xs:boolean
{
    if (xdmp:login ($user, $password)) then
        fn:true()
    else
        fn:false()
};


(: TODO - remove later?
declare function tix-common:checkForUserDocument()
{
   if (not(doc("tix-users.xml"))) then   
        tix-common:createUserDocument()
    else ()
};
:)

(:
:: Summary:
::      Creates the User document (n.b. Developer should test as to whether the doc exists first)
::
::      See: /xq/users/list.xq for this checking
:)

declare function tix-common:createInitDocuments(){
    xdmp:document-insert(
             "tix-users.xml", 
             <CodeTable><DataElementName>registeredUsers</DataElementName><EnumeratedValues><Item><Label>(Choose a User)</Label><Value/></Item></EnumeratedValues></CodeTable>,
             xdmp:default-permissions(),
             "tix-admin"),
    xdmp:document-insert(
             "tix-projects.xml", 
             <CodeTable><DataElementName>registeredProjects</DataElementName><EnumeratedValues><Item><Label>(Choose a Project)</Label><Value/></Item></EnumeratedValues></CodeTable>,
             xdmp:default-permissions(),
             "tix-admin")
};

(:
:: Updates node in user doc
:)
declare function tix-common:updateUserDoc($user as xs:string, $desc as xs:string){
    xdmp:node-insert-child(fn:doc(
            "tix-users.xml")/CodeTable/EnumeratedValues,
            <Item><Label>{$desc}</Label><Value>{$user}</Value></Item>)
};

(:
:: Updates node in project doc
:)
declare function tix-common:updateProjectDoc($name as xs:string, $desc as xs:string){
    xdmp:node-insert-child(fn:doc(
            "tix-projects.xml")/CodeTable/EnumeratedValues,
            <Item><Label>{$desc}</Label><Value>{$name}</Value></Item>)
};

(:
:: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
:: TODO - talk to someone at ML about how the XSLTForms PI can be injected into an xqy file. 
:: This currently does not seem to work -- at least; not for me.
:)
declare function tix-common:generateXsltFormsPi() as xs:string {
    let $pi := "<?xml-stylesheet href='xsltforms/xsltforms.xsl' type='text/xsl'?>"
    return (xdmp:unquote($pi))
};

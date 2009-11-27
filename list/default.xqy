xquery version "1.0-ml";

import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";

declare function local:getCollectionContents($collection as xs:string){
let $node := for $doc in collection($collection)
      return <p><a href="getCrv.xqy?recipeName={document-uri($doc)}">a-doc</a>
      </p>
return $node
};

<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Tix</title></head>
<body>
<h1>Current tickets</h1>
<h2>request field: {xdmp:get-request-field("colname")}</h2>
<div xmlns="">
  { 
  local:getCollectionContents(xdmp:get-request-field("colname"))
  }
</div>
<h3>and: {tix-common:getDocCount(xdmp:get-request-field("colname"))}</h3>
</body></html>
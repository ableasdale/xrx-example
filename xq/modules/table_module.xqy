(:~
: Module providing standard markup components for information displayed as tabular data 
:
: @author Alex Bleasdale
: @version 1.0
:)
xquery version "1.0-ml";
module namespace tix-table = "http://www.alexbleasdale.co.uk/tix-table";
import module namespace tix-common = "http://www.alexbleasdale.co.uk/tix-common" at "/xq/modules/common_module.xqy";

(:
:: Summary:
::
::      Resolver for a project's name based on a given id
::
:: Parameters:
::
::      $projectId 
::            The Project Id
::
:)
declare function tix-table:getProjectNameById($projectId as xs:string) {
   
    let $projectName := 
    if (fn:empty($projectId) = fn:false()) then
        <span class="information"> for {tix-common:getCodeTableLabelFromValue("tix-projects.xml", $projectId)}</span>
    else
        (: 
            TODO - Why do we *never* reach the else?? 
            can someone at ML explain this behaviour in the code review?
        :)
        <span class="information">All Projects</span>
    
    return $projectName   
};

declare function tix-table:getDoc() {
    let $doc := fn:doc(xdmp:get-request-field("id"))
    return $doc
};


(:
:: Summary:
::
::      Generates standard table "Dashboard markup" for TiX Dashboards
::
:)
declare function tix-table:generateDashboard(){
    let $projectId := xdmp:get-request-field("projectChooser")
    return
    
    let $response :=
    <div id="dashboard">
        <h2>Dashboard overview {tix-table:getProjectNameById($projectId)}</h2>
        <table summary="This table provides an overview of the tickets currently logged with TiX" class="tablesorter" id="dashboard-project-overview">
        <thead> 
            <tr>
                <th>Project Uri</th>
                <th>Type</th>
                <th>Summary</th>
                <th>Created Date</th>
                <th>Priority</th>
                <th>Reporter Id</th>
                <th>View HTML</th>
                <th>View XML</th>
                <th>Update Worflow</th>
            </tr>
         </thead>    
         <tbody>
            {
            for $item in fn:collection("tixOpen")
            let $inner-node := 
            <tr>
                <td>{xdmp:node-uri($item)}</td>
                <td>{$item/TicketDocument/Ticket/type/text()}</td>
                <td>{$item/TicketDocument/Ticket/summary/text()}</td>
                <td>{xdmp:strftime("%a, %d %b %Y %H:%M:%S",$item/TicketDocument/Ticket/createdDate/text())}</td>
                <td>{$item/TicketDocument/Ticket/ticketPriority/text()}</td>
                <td>{$item/TicketDocument/Ticket/reporterId/text()}</td>
                <td><a title="View HTML {xdmp:node-uri($item)}" href="/detail/default.xqy?id={xdmp:node-uri($item)}">View/Edit</a></td>
                <td><a title="View XML for {xdmp:node-uri($item)}" href="/detail/xml.xqy?id={xdmp:node-uri($item)}">XML</a></td>
                <td><a title="Update Workflow for {xdmp:node-uri($item)}" href="/update/default.xqy?id={xdmp:node-uri($item)}">Update</a></td>
            </tr>
            
            let $where-clause := if ($projectId) then
                ($item/TicketDocument/Ticket/id/text() = $projectId)
            else fn:true()
            
            
            where $where-clause
            order by $item/TicketDocument/Ticket/createdDate descending
            return $inner-node
            }
            </tbody>
        </table>
        {tix-table:getPagerWidget()}
    </div>
    return $response
};

(:
:: Summary:
::
::      Generates standard table "Dashboard markup" for TiX Dashboards
::
:)
declare function tix-table:getWorkflow(){
let $workflow-table := 
<div id="workflow">
    <table class="tablesorter" id="dashboard-project-overview">
      <thead>
        <tr>
            <th>Workflow Date</th>
            <th>Workflow Comment</th>
            <th>Workflow User</th>
        </tr>
      </thead>
      <tbody>
        {
         for $item in tix-table:getDoc()/TicketDocument/WorkflowEvents/WorkflowEvent
            let $inner-node := 
            <tr>
                <td>{xdmp:strftime("%a, %d %b %Y %H:%M:%S",$item/updatedDate/text())}</td>
                <td>{$item/workflowCommentText/text()}</td>
                <td>{$item/workflowUserId/text()}</td>
            </tr>
            return $inner-node
        }
      </tbody>
    </table>
    {tix-table:getPagerWidget()}
</div>
    return $workflow-table
};

(:
:: Summary:
::
::      Generates search result table
::
:)
declare function tix-table:getSearchResults(){
    let $elem := 
    <div id="search-results">
        <table class="tablesorter" id="dashboard-project-overview">
        <thead>
            <tr>
                <th>View Document</th>
                <th>Summary</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
        {
            for $item in cts:search(//TicketDocument/Ticket (:[and preding-sibling::/*[1]]:)
            , cts:word-query(xdmp:get-request-field("word")) )
            return
            <tr>
                <td><a title="View {xdmp:node-uri($item)}" href="/detail/default.xqy?id={xdmp:node-uri($item)}">View {xdmp:node-uri($item)}</a></td>
                <td>{$item/summary/text()}</td>
                <td>{$item/description/text()}</td>
            </tr>
        }
        </tbody>
        </table>
        {tix-table:getPagerWidget()}
    </div>    
    return $elem 
};


(:
:: Summary:
::
::      Generates a pager widget for TiX Dashboards
::
:)
declare function tix-table:getPagerWidget(){
let $pager :=
<div id="pager" class="pager">
    <form>
        <img class="first" src="/img/first.png"/>
        <img class="prev" src="/img/prev.png"/>
        <input class="pagedisplay" type="text"/>
        <img class="next" src="/img/next.png"/>
        <img class="last" src="/img/last.png"/>
    <select class="pagesize">
        <option selected="selected"  value="10">10</option>
        <option value="20">20</option>
        <option value="30">30</option>
        <option  value="40">40</option>
    </select>
    </form>
</div>
return $pager
};
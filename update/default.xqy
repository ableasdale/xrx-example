(:~
: Default Workflow page for TiX
:
: N.B. I had to resort to an HTML form (rather than an XForm) as I encountered issues
: with ML XQuery and the XSLTForms PI.  Will work to solve this issue another time..
:
: @author Alex Bleasdale
: @version 1.0
:)
xquery version "1.0-ml";
import module namespace tix-include = "http://www.alexbleasdale.co.uk/tix-include" at "/xq/modules/include_module.xqy";

xdmp:set-response-content-type("text/html; charset=utf-8"),
<html xmlns="http://www.w3.org/1999/xhtml">
    {tix-include:getDocumentHead("Welcome to TiX - Update Document Workflow")}
    <body>
    <div id="container">
    {tix-include:getHeader()}
    <div id="main-content">
        <div id="cta" class="center">
            <h2 class="information">Update Ticket Workflow for {xdmp:get-request-field("id")}</h2>
            <h3>In a later release this would be an XForm (as soon as I can get MarkLogic XQuery to generate/output the XSLTForms PI)</h3>
            
            <form action="/update/workflow.xqy" method="post"> 
            
                <input type="hidden" name="id" value="{xdmp:get-request-field("id")}" />
                
                <p class="inputfield">
                    <label for="wf-comment">Workflow Comment: </label>
                    <textarea id="wf-comment" name="wf-comment" rows="10" cols="50" />
                </p>
            
                <p class="inputfield">
                    <label for="status">Change Ticket Status (if necessary): </label>
                    <select id="status" type="text" name="status">
                        <option value="" selected="selected">(Please Choose)</option>
                        <option value="open">Open</option>
                        <option value="closed">Closed</option>
                        <option value="reopened">Reopened</option>
                        <option value="fixed">Fixed</option>
                        <option value="will-not-fix">Will Not Fix</option>
                    </select>
                </p>
                             
                <p class="inputfield">
                    <label for="priority">Change Priority (if necessary): </label>
                     <select id="priority" type="text" name="priority">
                        <option value="" selected="selected">(Please Choose)</option>
                        <option value="critical">Critical</option>
                        <option value="high">High</option>
                        <option value="medium">Medium</option>
                        <option value="low">Low</option>
                    </select>
                </p>
                
                <p class="inputfield">
                    <label for="reassign">Reassign to (if necessary): </label>
                    {tix-include:getUsersAsHtml()}
                </p>

                <p>
                    <input type="submit" name="submit" value="Submit" />
                </p>
            </form>
         </div>
    </div>
    {tix-include:getFooter()}
    </div>
    </body>
</html>
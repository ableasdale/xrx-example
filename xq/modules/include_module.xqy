(:~
: Module providing standard markup components for re-use across pages 
:
: @author Alex Bleasdale
: @version 1.0
:)
xquery version "1.0-ml";
module namespace tix-include="http://www.alexbleasdale.co.uk/tix-include";
import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

(:
:: Summary:
::
::      Generates the common html <head> element, which is rendered on every page on the 
::      application.
::
:: Parameters:
::
::      $pageName 
::          The first portion of the html <title> element, used to identify the page and
::          for SEO best practice.
:: 
:)
declare function tix-include:getDocumentHead($pageName as xs:string){
  let $head := 
  <head xmlns="http://www.w3.org/1999/xhtml">
    <title>{$pageName} | TiX Bug Tracker v0.1</title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <link rel="stylesheet" type="text/css" media="screen, projection" href="/css/styles.css" />
    <script type="text/javascript" src="/js/jquery-1.3.2.min.js"></script>
    <script type="text/javascript" src="/js/jquery.qtip-1.0.0-rc3.min.js"></script>
    <script type="text/javascript" src="/js/jquery.highlight-3.yui.js"></script>
    <script type="text/javascript" src="/js/jquery.tablesorter.min.js"></script>
    <script type="text/javascript" src="/js/jquery.tablesorter.pager.js"></script>
    <script type="text/javascript">
    /* <![CDATA[ */
    $(document).ready(function() {
        
        $('[title]').qtip({ 
        position: {
        corner: { target: 'topMiddle', tooltip: 'bottomMiddle'} }, adjust: { screen: true },
        style: { border: { width:7, radius:5}, padding:5, name: 'dark', tip: true } }
        );
        
        $(".hide").hide();
        
        // TODO - The 'pager' is buggy if there are zero issues in a project; 
        // should be fairly easy to fix if I need to later..
        
        $("#dashboard-project-overview").tablesorter({widthFixed: true, widgets: ['zebra']}) 
    .tablesorterPager({container: $("#pager")});
    
        
    });
    /* ]]> */
    </script>
  </head>
  return $head  
};

(:
:: Summary:
::
::      Returns the applications "Login" status as an html element (used on both the header
::      and footer elements on the page.
:: 
:)
declare function tix-include:getCurrentUserCredentials(){
  let $credentials-pane := 
  if (xdmp:get-current-user() = "nobody") then
    <div class="split-pane">
        <p class="left">Currently not logged in</p>
        <br class="clearboth" />
    </div>
 else
    <div class="split-pane">
        <p class="left">Currently Logged in as: <span class="user">{xdmp:get-current-user()}</span></p>
        <p class="right"><a href="/" title="This will take you to your dashboard">Home</a> | <a href="/create/form.xml" title="Create a new Ticket">New Ticket</a> | <a href="/xq/user/logout.xqy" title="This will end your TiX session">Logout</a></p>
        <br class="clearboth" />
    </div>
 
 return $credentials-pane
};

(:
:: Summary:
::
::      If a user with administrative privileges is logged in, this element will be rendered
::      and allows an administrator to create uers, etc.
:: 
:)
declare function tix-include:getAdminUserLink(){
    let $admin-link := if (xdmp:get-current-user() = "admin") then
        <p class="cta-panel">Administrators: <a href="registration-form.xqy">create new user account</a></p>
    else 
        <p class="cta-panel">Not got an account yet? <a href="mailto:administrator@example.com" title="this will compose an email to the System administrators for an account to be set up.">Request one here</a></p>
    return $admin-link
};

(:
:: Summary:
::
::      If the administrator is logged in, extra options appear on the index page
:: 
:)
declare function tix-include:getAdminPanel(){
    let $admin-panel := if (xdmp:get-current-user() = "admin") then
        <p class="cta-info">
            There are currently <strong>{tix-include:getTotalUsers()}</strong> registered users and <strong>{tix-include:getTotalProjects()}</strong> registered projects<br /><br />
            <strong>Quick links for <span class="information">{xdmp:get-current-user()}</span>:</strong>&nbsp;<a title="This takes you to the new user registration form" href="/xq/user/registration-form.xqy">Create a new user account</a> | <a title="This takes you to the new project registration form" href="/xq/project/registration-form.xqy">Create a new project</a> | <a title="This takes you to the new ticket XForm" href="/create/form.xml">Create a new ticket</a>
        </p>
    else
        <p class="cta-info">
            Quick links for <span class="information">{xdmp:get-current-user()}</span><br />
            <a href="/create/form.xml">Create new ticket</a>
        </p>
    return $admin-panel
};

(:
:: Summary:
::
::      Returns a count of all registered users
:: 
:)
declare function tix-include:getTotalUsers() as xs:integer {
   let $users := (fn:count(fn:doc("tix-users.xml")/CodeTable/EnumeratedValues/Item) - 1)
   return $users
};

(:
:: Summary:
::
::      Returns a count of all registered users
:: 
:)
declare function tix-include:getTotalProjects() as xs:integer {
   let $projects := (fn:count(fn:doc("tix-projects.xml")/CodeTable/EnumeratedValues/Item) - 1)
   return $projects
};


(:
:: Summary:
::
::      Gets the Explorer for the TiX Dashboard pages; this is a standard UI 
::      enabling the user to switch between available projects and adds the 
::      search functionality for word searches
::
:)
declare function tix-include:getTixExplorer(){
    let $tix-explorer := 
    <div id="project-explorer" class="split-pane">
            <form class="left" title="Select a project to view the dashboard" action="/" method="post" onchange="this.submit();">
            {tix-include:getProjectsAsHtml()}
            <input class="hide" type="submit" value="View Dashboard"/>
        </form>
        <form class="right" action="/search/default.xqy" method="post">
            <input class="mr10" type="text" name="word" title="Please enter search word to locate tickets"/>
            <label for="word-search" class="hide">Search keyword: </label>
            <input id="word-search" type="submit" value="Search" />
        </form>
        <br class="clearboth" />
    </div>
    return $tix-explorer
};

declare function tix-include:getProjectsAsHtml(){
let $project-html-list :=
<select name="projectChooser">
    {
    for $item in fn:doc("tix-projects.xml")/CodeTable/EnumeratedValues/Item
    let $inner-node := <option value="{$item/Value}">{$item/Label}</option>
    return $inner-node
    }
</select>
return $project-html-list
};

(:  TODO - currently breaking the app... if req-field is empty :/
declare function tix-include:isSelected($item as xs:string) {
    let $sel := if( $item/Value[ text() = xdmp:get-request-field("projectChooser") ]) then 
        <option selected="selected" value="{$item/Value}">{$item/Label}</option>
        else <option value="{$item/Value}">{$item/Label}</option>
    return $sel
};
:)

declare function tix-include:getUsersAsHtml(){
let $user-html-list :=
<select id="reassign" type="text" name="reassign">
    {
    for $item in fn:doc("tix-users.xml")/CodeTable/EnumeratedValues/Item
    let $inner-node := <option value="{$item/Value}">{$item/Label}</option>
    return $inner-node
    }
</select>
return $user-html-list
};


(:
:: Summary:
::
::      Returns the html login form used on both the login and logout pages.
:: 
:)
declare function tix-include:getLoginForm(){
   let $login-form :=
   <div id="login-component">
   <form action="/xq/user/validatelogin.xqy" method="post"> 
    <p class="inputfield">
        <label for="username">User name: </label>
        <input id="username" type="text" name="user" />
    </p>
    
    <p class="inputfield">
        <label for="password">Password: </label>
        <input type="password" name="password" />
    </p>
    
    <p>
        <input type="submit" name="submit" value="Submit" />
    </p>
   </form>
   {tix-include:getAdminUserLink()}
   </div>
   return $login-form
};

(:
:: Summary:
::
::      Returns the html <strong>header</strong> div, which is used on all 
::      pages in the application
:: 
:)
declare function tix-include:getHeader(){
    let $header := 
    <div id="header">
        <h1>TiX : XML Bug Tracking System (v0.1)</h1>
        {tix-include:getCurrentUserCredentials()}
    </div>
    return $header
};

(:
:: Summary:
::
::      Returns the html <strong>footer</strong> div, which is used on all 
::      pages in the application
:: 
:)
declare function tix-include:getFooter(){
    let $footer :=
    <div id="footer">
        <h3>&#x00A9; 2009 TiX | Privacy Policy | Support</h3>
        {tix-include:getCurrentUserCredentials()}
    </div>
    return $footer
};

declare function tix-include:checkForWarnings(){
    let $status := 
    if (xdmp:get-session-field("login-status") = "invalid") then
    <p class="cta-warning">Invalid credentials provided - try again?</p>
    else if (xdmp:get-session-field("login-status") = "notadmin") then
    <p class="cta-warning">You need to be logged in as <strong>administrator</strong> to create user accounts</p>
    else
    <p class="cta-info">Welcome! Please log in using the form below</p>
    return $status
};


        

(:~
: Module providing standard markup components for re-use across pages 
:
: @author Alex Bleasdale
: @version 1.0
:)
xquery version "1.0-ml";

module namespace tix-include="http://www.alexbleasdale.co.uk/tix-include";
import module "http://marklogic.com/xdmp/security" at "security.xqy";

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
  let $head := <head xmlns="http://www.w3.org/1999/xhtml"><title>{$pageName} | TiX Bug Tracker v0.1</title><link rel="stylesheet" type="text/css" media="screen, projection" href="../../css/styles.css" /></head>
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
        <p class="right"><a href="/xq/user/logout.xqy" title="This will end your TiX session">Logout</a></p>
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
        <p class="cta-panel">
            There are currently <strong>{tix-include:getTotalUsers()}</strong> users and <strong>{tix-include:getTotalProjects()}</strong> projects<br />
            <a href="/xq/user/registration-form.xqy">create new user account</a><br />
            <a href="/xq/project/registration-form.xqy">create new project</a><br />
        </p>
    else
        <p class="cta-panel">TODO - normal user panel</p>
    return $admin-panel
};

(:
:: Summary:
::
::      Returns a count of all registered users
:: 
:)
declare function tix-include:getTotalUsers(){
   let $users := fn:count(fn:doc("tix-users.xml")/CodeTable/EnumeratedValues/Item)
   return $users
};

(:
:: Summary:
::
::      Returns a count of all registered users
:: 
:)
declare function tix-include:getTotalProjects(){
   let $projects := fn:count(fn:doc("tix-projects.xml")/CodeTable/EnumeratedValues/Item)
   return $projects
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
<?php

if(isset($_GET['sort']))
	$sortby = $_GET['sort'];
else
	$sortby = "last_update";

$link = mysql_connect('localhost','inventory','');
if (!$link) {
    die('Could not connect: ' . mysql_error());
}
$selected = mysql_select_db('inventory', $link);

if (!$selected) {
    die ('Can\'t use inventory : ' . mysql_error());
}

$q =  "select count(*) from systems";
$result = mysql_query($q);
$count = mysql_fetch_row($result);

$q = "select hostname,last_update from systems order by last_update asc limit 1";
$result = mysql_query($q);
$oldest_checkin = mysql_fetch_row($result);

$q = "select hostname,last_update from systems order by last_update desc limit 1";
$result = mysql_query($q);
$newest_checkin = mysql_fetch_row($result);

if (isset($_POST['search']))
	$search = $_POST['search'];
else
	$search = $_GET['search'];

if (isset($_POST['sindex']))
	$sfield = $_POST['sindex'];
else
	$sfield = $_GET['sindex'];

if ($search != '' && isset($search))
	$sq = "WHERE $sfield LIKE '%".$search."%'";
else
	$sq = "";

if ($sortby == "ageold")
        $q =  "select * from systems ".$sq." order by last_update ASC";
elseif ($sortby == "agenew")
        $q =  "select * from systems ".$sq." order by last_update DESC";
elseif ($sortby == "memory")
        $q =  "select * from systems ".$sq." order by ".$sortby." DESC";
elseif ($sortby == "bios_release_date")
        $q =  "select * from systems ".$sq." order by mid(".$sortby.", 6) ASC"; //sort by substring representing the year, oldest first.
else
        $q =  "select * from systems ".$sq." order by ".$sortby." ASC";

$result = mysql_query($q);
$searchcount = mysql_num_rows($result);
$display = "<script>		
	if (window.parent && window.parent.synchTab)
	window.parent.synchTab(window.name);

	function show_hide_column(col_no, do_show) {

    	  var stl;
    	  if (do_show) stl = 'block'
    	  else         stl = 'none';
    	  var tbl  = document.getElementById('inventory');
    	  var rows = tbl.getElementsByTagName('tr');
    	  for (var row=0; row<rows.length;row++) {
      	  var cels = rows[row].getElementsByTagName('td')
      	  cels[col_no].style.display=stl;
	  }
	}
	</script><table id=\"inventory\" border=\"1\" cellspacing=\"1\">
        <tr>";
   if ($sortby == "hostname")
                $display .= "<td style=\"background-color:#d0b0ff\"><input type=\"checkbox\" name=\"hidehost\" onClick='javascript:show_hide_column(0, false);' value=\"hide\" checked><b>Hostname</b></td>";
        else
                $display .= "<td><input type=\"checkbox\" name=\"hidehost\" onClick='javascript:show_hide_column(0, false);' value=\"hide\" checked><b>Hostname</b></td>";
        if ($sortby == "ip")
                $display .= "<td style=\"background-color:#d0b0ff\"><input type=\"checkbox\" name=\"hideip\" onClick='javascript:show_hide_column(1, false);' value=\"hide\" checked><b>IP Address</b></td>";
        else
                $display .= "<td><input type=\"checkbox\" name=\"hideip\" onClick='javascript:show_hide_column(1, false);' value=\"hide\" checked><b>IP Address</b></td>";
        if ($sortby == "version")
                $display .= "<td style=\"background-color:#d0b0ff\"><input type=\"checkbox\" name=\"hiderel\" onClick='javascript:show_hide_column(2, false);' value=\"hide\" checked><b>Release</b></td>";
        else
                $display .= "<td><input type=\"checkbox\" name=\"hiderel\" onClick='javascript:show_hide_column(2, false);' value=\"hide\" checked><b>Release</b></td>";
        if ($sortby == "kernel")
                $display .= "<td style=\"background-color:#d0b0ff\"><input type=\"checkbox\" name=\"hidever\" onClick='javascript:show_hide_column(3, false);' value=\"hide\" checked><b>Kernel Version</b></td>";
        else
                $display .= "<td><input type=\"checkbox\" name=\"hidever\" onClick='javascript:show_hide_column(3, false);' value=\"hide\" checked><b>Kernel Version</b></td>";
        $display .= "<td><input type=\"checkbox\" name=\"hidearch\" onClick='javascript:show_hide_column(4, false);' value=\"hide\" checked><b>Arch</b></td>";
        if ($sortby == "device")
                $display .= "<td style=\"background-color:#d0b0ff\"><input type=\"checkbox\" name=\"hideprod\" onClick='javascript:show_hide_column(5, false);' value=\"hide\" checked><b>Product Name</b></td>";
        else
                $display .= "<td><input type=\"checkbox\" name=\"hideprod\" onClick='javascript:show_hide_column(5, false);' value=\"hide\" checked><b>Product Name</b></td>";
        if ($sortby == "serial_number")
                $display .= "<td style=\"background-color:#d0b0ff\"><input type=\"checkbox\" name=\"hideserial\" onClick='javascript:show_hide_column(6, false);' value=\"hide\" checked><b>Serial Number</b></td>";
        else
                $display .= "<td><input type=\"checkbox\" name=\"hideserial\" onClick='javascript:show_hide_column(6, false);' value=\"hide\" checked><b>Serial Number</b></td>";
        if ($sortby == "bios_release_date")
                $display .= "<td style=\"background-color:#d0b0ff\"><input type=\"checkbox\" name=\"hideserial\" onClick='javascript:show_hide_column(7, false);' value=\"hide\" checked><b>Release Date</b></td>";
        else
                $display .= "<td><input type=\"checkbox\" name=\"hideserial\" onClick='javascript:show_hide_column(7, false);' value=\"hide\" checked><b>Release Date</b></td>";
        if ($sortby == "line_speed")
                $display .= "<td style=\"background-color:#d0b0ff\"><input type=\"checkbox\" name=\"hidespeed\" onClick='javascript:show_hide_column(8, false);' value=\"hide\" checked><b>Line Speed</b></td>";
        else
                $display .= "<td><input type=\"checkbox\" name=\"hidespeed\" onClick='javascript:show_hide_column(8, false);' value=\"hide\" checked><b>Line Speed</b></td>";
        if ($sortby == "memory")
                $display .= "<td style=\"background-color:#d0b0ff\"><input type=\"checkbox\" name=\"hidemem\" onClick='javascript:show_hide_column(9, false);' value=\"hide\" checked><b>Memory</b></td>";
        else
                $display .= "<td><input type=\"checkbox\" name=\"hidemem\" onClick='javascript:show_hide_column(9, false);' value=\"hide\" checked><b>Memory</b></td>";
        if ($sortby == "username")
                $display .= "<td style=\"background-color:#d0b0ff\"><input type=\"checkbox\" name=\"hideuser\" onClick='javascript:show_hide_column(10, false);' value=\"hide\" checked><b>User Logged On</b></td>";
        else
                $display .= "<td><input type=\"checkbox\" name=\"hideuser\" onClick='javascript:show_hide_column(10, false);' value=\"hide\" checked><b>User Logged On</b></td>";
        $display .= "<td><input type=\"checkbox\" name=\"hidevid\" onClick='javascript:show_hide_column(11, false);' value=\"hide\" checked><b>Video Card</b></td>";
        $display .= "<td><input type=\"checkbox\" name=\"hidepanel\" onClick='javascript:show_hide_column(12, false);' value=\"hide\" checked><b>Panels</b></td>";
        if ($sortby == "agenew" || $sortby == "ageold")
                $display .= "<td style=\"background-color:#d0b0ff\"><input type=\"checkbox\" name=\"hidedate\" onClick='javascript:show_hide_column(13, false);' value=\"hide\" checked><b>Last Check-in Date/Time</b></td>";
        else
                $display .= "<td><input type=\"checkbox\" name=\"hidedate\" onClick='javascript:show_hide_column(13, false);' value=\"hide\" checked><b>Last Check-in Date/Time</b></td>";
        $display .= "<td><input type=\"checkbox\" name=\"hidevia\" onClick='javascript:show_hide_column(14, false);' value=\"hide\" checked><b>Via</b></td>";
$display .= "        </tr>";

while ($row = mysql_fetch_row($result)) {
	//this fixes the table blanking carp if theres no value 
	foreach ($row as &$item) {
    		if ($item == "" || $item == NULL)
			$item = "&nbsp;";
	}
	if ($sortby == "hostname")
		$display .= "<tr><td style=\"background-color:#d0b0ff\">$row[1]</td>";
	else
		$display .= "<td>$row[1]</td>";
        if ($sortby == "ip")
                $display .= "<td style=\"background-color:#d0b0ff\">$row[2]</td>";
        else
                $display .= "<td>$row[2]</td>";
        if ($sortby == "version")
                $display .= "<td style=\"background-color:#d0b0ff\">$row[3]</td>";
        else
                $display .= "<td>$row[3]</td>";
        if ($sortby == "kernel")
                $display .= "<td style=\"background-color:#d0b0ff\">$row[4]</td>";
        else
                $display .= "<td>$row[4]</td>";
	$display .= "<td>$row[5]</td>";
        if ($sortby == "device")
                $display .= "<td style=\"background-color:#d0b0ff\">$row[6]</td>";
        else
                $display .= "<td>$row[6]</td>";
        if ($sortby == "serial_number")
                $display .= "<td style=\"background-color:#d0b0ff\">$row[7]</td>";
        else
                $display .= "<td>$row[7]</td>";
        if ($sortby == "bios_release_date")
                $display .= "<td style=\"background-color:#d0b0ff\">$row[15]</td>";
        else
                $display .= "<td>$row[15]</td>";
        if ($sortby == "line_speed")
                $display .= "<td style=\"background-color:#d0b0ff\">$row[8]</td>";
        else
                $display .= "<td>$row[8]</td>";
	if ($sortby == "memory")
                $display .= "<td style=\"background-color:#d0b0ff\">$row[9]</td>";
        else
                $display .= "<td>$row[9]</td>";
        if ($sortby == "username")
                $display .= "<td style=\"background-color:#d0b0ff\">$row[10]</td>";
        else
                $display .= "<td>$row[10]</td>";
        $display .= "<td>$row[11]</td>";
        $display .= "<td>$row[12]</td>";
        if ($sortby == "agenew" || $sortby == "ageold")
                $display .= "<td style=\"background-color:#d0b0ff\">$row[13]</td>";
        else
                $display .= "<td>$row[13]</td>";
        $display .= "<td>$row[14]</td></tr>";
}
$display .= "</table>";

if (!isset($_GET['sort']) || $_GET['sort'] == '') {
print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
<!--************************************************************************-->
<!--* Tabs Demo                                                            *-->
<!--*                                                                      *-->
<!--* Copyright 2002 by Mike Hall                                          *-->
<!--* Please see http://www.brainjar.com for terms of use.                 *-->
<!--*                                                                      *-->
<!--* Note: A transitional DTD is needed due to the use of link targets.   *-->
<!--************************************************************************-->
<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
<head>
<title>Inventory</title>
<meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" />
<!--<link href=\"/common/default.css\" rel=\"stylesheet\" type=\"text/css\" />-->
<style type=\"text/css\">

/******************************************************************************
* Styles for the tabbed displays.                                             *
******************************************************************************/
body {
    background-color: #DEDEDE
}

div.tabBox {}

div.tabArea {
  font-size: 80%;
  font-weight: bold;
  padding: 0px 0px 3px 0px;
}

a.tab {
  background-color: #d0b0ff;
  border: 2px solid #000000;
  border-bottom-width: 0px;
  border-color: #f0d0ff #b090e0 #b090e0 #f0d0ff;
  -moz-border-radius: .75em .75em 0em 0em;
  border-radius-topleft: .75em;
  border-radius-topright: .75em;
  padding: 2px 1em 2px 1em;
  position: relative;
  text-decoration: none;
  top: 3px;
  z-index: 100;
}

a.tab, a.tab:visited {
  color: #8060b0;
}

a.tab:hover {
  background-color: #a080d0;
  border-color: #c0a0f0 #8060b0 #8060b0 #c0a0f0;
  color: #ffe0ff;
}

a.tab.activeTab, a.tab.activeTab:hover, a.tab.activeTab:visited {
  background-color: #9070c0;
  border-color: #b090e0 #7050a0 #7050a0 #b090e0;
  color: #ffe0ff;
}

a.tab.activeTab {
  padding-bottom: 4px;
  top: 1px;
  z-index: 102;
}

div.tabMain {
  background-color: #9070c0;
  border: 2px solid #000000;
  border-color: #b090e0 #7050a0 #7050a0 #b090e0;
  -moz-border-radius: 0em .5em .5em 0em;
  border-radius-topright: .5em;
  border-radius-bottomright: .5em;
  padding: .5em;
  position: relative;
  z-index: 101;
}

div.tabIframeWrapper {
  width: 100%;
}

iframe.tabContent {
  background-color: #9070c0;
  border: 1px solid #000000;
  border-color: #7050a0 #b090e0 #b090e0 #7050a0;
  width: 100%;
  height: 100ex;
}

/******************************************************************************
* Additional styles.                                                          *
******************************************************************************/

h4#title {
  background-color: #503080;
  border: 1px solid #000000;
  border-color: #7050a0 #b090e0 #b090e0 #7050a0;
  color: #d0b0ff;
  font-weight: bold;
  margin-top: 0em;
  margin-bottom: .5em;
  padding: 2px .5em 2px .5em;
}

</style>

<script type=\"text/javascript\">//<![CDATA[

//*****************************************************************************
// Do not remove this notice.
//
// Copyright 2002 by Mike Hall.
// See http://www.brainjar.com for terms of use.
//*****************************************************************************

function synchTab(frameName) {

  var elList, i;

  // Exit if no frame name was given.

  if (frameName == null)
    return;

  // Check all links.

  elList = document.getElementsByTagName(\"A\");

  for (i = 0; i < elList.length; i++)

    // Check if the links target matches the frame being loaded.

    if (elList[i].target == frameName) {

      // If the links URL matches the page being loaded, activate it.
      // Otherwise, make sure the tab is deactivated.

      if (elList[i].href == window.frames[frameName].location.href) {
        elList[i].className += \" activeTab\";
        elList[i].blur();
      }
      else
        removeName(elList[i], \"activeTab\");
    }
}

function removeName(el, name) {

  var i, curList, newList;

  if (el.className == null)
    return;

  // Remove the given class name from the elements className property.

  newList = new Array();
  curList = el.className.split(\" \");
  for (i = 0; i < curList.length; i++)
    if (curList[i] != name)
      newList.push(curList[i]);
  el.className = newList.join(\" \");
}

//]]></script>
</head>
<body>

<div id=\"demoBox\">
<table width=\"100%\"><tr><td align=\"left\">
<h3>CFengine System Inventory</h3>
        <i>Total number of systems checked in: <b>".$count[0]."</b><br>";
	if (isset($search) && isset($sfield))
		print "<i>Search returned <b>".$searchcount."</b> systems matching <b>".$sfield." ".$search."</b><br>";
        print "<i>Oldest check-in: ".$oldest_checkin[0]." at <b>".$oldest_checkin[1]."</b><br>
        <i>Most recent check-in: ".$newest_checkin[0]." at <b>".$newest_checkin[1]."</b><br>

</div></td>
<td align=\"right\">
<form action=\"inventory.php\" method=\"post\">
	<fieldset style=\"width: 200px; padding: 5px; background-color: e5e5e5; white-space:nowrap;\">
	<legend style=\"font: bold 14pt arial; color: black; \">Search</legend>
	<input type=\"radio\" name=\"sindex\" value=\"hostname\" checked>Hostname
	<input type=\"radio\" name=\"sindex\" value=\"username\" unchecked>Username
	<input type=\"radio\" name=\"sindex\" value=\"ip\" unchecked>IP Address
	<p>Search: <input type=\"text\" name=\"search\" size=\"10\" maxlength=\"30\" value=\"".$search."\"><br>
	<input type=\"submit\" name=\"searchbtn\" value=\"Search\">
</fieldset>
</td></tr></table>
<p></p>

<div class=\"tabBox\" style=\"clear:both;\">
  <div class=\"tabArea\">
    <a class=\"tab\" href=\"inventory.php?sort=hostname&search=".$search."&sindex=".$sfield."\" target=\"tabIframe2\">Hostname</a>
    <a class=\"tab\" href=\"inventory.php?sort=ip&search=".$search."&sindex=".$sfield."\" target=\"tabIframe2\">IP</a>
    <a class=\"tab\" href=\"inventory.php?sort=version&search=".$search."&sindex=".$sfield."\" target=\"tabIframe2\">OS Release</a>
    <a class=\"tab\" href=\"inventory.php?sort=kernel&search=".$search."&sindex=".$sfield."\" target=\"tabIframe2\">Kernel Version</a>
    <a class=\"tab\" href=\"inventory.php?sort=device&search=".$search."&sindex=".$sfield."\" target=\"tabIframe2\">Product Name</a>
    <a class=\"tab\" href=\"inventory.php?sort=serial_number&search=".$search."&sindex=".$sfield."\" target=\"tabIframe2\">Serial #</a>
    <a class=\"tab\" href=\"inventory.php?sort=bios_release_date&search=".$search."&sindex=".$sfield."\" target=\"tabIframe2\">Release Date</a>
    <a class=\"tab\" href=\"inventory.php?sort=line_speed&search=".$search."&sindex=".$sfield."\" target=\"tabIframe2\">Line Speed</a>
    <a class=\"tab\" href=\"inventory.php?sort=memory&search=".$search."&sindex=".$sfield."\" target=\"tabIframe2\">Memory</a>
    <a class=\"tab\" href=\"inventory.php?sort=username&search=".$search."&sindex=".$sfield."\" target=\"tabIframe2\">Username</a>
    <a class=\"tab\" href=\"inventory.php?sort=ageold&search=".$search."&sindex=".$sfield."\" target=\"tabIframe2\">Sort Oldest First</a>
    <a class=\"tab\" href=\"inventory.php?sort=agenew&search=".$search."&sindex=".$sfield."\" target=\"tabIframe2\">Sort Newest First</a>
  </div>
  <div class=\"tabMain\">
    <div class=\"tabIframeWrapper\"><iframe class=\"tabContent\" name=\"tabIframe2\" src=\"inventory.php?sort=agenew&search=".$search."&sindex=".$sfield."\" marginheight=\"8\" marginwidth=\"8\" frameborder=\"0\">$display</iframe></div>
  </div>

</div>

</body>
</html>";
}
else
	print $display;
?>

'
' Likewise Enterprise migration script to import Linux/UNIX users to OU in DC=onshore,DC=pgs,DC=com
'
' Generated: {unknown date} by {unknown}
' Migration tool version: {generated by LwDeployVbs module}
'
' IMPORTANT NOTE:
' This is an automatically generated script file. Executing this file will result
' in changes to your directory server. It is important that you read through this
' file, understand its operation and verify that it will do what you expect it to.
'
' To execute this file, type:
'    cscript SCRIPTNAME
'
' This script will always run with your current (login) credentials.

If UCase(Right(Wscript.FullName, 11)) <> "CSCRIPT.EXE" Then
    Wscript.Echo "This script must be run with CSCRIPT, not WSCRIPT."
    Wscript.Quit
End If

' Variable declarations
Dim LikewiseIdentity
Dim LWIConnection
Dim LWIADGroup
Dim LWICell
Dim LWIUser
Dim LWIGroup
Dim LWIMapEntry
Dim ADSIDomainDN
Dim ADSIOUObject
Dim ADSIGroupObject
Dim ADOConnection
Dim ADOCommand
Dim bChanged
Dim objUConnection ' connection for searching user by samAccountName
Dim objUCommand ' command to be used for user search
Dim objURecordSet ' Recordset for finding user by samAccountName
Dim strUDN ' User full DN
Dim strRelDN ' User's Relative DN, because LikewiseIdentity doesn't accept full DNs

Dim objFSO, folder, outfile, mappingList


Set ADOConnection = Nothing

'organizationalunit = Wscript.Arguments(0)
'mapfilelocation = Wscript.Arguments(1)
'passwdfilelocation = Wscript.Arguments(2)

organizationalunit = ""
mapfilelocation = ""
passwdfilelocation = ""

For i = 0 to Wscript.Arguments.Count - 1
	If Wscript.Arguments(i) = "-c" Then
		organizationalunit = Wscript.Arguments(i+1)
	Elseif Wscript.Arguments(i) = "-m" Then
		mapfilelocation = Wscript.Arguments(i+1)
	Elseif Wscript.Arguments(i) = "-p" Then
		passwdfilelocation = Wscript.Arguments(i+1)
	Elseif Wscript.Arguments(i) = "-h" or Wscript.Arguments(i) = "-h"  Then
		Wscript.Echo("Usage: migration.vbs -c [cell name] -m [map file location] -p [passwd file location]" & vbCr & vbLf & vbCr & vbLf &  "Example: migration.vbs -c houston -m map.txt -p passwd.txt")
		Wscript.Quit 0
		End If
Next

If organizationalunit = "" or mapfilelocation = "" or passwdfilelocation = "" Then
	Wscript.Echo("Usage: migration.vbs -c [cell name] -m [map file location] -p [passwd file location]" & vbCr & vbLf & vbCr & vbLf &  "Example: migration.vbs -c houston -m map.txt -p passwd.txt")
	Wscript.Quit 0
End If

WScript.Echo "Starting Likewise Enterprise account migration to: OU=" & organizationalunit & ",DC=onshore,DC=pgs,DC=com"

' Connect to Likewise Enterprise scripting object
WScript.Echo "Initializing..."
Set LikewiseIdentity = CreateObject("Likewise.Identity")
Set LWIConnection = LikewiseIdentity.Initialize()

' Connect to the domain
WScript.Echo "Connecting to domain..."
LWIConnection.Connect "LDAP://onshore.pgs.com/DC=onshore,DC=pgs,DC=com"

' Get object for cell at: Regional OU
WScript.Echo "Opening cell: OU=" & organizationalunit
Set LWICell = LWIConnection.GetCell("OU=" & organizationalunit)

Set ADSIOUObject = GetObject("LDAP://onshore.pgs.com/OU=" & organizationalunit & ",DC=onshore,DC=pgs,DC=com")






Const ForReading = 1
Set objFSO = CreateObject("Scripting.FileSystemObject")
'Set folder = objFSO.GetFolder("c:\test\")
Set mapfile = objFSO.OpenTextFile(mapfilelocation, ForReading)
'Set outfile = objFSO.CreateTextFile("c:\test\testout.txt")
Set mappingList = CreateObject( "System.Collections.ArrayList" )


'for each file in folder.Files

'if lcase(objFSO.getExtensionName(file.path))="txt" then

'Set testfile = objFSO.OpenTextFile(file.path, ForReading)
Do Until mapfile.AtEndOfStream
     line = mapfile.ReadLine
     usermap = Split(line, vbtab)
     mappingList.Add(usermap)
Loop

mapfile.close

Set passwdfile = objFSO.OpenTextFile(passwdfilelocation, ForReading)
Set passwdentry = CreateObject( "System.Collections.ArrayList" )

Do Until passwdfile.AtEndOfStream
     entry = passwdfile.ReadLine
     passwdentry = Split(entry, ":")
	 adname = ""
	 unixname = passwdentry(0)
	 unixuid = passwdentry(2)
	 unixgid = passwdentry(3)
	 gecos = passwdentry(4)
	 homedir = passwdentry(5)
	 shell = passwdentry(6)
	 foundinmap = 0
     For Each account in mappingList
		'==========================================================================================================
		'SETUP ACCOUNT INFORMATION IN ACTIVE DIRECTORY
		if StrComp(account(0),passwdentry(0)) = 0 Then
			Wscript.echo("Migrating UNIX user " + unixname + " to: " + account(1))
			foundinmap = 1 'Found in mappingList
			adname = account(1)
			lwlogin = LCase(adname)
	 
			' Set up connections for finding user
			Set objConnection = CreateObject("ADODB.Connection")
			Set objUCommand = CreateObject("ADODB.Command")
			objConnection.Provider = "ADsDSOObject"
			objConnection.Open "Active Directory Provider"

			' need to create a command object for the user
			set objUCommand.ActiveConnection = objConnection
			objUCommand.CommandText = "SELECT sAMAccountName,cn,distinguishedName FROM 'LDAP://onshore.pgs.com' WHERE objectCategory='Person' and objectClass='User' and sAMAccountName='" & adname & "'"
			Set objURecordSet = objUCommand.Execute
			if objURecordSet.RecordCount = 0 Then
				Wscript.Echo "Could not find name " & adname & " so searching for unix name " & unixname
				objUCommand.CommandText = "SELECT sAMAccountName,cn,distinguishedName FROM 'LDAP://onshore.pgs.com' WHERE objectCategory='Person' and objectClass='User' and sAMAccountName='" & unixname & "'"
			End If
			if  objURecordSet.RecordCount = 1 Then
				strUDN=objURecordset.Fields("distinguishedName")

				strRelDN = left(strUDN, instr(strUDN, ",DC=")-1)

				' "strUDN" below used to be '$userRelDN' in the original Perl
				' enabling user 
				Set LWIUser = LWICell.GetUser(strRelDN)
				If LWIUser is Nothing Then
					' Enable user stored in  strRelDN
					WScript.Echo "Enabling user: " & strRelDN
					Set LWIUser = LWICell.EnableUserEx(strRelDN, "CN=Domain Users,CN=Users", unixuid)
				End If
				LWIUser.UID = unixuid
				LWIUser.GID = unixgid
				LWIUser.LoginName = lwlogin
				LWIUser.LoginShell = shell
				LWIUser.HomeDirectory = homedir
				LWIUser.GECOS = gecos
				Call LWIUser.CommitChanges
			Else

				'WScript.Echo "Didn't find 1 entry for " & adname & ", but did find:"
				do Until objURecordset.EOF
					WScript.Echo objURecordset.Fields("distinguishedName")
				loop
		 
			End If

			'unset the user connections, so the next user doesn't rematch this search.
			set objConnection = Nothing
			set objUCommand = Nothing
			set objURecordSet = Nothing
			set strUDN = Nothing
			set strRelDN = Nothing
		end If
	'=========================================================================================================='
	'Go to next user
    Next
	 
	if foundinmap = 0 Then
		MsgBox unixname & " did not map to an Active Directory ID in map file"
	End If
Loop

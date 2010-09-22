''' VBScript

''' ###########################################################################
'''
''' TortoiseSVN Desktop Shortcut Creator
''' ------------------------------------
'''
''' $URL$
''' $Rev$
'''
''' This file accompanies Rob Hubbard's Subversion Configuration Suite
'''
''' @ 2010, Rob Hubbard.
'''
''' ###########################################################################

Option Explicit

''' ===========================================================================

Const window_style_normal = 1
Const window_style_maximised = 3
Const window_style_minimised = 7

''' ===========================================================================

Sub Create_Desktop_ShortCut ( _
	ByVal target_name, _
	ByVal target_path, _
	ByVal target_args, _
	ByVal working_path, _
	ByVal window_style, _
	ByVal icon_path, _
	ByVal icon_num, _
	ByVal comment )

	Dim wsh_shell
	Set wsh_shell = CreateObject("WScript.Shell")

	Dim shortcut_path
	shortcut_path = "Desktop"
	shortcut_path = wsh_shell.SpecialFolders(shortcut_path)
	Dim shortcut
	Set shortcut = wsh_shell.CreateShortcut(shortcut_path & "\" & target_name & ".lnk")
	With shortcut
		.TargetPath = target_path
		.Arguments = target_args
		.WorkingDirectory = working_path
		.WindowStyle = window_style
		.IconLocation = icon_path & "," & icon_num
		.Description = comment
		'.FullName
		'.RelativePath
		.Save
	End With

End Sub

''' ===========================================================================

Sub Create_TSVN_Desktop_ShortCut ( _
	ByVal target_name, _
	ByVal args, _
	ByVal comment )

	Create_Desktop_ShortCut target_name, _
		"C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe", _
		args, "", window_style_normal, _
		"C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe", 0, _
		comment

End Sub

''' ---------------------------------------------------------------------------

Sub Create_TSVN_Settings_Desktop_ShortCut ()

	Create_TSVN_Desktop_ShortCut _
		"TSVN Settings", _
		"/command:settings", _
		"open TortoiseSVN settings"

End Sub

''' ---------------------------------------------------------------------------

Sub Create_TSVN_RepoBrowser_Desktop_ShortCut ( _
	ByVal target_name, _
	ByVal url )

	Create_TSVN_Desktop_ShortCut _
		"Browse " & target_name, _
		"/command:repobrowser /path:" & url, _
		"open TortoiseSVN RepoBrowser to " & target_name & " at " & url

End Sub

''' ---------------------------------------------------------------------------

Sub Create_TSVN_Log_Desktop_ShortCut ( _
	ByVal target_name, _
	ByVal url )

	Create_TSVN_Desktop_ShortCut _
		"Log of " & target_name, _
		"/command:log /path:" & url, _
		"open TortoiseSVN Log to " & target_name & " at " & url

End Sub

''' ---------------------------------------------------------------------------

Sub Create_TSVN_Mods_Desktop_ShortCut ( _
	ByVal target_name, _
	ByVal wc_path )

	Create_TSVN_Desktop_ShortCut _
		"Local Modifications to " & target_name, _
		"/command:repostatus /path:" & wc_path, _
		"open TortoiseSVN Local Modifications to " & target_name & " at " & wc_path

End Sub

''' ---------------------------------------------------------------------------

Sub Create_Kill_TSVN_Cache_Desktop_ShortCut ()

	Dim curDir
	curDir = left(WScript.ScriptFullName, _
		(Len(WScript.ScriptFullName))-(len(WScript.ScriptName)))

	Create_Desktop_ShortCut _
		"Kill TSVN Cache", _
		curDir & "\" & "process_kill_tsvn-cache.bat", _
		"", _
		"", _
		window_style_normal, _
		"C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe", 0, _
		"kill TortoiseSVN cache"

		'"C:\WINDOWS\system32\SHELL32.dll", 71, _

End Sub

''' ===========================================================================

'Create_Desktop_ShortCut "Notepad", "C:\WINDOWS\NOTEPAD.EXE", "", "", window_style_normal, "C:\WINDOWS\NOTEPAD.EXE", 0, "open Notepad"

'Create_TSVN_Settings_Desktop_ShortCut
'Create_TSVN_RepoBrowser_Desktop_ShortCut "Meta", "svn:///svn-meta/_trunk/"
'Create_TSVN_Log_Desktop_ShortCut "Meta", "svn:///svn-meta/_trunk/"
'Create_TSVN_Mods_Desktop_ShortCut "Meta", "C:\Rob\version_controlled\wc\svn-meta\trunk"

'Create_TSVN_RepoBrowser_Desktop_ShortCut "Code", "svn:///eng/_trunk/code/"

'Create_Kill_TSVN_Cache_Desktop_ShortCut

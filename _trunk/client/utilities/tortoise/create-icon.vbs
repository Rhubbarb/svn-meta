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
	ByVal icon_num, _
	ByVal comment )

	Dim wsh_shell
	Set wsh_shell = CreateObject("WScript.Shell")

	Dim shortcut_path
	shortcut_path = "Desktop"
	shortcut_path = wsh_shell.SpecialFolders(shortcut_path)
	Dim shortcut
	Set shortcut = wsh_shell.CreateShortcut(shortcut_path & "\\" & target_name & ".lnk")
	With shortcut
		.TargetPath = target_path
		.Arguments = target_args
		.WorkingDirectory = working_path
		.WindowStyle = window_style
		.IconLocation = target_path & "," & icon_num
		.Description = comment
		'.FullName
		'.RelativePath
		.Save
	End With

End Sub

''' ===========================================================================

Sub Create_TSVN_Desktop_ShortCut ( _
	ByVal target_name, _
	ByVal args )

	Create_Desktop_ShortCut target_name, _
		"C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe", _
		args, "", window_style_normal, 0, ""

End Sub

''' ---------------------------------------------------------------------------

Sub Create_TSVN_Settings_Desktop_ShortCut ( _
	ByVal target_name)

	Create_TSVN_Desktop_ShortCut _
		target_name, _
		"/command:settings"

End Sub

''' ---------------------------------------------------------------------------

Sub Create_TSVN_RepoBrowser_Desktop_ShortCut ( _
	ByVal target_name, _
	ByVal url )

	Create_TSVN_Desktop_ShortCut _
		"Browse " & target_name, _
		"/command:repobrowser /path:" & url

End Sub

''' ---------------------------------------------------------------------------

Sub Create_TSVN_Log_Desktop_ShortCut ( _
	ByVal target_name, _
	ByVal url )

	Create_TSVN_Desktop_ShortCut _
		"Log of " & target_name, _
		"/command:log /path:" & url

End Sub

''' ---------------------------------------------------------------------------

Sub Create_TSVN_Mods_Desktop_ShortCut ( _
	ByVal target_name, _
	ByVal wc_path )

	Create_TSVN_Desktop_ShortCut _
		"Local Modifications to " & target_name, _
		"/command:repostatus /path:" & wc_path

End Sub

''' ===========================================================================

'Create_Desktop_ShortCut "Open Notepad", "C:\WINDOWS\NOTEPAD.EXE", "", "", window_style_normal, 0, "notepad"

'Create_TSVN_Settings_Desktop_ShortCut "TSVN Settings"
'Create_TSVN_RepoBrowser_Desktop_ShortCut "Meta", "svn:///svn-meta/_trunk/"
'Create_TSVN_Log_Desktop_ShortCut "Meta", "svn:///svn-meta/_trunk/"
'Create_TSVN_Mods_Desktop_ShortCut "Meta", "C:\\Rob\\version_controlled\\wc\\svn-meta\\trunk"

'Create_TSVN_RepoBrowser_Desktop_ShortCut "Code", "svn:///eng/_trunk/code/"

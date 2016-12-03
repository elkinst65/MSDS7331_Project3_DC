Dim goFSO: Set goFSO = CreateObject("Scripting.FileSystemObject")
Dim goRules : Set goRules = CreateObject("Scripting.Dictionary")
'Dim goData: Set goData = goFSO.OpenTextFile("C:\Users\Thomas\OneDrive\Documents\School\7331 - Data Mining\MSDS7331_Project3_DC\trunk\data\DC_Crime_2015_Lab3_ARules_Coded3.csv")
Dim goData: Set goData = goFSO.OpenTextFile("C:\Users\Thomas\OneDrive\Documents\School\7331 - Data Mining\MSDS7331_Project3_DC\trunk\data\DC_Crime_2015_Lab3_ARules_VP.csv")

goData.Readline
gnRec = 0
While Not goData.AtEndOfStream
	psTransaction = goData.Readline
	
	paItems = Split(psTransaction,",")
	'
	'	[0] Transaction
	'	[1] Offense 	(A)
	'	[2] PSA			(B)
	'	[3] Avg Temp	(C)
	'	[4] Avg Humid	(D)
	'	[5] Precip		(E)
	'	[6] Season		(F)
	'	[7] Weekday		(G)
	'	[8] Period		(H)
	'
	Ruler "", 1
	
	gnRec = gnRec + 1
WEnd

Dim goRuleFile: Set goRuleFile = goFSO.CreateTextFile("C:\Users\Thomas\OneDrive\Documents\School\7331 - Data Mining\MSDS7331_Project3_DC\trunk\data\Rules_SMOTE.csv")
goRuleFile.Writeline "LHS,RHS,Count,Support,Confidence,Lift"

For Each psRule In goRules.Keys
	'
	'	Rule = :A
	'	Rule = :A:B
	pSupport = Support(psRule)
	pConf = InStr(2,psRule,":")
	
	If pConf > 0 Then
		'Msgbox "psRule: {" & psRule & "}; Colon found @ " & pConf & "; Parent: {" & Mid(psRule,pConf+1) & "}; Count: " & goRules(Mid(psRule,pConf))
		sLHS = Left(psRule,pConf-1)
		sRHS = Mid(psRule,pConf)
		goRuleFile.Write "{" & Mid(sRHS,2) & "},{" & Mid(sLHS,2) & "}," & goRules(psRule) & "," & pSupport & "," & CDbl(goRules(psRule)) / CDbl(goRules(sRHS)) & "," & Lift(sLHS,sRHS)
	Else
		sLHS = ""
		sRHS = psRule
		goRuleFile.Write "{},{" & Mid(psRule,2) & "}," & goRules(psRule) & "," & pSupport
	End If
	
	goRuleFile.Writeline
Next
goRuleFile.Close

Function Support(sRule)
	Support = CDbl(goRules(sRule)) / CDbl(gnRec)
End Function

Function Lift(sLeft, sRight)
	Dim pdLift
	On Error Resume Next
	'Msgbox "s{" & sLeft & sRight & "} = " & Support(sLeft & sRight) & vbCRLF & "s{" & sRight & "} = " & Support(sRight) & vbCRLF & "s{" & sLeft & "} = " & Support(sLeft)
	pdLift = Support(sLeft & sRight) / (Support(sRight) * Support(sLeft))
	If Err.Number <> 0 Then pdLift = 0.0
	On Error Goto 0
	Lift = pdLift
End Function

Sub Ruler(sPrefix, nIndex)
	
	For idx = nIndex to 8
		sWord = paItems(idx)
		
		sItem = sPrefix & ":" & sWord
		
		If goRules.Exists(sItem) Then
			goRules(sItem) = goRules(sItem) + 1
		Else
			goRules(sItem) = 1
		End If
		
		If idx < 8 Then Ruler sItem,idx + 1
	Next
End Sub

	'	0	1	2	3
	'	1	A1	B3	C1
	'	2	A1	B2	C1
	'	3	A2	B1	C2
	'	4	A2	B1	C1
	'
	'1:
	'	1:2	=			A1,B3		1
	'		1:2:3	=	A1,B3,C1	1
	'	1:3	=			A1,C1		1
	'2:
	'	1:2 =			A1,B2		1
	'		1:2:3 =		A1,B2,C1	1
	'	1:3 =			A1,C1		2
	'3:
	'	1:2 =			A2,B1		1
	'		1:2:3 =		A2,B1,C2	1
	'	1:3 =			A2,C2		1
	'4:
	'	1:2 =			A2,B1		2
	'		1:2:3 =		A2,B1,C1	1
	'	1:3 =			A2,C1		1
	'
	'Rec 1: A1, B3, C1
	'	Ruler(A1,2)
	'		Loop 2-3
	'			@2:	A1 + Rec[@2]	= 				A1|B3		New: 1
	'				2 < 3 --> Ruler(A1|B3,3)
	'					Loop 3-3
	'						@3: A1|B3 + Rec(3) = 	A1|B3|C1	New: 1
	'					End
	'			@3: A1 + Rec(3)		= 				A1|C1		New: 1
	'				3 !< 3
	'Rec 2: A1, B2, C1
	'	Ruler(A1,2)
	'		Loop 2-3
	'			@2: A1 + Rec(2) =					A1|B2		New: 1
	'				2<3 --> Ruler(A1|B2,3)
	'					Loop 3-3
	'						@3: A1|B2 + Rec(3) = 	A1|B2|C1	New: 1
	'							3!<3
	'					End
	'				End
	'			@3:	A1 + Rec(3) = 					A1|C1		Add: 2
	'				3!<3
	'		End
	'	End
	'Rec 3:	A2, B1, C2
	'	Ruler(A2,2)
	'		Loop 2-3
	'			@2: A2 + Rec(2) =					A2|B1		New: 1
	'				2<3 --> Ruler(A2|B1,3)
	'					Loop 3-3
	'						@3: A2|B1 + Rec(3) = 	A2|B1|C2	New: 1
	'							3 !< 3
	'					End
	'				End
	'			@3: A2 + Rec(3) =					A2|C2		New: 1
	

goData.Close
msgbox "# records = " & gnRec
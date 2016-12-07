Dim goFSO	: Set goFSO = CreateObject("Scripting.FileSystemObject")
Dim goRules : Set goRules = CreateObject("Scripting.Dictionary")
Dim gaItems
Dim gnRules
Dim gnTx
Dim goTopCol : Set goTopCol = CreateObject("Scripting.Dictionary")
Dim goTopRow : Set goTopRow = CreateObject("Scripting.Dictionary")
Dim goTopRule: Set goTopRule = CreateObject("Scripting.Dictionary")
'
'	Process files that are dragged/dropped onto this script
For Each sFile In WScript.Arguments
	pdStart = Timer
	
	gnRules = 0
	gnTx = 0
	
	GenerateItemsets sFile
	GenerateRules sFile
	
	MsgBox "Processed " & gnTx & " transactions in file '" & sFile & "': Generated " & gnRules & " rules in " & Round(Timer-pdStart,2) & " seconds."
Next


Sub GenerateItemsets(xsFile)
	Dim goData	: Set goData = goFSO.OpenTextFIle(xsFile)

	goData.Readline		'	Skip over the field header
	gnTx = 0			'	Reset the record counter
	
	'
	'	Loop through the file
	While Not goData.AtEndOfStream
		'
		'	Read a transaction
		psTransaction = goData.Readline
		'
		'	Break the transaction into individual items
		gaItems = Split(psTransaction,",")
		'
		'	[0] Transaction
		'	[1] Offense
		'	[2] PSA
		'	[3] Avg Temp
		'	[4] Avg Humid
		'	[5] Precip
		'	[6] Season
		'	[7] Weekday
		'	[8] Period
		'
		Ruler "", 1
	
		gnTx = gnTx + 1
	WEnd
	'
	'	Close the input file
	goData.Close
End Sub

Sub GenerateRules(xsFile)
	'
	'	Get the input file's extension
	psExt = goFSO.GetExtensionName(xsFile)
	
	'	Replace the file extension with the _Rules indicator and CSV extension
	Dim goRuleFile: Set goRuleFile = goFSO.CreateTextFile(Replace(xsFile,"." & psExt,"_Rules.csv"))
	Dim goSupVConf: Set goSupVConf = goFSO.CreateTextFile(Replace(xsFile,"." & psExt,"_SvC.htm"))
	Dim goSupVLift: Set goSupVLift = goFSO.CreateTextFile(Replace(xsFile,"." & psExt,"_SvL.htm"))
	Dim goTopRules: Set goTopRules = goFSO.CreateTextFile(Replace(xsFile,"." & psExt,"_TopRules.csv"))
	Dim goRuleMatx: Set goRUleMatx = goFSO.CreateTextFile(Replace(xsFile,"." & psExt,"_RuleMatrix.htm"))
	
	SetupSVC goSupVConf, xsFile
	SetupSVL goSupVLift, xsFile
	
	'	Write the field header
	goRuleFile.Writeline "LHS,RHS,Count,Support,Confidence,Lift"
	pnTopRules = 0

	'	Loop through the itemsets found in the previous step
	For Each psRule In goRules.Keys
		'
		'	Ignore itemsets that appear only once
		pnCnt = goRules(psRule)
		If pnCnt > 1 Then
			'
			'	Look for a multi-item set
			pnMult = InStr(2,psRule,":")
			
			'	Do we have a multi-item set?
			If pnMult > 0 Then
				'
				'	Separate the left-most item and make it our target
				'Msgbox "psRule: {" & psRule & "}; Colon found @ " & pnMult & "; Parent: {" & Mid(psRule,pnMult+1) & "}; Count: " & goRules(Mid(psRule,pnMult))
				sLHS = Left(psRule,pnMult-1)
				sRHS = Mid(psRule,pnMult)
				
				pdSup = Support(psRule)
				pdCnf = CDbl(pnCnt) / CDbl(goRules(sRHS))
				pdLft = Lift(sLHS,sRHS)
				
				'psRed = Right("0" & Hex(255 - Round(pdLft * 3.0,0)),2)
				psRed = Right("0" & Hex(Round(pdSup * 255,0)), 2)
				psGrn = Right("0" & Hex(Round(pdCnf * 255,0)), 2)
				psBlu = Right("0" & Hex(Round(pdLft * 20.0,0)), 2)
				
				psItm = Mid(sRHS,2)
				psTgt = Mid(sLHS,2)
				
				'
				'	Write the rule, the count, the support, the confidence, and the lift for this rule
				goRuleFile.Write "{" & psItm & "},{" & psTgt & "}," & pnCnt & "," & pdSup & "," & pdCnf & "," & pdLft
				
				If (pdSup > 0.2) and (pdCnf > 0.2) Then
					'
					'
					pnTopRules = pnTopRules + 1
					goTopRules.Writeline "{" & psItm & "},{" & psTgt & "}," & pnCnt & "," & pdSup & "," & pdCnf & "," & pdLft
					'
					'	Set the unique column (items) label
					goTopCol(psItm) = psItm
					'
					'	Set the unique row (target) label
					goTopRow(psTgt) = psTgt
					'
					'	Save the rule
					goTopRule(psItm & "-->" & psTgt) = pnCnt & "," & pdSup & "," & pdCnf & "," & pdLft
				End If
				
				If Int(pdSup * 100) > 0 Then
					'
					'	Support v Confidence
					goSupVConf.Writeline "    <circle cx='" & Round(pdSup * 500,0) + 100 & "' cy='" & 500 - Round(pdCnf * 500,0) & "' r='5' style='fill:#" & psRed & psGrn & psBlu & ";stroke:#A9A9A9;stroke-width:1;fill-opacity:0.5;stroke-opacity:0.3;'><title>{" & Mid(sRHS,2) & "}&rarr;{" & Mid(sLHS,2) & "}</title></circle>"
					'
					'	Support v Lift
					goSupVLift.Writeline "    <circle cx='" & Round(pdSup * 500,0) + 100 & "' cy='" & 500 - Round(pdLft / 20 * 500,0) & "' r='5' style='fill:#" & psRed & psGrn & psBlu & ";stroke:#A9A9A9;stroke-width:1;fill-opacity:0.5;stroke-opacity:0.3;'><title>{" & Mid(sRHS,2) & "}&rarr;{" & Mid(sLHS,2) & "}</title></circle>"
				End If
			Else
				'
				'	Write the null-based rule, the count, and support
				goRuleFile.Write "{},{" & Mid(psRule,2) & "}," & goRules(psRule) & "," & Support(psRule)
			End If
			
			goRuleFile.Writeline
		End If
	Next
	goRuleFile.Close
	goSupVConf.Writeline "</svg></body></html>"
	goSupVConf.Close
	goSupVLift.Writeline "</svg></body></html>"
	goSupVLift.Close
	'
	'	Create the rule matrix plot
	If goTopRule.Count > 0 Then
		'
		'	How many unique columns?
		pnCol = goTopCol.Count
		'
		'	How many unique rows?
		pnRow = goTopRow.Count
		'
		'	Set the SVG window width to 30*Col + 300 (for row labels); height = 30 * row + 320 (for col labels)
		goRuleMatx.Writeline "<html><body style='font-family:Arial'><h1>Top Association Rules</h1><h3>" & goFSO.GetBaseName(xsFile) & "</h3><h5>Support > 20%; Color = Support; Size = Confidence</h5><svg width='" & (30.0 * pnCol) + 350 & "' height='" & (30.0 * pnRow) + 320 & "'>"
		'
		'	Loop through the column labels
		piLbl = 1
		For Each psLbl In goTopCol.Keys
			goRuleMatx.Writeline "<text x='" & (30 * (piLbl - 1)) + 65 & "' y='300' transform='rotate(-90 " & (30 * (piLbl - 1)) + 65 & ",300)'>{" & psLbl & "}</text>"
			goRuleMatx.Writeline "<line x1='" & (30 * (piLbl - 1)) + 60 & "' y1='315' x2='" & (30 * (piLbl - 1)) + 60 & "' y2='" & (30 * pnRow) + 330 & "' stroke='silver' stroke-dasharray='2,5'/>"
			piLbl = piLbl + 1
		Next
		'
		'	Loop through the row labels
		piLbl = 1
		For Each psLbl In goTopRow.Keys
			goRuleMatx.Writeline "<text x='" & (30 * pnCol) + 60 & "' y='" & (30 * (piLbl - 1)) + 330 & "'>{" & psLbl & "}</text>"
			goRuleMatx.Writeline "<line x1='50' y1='" & (30 * (piLbl - 1)) + 325 & "' x2='" & (30 * pnCol) + 50 & "' y2='" & (30 * (piLbl - 1)) + 325 & "' stroke='silver' stroke-dasharray='2,5'/>"
			piLbl = piLbl + 1
		Next
		'
		'	Loop through the rules
		piCol = 1
		For Each psItm In goTopCol.Keys
			piRow = 1
			For Each psTgt In goTopRow.Keys
				If goTopRule.Exists(psItm & "-->" & psTgt) Then
					paVal = Split(goTopRule(psItm & "-->" & psTgt),",")
					
					psRed = Right("0" & Hex(255 - Round(CDbl(paVal(1)) * 255,0)), 2)
					psGrn = Right("0" & Hex(Round(CDbl(paVal(2)) * 255,0)), 2)
					psBlu = Right("0" & Hex(Round(CDbl(paVal(3)) * 20.0,0)), 2)
					
					goRuleMatx.Writeline "<circle cx='" & (30 * (piCol - 1)) + 60 & "' cy='" & (30 * (piRow - 1)) + 325 & "' r='" & 30.0 * CDbl(paVal(2)) & "' style='fill:#FF" & psRed & psRed & ";stroke:#A9A9A9;stroke-width:1;fill-opacity:0.5;stroke-opacity:0.3;'/>"
				End If
				piRow = piRow + 1
			Next
			piCol = piCol + 1
		Next
		'
		goRuleMatx.Writeline "</svg></body></html>"
		goRuleMatx.Close
	End If
End Sub

	
Function Support(sRule)
	Support = CDbl(goRules(sRule)) / CDbl(gnTx)
End Function

Function Lift(sLeft, sRight)
	Dim pdLift
	On Error Resume Next
	pdLift = Support(sLeft & sRight) / (Support(sRight) * Support(sLeft))
	If Err.Number <> 0 Then pdLift = 0.0
	On Error Goto 0
	Lift = pdLift
End Function

Sub Ruler(sPrefix, nIndex)
	
	For idx = nIndex to 8
		sWord = gaItems(idx)
		
		sItem = sPrefix & ":" & sWord
		
		If goRules.Exists(sItem) Then
			goRules(sItem) = goRules(sItem) + 1
		Else
			goRules(sItem) = 1
			gnRules = gnRules + 1
		End If
		
		If idx < 8 Then Ruler sItem,idx + 1
	Next
End Sub

Sub SetupSVC(goHTM, xsFile)
	goHTM.Writeline "<html><body style='font-family:Arial'>"
	goHTM.Writeline "<h1>Support vs. Confidence</h1>"
	goHTM.Writeline "<h3>" & goFSO.GetBaseName(xsFile) & "</h3>"
	goHTM.Writeline "<svg width='620' height='600'>"
	goHTM.Writeline "<rect x='200' y='0' width='400' height='400' style='fill:#f0f0f0;'/>"
	goHTM.Writeline "<!-- vertical grid lines -->"
	goHTM.Writeline "<line x1='100' y1='0' x2='100' y2='510' stroke='black'/>"
	goHTM.Writeline "<line x1='200' y1='0' x2='200' y2='510' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='300' y1='0' x2='300' y2='510' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='400' y1='0' x2='400' y2='510' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='500' y1='0' x2='500' y2='510' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='600' y1='0' x2='600' y2='510' stroke='black'/>"
	goHTM.Writeline "<!-- Support labels -->"
	goHTM.Writeline "<text x='100' y='520' fill='black' text-anchor='middle'>0%</text>"
	goHTM.Writeline "<text x='200' y='520' fill='black' text-anchor='middle'>20%</text>"
	goHTM.Writeline "<text x='300' y='520' fill='black' text-anchor='middle'>40%</text>"
	goHTM.Writeline "<text x='400' y='520' fill='black' text-anchor='middle'>60%</text>"
	goHTM.Writeline "<text x='500' y='520' fill='black' text-anchor='middle'>80%</text>"
	goHTM.Writeline "<text x='600' y='520' fill='black' text-anchor='middle'>100%</text>"
	goHTM.Writeline "<text x='350' y='540' fill='black' text-anchor='middle'>Support</text>"
	goHTM.Writeline "<!-- horizontal grid lines -->"
	goHTM.Writeline "<line x1='90' y1='0' x2='600' y2='0' stroke='black'/>"
	goHTM.Writeline "<line x1='90' y1='100' x2='600' y2='100' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='90' y1='200' x2='600' y2='200' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='90' y1='300' x2='600' y2='300' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='90' y1='400' x2='600' y2='400' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='90' y1='500' x2='600' y2='500' stroke='black'/>"
	goHTM.Writeline "<!-- Confidence labels -->"
	goHTM.Writeline "<text x='85' y='10' fill='black' text-anchor='end'>100%</text>"
	goHTM.Writeline "<text x='85' y='105' fill='black' text-anchor='end'>80%</text>"
	goHTM.Writeline "<text x='85' y='205' fill='black' text-anchor='end'>60%</text>"
	goHTM.Writeline "<text x='85' y='305' fill='black' text-anchor='end'>40%</text>"
	goHTM.Writeline "<text x='85' y='405' fill='black' text-anchor='end'>20%</text>"
	goHTM.Writeline "<text x='85' y='505' fill='black' text-anchor='end'>0%</text>"
	goHTM.Writeline "<text x='50' y='250' fill='black' transform='rotate(-90 50,250)' text-anchor='middle'>Confidence</text>"
End Sub

Sub SetupSVL(goHTM, xsFile)
	goHTM.Writeline "<html><body style='font-family:Arial'>"
	goHTM.Writeline "<h1>Support vs. Lift</h1>"
	goHTM.Writeline "<h3>" & goFSO.GetBaseName(xsFile) & "</h3>"
	goHTM.Writeline "<svg width='620' height='600'>"
	goHTM.Writeline "<rect x='200' y='0' width='400' height='400' style='fill:#f0f0f0;'/>"
	goHTM.Writeline "<!-- vertical grid lines -->"
	goHTM.Writeline "<line x1='100' y1='0' x2='100' y2='510' stroke='black'/>"
	goHTM.Writeline "<line x1='200' y1='0' x2='200' y2='510' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='300' y1='0' x2='300' y2='510' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='400' y1='0' x2='400' y2='510' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='500' y1='0' x2='500' y2='510' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='600' y1='0' x2='600' y2='510' stroke='black'/>"
	goHTM.Writeline "<!-- Support labels -->"
	goHTM.Writeline "<text x='100' y='520' fill='black' text-anchor='middle'>0%</text>"
	goHTM.Writeline "<text x='200' y='520' fill='black' text-anchor='middle'>20%</text>"
	goHTM.Writeline "<text x='300' y='520' fill='black' text-anchor='middle'>40%</text>"
	goHTM.Writeline "<text x='400' y='520' fill='black' text-anchor='middle'>60%</text>"
	goHTM.Writeline "<text x='500' y='520' fill='black' text-anchor='middle'>80%</text>"
	goHTM.Writeline "<text x='600' y='520' fill='black' text-anchor='middle'>100%</text>"
	goHTM.Writeline "<text x='350' y='540' fill='black' text-anchor='middle'>Support</text>"
	goHTM.Writeline "<!-- horizontal grid lines -->"
	goHTM.Writeline "<line x1='90' y1='0' x2='600' y2='0' stroke='black'/>"
	goHTM.Writeline "<line x1='90' y1='100' x2='600' y2='100' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='90' y1='200' x2='600' y2='200' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='90' y1='300' x2='600' y2='300' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='90' y1='400' x2='600' y2='400' stroke-dasharray='5,5' stroke='silver'/>"
	goHTM.Writeline "<line x1='90' y1='500' x2='600' y2='500' stroke='black'/>"
	goHTM.Writeline "<!-- Lift labels -->"
	goHTM.Writeline "<text x='85' y='10' fill='black' text-anchor='end'>20</text>"
	goHTM.Writeline "<text x='85' y='105' fill='black' text-anchor='end'>16</text>"
	goHTM.Writeline "<text x='85' y='205' fill='black' text-anchor='end'>12</text>"
	goHTM.Writeline "<text x='85' y='305' fill='black' text-anchor='end'>8</text>"
	goHTM.Writeline "<text x='85' y='405' fill='black' text-anchor='end'>4</text>"
	goHTM.Writeline "<text x='85' y='505' fill='black' text-anchor='end'>0</text>"
	goHTM.Writeline "<text x='50' y='250' fill='black' transform='rotate(-90 50,250)' text-anchor='middle'>Lift</text>"
End Sub


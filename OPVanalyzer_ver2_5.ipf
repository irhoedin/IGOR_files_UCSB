
// OPV analyzer ver 2.5
// April, 17, 2016
// Hidenori Nakayama

//change from ver2.4
//change "p_wave" selecting key to "p_*_" from "p*_".

//In the older version, if the ID start from the letter "P", 
//the IV paramaters list in each time ("p_DMZ0000_0000.txt_1" for example)
//is added to time seaquence wave of each IV paramater list ("DMZ0000_Voc_1", for example).
//This is because the selection of IV parameters list is defined as
//
//p_wavelist = wavelist("p*_" + num2str(ch_i),";","").

//Now the selection key is modified to "p_*_" and this trouble is solved.

//change from ver2.3
// when modules are measured with Wakom, which produce
//ch2 signal of no devices, "Show IV Curves" procdues only IV for ch1
//Also, when module IVs are shown, the y limit is not fixed to -20 to 20,
//but flexibly expand from ymin to ymax

//change from ver 2.2
// W_ID and W_Cmt waves are created for automatic annotion for the each waves

//change from ver 2.1
//when only one paramater is selcted, a large graph window is showen

//change from ver 2.0
//debug "NaN" showing problem in showIVcurves
//Add "setdatafolder root:" to the end of IVcomparison

//change from ver 1.4
//Add "IV comparison" module

//change from ver 1.3
//automatic recognition of sample type (module or flexible or glass)
//delete "select mode" group in "Import IV curves" panel
//change from ver 1.2.1
//now correctly import IV text from GB1 data 
//"DMZ0001.txt" amd "DMZ0001_P.txt" is now handled without error.
//when they areimported, they are renamed as "DMZ0001_1.txt_1p_iv" 

//change from ver 1.2
//axis alignment of IV graphs for modules are corrected

//change from ver1.1.1
//The IV import method was corrected.
//IVcurve text files of modules has bias, photo, dark seaquence of waves,
//while devices bias, dark, photo
//
//change from ver 1.1.1
//changed axis and grid positions for 1ch and 2ch graphs apperes from "show IV curves"

//
//change from ver 1.1
//variable/G root:GLOBAL:ImportIVcurves:chNum = 4
//to set the initial value of chNum as "4"

//change from ver 1.0
//change "time_plot" to "_plot_time", which is originally used in the OPVanalyzer macro.


//1. Menu
Menu "OPV analysis"

	"Import IV curves"				, P_importIVcurves()
	"Show IV cuves"					, P_ShowIVcurves()
	"Plot Properties"				, P_PlotProperties()
	"IV comparison"					, IV_comparison()
	"Refresh Global Parameters"	,RefreshGlobalParameters()

End

//2. import IV curves
Window p_ImportIVcurves() : Panel
	DoWindow/K p_ImportIVcurves
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(0,0,370,150) as "Import IV curves"
	ModifyPanel cbRGB=(65280,54528,48896), frameStyle=2
		
	SetVariable IDPrefix,pos={27,30},size={75,16},bodyWidth=60,title="ID", value = root:GLOBAL:ImportIVcurves:IDprefix
	SetVariable StartNum,pos={115,30},size={89,16},bodyWidth=60,title="Start", value =  root:GLOBAL:ImportIVcurves:StartNum
	SetVariable EndNum,pos={217,30},size={83,16},bodyWidth=60,title="End", value = root:GLOBAL:ImportIVcurves:EndNum
	Button MakeList,pos={132,55},size={70,20},title="Make List", proc=MakeFilterList
	SetVariable ImportFilter,pos={26,80},size={286,16}, value = root:GLOBAL:ImportIVcurves:FilterList
	
	Button Import,pos={133,120},size={70,22},proc=ImportIVcurves,title="\\Z16IMPORT"
	
EndMacro


Function MakeFilterList(ctrlName) :ButtonControl
string ctrlName

SVAR gFilterList  = root:GLOBAL:ImportIVcurves:FilterList
SVAR gIDprefix    = root:GLOBAL:ImportIVcurves:IDprefix
NVAR gStartNum = root:GLOBAL:ImportIVcurves:StartNum
NVAR gEndNum   = root:GLOBAL:ImportIVcurves:EndNum

	gFilterList = ListUpIDs(gIDprefix, gStartNum, gEndNum)

End



Function ImportIVCurves(ctrlName) :ButtonControl
string ctrlName
string pathName
string fileName

Variable index=0

variable retCalParamaters
variable retPlotParamaters

SVAR gFilterList  = root:GLOBAL:ImportIVcurves:FilterList
string IDinFilter
string IDastarisk
variable IDmatch = 0
variable IDmatch_i = 0
variable chNum




NewPath/O temporaryPath // This will put up a dialog
pathName = "temporaryPath"


string fileList = indexedfile($pathname, -1, ".txt") //get a list of the name of text files in the folder
string matchedList = ""

do // loop on index. Fix matchName
		
	string matchName = stringfromlist(index, gFilterList)
	string matchNameAstr = "*" + matchName + "*"

	
	if (strlen(matchName) == 0) // No more files?
		break // Break out of loop
	endif

	
	variable i = 0
	do // loop on nothing. Set matchedList. loop until whichlistitem == -1
	
	string fileNameinList = stringfromlist(i, fileList)
	
	if(strlen(fileNameinList) == 0)
		break
	endif
	
	
	if(stringmatch(fileNameinList,matchNameAstr) == 1) 
	
	variable fileNum = whichlistitem(fileNameinList, fileList, ";", 0, 0)	
	matchedList = matchedList + num2str(fileNum) + ";"
	
	endif
	
	i +=1
	while(1)

index += 1
while(1)

variable getFile_i
do // Loop through each file in folder

	string fileIndex = stringfromlist(getFile_i, matchedList)
	
	
	
	if(strlen(fileIndex) == 0)
		break
	endif
	
	variable fileIndexnum = str2num(fileIndex)
	fileName = textFile($pathName, fileIndexnum)
	
			retCalParamaters = CalParameters(fileName, pathName)
	

	getFile_i += 1
while (1)
	
if (Exists("temporaryPath")) // Kill temp path if it exists
KillPath temporaryPath
endif
return 0 // Signifies success.
End





static Function CalParameters(fileName, pathName) //called from ImportIVCruves
string fileName
string pathName
variable chNum

LoadWave/Q/A/J/D/O/P = $pathName fileName
if(V_flag==0)
	return -1
elseif(V_flag==3)
	chNum = 1
elseif(V_flag==5)
	chNum = 2
elseif(V_flag==9)
	chNum = 4
endif



//set deviceID
variable underbarPos
variable dotPos
string deviceID


underbarPos = strsearch(S_filename, "_",0)
if(underbarPos == -1) 										// Ex. DMZ0010.txt

	dotPos = strsearch(s_fileName, ".",0)
	deviceID = S_fileName[0, dotPos -1]

elseif(stringmatch(S_fileName, "*_P_*") == 1)			// Ex. DMZ0010_P.txt

	deviceID = S_fileName[0,underbarPos+1]

else 															// Ex. DMZ0010_0020.txt

	deviceID = S_fileName[0, underbarPos - 1]

endif



//designate Photo and Dark curves
string bias = StringFromList(0, S_waveNames)
Wave biasCurve = $bias
variable startBias = biasCurve[0]
variable biasStep = biasCurve[1] - biasCurve[0]

SetScale/P x,startBias,biasStep, "", biasCurve

variable endPoint
variable zeroPoint

WaveStats/Q biasCurve
endPoint = V_endRow
zeroPoint = x2pnt(biasCurve, 0)


variable ch_i = 1
string photo
string dark

do

	if(chNum==1) // when IV curve of modules are imported. The waves has seaquence of bias, photo, dark
	
	photo = StringFromList(1, S_waveNames)
	wave photoCurve = $photo
	
	dark   = StringFromList(2, S_waveNames)
	wave darkCurve = $dark

	
	else //when 2 or 4 ch devices are imported. The waves has a seaquence of bias, dark, photo

	photo = StringFromList(ch_i*2, S_waveNames)
	wave photoCurve = $photo
	
	dark   = StringFromList(ch_i*2 - 1, S_waveNames)
	wave darkCurve = $dark
	
	endif
	
	SetScale/P x,startBias,biasStep, "", photoCurve, darkCurve
	
	Make/O/N=6 paramList
	//paramList Voc;Jsc;FF;PCE;Rs(photo);Rsh(photo)
	
	
	//1. Voc unit: V
	FindLevel/Q photoCurve, 0 //find the point where the value closest to J = 0
	paramList[0] = V_LevelX
	
	//2. Jsc unit: mA/cm2
	paramList[1] = photoCurve(0)
	
	//3. FF
	Duplicate/O photoCurve JxV
	JxV = photoCurve*x //unit of energy unit: mW/cm2
	
	WaveStats/Q JxV
	variable JVmax
	JVmax = V_max
	paramList[2] = JVmax/paramList[0]/paramList[1]
	
	//4. PCE unit: %
	variable pint = 100 //energy of incident light unit: mW/cm2
	paramList[3] = JVmax*100/Pint //unit of percentage
	
	//5. Rs unit: ohm cm2
	Make/O/N=2 Rs_coef
	curvefit /Q line kwCwave=Rs_coef photoCurve[endPoint - 10, endPoint]
	paramList[4] = -1000/Rs_coef[1]
	
	//6. Rsh: ohm cm2
	Make/O/N=2 Rsh_coef
	curvefit/Q line kwCWave=Rsh_coef photoCurve[zeroPoint - 5, zeroPoint + 5] //tilt angle at V = 0
	paramList[5] = -1000/Rsh_coef[1]


	//7. Resister waves
	if(DataFolderExists(deviceID) == 0)
		NewDataFolder root:$(deviceID)
	endif
	
	string chNameList = "1d;1p;2d;2p;3d;3p;4d;4p"
	string ch_p = StringFromList(ch_i*2 - 1, chNameList) 
	string ch_d = StringFromList(ch_i*2 - 2, chNameList)
	string ivName
	
	if(stringmatch(S_fileName,"*_*") == 0) //when "DMZ0001.txt" is imported
		ivName = deviceID + "_1.txt"
	elseif(stringmatch(S_filename,"*_P.*") == 1) //when "DMZ0001_P.txt" is imported
		ivName = deviceID + "_1.txt"
	else
		ivName = S_fileName
	endif
	
	Duplicate/O photoCurve  root:$(deviceID):$(ivName + "_" + ch_p + "_iv")
	Duplicate/O darkCurve   root:$(deviceID):$(ivName + "_" + ch_d + "_iv")
	
	Duplicate/O paramList   root:$(deviceID):$("p_" + ivName + "_" + num2str(ch_i))
	
	Killwaves photoCurve, darkCurve, paramList, JxV, Rs_coef, Rsh_coef

	ch_i += 1
while (ch_i <= chNum)

killwaves biasCurve

SetDataFolder :$(deviceID)
ch_i = 1
variable retPlotParameters
string p_wavelist
do
	p_wavelist = wavelist("p_*_" + num2str(ch_i),";","")

	retPlotParameters = plotParameters(p_wavelist, deviceID, ch_i)
	
	ch_i  += 1
while (ch_i <=chNum)



setDataFolder ::
return 0
End




static Function PlotParameters(p_wavelist, deviceID, ch_i)

string p_wavelist

string deviceID
variable ch_i

string p_wave
variable mes_i = 0
variable mesNum //number of memsurments on the device
string S_mesTime
variable underbarPos
variable mesTimePos
variable mesTime

mesNum = ItemsInList(p_wavelist)

Make/O/N=(mesNum) timePlot,VocPlot, JscPlot, FFPlot, PCEPlot, RsPlot, RshPlot

do
	
	p_wave = StringFromList(mes_i , p_wavelist)

	mesTimePos = 2 + strlen(deviceID)
	S_mesTime = p_wave[mesTimePos+1, mestimePos+4]

	
	if(stringmatch(S_mesTime,"txt*") == 1) // when "DMZ0001.txt" is imported
		mesTime = 1
	else
	mesTime = str2num(S_mesTime)
	endif
	
	
	wave pWave = $p_wave
	
	timePlot[mes_i] = mesTime
	VocPlot[mes_i]  = pWave[0]
	JscPlot[mes_i]  = pWave[1]
	FFPlot[mes_i]   = pWave[2]
	PCEPlot[mes_i]  = pWave[3]
	RsPlot[mes_i]   = pWave[4]
	RshPlot[mes_i]  = pWave[5]
	
	mes_i += 1
while (mes_i <= mesNum - 1) //mes_i starts from zero

sort timePlot, timePlot, VocPlot, JscPlot, FFPlot, PCEPlot, RsPlot, RshPlot

//create Normalized plot
Duplicate/O VocPlot VocPlot_r
Duplicate/O JscPlot JscPlot_r
Duplicate/O FFPlot  FFPlot_r
Duplicate/O PCEPlot PCEPlot_r
Duplicate/O RsPlot  RsPlot_r
Duplicate/O RshPlot RshPlot_r

VocPlot_r = VocPlot/VocPlot[0]
JscPlot_r = JscPlot/JscPlot[0]
FFPlot_r  = FFPlot/FFPlot[0]
PCEPlot_r = PCEPlot/PCEPlot[0]
RsPlot_r  = RsPlot/RsPlot[0]
RshPlot_r = RshPlot/RshPlot[0]

//rename *Plot


Duplicate/O timePlot, $(deviceID+"_plot_time")

Duplicate/O VocPlot,  $(deviceID+"_Voc_"+num2str(ch_i))
Duplicate/O JscPlot,  $(deviceID+"_Jsc_"+num2str(ch_i))
Duplicate/O FFPlot,   $(deviceID+"_FF_"+num2str(ch_i))
Duplicate/O PCEPlot,  $(deviceID+"_PCE_"+num2str(ch_i))
Duplicate/O RsPlot,   $(deviceID+"_Rs_"+num2str(ch_i))
Duplicate/O RshPlot,  $(deviceID+"_Rsh_"+num2str(ch_i))

Duplicate/O VocPlot_r,  $(deviceID+"_Voc_r_"+num2str(ch_i))
Duplicate/O JscPlot_r,  $(deviceID+"_Jsc_r_"+num2str(ch_i))
Duplicate/O FFPlot_r,   $(deviceID+"_FF_r_"+num2str(ch_i))
Duplicate/O PCEPlot_r,  $(deviceID+"_PCE_r_"+num2str(ch_i))
Duplicate/O RsPlot_r,   $(deviceID+"_Rs_r_"+num2str(ch_i))
Duplicate/O RshPlot_r,  $(deviceID+"_Rsh_r_"+num2str(ch_i))

killWaves  timePlot, VocPlot, JscPlot, FFPlot, PCEPlot, RsPlot, RshPlot
killWaves  VocPlot_r, JscPlot_r, FFPlot_r, PCEPlot_r, RsPlot_r, RshPlot_r

return 0
End

//3. show IV curves///////////////////////////////////////////////////////////////////
Window P_ShowIVcurves() : Panel
	Dowindow/K P_ShowIVcurves
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(0,100,370,450) as "Show IV Curves"
	ModifyPanel cbRGB=(49152,65280,32768), frameStyle=2
	
	SetVariable showIV_ID,pos={60,20},size={120,15},bodyWidth=90,title="\\Z24\\f01ID"
	SetVariable ShowIV_ID, value = root:GLOBAL:ShowIVcurves:ID
	SetVariable unit,pos={220,35},size={90,15},bodyWidth=60,title="unit"
	SetVariable unit, value = root:GLOBAL:ShowIVcurves:unit
	
	
	GroupBox ParmPlotrange,pos={50,70},size={120,80},title="Param. plot range",frame=0
	SetVariable parmFrom,pos={70,90},size={90,15},bodyWidth=60,title="From"
	SetVariable parmFrom, value = root:GLOBAL:ShowIVcurves:paramfrom
	SetVariable parmTo,pos={70,120},size={90,15},bodyWidth=60,title="To"
	SetVariable parmTo, value = root:GLOBAL:ShowIVcurves:paramTo
	
	
	
	GroupBox PCEPlotrange,pos={200,70},size={120,80},title="PCE plot range",frame=0
	SetVariable PCEfrom,pos={220,90},size={90,15},bodyWidth=60,title="From"
	SetVariable PCEfrom, value = root:GLOBAL:ShowIVcurves:PCEfrom
	SetVariable PCEto,pos={220,120},size={90,15},bodyWidth=60,title="To"
	SetVariable PCEto, value = root:GLOBAL:ShowIVcurves:PCETo
	
	
	
	GroupBox exPeriod,pos={50,170},size={270,120},title="Exclusion Periods",frame=0
	DrawText 95,220,"Period 1"
	SetVariable exFrom1,pos={80,230},size={90,15},bodyWidth=60,title="From"
	SetVariable exFrom1, value = root:GLOBAL:ShowIVcurves:from1
	SetVariable exTo1,pos={80,260},size={90,15},bodyWidth=60,title="To"
	SetVariable exTo1, value = root:GLOBAL:ShowIVcurves:to1
	
	DrawText 215,220,"Period 2"
	SetVariable exFrom2,pos={200,230},size={90,15},bodyWidth=60,title="From"
	SetVariable exFrom2, value = root:GLOBAL:ShowIVcurves:from2
	SetVariable exTo2,pos={200,260},size={90,15},bodyWidth=60,title="To"
	SetVariable exTo2, value = root:GLOBAL:ShowIVcurves:to2



	Button Show_All,pos={145,300},size={69,24},proc=Show_IV_prop,title="Show All"


EndMacro


Function Show_IV_prop(ctrlName): ButtonControl
string ctrlName
SVAR ID    = root:GLOBAL:ShowIVcurves:ID
SVAR unit  = root:GLOBAL:ShowIVcurves:unit


NVAR from1 = root:GLOBAL:ShowIVcurves:from1
NVAR to1   = root:GLOBAL:ShowIVcurves:to1
NVAR from2 = root:GLOBAL:ShowIVcurves:from2
NVAR to2   = root:GLOBAL:ShowIVcurves:to2

NVAR paramFrom  = root:GLOBAL:ShowIVcurves:paramfrom
NVAR paramTo    =  root:GLOBAL:ShowIVcurves:paramto
NVAR PCEFrom    = root:GLOBAL:ShowIVcurves:PCEfrom
NVAR PCETo      = root:GLOBAL:ShowIVcurves:PCEto




Wave rColor = root:GLOBAL:rColor
Wave gColor = root:GLOBAL:gColor
Wave bColor = root:GLOBAL:bColor
string IVwavelist_2p
string Wave2p

string legend1, legend2

legend2 = "\\K" + "(65280,0,0)" + "Voc"+ "\r" + "\\K" + "(65280,43520,0)" + "Jsc" + "\r" + "\\K" + "(0,39168,0)" + "FF" + "\r" + "\\K" + "(0,43520,65280)" + "PCE" +  "\r" +"\\K(0,0,65280)Rs\r" + "\\K(29440,0,58880)Rsh"




setdatafolder root:$(ID)

// calculate number of channels
string IVwaveList = wavelist("*_iv",";","")
variable NumOfCh

if(stringmatch(IVwaveList,"*2d*") == 0) //only 1 ch
	NumOfCh = 1
elseif(stringmatch(IVwaveList, "*3d*") == 0) // 2 ch
	NumOfCh = 2
	
	//if a module is measured in Wakom
	IVwavelist_2p = wavelist("*2p*",";","")
	Wave2p = stringfromlist(0, IVwavelist_2p)
	Wavestats/Q $(Wave2p)
	
	if (V_max < 1e-3)
		NumOfCh = 1
	endif
	
	
else // 4 ch
	NumOfCh = 4 
endif

//make outline
variable left, top, right, down

left  = 0
top   = 0
right = 210 * numOfCh
down  = 550

Display /W=(left,top,right,down)
DoWindow /T kwTopWin, ID
ModifyGraph gFont="Arial",gfSize=10,gmSize=3



//show parameters
variable chNum = 1


do

	string ch = num2str(chNum)
	string L = "Left" + ch
	string B = "Buttom" + ch
	
	Appendtograph/L=$L /B=$B/C=(65280,0,0) $(ID+"_Voc_r_" + ch) vs $(ID+"_plot_time")
	Modifygraph mode($(ID+"_Voc_r_" + ch))=4, marker($(ID + "_Voc_r_" + ch))=19	
	
	Appendtograph/L=$L /B=$B/C=(65280,43520,0) $(ID+"_Jsc_r_"  + ch) vs $(ID+"_plot_time")
	Modifygraph mode($(ID+"_Jsc_r_" + ch))=4, marker($(ID + "_Jsc_r_" + ch))=19	
	
	Appendtograph/L=$L /B=$B/C=(0,39168,0) $(ID+"_FF_r_"  + ch) vs $(ID+"_plot_time")
	Modifygraph mode($(ID+"_FF_r_" + ch))=4, marker($(ID + "_FF_r_" + ch))=19	
	
	Appendtograph/L=$L /B=$B/C=(0,43520,65280) $(ID+"_PCE_r_"  + ch) vs $(ID+"_plot_time")
	Modifygraph mode($(ID+"_PCE_r_" + ch))=4, marker($(ID + "_PCE_r_" + ch))=19	
	
	Appendtograph/L=$L /B=$B/C=(0,0,65280) $(ID+"_Rs_r_"  + ch) vs $(ID+"_plot_time")
	Modifygraph mode($(ID+"_Rs_r_" + ch))=4, marker($(ID + "_Rs_r_" + ch))=19	
	
	Appendtograph/L=$L /B=$B/C=(29440,0,58880) $(ID+"_Rsh_r_"  + ch) vs $(ID+"_plot_time")
	Modifygraph mode($(ID+"_Rsh_r_" + ch))=4, marker($(ID + "_Rsh_r_" + ch))=19	
	
	setaxis $L paramFrom,paramTo

	Appendtograph/L=$("PCE" + ch) /B=$("PCE_t"+ch)/C=(0,0,0) $(ID+"_PCE_" + ch) vs $(ID+"_plot_time")
	Modifygraph mode($(ID+"_PCE_" + ch))=4, marker($(ID + "_PCE_" + ch))=19	
	
	setaxis $("PCE" + ch) PCEFrom, PCETo
	
chNum += 1
while(chNum <= NumOfCh)

// list up IVcurve

string IVwaveList_1p = wavelist("*_1p_iv",";","")

string timeList = ""
string curve_1p
variable i = 0
variable mesTimePos
string S_mesTime
do
	curve_1p = stringfromlist(i,IVwaveList_1p)
	
	if(strlen(curve_1p) == 0)
	 	break
	endif
	
	mesTimePos = strlen(ID)
	S_mesTime = curve_1p[mesTimePos + 1, mesTimePos + 4]

	
	timelist = timelist + S_mesTime + ";"
	
	
i += 1
while(1)

//plot IV curves
variable NumOfTimes = ItemsInList(timeList)

variable time_i = 0
variable exclude_count = 0
do //as for time_i check out how many times should be excludes
	string timeName = stringfromlist(time_i, timelist)
	
	if(strlen(timeName) == 0)
		break
	endif
	
	variable timeN = str2num(timeName)
	
	if(from1 < to1 && from1 <= timeN && timeN <= to1) // if timeN is between the exlusion period1
		exclude_count += 1
	elseif(from2 < to2 && from2 <= timeN && timeN <= to2)
		exclude_count += 1
	endif

time_i +=1
while(1)


Make/O   /N=(NumOfTimes - exclude_count) timeWave = nan
Make/O/T /N=(NumOFTimes - exclude_count) legendWave = ""


time_i = 0
variable timeWave_i = 0
string matchedWave
variable ch_i



do //as for time_i
	string rC = num2str(rColor[timeWave_i])
	string gC = num2str(gColor[timeWave_i])
	string bC = num2str(bColor[timeWave_i])
	timeName = stringfromlist(time_i, timelist)
	
	if(strlen(timeName) == 0)
		break
	endif
	
	timeN = str2num(timeName)
	
	if(from1 < to1 && from1 <= timeN && timeN <= to1) // if timeN is between the exlusion period1
		time_i += 1

	elseif(from2 < to2 && from2 <= timeN && timeN <= to2)
		time_i += 1
	
	else
		
		timeWave[timeWave_i] = timeN
		legendWave[timeWave_i] = "\K("+rC+","+gC+","+bC+")" 
	
		ch_i = 1
		do //as for ch_i
			string current = "current" + num2str(ch_i)
			string bias = "bias" + num2str(ch_i)

			matchedWave = wavelist("*"+timeName+"*_"+ num2str(ch_i)+"d_iv", "","") //dark

			appendtograph/L=$current/B=$bias/C=(rColor[timeWave_i],gColor[timeWave_i],bColor[timeWave_i]) $(matchedWave)
		
			matchedWave = wavelist("*"+timeName+"*_"+ num2str(ch_i)+"p_iv", "","") //photo
			appendtograph/L=$current/B=$bias/C=(rColor[timeWave_i],gColor[timeWave_i],bColor[timeWave_i]) $(matchedWave)
			
			if (NumOfCh == 4)
				setaxis $current -20,20
			endif
			
		ch_i += 1
		while(ch_i <= NumOfCh)

		
		time_i +=1
		timeWave_i += 1
	endif
while(1)

// make Legend1
sort timeWave, timeWave, legendWave

legend1 = ""
	i = 0
	do
		
		legend1 = legend1 + legendWave[i] + num2str(timeWave[i])+ " " + unit + "\r"
	
	i += 1
	while(i <= numOfTimes -exclude_count- 1) // wavepoint starts from zero.


//align axis

if(NumOfCh == 4) //four channels
ch_i = 1
	do
	//freepos
		ch = num2str(ch_i)
		Modifygraph/Z freePos($("current" + ch)) = {0.04 + 0.24*(ch_i - 1), kwFraction}
		Modifygraph/Z freePos($("left" + ch)) = {0.04 + 0.24*(ch_i - 1), kwFraction}
		Modifygraph/Z freePos($("PCE" + ch)) = {0.04 + 0.24*(ch_i - 1), kwFraction}
	
		Modifygraph/Z freePos($("bias" + ch)) = {0.7, kwFraction}
		Modifygraph/Z freePos($("buttom" + ch)) = {0.35, kwFraction}
		Modifygraph/Z freePos($("PCE_t" + ch)) = {0.05, kwFraction}
	
	//axisEnab
		ModifyGraph/Z axisEnab($("current" + ch)) = {0.7,0.95}
		ModifyGraph/Z axisEnab($("left" + ch)) = {0.35,0.6}
		ModifyGraph/Z axisEnab($("PCE" + ch)) = {0.05,0.3}
			
		Modifygraph/Z axisEnab($("bias" + ch)) = {0.04 + 0.24*(ch_i - 1), 0.24 + 0.24*(ch_i - 1)}
		Modifygraph/Z axisEnab($("buttom" + ch)) = {0.04 + 0.24*(ch_i - 1), 0.24 + 0.24*(ch_i - 1)}
		Modifygraph/Z axisEnab($("PCE_t" + ch)) = {0.04 + 0.24*(ch_i - 1), 0.24 + 0.24*(ch_i - 1)}
	
	//grid
	
		ModifyGraph/Z grid($("current" + ch))=1, gridStyle($("current" + ch))=1
		ModifyGraph/Z gridEnab($("current" + ch)) = {0.04 + 0.24*(ch_i - 1), 0.24 + 0.24*(ch_i - 1)}
		ModifyGraph/Z gridRGB($("current" + ch)) = (43520,43520,43520)

		ModifyGraph/Z grid($("bias" + ch))=1, gridStyle($("bias" + ch))=1
		ModifyGraph/Z gridEnab($("bias" + ch)) = {0.7,0.95}
		ModifyGraph/Z gridRGB($("bias" + ch)) = (43520,43520,43520)

		ModifyGraph/Z grid($("left" + ch))=1, gridStyle($("left" + ch))=1
		ModifyGraph/Z gridEnab($("left" + ch)) = {0.04 + 0.24*(ch_i - 1), 0.24 + 0.24*(ch_i - 1)}
		ModifyGraph/Z gridRGB($("left" + ch)) = (43520,43520,43520)

		ModifyGraph/Z grid($("PCE" + ch))=1, gridStyle($("PCE" + ch))=1
		ModifyGraph/Z gridEnab($("PCE" + ch)) = {0.04 + 0.24*(ch_i - 1), 0.24 + 0.24*(ch_i - 1)}
		ModifyGraph/Z gridRGB($("PCE" + ch)) = (43520,43520,43520)


	
		ch_i += 1
	while(ch_i <= numOfCh)

elseif(numOfCh == 2) // two channels

ch_i = 1
	do
	//freepos
		ch = num2str(ch_i)
		Modifygraph/Z freePos($("current" + ch)) = {0.1 + 0.45*(ch_i - 1), kwFraction}
		Modifygraph/Z freePos($("left" + ch)) = {0.1 + 0.45*(ch_i - 1), kwFraction}
		Modifygraph/Z freePos($("PCE" + ch)) = {0.1 + 0.45*(ch_i - 1), kwFraction}
	
		Modifygraph/Z freePos($("bias" + ch)) = {0.7, kwFraction}
		Modifygraph/Z freePos($("buttom" + ch)) = {0.35, kwFraction}
		Modifygraph/Z freePos($("PCE_t" + ch)) = {0.05, kwFraction}
	
	//axisEnab
		ModifyGraph/Z axisEnab($("current" + ch)) = {0.7,0.95}
		ModifyGraph/Z axisEnab($("left" + ch)) = {0.35,0.6}
		ModifyGraph/Z axisEnab($("PCE" + ch)) = {0.05,0.3}
	
		Modifygraph/Z axisEnab($("bias" + ch)) = {0.1 + 0.45*(ch_i - 1), 0.45 + 0.45*(ch_i - 1)}
		Modifygraph/Z axisEnab($("buttom" + ch)) = {0.1 + 0.45*(ch_i - 1), 0.45 + 0.45*(ch_i - 1)}
		Modifygraph/Z axisEnab($("PCE_t" + ch)) = {0.1 + 0.45*(ch_i - 1), 0.45 + 0.45*(ch_i - 1)}
	
	//grid
	
		ModifyGraph/Z grid($("current" + ch))=1, gridStyle($("current" + ch))=1
		ModifyGraph/Z gridEnab($("current" + ch)) = {0.1 + 0.45*(ch_i - 1), 0.45 + 0.45*(ch_i - 1)}
		ModifyGraph/Z gridRGB($("current" + ch)) = (43520,43520,43520)

		ModifyGraph/Z grid($("bias" + ch))=1, gridStyle($("bias" + ch))=1
		ModifyGraph/Z gridEnab($("bias" + ch)) = {0.7,0.95}
		ModifyGraph/Z gridRGB($("bias" + ch)) = (43520,43520,43520)

		ModifyGraph/Z grid($("left" + ch))=1, gridStyle($("left" + ch))=1
		ModifyGraph/Z gridEnab($("left" + ch)) = {0.1 + 0.45*(ch_i - 1), 0.45 + 0.45*(ch_i - 1)}
		ModifyGraph/Z gridRGB($("left" + ch)) = (43520,43520,43520)

		ModifyGraph/Z grid($("PCE" + ch))=1, gridStyle($("PCE" + ch))=1
		ModifyGraph/Z gridEnab($("PCE" + ch)) = {0.1 + 0.45*(ch_i - 1), 0.45 + 0.45*(ch_i - 1)}
		ModifyGraph/Z gridRGB($("PCE" + ch)) = (43520,43520,43520)
	ch_i += 1
	while(ch_i <= numOfCh)


else // only one channel
		Modifygraph/Z freePos($("current1")) = {0.2, kwFraction}
		Modifygraph/Z freePos($("left1")) = {0.2, kwFraction}
		Modifygraph/Z freePos($("PCE1")) = {0.2, kwFraction}
	
		Modifygraph/Z freePos($("bias1")) = {0.7, kwFraction}
		Modifygraph/Z freePos($("buttom1")) = {0.35, kwFraction}
		Modifygraph/Z freePos($("PCE_t1")) = {0.05, kwFraction}
	
	//axisEnab
		ModifyGraph/Z axisEnab($("current1")) = {0.7,0.95}
		ModifyGraph/Z axisEnab($("left1")) = {0.35,0.6}
		ModifyGraph/Z axisEnab($("PCE1")) = {0.05,0.3}
	
		Modifygraph/Z axisEnab($("bias1")) = {0.2, 0.9}
		Modifygraph/Z axisEnab($("buttom1")) = {0.2, 0.9}
		Modifygraph/Z axisEnab($("PCE_t1")) = {0.2, 0.9}


		//grid
	
		ModifyGraph/Z grid($("current1"))=1, gridStyle($("current1"))=1
		ModifyGraph/Z gridEnab($("current1")) = {0.2, 0.9}
		ModifyGraph/Z gridRGB($("current1")) = (43520,43520,43520)

		ModifyGraph/Z grid($("bias1"))=1, gridStyle($("bias1"))=1
		ModifyGraph/Z gridEnab($("bias1")) = {0.7,0.95}
		ModifyGraph/Z gridRGB($("bias1")) = (43520,43520,43520)

		ModifyGraph/Z grid($("left1"))=1, gridStyle($("left1"))=1
		ModifyGraph/Z gridEnab($("left1")) = {0.2, 0.9}
		ModifyGraph/Z gridRGB($("left1")) = (43520,43520,43520)

		ModifyGraph/Z grid($("PCE1"))=1, gridStyle($("PCE1"))=1
		ModifyGraph/Z gridEnab($("PCE1")) = {0.2, 0.9}
		ModifyGraph/Z gridRGB($("PCE1")) = (43520,43520,43520)

endif

//legends

string printID = "\\f01\\Z12 "+ID

TextBox/C/N=legend0/F=0/A=MC/B=1/X=0/Y=50 printID

TextBox/C/N=legend1/F=0/A=MC/B=1/X=50/Y=30 legend1

TextBox/C/N=legend2/F=0/A=MC/B=1/X=50/Y=-2 legend2

TextBox/C/N=legend3/F=0/A=MC/B=1/O=90/X=-50/Y=-2 "Normalized Param."

TextBox/C/N=legend4/F=0/A=MC/B=1/O=90/X=-50/Y=-32 "PCE (%)"

if(numofch == 4)
	TextBox/C/N=ch1/F=0/A=MC/B=1/X=-40/Y=47 "\\f01ch1"
	TextBox/C/N=ch2/F=0/A=MC/B=1/X=-15/Y=47 "\\f01ch2"
	TextBox/C/N=ch3/F=0/A=MC/B=1/X=10/Y=47 "\\f01ch3"
	TextBox/C/N=ch4/F=0/A=MC/B=1/X=35/Y=47 "\\f01ch4"
endif


setdatafolder root:


End

//4. plot properties//////////////////////////////////////////////////////////////////
Window P_PlotProperties() : Panel
	Dowindow/K P_Plotproperties
	NewPanel /W=(0,200,370,600) as "Plot Properties"
	PauseUpdate; Silent 1		// building window...
	ModifyPanel cbRGB=(48896,52992,65280), frameStyle=2
	
	//ID select
	GroupBox IDselect,pos={15,20},size={330,105},title="ID select"
	
	SetVariable IDPrefix,pos={45,45},size={75,16},bodyWidth=60,title="ID"
	SetVariable IDPrefix,value= root:GLOBAL:PlotProperties:IDprefix_p
	SetVariable StartNum,pos={129,45},size={89,16},bodyWidth=60,title="Start"
	SetVariable StartNum,value= root:GLOBAL:PlotProperties:startNum_p
	SetVariable EndNum,pos={232,45},size={83,16},bodyWidth=60,title="End"
	SetVariable EndNum,value= root:GLOBAL:PlotProperties:EndNum_p
	
	Button MakeList,pos={50,70},size={60,20},title="Make List"
	Button MakeList, proc=MakeIDList
	
	
	Button add_P,pos={150,70},size={60,20},title="Add P"
	Button add_P, proc=add_P
	
	
	Button delete_P,pos={250,70},size={60,20},title="Delete P"
	Button delete_P, proc=delete_P
	
	SetVariable selectedID,pos={45,95},size={270,16},title="ID list",value = root:GLOBAL:PlotProperties:IDList_p
	
	//Param. select
	GroupBox Paramselect,pos={15,130},size={330,93},title="Param. select"
	
	CheckBox Vocchk,pos={48,154},size={38,14},title="Voc",value=  root:GLOBAL:PlotProperties:VocChk, proc=VocChkProc
	CheckBox Jscchk,pos={96,154},size={37,14},title="Jsc",value=  root:GLOBAL:PlotProperties:JscChk, proc=JscChkProc
	CheckBox FFchk,pos={143,154},size={32,14},title="FF",value=  root:GLOBAL:PlotProperties:FFChk, proc=FFChkProc
	CheckBox PCEchk,pos={185,154},size={40,14},title="PCE",value=  root:GLOBAL:PlotProperties:PCEChk, proc=PCEChkProc
	CheckBox Rschk,pos={235,154},size={32,14},title="Rs",value=  root:GLOBAL:PlotProperties:RsChk, proc=RsChkProc
	CheckBox Rshchk,pos={277,154},size={38,14},title="Rsh",value=  root:GLOBAL:PlotProperties:RshChk, proc=RshChkProc
	
	CheckBox Voc_rchk,pos={48,174},size={46,14},title="Voc_r",value=  root:GLOBAL:PlotProperties:Voc_rChk, proc=Voc_rChkProc
	CheckBox Jsc_rchk,pos={96,174},size={45,14},title="Jsc_r",value=  root:GLOBAL:PlotProperties:Jsc_rChk, proc=Jsc_rChkProc
	CheckBox FF_rchk,pos={143,174},size={40,14},title="FF_r",value=  root:GLOBAL:PlotProperties:FF_rChk, proc=FF_rChkProc
	CheckBox PCE_Rchk,pos={185,174},size={48,14},title="PCE_r",value=  root:GLOBAL:PlotProperties:PCE_rChk, proc=PCE_rChkProc
	CheckBox Rs_rchk,pos={235,174},size={40,14},title="Rs_r",value=  root:GLOBAL:PlotProperties:Rs_rChk, proc=Rs_rChkProc
	CheckBox Rsh_rchk,pos={277,174},size={46,14},title="Rsh_r",value=  root:GLOBAL:PlotProperties:Rsh_rChk, proc=Rsh_rChkProc
	
	Button select_all,pos={37,196},size={69,20},title="select all"
	Button select_all, proc=selectAll
	Button disselect_all,pos={116,196},size={79,20},title="disselect all"
	Button disselect_all, proc=disselectAll
	Button abs_only,pos={205,196},size={60,20},title="abs. only"
	Button abs_only, proc=absOnly
	Button norm_only,pos={273,197},size={65,20},title="norm. only"
	Button norm_only, proc=normOnly
	
	//left axis
	GroupBox left,pos={15,230},size={127,120},title="left axis"
	
	CheckBox auto_range_left,pos={25,250},size={100,14},title="automatic range",value= 1, proc=leftChkProc
	SetVariable left_from,pos={28,275},size={77,16},bodyWidth=50,title="from"
	SetVariable left_from, value =  root:GLOBAL:PlotProperties:leftFrom
	SetVariable left_to,pos={40,300},size={64,16},bodyWidth=50,title="to"
	SetVariable left_to, value =  root:GLOBAL:PlotProperties:leftTo
	
	//bottom axis
	GroupBox bottom,pos={150,230},size={120,120},title="bottom axis"
	
	CheckBox auto_range_bottom,pos={160,250},size={100,14},title="automatic range", proc=bottomChkProc
	CheckBox auto_range_bottom,value= 1
	SetVariable bottom_from,pos={163,275},size={77,16},bodyWidth=50,title="from"
	SetVariable bottom_from, value =  root:GLOBAL:PlotProperties:bottomFrom
	SetVariable bottom_to,pos={176,300},size={64,16},bodyWidth=50,title="to"
	SetVariable bottom_to, value =  root:GLOBAL:PlotProperties:bottomTo
	SetVariable bottom_unit,pos={167,325},size={83,16},bodyWidth=60,title="unit"
	SetVariable bottom_unit, value =  root:GLOBAL:PlotProperties:bottomUnit
	// ch select
	GroupBox chchk,pos={280,230},size={63,120},title="ch select"
	
	
	CheckBox ch1chk,pos={290,250},size={36,14},title="ch1",value= 0, proc=ch1ChkProc
	CheckBox ch2chk,pos={290,275},size={36,14},title="ch2",value= 0, proc=ch2ChkProc
	CheckBox ch3chk,pos={290,300},size={36,14},title="ch3",value= 0, proc=ch3ChkProc
	CheckBox ch4chk,pos={290,325},size={36,14},title="ch4",value= 0, proc=ch4ChkProc
	Button show_graph,pos={114,365},size={50,20},title="GRAPH"
	Button show_graph, proc=PlotPropertiesGraph
	Button show_table,pos={174,365},size={50,20},title="TABLE"
	Button show_table, proc=ShowProperitesTable
EndMacro


//checkbox set cheked -> 1 unchecked ->0
Function VocChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR VocChk = root:GLOBAL:PlotProperties:VocChk

	VocChk = checked

End

Function JscChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR JscChk = root:GLOBAL:PlotProperties:JscChk

	JscChk = checked

End

Function FFChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR FFChk = root:GLOBAL:PlotProperties:FFChk

	FFChk = checked

End

Function PCEChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR PCEChk = root:GLOBAL:PlotProperties:PCEChk

	PCEChk = checked

End

Function RsChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR RsChk = root:GLOBAL:PlotProperties:RsChk

	RsChk = checked

End

Function RshChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR RshChk = root:GLOBAL:PlotProperties:RshChk

	RshChk = checked

End

Function Voc_rChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR Voc_rChk = root:GLOBAL:PlotProperties:Voc_rChk

	Voc_rChk = checked

End

Function Jsc_RChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR Jsc_rChk = root:GLOBAL:PlotProperties:Jsc_rChk

	Jsc_rChk = checked

End

Function FF_rChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR FF_rChk = root:GLOBAL:PlotProperties:FF_rChk

	FF_rChk = checked

End

Function PCE_rChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR PCE_rChk = root:GLOBAL:PlotProperties:PCE_rChk

	PCE_rChk = checked

End

Function Rs_rChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR Rs_rChk = root:GLOBAL:PlotProperties:Rs_rChk

	Rs_rChk = checked

End

Function Rsh_rChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR Rsh_rChk = root:GLOBAL:PlotProperties:Rsh_rChk

	Rsh_rChk = checked

End

Function leftChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR leftAutoChk = root:GLOBAL:PlotProperties:leftAutoChk

	leftAutoChk = checked

End


Function bottomChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR  bottomAutoChk = root:GLOBAL:PlotProperties:bottomAutoChk

	bottomAutoChk = checked

End


Function ch1ChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR  ch1Chk = root:GLOBAL:PlotProperties:ch1Chk

	ch1Chk = checked

End


Function ch2ChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR  ch2Chk = root:GLOBAL:PlotProperties:ch2Chk

	ch2Chk = checked

End

Function ch3ChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR  ch3Chk = root:GLOBAL:PlotProperties:ch3Chk

	ch3Chk = checked

End

Function ch4ChkProc(ctrlName, checked) :CheckBoxControl
	string ctrlName
	variable checked
	NVAR  ch4Chk = root:GLOBAL:PlotProperties:ch4Chk

	ch4Chk = checked

End

//set butttons
Function MakeIDList(ctrlName) :ButtonControl
string ctrlName

SVAR gFilterList  = root:GLOBAL:PlotProperties:IDList_p
SVAR gIDprefix    = root:GLOBAL:PlotProperties:IDprefix_p
NVAR gStartNum = root:GLOBAL:PlotProperties:StartNum_p
NVAR gEndNum   = root:GLOBAL:PlotProperties:EndNum_p

	gFilterList = ListUpIDs(gIDprefix, gStartNum, gEndNum)

End

Function add_P(ctrlName) :ButtonControl
string ctrlName
SVAR gFilterList  = root:GLOBAL:PlotProperties:IDList_p

variable i = 0
string ID
string ID_P_list = ""

do
	ID = stringfromList(i,gFilterList)
	
	if(strlen(ID) == 0)
		break
	endif
	
	ID_P_list = ID_P_list + ID + "_p;"
	
	i += 1
while(1)

	gFilterList = ID_P_list

End

Function delete_P(ctrlName) :ButtonControl
string ctrlName
SVAR gFilterList  = root:GLOBAL:PlotProperties:IDList_p

variable i = 0
string ID
string ID_noP_list = ""
variable underberPos

do
	ID = stringfromList(i,gFilterList)
	
	if(strlen(ID) == 0)
		break
	endif
	
	underberPos = strsearch(ID,"_p",0)
	
	if(underberPos >= 0) //if "DMZ0010_p" is found
		ID_noP_list = ID_noP_list + ID[0, underberPos -1 ] + ";"
	else //if "DMZ0010" is found
		ID_noP_list = ID_noP_list + ID + ":"
	endif
	
	i += 1
while(1)

	gFilterList = ID_noP_list

End



Function selectAll(ctrlName) :ButtonControl
string ctrlName

NVAR VocChk = root:GLOBAL:PlotProperties:VocChk
NVAR JscChk = root:GLOBAL:PlotProperties:JscChk
NVAR FFChk = root:GLOBAL:PlotProperties:FFChk
NVAR PCEChk = root:GLOBAL:PlotProperties:PCEChk
NVAR RsChk = root:GLOBAL:PlotProperties:RsChk
NVAR RshChk = root:GLOBAL:PlotProperties:RshChk

NVAR Voc_rChk = root:GLOBAL:PlotProperties:Voc_rChk
NVAR Jsc_rChk = root:GLOBAL:PlotProperties:Jsc_rChk
NVAR FF_RChk = root:GLOBAL:PlotProperties:FF_rChk
NVAR PCE_rChk = root:GLOBAL:PlotProperties:PCE_rChk
NVAR Rs_rChk = root:GLOBAL:PlotProperties:Rs_rChk
NVAR Rsh_rChk = root:GLOBAL:PlotProperties:Rsh_rChk

VocChk = 1
JscChk = 1
FFChk = 1
PCEChk = 1
RsChk = 1
RshChk = 1

Voc_rChk = 1
Jsc_rChk = 1
FF_rChk = 1
PCE_rChk = 1
Rs_RChk = 1
Rsh_rChk = 1

Execute "P_PlotProperties()" 

End


Function disselectAll(ctrlName) :ButtonControl
string ctrlName


NVAR VocChk = root:GLOBAL:PlotProperties:VocChk
NVAR JscChk = root:GLOBAL:PlotProperties:JscChk
NVAR FFChk = root:GLOBAL:PlotProperties:FFChk
NVAR PCEChk = root:GLOBAL:PlotProperties:PCEChk
NVAR RsChk = root:GLOBAL:PlotProperties:RsChk
NVAR RshChk = root:GLOBAL:PlotProperties:RshChk

NVAR Voc_rChk = root:GLOBAL:PlotProperties:Voc_rChk
NVAR Jsc_rChk = root:GLOBAL:PlotProperties:Jsc_rChk
NVAR FF_RChk = root:GLOBAL:PlotProperties:FF_rChk
NVAR PCE_rChk = root:GLOBAL:PlotProperties:PCE_rChk
NVAR Rs_rChk = root:GLOBAL:PlotProperties:Rs_rChk
NVAR Rsh_rChk = root:GLOBAL:PlotProperties:Rsh_rChk

VocChk = 0
JscChk = 0
FFChk = 0
PCEChk = 0
RsChk = 0
RshChk = 0

Voc_rChk = 0
Jsc_rChk = 0
FF_rChk = 0
PCE_rChk = 0
Rs_RChk = 0
Rsh_rChk = 0

Execute "P_PlotProperties()" 

End


Function absOnly(ctrlName) :ButtonControl
string ctrlName


NVAR VocChk = root:GLOBAL:PlotProperties:VocChk
NVAR JscChk = root:GLOBAL:PlotProperties:JscChk
NVAR FFChk = root:GLOBAL:PlotProperties:FFChk
NVAR PCEChk = root:GLOBAL:PlotProperties:PCEChk
NVAR RsChk = root:GLOBAL:PlotProperties:RsChk
NVAR RshChk = root:GLOBAL:PlotProperties:RshChk

NVAR Voc_rChk = root:GLOBAL:PlotProperties:Voc_rChk
NVAR Jsc_rChk = root:GLOBAL:PlotProperties:Jsc_rChk
NVAR FF_RChk = root:GLOBAL:PlotProperties:FF_rChk
NVAR PCE_rChk = root:GLOBAL:PlotProperties:PCE_rChk
NVAR Rs_rChk = root:GLOBAL:PlotProperties:Rs_rChk
NVAR Rsh_rChk = root:GLOBAL:PlotProperties:Rsh_rChk

VocChk = 1
JscChk = 1
FFChk = 1
PCEChk = 1
RsChk = 1
RshChk = 1

Voc_rChk = 0
Jsc_rChk = 0
FF_rChk = 0
PCE_rChk = 0
Rs_RChk = 0
Rsh_rChk = 0

Execute "P_PlotProperties()" 

End


Function normOnly(ctrlName) :ButtonControl
string ctrlName
NVAR VocChk = root:GLOBAL:PlotProperties:VocChk
NVAR JscChk = root:GLOBAL:PlotProperties:JscChk
NVAR FFChk = root:GLOBAL:PlotProperties:FFChk
NVAR PCEChk = root:GLOBAL:PlotProperties:PCEChk
NVAR RsChk = root:GLOBAL:PlotProperties:RsChk
NVAR RshChk = root:GLOBAL:PlotProperties:RshChk

NVAR Voc_rChk = root:GLOBAL:PlotProperties:Voc_rChk
NVAR Jsc_rChk = root:GLOBAL:PlotProperties:Jsc_rChk
NVAR FF_RChk = root:GLOBAL:PlotProperties:FF_rChk
NVAR PCE_rChk = root:GLOBAL:PlotProperties:PCE_rChk
NVAR Rs_rChk = root:GLOBAL:PlotProperties:Rs_rChk
NVAR Rsh_rChk = root:GLOBAL:PlotProperties:Rsh_rChk

VocChk = 0
JscChk = 0
FFChk = 0
PCEChk = 0
RsChk = 0
RshChk = 0

Voc_rChk = 1
Jsc_rChk = 1
FF_rChk = 1
PCE_rChk = 1
Rs_RChk = 1
Rsh_rChk = 1

Execute "P_PlotProperties()" 


End

//Plot Graph Window

Function PlotPropertiesGraph(ctrlName) :ButtonControl
string ctrlName

SVAR IDList = root:GLOBAL:PlotProperties:IDList_p

NVAR VocChk = root:GLOBAL:PlotProperties:VocChk
NVAR JscChk = root:GLOBAL:PlotProperties:JscChk
NVAR FFChk = root:GLOBAL:PlotProperties:FFChk
NVAR PCEChk = root:GLOBAL:PlotProperties:PCEChk
NVAR RsChk = root:GLOBAL:PlotProperties:RsChk
NVAR RshChk = root:GLOBAL:PlotProperties:RshChk

NVAR Voc_rChk = root:GLOBAL:PlotProperties:Voc_rChk
NVAR Jsc_rChk = root:GLOBAL:PlotProperties:Jsc_rChk
NVAR FF_RChk = root:GLOBAL:PlotProperties:FF_rChk
NVAR PCE_rChk = root:GLOBAL:PlotProperties:PCE_rChk
NVAR Rs_rChk = root:GLOBAL:PlotProperties:Rs_rChk
NVAR Rsh_rChk = root:GLOBAL:PlotProperties:Rsh_rChk

NVAR leftAutoChk = root:GLOBAL:PlotProperties:leftAutoChk
NVAR bottomAutoChk =  root:GLOBAL:PlotProperties:bottomAutoChk

NVAR ch1Chk =  root:GLOBAL:PlotProperties:ch1Chk
NVAR ch2Chk = root:GLOBAL:PlotProperties:ch2Chk
NVAR ch3Chk = root:GLOBAL:PlotProperties:ch3Chk
NVAR ch4Chk = root:GLOBAL:PlotProperties:ch4Chk

NVAR leftFrom = root:GLOBAL:PlotProperties:leftFrom
NVAR leftTo = root:GLOBAL:PlotProperties:leftTo

NVAR bottomFrom = root:GLOBAL:PlotProperties:bottomFrom
NVAR bottomTo = root:GLOBAL:PlotProperties:bottomTo
SVAR bottomUnit = root:GLOBAL:PlotProperties:bottomUnit

//Make a pick up list
string AbsList = PlotCheckedProperties(0,VocChk, JscChk, FFChk, PCEChk, RsChk, RshChk)
string NormList = PlotCheckedProperties(1,Voc_rChk, Jsc_rChk, FF_rChk, PCE_rChk, Rs_rChk, Rsh_rChk)
variable OneF = 0 //a flag to tell only one property is selected

variable AbsListNum = ItemsInList(AbsList)
variable NormListNum = ItemsInList(NormList)


if(AbsListNum + NormListNum == 0)
	return -1 //no param. is selected
endif

if(AbsListNum + NormListNum == 1)
	OneF = 1
endif


if(ch1chk + ch2chk + ch3chk + ch4chk == 0) //no check in ch selsect
	return -1
endif


//OutLine of the GraphArea
//the graph is showed at top-left
variable left, top ,right, bottom

left = 0
top = 0

if(AbsListNum >= NormListNum) //the widnth of each plot is set to be 120
	right = AbsListNum *150
else
	right = NormListNum * 150
endif

if(AbsListNum == 0 || NormListNum == 0)//the hight
	bottom = 250
else
	bottom = 400
endif

if(OneF == 1)
	right = 500
	bottom = 500
endif

Display /W=(left, top, right, bottom)


//import data

variable returnFromAppendAbs

	returnFromAppendAbs = AppendProp(IDList, AbsList, VocChk, JscChk, FFChk, PCEChk, RsChk, RshChk, ch1chk, ch2chk, ch3chk, ch4chk)
	
variable returnFromAppendNorm

	returnFromAppendNorm = AppendProp(IDList, NormList, Voc_RChk, Jsc_rChk, FF_rChk, PCE_rChk, Rs_rChk, Rsh_rChk, ch1chk, ch2chk, ch3chk, ch4chk)


//axis alginment 

if(OneF == 0)
	ModifyGraph gfSize=10, gFont="Arial"
	ModifyGraph lblPosMode=4
else
	ModifyGraph gfSize = 20, msize = 5
	ModifyGraph lblPos = -500
endif

variable List_i = 0
string absANDnormList = "absList;normList"
string propList


string LA, BA
string Baxis
variable BAfrac

if(AbsListNum >= NormListNum)
	BAfrac = 1/AbsListNum
else
	BAfrac = 1/ NormListNum
endif

variable LeftMargin = BAFrac/3

//Abs axis
string prop

do//on List_i = 0 (absList) or 1(normList)
if(List_i == 0)
	propList = absList
else
	propList = normList
endif



	variable prop_i = 0
	do //on prop_i
	 
		prop = stringfromlist(prop_i, propList)
		
		if(strlen(prop) == 0)
			break
		endif
	
		LA = prop + "_left"
		BA = prop + "_bottom"
		
		//on bottom axis
		Label $BA bottomUnit
		
		if(OneF == 0)
			ModifyGraph axisEnab($BA) = {BAfrac * prop_i + LeftMargin, BAfrac * (prop_i + 1)}
		
			if(absListNum == 0 || normListNum == 0) //if only abs or norm is selected
				ModifyGraph lblPos($BA)   = 40
				ModifyGraph freePos($BA) = {0.15,kwFraction}
			else // if abs and norm is selected
			
				ModifyGraph lblPos($BA)   = 35
		
				if(List_i == 0) //if abs axis
					ModifyGraph freePos($BA) = {0.50, kwFraction}
				else //if norm axis
					ModifyGraph freePos($BA) = {0.10, kwFraction}
				
				endif
		
			endif
		
		else
			ModifyGraph freepos($BA) = 0
			ModifyGraph lblpos($BA) = 70
		endif
		
		//on left axis
		Label $LA prop
		
		if(OneF == 0)
			ModifyGraph freePos($LA)  = {BAfrac * prop_i + LeftMargin, kwFraction}
			
			if(stringmatch(LA, "*Voc*") == 1)// lalPos should be wider for Voc
				ModifyGraph lblPos($LA) = 45
			else
				ModifyGraph lblPos($LA) = 40
			endif
			
			if(absListNum == 0 || normListNum == 0) // if only abs or norm is selected
			
			
				ModifyGraph axisEnab($LA) = {0.15, 0.6}
			else// if abs and norm is slected
		
				if(List_i == 0) // if abs axis
					ModifyGraph axisEnab($LA) = {0.50, 0.8}
				else
					ModifyGraph axisEnab($LA) = {0.10, 0.40}
				endif
			
			endif
			
		ModifyGraph gridEnab($LA) = {BAfrac * prop_i + LeftMargin, BAfrac * (prop_i + 1)}
		
		else
			Modifygraph freePos($LA) = 0
			ModifyGraph lblpos($LA) = 70
		endif	
		
		ModifyGraph grid($LA)=1, gridStyle($LA)=1
		ModifyGraph gridRGB($LA) = (43520,43520,43520)

		//setAxis automatic or not
		
		if(bottomAutoChk == 0)
			setAxis $BA bottomFrom, bottomTO 
		endif
	
		if(leftAutoChk == 0)
			if(leftTo == 0)
				setAxis $LA leftFrom,*
			else
				setAxis $LA leftFrom,leftTo
			endif
		endif
		
		
		prop_i += 1
	while(1)

List_i += 1
while(List_i <= 1) //List_i = 0 (absList) or 1(normList)


//Norm axis

End

Function ShowProperitesTable(ctrlName) :ButtonControl

string ctrlName

SVAR IDList = root:GLOBAL:PlotProperties:IDList_p

NVAR VocChk = root:GLOBAL:PlotProperties:VocChk
NVAR JscChk = root:GLOBAL:PlotProperties:JscChk
NVAR FFChk = root:GLOBAL:PlotProperties:FFChk
NVAR PCEChk = root:GLOBAL:PlotProperties:PCEChk
NVAR RsChk = root:GLOBAL:PlotProperties:RsChk
NVAR RshChk = root:GLOBAL:PlotProperties:RshChk

NVAR Voc_rChk = root:GLOBAL:PlotProperties:Voc_rChk
NVAR Jsc_rChk = root:GLOBAL:PlotProperties:Jsc_rChk
NVAR FF_RChk = root:GLOBAL:PlotProperties:FF_rChk
NVAR PCE_rChk = root:GLOBAL:PlotProperties:PCE_rChk
NVAR Rs_rChk = root:GLOBAL:PlotProperties:Rs_rChk
NVAR Rsh_rChk = root:GLOBAL:PlotProperties:Rsh_rChk

NVAR ch1Chk =  root:GLOBAL:PlotProperties:ch1Chk
NVAR ch2Chk = root:GLOBAL:PlotProperties:ch2Chk
NVAR ch3Chk = root:GLOBAL:PlotProperties:ch3Chk
NVAR ch4Chk = root:GLOBAL:PlotProperties:ch4Chk



//show a table
Edit /N=IDList

//Make a pick up list
string AbsList = PlotCheckedProperties(0,VocChk, JscChk, FFChk, PCEChk, RsChk, RshChk)
string NormList = PlotCheckedProperties(1,Voc_rChk, Jsc_rChk, FF_rChk, PCE_rChk, Rs_rChk, Rsh_rChk)

variable AbsListNum = ItemsInList(AbsList)
variable NormListNum = ItemsInList(NormList)


if(AbsListNum + NormListNum == 0)
	return -1 //no param. is selected
endif
if(ch1chk + ch2chk + ch3chk + ch4chk == 0) //no check in ch selsect
	return -1
endif


//import data

variable returnFromAppendTableAbs

	returnFromAppendTableAbs = AppendTableProp(IDList, AbsList, VocChk, JscChk, FFChk, PCEChk, RsChk, RshChk, ch1chk, ch2chk, ch3chk, ch4chk)
	
variable returnFromAppendTableNorm

	returnFromAppendTableNorm = AppendTableProp(IDList, NormList, Voc_RChk, Jsc_rChk, FF_rChk, PCE_rChk, Rs_rChk, Rsh_rChk, ch1chk, ch2chk, ch3chk, ch4chk)



End



static function/S PlotCheckedProperties(AbsorNorm, Voc, Jsc, FF, PCE, Rs, Rsh)
variable AbsorNorm, Voc, Jsc, FF, PCE, Rs, Rsh
string List = ""
string surfix = ""

if(AbsorNorm == 1) // if Norm
	surfix = "_r"
endif

if(Voc == 1)
	List = List + "Voc" + surfix + ";"
endif
if(Jsc == 1)
	List = List + "Jsc" + surfix +";"
endif
if(FF == 1)
	List = List + "FF" + surfix +";"
endif
if(PCE == 1)
	List = List + "PCE" + surfix +";"
endif
if(Rs == 1)
	List = List + "Rs" + surfix +";"
endif
if(Rsh == 1)
	List = List + "Rsh" + surfix +";"
endif

return List

End

static function AppendProp(IDList, PropList, Voc, Jsc, FF, PCE, Rs, Rsh, ch1, ch2, ch3, ch4)
string IDList, PropList
variable Voc, Jsc, FF, PCE, Rs, Rsh, ch1, ch2, ch3, ch4

Wave rColor = root:GLOBAL:rColor
Wave gColor = root:GLOBAL:gColor
Wave bColor = root:GLOBAL:bColor

string LA, BA


string ID
variable ID_i = 0

string prop
variable P_i

string PropWave
string TimeWave

variable r, g, b

string Legendstr = ""

do // loop for ID
	
	ID = StringFromList(ID_i, IDList) //Ex. "DMZ0001"
	
	if(strlen(ID) == 0)
		break
	endif
	setDataFolder root:$ID
	TimeWave = WaveList("*_plot_time","","")
	Wave TWave = root:$(ID):$TimeWave
	
	P_i = 0
	do //loop for abs properties
		prop = StringFromList(P_i, PropList) //Ex. "Voc"

		if(strlen(prop) == 0)
			break
		endif
		
		LA = prop + "_left"
		BA = prop + "_bottom"
		
		if(ch1 == 1)
			PropWave = WaveList("*"+ prop +"_1","","")
			Appendtograph /L=$LA/B=$BA/C=(rColor[ID_i],gColor[ID_i],bColor[ID_i]) root:$(ID):$PropWave vs TWave
			ModifyGraph mode($propwave)=4,msize($propwave)=2,lsize($propwave)=1, marker($propwave)=19 // set Marker mode
		endif
		
		if(ch2 == 1)
			PropWave = WaveList("*"+ prop +"_2","","")
			Appendtograph /L=$LA/B=$BA/C=(rColor[ID_i],gColor[ID_i],bColor[ID_i]) root:$(ID):$PropWave vs TWave 
			ModifyGraph mode($propwave)=4,msize($propwave)=2,lsize($propwave)=1, marker($propwave)=8
		endif
		if(ch3 == 1)
			PropWave = WaveList("*"+ prop +"_3","","")
			Appendtograph /L=$LA/B=$BA/C=(rColor[ID_i],gColor[ID_i],bColor[ID_i]) root:$(ID):$PropWave vs TWave
			ModifyGraph mode($propwave)=4,msize($propwave)=2,lsize($propwave)=1, marker($propwave)=16
		endif
		if(ch4 == 1)
			PropWave = WaveList("*"+ prop +"_4","","")
			Appendtograph /L=$LA/B=$BA/C=(rColor[ID_i],gColor[ID_i],bColor[ID_i]) root:$(ID):$PropWave vs TWave 
			ModifyGraph mode($propwave)=4,msize($propwave)=2,lsize($propwave)=1, marker($propwave)=5
		endif
		
	P_i += 1
	while(1)

// make legend
string color
color = "("+ num2str(rColor[ID_i]) + "," + num2str(gColor[ID_i]) + "," + num2str(bColor[ID_i]) + ")"
legendstr = legendstr + "\\K" + color + ID +" " + ID_comment(ID) +"\r" 

ID_i += 1
while(1)

TextBox/C/N=text0/B=1/X=-1.23/Y=-1.81/F=0 legendstr //legend for traces
TextBox/C/N=text1/B=1/X=90/Y=0/F=0 "\W519ch1\r\W508ch2\r\W516ch3\r\W505ch4" //legend for markers


setDataFolder root:

return 0
End

static function/T ID_comment(ID)
string ID
Wave/T W_ID = root:W_ID, W_Cmt = root:W_Cmt

FindValue/TEXT = (ID) W_ID

if(V_value >= 0)
	
	return W_Cmt[V_value]
	
else

	return ""

endif

End



static function AppendTableProp(IDList, PropList, Voc, Jsc, FF, PCE, Rs, Rsh, ch1, ch2, ch3, ch4)
string IDList, PropList
variable Voc, Jsc, FF, PCE, Rs, Rsh, ch1, ch2, ch3, ch4

Wave rColor = root:GLOBAL:rColor
Wave gColor = root:GLOBAL:gColor
Wave bColor = root:GLOBAL:bColor


string ID
variable ID_i = 0

string prop
variable P_i

string PropWave
string TimeWave

variable r, g, b

do // loop for ID
	
	ID = StringFromList(ID_i, IDList) //Ex. "DMZ0001"
	
	if(strlen(ID) == 0)
		break
	endif
	setDataFolder root:$ID
	TimeWave = WaveList("*_plot_time","","")
	Wave TWave = root:$(ID):$TimeWave
	
	P_i = 0
	do //loop for abs properties
		prop = StringFromList(P_i, PropList) //Ex. "Voc"

		if(strlen(prop) == 0)
			break
		endif
		
			AppendtoTable TWave
			Modifytable rgb(Twave) = (rColor[ID_i],gColor[ID_i],bColor[ID_i])
		
		if(ch1 == 1)
			PropWave = WaveList("*"+ prop +"_1","","")
			Appendtotable root:$(ID):$PropWave
			Modifytable rgb(root:$(ID):$PropWave) = (rColor[ID_i],gColor[ID_i],bColor[ID_i])
		endif
		
		if(ch2 == 1)
			PropWave = WaveList("*"+ prop +"_2","","")
			Appendtotable root:$(ID):$PropWave
			Modifytable rgb(root:$(ID):$PropWave) = (rColor[ID_i],gColor[ID_i],bColor[ID_i])
		endif
		if(ch3 == 1)
			PropWave = WaveList("*"+ prop +"_3","","")
			Appendtotable root:$(ID):$PropWave
			Modifytable rgb(root:$(ID):$PropWave) = (rColor[ID_i],gColor[ID_i],bColor[ID_i])
		endif
		if(ch4 == 1)
			PropWave = WaveList("*"+ prop +"_4","","")
			Appendtotable root:$(ID):$PropWave
			Modifytable rgb(root:$(ID):$PropWave) = (rColor[ID_i],gColor[ID_i],bColor[ID_i])
		endif
		
	P_i += 1
	while(1)
ID_i += 1
while(1)
setDataFolder root:

return 0
End

//5.IV comparison/////////////////////////////////////////////////////////////////

Window IV_comparison() : Panel
	DoWindow/K IV_comparison
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(0,400,370,680) as "IV comparison"
	DoWindow/C IV_comparison
	ModifyPanel cbRGB=(65280,48896,55552)
	SetDrawLayer UserBack
	DrawText 60,35,"ID"
	DrawText 150,35,"Time/Cycle"
	DrawText 220,35,"Photo/Dark"
	DrawText 290,35, "channels"
//ID
	SetVariable ID1,pos={50, 40},size={60,20},bodyWidth=80, value = root:GLOBAL:IVcomparison:ID1
	SetVariable ID2,pos={50, 60},size={60,20},bodyWidth=80, value = root:GLOBAL:IVcomparison:ID2
	SetVariable ID3,pos={50, 80},size={60,20},bodyWidth=80, value = root:GLOBAL:IVcomparison:ID3
	SetVariable ID4,pos={50,100},size={60,20},bodyWidth=80, value = root:GLOBAL:IVcomparison:ID4
	SetVariable ID5,pos={50,120},size={60,20},bodyWidth=80, value = root:GLOBAL:IVcomparison:ID5
	SetVariable ID6,pos={50,140},size={60,20},bodyWidth=80, value = root:GLOBAL:IVcomparison:ID6
	SetVariable ID7,pos={50,160},size={60,20},bodyWidth=80, value = root:GLOBAL:IVcomparison:ID7
	SetVariable ID8,pos={50,180},size={60,20},bodyWidth=80, value = root:GLOBAL:IVcomparison:ID8

//Time/Cycle
	SetVariable TC1,pos={150, 40},size={60,20},bodyWidth=60, value = root:GLOBAL:IVcomparison:TC1
	SetVariable TC2,pos={150, 60},size={60,20},bodyWidth=60, value = root:GLOBAL:IVcomparison:TC2
	SetVariable TC3,pos={150, 80},size={60,20},bodyWidth=60, value = root:GLOBAL:IVcomparison:TC3
	SetVariable TC4,pos={150,100},size={60,20},bodyWidth=60, value = root:GLOBAL:IVcomparison:TC4
	SetVariable TC5,pos={150,120},size={60,20},bodyWidth=60, value = root:GLOBAL:IVcomparison:TC5
	SetVariable TC6,pos={150,140},size={60,20},bodyWidth=60, value = root:GLOBAL:IVcomparison:TC6
	SetVariable TC7,pos={150,160},size={60,20},bodyWidth=60, value = root:GLOBAL:IVcomparison:TC7
	SetVariable TC8,pos={150,180},size={60,20},bodyWidth=60, value = root:GLOBAL:IVcomparison:TC8

//photo/dark
	PopupMenu photo_dark1,pos={225,40},size={60,20}, value = "photo;Dark"
	PopupMenu photo_dark2,pos={225,60},size={60,20}, value = "photo;Dark"
	PopupMenu photo_dark3,pos={225,80},size={60,20}, value = "photo;Dark"
	PopupMenu photo_dark4,pos={225,100},size={60,20}, value = "photo;Dark"
	PopupMenu photo_dark5,pos={225,120},size={60,20}, value = "photo;Dark"
	PopupMenu photo_dark6,pos={225,140},size={60,20}, value = "photo;Dark"
	PopupMenu photo_dark7,pos={225,160},size={60,20}, value = "photo;Dark"
	PopupMenu photo_dark8,pos={225,180},size={60,20}, value = "photo;Dark"
	
	
//ch
	PopupMenu ch1,pos={300,40},size={60,20}, value = "1;2;3;4"
	PopupMenu ch2,pos={300,60},size={60,20}, value = "1;2;3;4"
	PopupMenu ch3,pos={300,80},size={60,20}, value = "1;2;3;4"
	PopupMenu ch4,pos={300,100},size={60,20}, value = "1;2;3;4"
	PopupMenu ch5,pos={300,120},size={60,20}, value = "1;2;3;4"
	PopupMenu ch6,pos={300,140},size={60,20}, value = "1;2;3;4"
	PopupMenu ch7,pos={300,160},size={60,20}, value = "1;2;3;4"
	PopupMenu ch8,pos={300,180},size={60,20}, value = "1;2;3;4"
	
	Button IVcompare, pos={130, 220}, size={120, 22}, proc=IVcompare, title="COMPARE IVs"
EndMacro

function IVcompare(ctrlName) :ButtonControl
string ctrlName

SVAR ID1 = root:GLOBAL:IVcomparison:ID1
SVAR ID2 = root:GLOBAL:IVcomparison:ID2
SVAR ID3 = root:GLOBAL:IVcomparison:ID3
SVAR ID4 = root:GLOBAL:IVcomparison:ID4
SVAR ID5 = root:GLOBAL:IVcomparison:ID5
SVAR ID6 = root:GLOBAL:IVcomparison:ID6
SVAR ID7 = root:GLOBAL:IVcomparison:ID7
SVAR ID8 = root:GLOBAL:IVcomparison:ID8

SVAR TC1 = root:GLOBAL:IVcomparison:TC1
SVAR TC2 = root:GLOBAL:IVcomparison:TC2
SVAR TC3 = root:GLOBAL:IVcomparison:TC3
SVAR TC4 = root:GLOBAL:IVcomparison:TC4
SVAR TC5 = root:GLOBAL:IVcomparison:TC5
SVAR TC6 = root:GLOBAL:IVcomparison:TC6
SVAR TC7 = root:GLOBAL:IVcomparison:TC7
SVAR TC8 = root:GLOBAL:IVcomparison:TC8

variable i = 1
string IDlist
string ID
string TClist
string TC
string PD
string PorD // = "p" or "d"
string PorDfull // "photo" or "dark"
string ch
string chNum // = "1", "2", "3", or "4"
string searchKey
Wave rColor = root:GLOBAL:rColor
Wave gColor = root:GLOBAL:gColor
Wave bColor = root:GLOBAL:bColor


Display /W=(0,0,300,300)
string legendstr = ""

for(i=0;;i+=1)
	IDlist = ID1+";"+ID2+";"+ID3+";"+ID4+";"+ID5+";"+ID6+";"+ID7+";"+ID8
	ID = stringfromlist(i , IDlist)

	if(strlen(ID)==0)
		break
	endif

	TClist = TC1+";"+TC2+";"+TC3+";"+TC4+";"+TC5+";"+TC6+";"+TC7+";"+TC8
	TC = "_" + stringfromlist(i, TClist)

	//set PDNum
	controlinfo /W=IV_comparison $("photo_dark"+num2str(i+1))
	if (V_value == 1)
		PorD = "p"
		PorDFull = "photo"
	else
		PorD = "d"
		PorDFull = "dark"

	endif

	//set chNum
	controlinfo /W=IV_comparison $("ch"+num2str(i+1))
	chNum = num2str(V_value)

	searchKey = ID + TC + "*" + chNum + PorD + "_iv"
	//ie. "DMZ0012_0000*1p_iv"
	

	//search IV curves
	string matchWave
	SetDataFolder root:$(ID)

	matchWave = Wavelist(searchKey,"","")
	appendtograph/C=(rColor[i],gColor[i],bColor[i]) root:$(ID):$matchWave
	
	//make legend
	string color = "("+ num2str(rColor[i]) + "," + num2str(gColor[i]) + "," + num2str(bColor[i]) + ")"
	legendstr = legendstr + "\\K" + color + ID + TC + " " + PorDfull + " ch" + chNum + "\r" 
	
endfor

// graphstyle
TextBox/C/N=text0/B=1/F=0 legendstr
SetAxis left -10,20
ModifyGraph zero=1,mirror=2
Label left "J(mA/cm\\S2\\M)"
Label bottom "Bias (V)"
ModifyGraph grid=1

setdatafolder root:

End


//6.general functions/////////////////////////////////////////////////////////////////
Function/S ListUpIDs(IDprefix, StartNum, EndNum)

string IDprefix
variable StartNum
variable EndNum

variable k = StartNum
string fourdigit
string list = ""

do
 
	fourdigit = MakeFourdigit(k) 
 
	list = list + IDprefix + fourdigit + ";"

k +=1
while (k <= endNum)

return list

End

Function/S MakeFourdigit(t)
variable t
string fourdigit

if (t <= 9)
    
   	fourdigit = "000" + num2str(t)
    
  elseif( t >= 10 && t <= 99 )
    
  	fourdigit = "00" + num2str(t)
    
  elseif(t >= 100 && t <= 999)
    
  	fourdigit = "0" + num2str(t)
    
  elseif(t >= 1000)
    
  	fourdigit = num2str(t)
   			
  endif

return fourdigit

End


//6. refresh global parameters/////////////////////////////////////////////////////////
Function RefreshGlobalParameters()

Make/T W_ID, W_Cmt
Edit W_ID, W_Cmt

NewDataFolder/O/S root:GLOBAL


NewDataFolder/O/S root:GLOBAL:ImportIVcurves

variable/G root:GLOBAL:ImportIVcurves:StartNum = 0
variable/G root:GLOBAL:ImportIVcurves:EndNum = 0
string/G root:GLOBAL:ImportIVcurves:IDprefix = ""
string/G root:GLOBAL:ImportIVcurves:FilterList = ""

NewDataFolder/O/S root:GLOBAL:ShowIVCurves

string/G root:GLOBAL:ShowIVcurves:ID = ""
string/G root:GLOBAL:ShowIVcurves:unit = "hour"


variable/G root:GLOBAL:ShowIVcurves:from1 = 0
variable/G root:GLOBAL:ShowIVcurves:to1   = 0
variable/G root:GLOBAL:ShowIVcurves:from2 = 0
variable/G root:GLOBAL:ShowIVcurves:to2   = 0

variable/G root:GLOBAL:ShowIVcurves:paramfrom = 0
variable/G root:GLOBAL:ShowIVcurves:paramto   = 1.2
variable/G root:GLOBAL:ShowIVcurves:PCEfrom   = 0
variable/G root:GLOBAL:ShowIVcurves:PCEto     = 9


NewDataFolder/O/S root:GLOBAL:PlotProperties


//checkbox
variable/G root:GLOBAL:PlotProperties:chNum_p
variable/G root:GLOBAL:PlotProperties:StartNum_p
variable/G root:GLOBAL:PlotProperties:EndNum_p
string/G root:GLOBAL:PlotProperties:IDprefix_p
string/G root:GLOBAL:PlotProperties:IDList_p

variable/G root:GLOBAL:PlotProperties:VocChk = 0
variable/G root:GLOBAL:PlotProperties:JscChk = 0
variable/G root:GLOBAL:PlotProperties:FFChk  = 0
variable/G root:GLOBAL:PlotProperties:PCEChk = 0
variable/G root:GLOBAL:PlotProperties:RsChk  = 0
variable/G root:GLOBAL:PlotProperties:RshChk = 0

variable/G root:GLOBAL:PlotProperties:Voc_rChk = 0
variable/G root:GLOBAL:PlotProperties:Jsc_rChk = 0
variable/G root:GLOBAL:PlotProperties:FF_rChk  = 0
variable/G root:GLOBAL:PlotProperties:PCE_RChk = 0
variable/G root:GLOBAL:PlotProperties:Rs_rChk  = 0
variable/G root:GLOBAL:PlotProperties:Rsh_rChk = 0


variable/G root:GLOBAL:PlotProperties:leftAutoChk = 1
variable/G root:GLOBAL:PlotProperties:bottomAutoChk = 1

variable/G root:GLOBAL:PlotProperties:ch1Chk = 0
variable/G root:GLOBAL:PlotProperties:ch2Chk = 0
variable/G root:GLOBAL:PlotProperties:ch3Chk = 0
variable/G root:GLOBAL:PlotProperties:ch4Chk = 0

//variables
variable/G root:GLOBAL:PlotProperties:leftFrom = 0
variable/G root:GLOBAL:PlotProperties:leftTo = 0

variable/G root:GLOBAL:PlotProperties:bottomFrom = 0
variable/G root:GLOBAL:PlotProperties:bottomTo = 0
string/G root:GLOBAL:PlotProperties:bottomUnit = "hour"


NewDataFolder/O/S root:GLOBAL:IVcomparison

string/G root:GLOBAL:IVcomparison:ID1 =""
string/G root:GLOBAL:IVcomparison:ID2 =""
string/G root:GLOBAL:IVcomparison:ID3 =""
string/G root:GLOBAL:IVcomparison:ID4 =""
string/G root:GLOBAL:IVcomparison:ID5 =""
string/G root:GLOBAL:IVcomparison:ID6 =""
string/G root:GLOBAL:IVcomparison:ID7 =""
string/G root:GLOBAL:IVcomparison:ID8 =""

string/G root:GLOBAL:IVcomparison:TC1 =""
string/G root:GLOBAL:IVcomparison:TC2 =""
string/G root:GLOBAL:IVcomparison:TC3 =""
string/G root:GLOBAL:IVcomparison:TC4 =""
string/G root:GLOBAL:IVcomparison:TC5 =""
string/G root:GLOBAL:IVcomparison:TC6 =""
string/G root:GLOBAL:IVcomparison:TC7 =""
string/G root:GLOBAL:IVcomparison:TC8 =""


SetDataFolder root:GLOBAL
Make/O rColor = {65280, 65280,     0,     0,    0,  29440, 26112, 19712,    0,      0, 52224, 52224}
Make/O gColor = {    0, 43520, 39168, 43520,    0,      0,     0,     0,  9472, 52224, 52224,     0}
Make/O bColor = {    0,     0,     0, 65280, 65280, 58880,     0, 39168, 39168, 26368,     0,     0}


SetDataFolder root:

DoWindow/K p_ImportIVcurves
DoWindow/K p_Plotproperties
Dowindow/K P_ShowIVcurves

End

Proc PCEonlygraph() : GraphStyle
	PauseUpdate; Silent 1
	ModifyGraph/Z gFont="Arial",gfSize=15
	ModifyGraph/Z mode=4
	ModifyGraph/Z grid(PCE_left)=1
	ModifyGraph/Z gridRGB(PCE_left)=(43520,43520,43520)
	ModifyGraph/Z gridStyle(PCE_left)=1
	ModifyGraph/Z lblPosMode=4
	ModifyGraph/Z lblPos(PCE_left)=55,lblPos(PCE_bottom)=40
	ModifyGraph/Z lblLatPos(PCE_left)=-2
	ModifyGraph/Z freePos(PCE_left)={0,kwFraction}
	ModifyGraph/Z freePos(PCE_bottom)={0,kwFraction}
	ModifyGraph/Z gridEnab(PCE_left)={0.3333,1}
	ModifyGraph axisEnab(PCE_left)={0,1},axisEnab(PCE_bottom)={0,1}
	ModifyGraph width=226.772,height={Aspect,1}
	ModifyGraph gridEnab(PCE_left)={0,1}
	ModifyGraph msize=4
	Label/Z PCE_left "PCE"
	Label/Z PCE_bottom "hour"
EndMacro

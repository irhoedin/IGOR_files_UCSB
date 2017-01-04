#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Menu "I-V data"

	"Import IV data", import_iv_curves()
	"IV finder window",  iv_finder()

End


Function import_iv_curves()
string pathname
string filename


SetDataFolder root:

//get filename list in the designated folder
NewPath/O temporaryPath
pathname = "temporaryPath"
string filelist = indexedfile($pathname, -1, ".txt")

//
variable filename_i = 0
do
	filename = stringfromlist(filename_i, filelist)
	
	if(strlen(filename)==0)//no more file to rad
		break
	endif
	
	string info_list = pickup_info(filename)
	string core_name = stringfromlist(0, info_list)
	string id = stringfromlist(1, info_list) 
	string cycle = stringfromlist(2, info_list) 
	string cmt = stringfromlist(3, info_list) 
	
	variable process_iv = process_iv_curve(pathname, filename, core_name, id, cmt, filename_i)
	variable show_iv_curve = show_iv(id, cmt, filename_i)
	variable show_iv_parm = show_list_table(id, cmt, filename_i)
	
	filename_i += 1
while(1)


print pathname
end function







static function process_iv_curve(pathname, filename, core_name, id, cmt, filename_i)
string pathname
string filename
string core_name
string id
string cmt
variable filename_i

variable CH_NO = 5
variable PINT = 100 //energy of incident light unit: mW/cm2

LoadWave/Q/A/J/D/O/P = $pathname filename

//get info from filename



if(DataFolderExists(id) == 0)
	NewDataFolder root:$(id)
endif

//read voltage column
string voltage = stringfromlist(0, S_waveNames)
Wave volt = $voltage
variable v_start = volt[0]
variable v_step = volt[1] - volt[0]

wavestats/Q volt
variable end_point = V_endRow
variable zero_point = x2pnt(volt, 0)

Duplicate/O volt root:$(id):$(core_name + "_voltage")

//read current column and cal parameters
variable ch_i = 1
do
	
	Make/O/N=6 param_list
	//paramList Voc;Jsc;FF;PCE;Rs(photo);Rsh(photo)
	
	string current = stringfromlist(ch_i, S_waveNames)
	Wave curr = $current

	SetScale/P x, v_start, v_step, "V", curr

	//1. Voc unit: V
	FindLevel/Q curr, 0 //find the point where the value closest to J = 0
	param_list[0] = V_LevelX
	
	//2. Jsc unit: mA/cm2
	param_list[1] = -curr(0)
	
	//3. FF
	Duplicate/O curr jv
	jv = -curr*x //unit of energy unit: mW/cm2
	
	WaveStats/Q jv
	variable jv_max
	jv_max = V_max
	param_list[2] = jv_max/param_list[0]/param_list[1]
	
	//4. PCE unit: %

	param_list[3] = jv_max*100/PINT //unit of percentage
	
	//5. Rs unit: ohm cm2
	Make/O/N=2 Rs_coef
	curvefit /Q line kwCwave=Rs_coef curr[end_point - 10, end_point]
	param_list[4] = 1000/Rs_coef[1]
	
	//6. Rsh: ohm cm2
	Make/O/N=2 Rsh_coef
	curvefit/Q line kwCWave=Rsh_coef curr[zero_point - 5, zero_point + 5] //tilt angle at V = 0
	param_list[5] = 1000/Rsh_coef[1]


	//7. Resister waves
	Duplicate/O curr root:$(id):$(core_name+ "_ch" + num2str(ch_i) + "_iv")
	Duplicate/O param_list root:$(id):$(core_name + "_parm_ch" +  num2str(ch_i))
	
	killwaves curr, param_list, jv, Rs_coef, Rsh_coef
	ch_i += 1
while(ch_i  <= CH_NO)
killwaves volt

end function








static function show_iv(id, cmt, filename_i)
string id, cmt
variable filename_i


if (stringmatch(cmt, "d")==1)
	return 0
else

SetDataFolder root:$(id)

//showing IV cureves

variable column = mod(filename_i, 12)
variable row = floor(filename_i/12)
variable left, top, right, down

left = 100 * column
top = row * 100
right = left + 300
down = top + 300

string light

string windowname = id + "g"
DoWindow/K windowname
Display /K=1/W=(left, top, right, down)/N=$windowname
DoWindow /T kwTopWin, id
ModifyGraph gFont="Helvetica", gfSize=12, gmSize=3

string photo_currlist = wavelist("*p*iv",";","")
string photo_current
variable pc_i = 0
do
	photo_current = stringfromlist(pc_i, photo_currlist)
	
	if(strlen(photo_current)==0)
		break
	endif
	
	Appendtograph $photo_current
	ModifyGraph lsize($photo_current)=2,rgb($photo_current)=(0,0,0)
	
	pc_i += 1

while(1)

string dark_currlist = wavelist("*d*iv",";","")
string dark_current
pc_i = 0
do
	dark_current = stringfromlist(pc_i, dark_currlist)
	
	if(strlen(dark_current)==0)
		break
	endif
	
	Appendtograph $dark_current
	ModifyGraph lsize($dark_current)=2,rgb($dark_current)=(0,0,0),lstyle($dark_current)=3
	
	pc_i += 1

while(1)

SetAxis left -20,20
ModifyGraph zero(left)=1
ModifyGraph zero=1

Label left "\\f02j \\f00[mA/cm\\S2\\M]"
Label bottom "\\f02V \\f00 [V]"
TextBox/C/N=text0/F=0/A=MT/X=0.00/Y=0.00 id


SetDataFolder root:

string savename = id + "_graph.pdf"
Dowindow /F  windowname
Savepict  /P=temporaryPath /E=-2  /O as savename


endif

return 1
end function








static function/S pickup_info(filename)
string filename


string core_name = Stringfromlist(0, filename, ".")

//get information from filename. "id_cycle_cmt"
string id = stringfromlist(0, core_name,"_") 
string cycle = stringfromlist(1, core_name, "_") 
string cmt = stringfromlist(2, core_name, "_") 

return (core_name+";"+id+";"+cycle+";"+cmt)

end function







static function show_list_table(id, cmt, filename_i)
string id, cmt
variable filename_i


if (stringmatch(cmt, "d")==1)
	return 0
else

Make/O/T/N=6 parm_name = {"Voc", "Jsc", "FF", "PCE", "Rs", "Rsh"}

variable column = mod(filename_i, 12)
variable row = floor(filename_i/12)
variable left, top, right, down

left = 100 * column
top = row * 100 + 500
right = left + 600
down = top + 200

string windowname = id + "t"
DoWindow/K windowname
Edit/K=1/W=(left, top, right, down)/N=$windowname parm_name as id

SetDataFolder root:$(id)

string photo_currlist = wavelist("*p_parm*",";","")
string photo_current
variable pc_i = 0
do
	photo_current = stringfromlist(pc_i, photo_currlist)
	
	if(strlen(photo_current)==0)
		break
	endif
	
	Appendtotable $photo_current
	
	pc_i += 1

while(1)

SetDataFolder root:

string savename = id + "_prm.csv"
SaveTableCopy /P=temporaryPath /W=$windowname/T=2/O as savename

endif

return 1
end function







Window iv_finder(): Panel
string/G root:id

DoWindow/K IV_comparison
NewPanel /W=(0,0,200,150) as "IV comparison"
DoWindow/C IV_comparison
ModifyPanel cbRGB=(49151,49152,65535)
SetDrawLayer UserBack

SetVariable ID, pos={35, 30}, size={120,100}, fSize=14, title="ID", value = id

Button show_iv_button, pos={40, 60}, size={120, 22}, proc=launch_show_iv, title="Show IV graph"
Button show_parm_button, pos={40, 90}, size={120, 22}, proc=launch_show_parm, title="Show IV parm"


end window




function launch_show_iv(ctrlName): ButtonControl
string ctrlName
string/G id = id

SetDataFolder root:

variable show_graph = show_iv(id, "p", 0)

End function




function launch_show_parm(ctrlName): ButtonControl
string ctrlName
string/G id = id

SetDataFolder root:

variable show_table = show_list_table(id, "p", 0)

End function

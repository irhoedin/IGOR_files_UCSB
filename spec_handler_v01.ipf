#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Spectra"
	"Load EQE file", load_eqe()
	"Load transmittance file", load_trans()
	
End




Function load_eqe()
//get filename list in the designated folder
NewPath/O temporaryPath
string pathname = "temporaryPath"
string filename
string filelist = indexedfile($pathname, -1, ".txt")

//
variable filename_i = 0
do
	filename = stringfromlist(filename_i, filelist)
	
	if(strlen(filename)==0)//no more file to rad
		break
	endif
	
        string core_name = Stringfromlist(0, filename, ".")
	
	LoadWave/Q/A/J/D/O/L={0,0,0,0,2}/P= $pathname filename
	string wl = stringfromlist(0, S_waveNames)
	Wave wavelength = $wl
	variable wl_start = wavelength[0]
	variable wl_step = wavelength[1] - wavelength[0]
	
	string eqe = stringfromlist(1, S_waveNames)
	Wave EQE_data = $eqe
	Setscale/P x, wl_start, wl_step, "wavelength [nm]", EQE_data
	
	string wname = core_name + "_EQE"
	Duplicate/O EQE_data, $wname
	Killwaves EQE_data, wavelength

	
	filename_i += 1
while(1)


end function



Function load_trans()
NewPath/O temporaryPath
string pathname = "temporaryPath"
string filename
string filelist = indexedfile($pathname, -1, ".txt")

//
variable filename_i = 0
do
	filename = stringfromlist(filename_i, filelist)
	
	if(strlen(filename)==0)//no more file to rad
		break
	endif
	
        string core_name = Stringfromlist(0, filename, ".")
	
	LoadWave/Q/A/J/D/O/L={0,17,0,0,2}/P= $pathname filename
	string wl = stringfromlist(0, S_waveNames)
	Wave wavelength = $wl
	
	string trns = stringfromlist(1, S_waveNames)
	Wave trns_data = $trns
	trns_data = trns_data/100     //remove [%]
	
	string trns_name = core_name + "_trans"
	string abs_name = core_name + "_abs"
	
	Interpolate2/I=3/X=wl_base/y=$trns_name wavelength, trns_data
	Wave transmittance = $trns_name	
		
	Wave wl_base
	variable wl_start = wl_base[0]
	variable wl_step = wl_base[1] - wl_start
	Setscale/P x, wl_start, wl_step, "wavelength [nm]", transmittance
	
	Duplicate/O transmittance, $abs_name
	Wave absorbance = $abs_name

	absorbance = -log(transmittance)
	
	Killwaves wavelength, trns_data
	
	filename_i += 1
while(1)



End function

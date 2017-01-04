#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Spectra"
	"Load EQE file", load_eqe()
	"Load transmittance file", load_trans()
	"Load absorption coefficient file", load_abscoeff()
	
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


function load_abscoeff()
NewPath/O temporaryPath
string pathname = "temporaryPath"
string filename
string filelist = indexedfile($pathname, -1, ".csv")

//
variable filename_i = 0
do
	filename = stringfromlist(filename_i, filelist)
	
	if(strlen(filename)==0)//no more file to rad
		break
	endif
	
        string core_name = Stringfromlist(0, filename, ".")
	
	LoadWave/Q/A/J/D/O/L={0,1,0,1,4}/P= $pathname filename
	string wl = stringfromlist(0, S_waveNames)
	Wave wavelength = $wl
	
	string abswl = stringfromlist(1, S_waveNames)
	Wave abs_wl = $abswl

	string ev = stringfromlist(2, S_waveNames)
	Wave energy_volt = $ev
	
	string absev = stringfromlist(3, S_waveNames)
	Wave abs_ev = $absev
		
	variable wl_start = wavelength[0]
	variable wl_step = wavelength[1] - wl_start
	print wl_start, wl_step
	Setscale/P x, wl_start, wl_step, "wavelength [nm]", abs_wl
	
	variable ev_start = energy_volt[0]
	variable ev_step = energy_volt[1] - ev_start
	Setscale/P x, ev_start, ev_step, "Energy [eV]", abs_ev
	
	string wl_name = core_name + "_abscff_wl"
	string ev_name = core_name + "_abscff_eV"
	
	Duplicate/O abs_wl, $wl_name
	Duplicate/O abs_ev, $ev_name
	
	Killwaves wavelength, abs_wl, energy_volt, abs_ev
	
	filename_i += 1
while(1)

end function

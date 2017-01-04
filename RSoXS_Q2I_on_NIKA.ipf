//by Hidenori Nakayama of Chabinyc Lab/Mitsubishi Chemical Corporation
//12/18/2016 ver1.0

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "NORI"
"RSoXS q^2*I", launch_q2i()
End

Macro launch_q2i()

	refresh_datalist()
	nori_q2i_panel()
	create_noriq2i_folders()

EndMacro



Window nori_q2i_panel()
	
	NewPanel /W=(0,0,300, 600)
	
	ListBox r_line_lists, pos={20,10}, size={250, 400}
	ListBox r_line_lists, listWave=root:nori_q2i:data_wave
	ListBox r_line_lists, selWave=root:nori_q2i:data_wave_num, mode=8
	
	Button cal_q2i_B, pos={90, 450}, size={100, 60}
	Button cal_q2i_B, proc=plot_q2i, title="Plot q^2 i vs q"

End



Proc create_noriq2i_folders()
	
	NewDataFolder/O/S root:nori_q2i
	variable refresh = refresh_datalist()

End



Function refresh_datalist()
		String objName
		String dfr_list = ""
		Variable index = 0
		DFREF dfr = GetDataFolderDFR()	// Reference to current data folder
		do
			objName = GetIndexedObjNameDFR(dfr, 4, index)
			if (strlen(objName) == 0)
				break
			endif
			dfr_list = dfr_list + objName + ";"
			index += 1
		while(1)
		
		print dfr_list
		print index
		Make/T/O/N=(index) root:nori_q2i:data_wave=stringfromlist(p, dfr_list)
		Make/O/N=(index) root:nori_q2i:data_wave_num
		
End



Function plot_q2i(ctrlName):ButtonControl
	string ctrlName
	wave/T data_wave = root:nori_q2i:data_wave
	wave num_wave = root:nori_q2i:data_wave_num
	Variable i
	String id_name
	
	Display /K=1/W=(0,0, 500, 500)
	DoWindow /T kwTopWin, "q^2 * i Plots"
	ModifyGraph gFont="Helvetica", gfSize=18, gmSize=3
	
	
	for(i=0; i<numpnts(num_wave); i+=1)
		if(num_wave[i]==1)
			id_name = data_wave[i]
			Wave q_wave = root:SAS:$(id_name):$("q_"+id_name)
			Wave r_wave = root:SAS:$(id_name):$("r_"+id_name)
			Duplicate/O q_wave, root:SAS:$(id_name):$("x_"+id_name)
			Wave q2i_wave = root:SAS:$(id_name):$("x_"+id_name)
			q2i_wave = q_wave^2 * r_wave
			
			AppendtoGraph q2i_wave vs q_wave
		
		endif
		
	endfor
	
	Label left "q\\S2\\MI"
	Label bottom "q [A\\S-1\\M]"
	

End
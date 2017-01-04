//
// by HIdenori Nakayama of Chabinyc Lab/Mitsubishi Chemical
//Ver 1.0
//12/22/2016

//Strongly inspired by Stephane's script for processing GIWAXS images from SSRL

#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "NI1_Loader"
#include "SO_WAXS_geometry"
#include "SO_WAXS_panel"

Menu "Macros"
	"initialize_NORI_ALS_GIWAXS /2"
End


Macro initialize_NORI_ALS_GIWAXS()
	NewDataFolder/O root:NORI_ALS_GIWAXS
	NewDataFolder/O root:NORI_ALS_GIWAXS:tiffs
	NewDataFolder/O root:NORI_ALS_GIWAXS:qfiles
	SetDataFolder root:NORI_ALS_GIWAXS
	
	variable/G BCX, BCY, dist, incidence
	variable/G pxsize = 0.172 // 12/16/2016 visit
	variable/G qrange = 2.1
	variable/G qres = 0.0015
	variable/G Npixels_x = 981 // 12/16/2016 visit
	variable/G Npixels_y = 1043 // 12/16/2016 visit
	variable/G lambda = 1.23984 // angstrom
	
	variable/G z_high
	variable/G z_low
	
	nori_update_wavelist()
	nori_ALS_GIWAXS_panel()

End


function nori_update_wavelist()
	SetDataFolder root:NORI_ALS_GIWAXS:tiffs
	string thewaves = Wavelist("*", ";", "")
	make/T/O/N=(ItemsInList(thewaves,";")) root:NORI_ALS_GIWAXS:thewavelist = stringfromlist(p,thewaves,";")
	make/O/N=(itemsinlist(thewaves,";")) root:NORI_ALS_GIWAXS:thewavelist_number
	
	SetDataFolder root:NORI_ALS_GIWAXS:qfiles
	string thewaves_q = Wavelist("*", ";", "")
	make/T/O/N=(ItemsInList(thewaves_q,";")) root:NORI_ALS_GIWAXS:thewavelist_q = stringfromlist(p,thewaves_q,";")
	make/O/N=(itemsinlist(thewaves_q,";")) root:NORI_ALS_GIWAXS:thewavelist_q_number
	
	SetDataFolder root:NORI_ALS_GIWAXS
	
end


Window nori_ALS_GIWAXS_panel():Panel
	
	NewPanel/W=(0, 0, 500, 500)
	ModifyPanel cbRGB=(49151,49152,65535)
	Button conv2tif, pos={20, 30}, size={100, 40}, proc=conv_gb2tif_BTN, title="Conv. .gb to .tif"
	Button load_tif, pos={20, 90}, size={100, 40}, proc=nori_load_tif_BTN, title="Load TIFF images"
	//Button reset_waves, pos={130, 90}, size={100,40}, proc=nori_reset_list, title = "Reset lists"
	ListBox tiff_list, pos={20, 140}, size={200, 150}, listWave=root:NORI_ALS_GIWAXS:thewavelist
	ListBox tiff_list, selWave=root:NORI_ALS_GIWAXS:thewavelist_number
	ListBox tiff_list, mode=8
	
	ListBox qfiles_list, pos={20, 320}, size={200, 150}, listWave=root:NORI_ALS_GIWAXS:thewavelist_q
	ListBox qfiles_list, selWave=root:NORI_ALS_GIWAXS:thewavelist_q_number
	ListBox qfiles_list, mode=8
	
	SetVariable BCX, pos={250, 30},size={100, 40}, value=root:NORI_ALS_GIWAXS:BCX
	SetVariable BCY, pos={250, 60},size={100, 40}, value=root:NORI_ALS_GIWAXS:BCY
	SetVariable dist, pos={250, 90},size={100, 40}, value=root:NORI_ALS_GIWAXS:dist
	SetVariable incidence, pos={250, 120},size={100, 40}, value=root:NORI_ALS_GIWAXS:incidence
	SetVariable pxsize, pos={250, 150},size={100, 40}, value=root:NORI_ALS_GIWAXS:pxsize
	SetVariable qrange pos={250, 180},size={100, 40}, value=root:NORI_ALS_GIWAXS:qrange
	SetVariable qres, pos={250, 210},size={100, 40}, value=root:NORI_ALS_GIWAXS:qres
	SetVariable Npixels_x, pos={250, 240},size={100, 40}, value=root:NORI_ALS_GIWAXS:Npixels_x
	SetVariable Npixels_y, pos={250, 270},size={100, 40}, value=root:NORI_ALS_GIWAXS:Npixels_y
	SetVariable lambda, pos={250, 300},size={100, 40}, value=root:NORI_ALS_GIWAXS:lambda
	
	Button conv2qrange, pos={250, 350},size={100, 40}, proc=nori_tiff2q, title="Conv. to q-range "
	Button plotq, pos={250, 420}, size={100, 40}, proc=nori_plotq_BTN, title="Plot q-range images"
	
	Slider Z_slider_high,pos={380,20},size={65,400},proc=nori_giwaxs_slider
	Slider Z_slider_high,limits={0,10,0.5},variable= root:NORI_ALS_GIWAXS:z_low
	Slider Z_slider_low,pos={440,20},size={65,400},proc=nori_giwaxs_slider
	Slider Z_slider_low,limits={0,10,0.5},variable= root:NORI_ALS_GIWAXS:z_high
	
	Titlebox z_low, pos={380, 430}, frame=0, fsize=12, title="Z-Low"
	Titlebox z_high, pos={440, 430}, frame=0, fsize=12, title="Z-High"


End


function nori_tiff2q(ctrlName):ButtonControl
			string ctrlName
			string thiswavename
			//print wavenamelist
			variable i
			wave/T thewavelist = root:NORI_ALS_GIWAXS:thewavelist
			wave thewavelist_number = root:NORI_ALS_GIWAXS:thewavelist_number
			variable list_num = numpnts(thewavelist)
			
			NVAR g_BCX = root:NORI_ALS_GIWAXS:BCX
			NVAR g_BCY = root:NORI_ALS_GIWAXS:BCY
			NVAR g_dist = root:NORI_ALS_GIWAXS:dist
			NVAR g_incidence = root:NORI_ALS_GIWAXS:incidence
			NVAR g_pxsize = root:NORI_ALS_GIWAXS:pxsize
			NVAR g_q_range = root:NORI_ALS_GIWAXS:qrange
			NVAR g_q_res = root:NORI_ALS_GIWAXS:qres
			NVAR g_Npixels_x = root:NORI_ALS_GIWAXS:Npixels_x
			NVAR g_Npixels_y= root:NORI_ALS_GIWAXS:Npixels_y
			NVAR g_lambda = root:NORI_ALS_GIWAXS:lambda
			
			
			for(i=0;i<list_num;i+=1)
				if(thewavelist_number[i]==1)
				thiswavename="root:NORI_ALS_GIWAXS:tiffs:" + thewavelist[i]
				Wave det_image = $thiswavename
				ALS_GIWAXS(det_image,g_BCX,g_BCY,g_dist,g_incidence,g_pxsize,g_q_range,g_q_res,g_Npixels_x, g_Npixels_y, g_lambda)
				print thiswavename
				endif
			endfor
End

function nori_giwaxs_slider(ctrlName, sliderValue, event):SliderControl

	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved
	
			NVAR g_Z_low = root:NORI_ALS_GIWAXS:z_low
			NVAR g_Z_high = root:NORI_ALS_GIWAXS:z_high
					string thisimage = stringfromlist(0,imagenamelist("",";"))
					ModifyImage $thisimage ctab= {g_Z_low,g_Z_high,Rainbow,1}

	if(event %& 0x1)	// bit 0, value set

	endif

	return 0
End




function ALS_GIWAXS(det_image,BCX,BCY,R,incidence,pxsize,qrange,qres,Npixels_x, Npixels_y, lambda) // take incidence angle into account!
	wave det_image // raw detector input, assumed new CCD detector
	variable BCX // beam center of detector image, X direction
	variable BCY
	variable R //0.07//e7 // sample-detector distance in pixels (0.1mm)
	variable incidence // incidence angle in rad
	variable pxsize // size of pixel in one dimension, square pixels assumed
	variable qrange // range of q that will be converted
	variable qres // resolution of the result image
	variable Npixels_x
	variable Npixels_y
	variable lambda // wavelength of the beam in angstrom
	
	variable qx
	variable qy
	variable qxy
	variable qz
	variable q
	variable chi
	variable px // for reference to detector image, p as in pixel
	variable py
	variable theta2
	variable k=2*Pi/lambda
//	variable incidence = 1.2 * Pi/180 // incidence angle in rad
	
	SetDataFolder root:NORI_ALS_GIWAXS:qfiles
	
	BCX=BCX*pxsize // beam center of detector image, X direction, convert to mm
	BCY=BCY*pxsize
	incidence = incidence * Pi/180 // incidence angle in rad
	
	duplicate/O det_image rawimage // easier to work with, I can set an x and y scaling for easier math
	
	setscale/P x, -BCX, pxsize, rawimage // pxsize pixel size, in mm
	setscale/P y, BCY, -pxsize, rawimage

	
	// here you need to find the maximum and minimum qz and qxy. Anything above those values needs to be zero
	// umm, just figure out if the pixel is outside of the image when filling the q space; this is easier probably.
	// assign variable to x min x max etc.
	// CCD detector size: 981x1043 pixels in ALS

	make/O/N=(Npixels_x) xwave // amazing that I didn't see anything odd when using this with mar2300 images!
	make/O/N=(Npixels_y) ywave
	setscale/P x, -BCX, pxsize, xwave
	setscale/P x, BCY, -pxsize, ywave
	xwave=x
	ywave=x
	//variable nmax = 3071
	variable xmin=xwave[0]
	print "xmin=", xmin
	variable xmax=xwave[Npixels_x  - 1]
	print "xmax=", xmax
	variable ymin=ywave[Npixels_y  - 1]
	print "ymin=", ymin
	variable ymax=ywave[0]
//	print "BCX=", BCX
//	print "BCY=", BCY
//	print "xmin=", xmin
//	print "xmax=", xmax
//	print "ymin=", ymin
//	print "ymax=", ymax
	
	

	// this is the result image (reciprocal space)
	// qres, qrange: e.g. range=2, res=0.0015 => 1333.33 pixels. Damn. number of pixels in result: round(range/res)
	
	variable qzpoints = round(qrange/qres)
	variable qxypoints = round(qrange/qres)
	
	make/O /N=(qxypoints,qzpoints) corr_image
	corr_image=0
	setscale/P x, 0, qres, corr_image
	setscale/P y, abs(qrange), (-1*qres), corr_image
	
	//make x and y waves for looking up the qxy and qz values
	make/O /N=(qzpoints) qzwave
	make/O /N=(qxypoints) qxywave
	setscale/P x, qrange, (-1*qres), qzwave
	setscale/P x, 0, qres, qxywave
	qxywave = x
	qzwave = x
	
	// loop for filling the reciprocal image
	variable i
	variable ii
	variable term
	variable costerm
	variable s // use same terms as in the Stribeck paper
	duplicate/O qzwave szwave
	szwave=qzwave/(2*Pi) // maybe faster than calculating this in the loop? not sure...
	
	for(i=0;i<qxypoints;i+=1) // qxy range
		for(ii=0;ii<qzpoints;ii+=1) // qz range
			s=(sqrt((qxywave[i])^2+(qzwave[ii])^2))/(2*Pi)
			//sz=qzwave[ii]/(2*Pi)
			term=2*lambda*R*s / (2-((lambda)^2) * s^2)
			costerm= ( (szwave[ii]/s) - ( (lambda*s/2)*sin(incidence) ) ) / cos(incidence) 
			// determine the pixels on the detector image:
			px=term * sqrt(1- (((lambda)^2) * (s^2)/4) - ((costerm)^2) )
			py=term * costerm
			// make px negative if qxy is negative (sign gets lost in taking the square):
			if(qxywave[i]<0)
				px=-px
			endif
			
//			print "qxy=",qxywave[i]
//			print "qz=", qz
//			print "px=",px
//			print "py=",py
//			print rawimage(px)(py)
				
				// insert values into corrected image
				// if pixel I'm trying to find is not on the detector, it's value will be zero
				if(px < xmin)
					corr_image[i][ii]=0
				elseif (px > xmax)
					corr_image[i][ii]=0
				elseif(py < ymin)
					corr_image[i][ii]=0
				elseif(py > ymax)
					corr_image[i][ii]=0
				elseif(numtype(px)==2) // means if px == NaN
					corr_image[i][ii]=0
				elseif(numtype(py)==2)
					corr_image[i][ii]=0
				else
					corr_image[i][ii]=rawimage(px)(py)
				endif
//			print corr_image[i][ii]

		endfor
	endfor
	
	// clean up folder
	killwaves xwave, ywave, qzwave, qxywave, szwave
	string newname = nameofwave(det_image) + "_qzqxy"
	duplicate/O corr_image $newname
	killwaves rawimage, corr_image
	
	SetDataFolder root:NORI_ALS_GIWAXS
	nori_update_wavelist()
end


/////////////////////////////////////////////////////////////
//Converting GB file to raw TIFF files
/////////////////////////////////////////////////////////////


Function Conv_gb2tif_BTN(ctrlName):ButtonControl
	String ctrlName
	Wave/T NIKA_list = root:Packages:Convert2Dto1D:ListOf2DSampleData
	variable i
	variable list_size = numpnts(NIKA_list)
	print list_size
	string image2conv
	
	for(i=0; i< list_size; i+=1)
		image2conv = NIKA_list[i]
		if(stringmatch(image2conv, "*.gb")==1)

			Nori_NI1A_DisplayOneDataSet(image2conv)
			Nori_NI1A_ExportDisplayedImage()
			
		endif
		
	endfor
	
	NI1A_UpdateDataListBox()
End


Function Nori_NI1A_DisplayOneDataSet(image2conv)
	string image2conv
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	//Kill top graph with Imge if it exists..
	DoWIndow CCDImageToConvertFig
	if(V_Flag)
		DoWIndow/K CCDImageToConvertFig
	endif
	//now kill the Calibrated wave, since this process will not create one
	Wave/Z Calibrated2DDataSet = root:Packages:Convert2Dto1D:Calibrated2DDataSet
	if(WaveExists(Calibrated2DDataSet))
		KillWaves /Z Calibrated2DDataSet
	endif
	//end set the parameters for display...
	NVAR DisplayProcessed2DData=root:Packages:Convert2Dto1D:DisplayProcessed2DData
	NVAR DisplayRaw2DData=root:Packages:Convert2Dto1D:DisplayRaw2DData
	DisplayProcessed2DData=0
	DisplayRaw2DData=1
	//and disable the controls...
	CheckBox DisplayProcessed2DData,win=NI1A_Convert2Dto1DPanel, disable=2
	
	Wave ListOf2DSampleDataNumbers=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
	if(sum(ListOf2DSampleDataNumbers)<1)
		abort 
	endif	
	Wave/T ListOf2DSampleData=root:Packages:Convert2Dto1D:ListOf2DSampleData
	string SelectedFileToLoad
	variable i, imax = numpnts(ListOf2DSampleDataNumbers), numLoadedImages=0
	string DataWaveName="CCDImageToConvert"
	string Oldnote=""
	string TempNote=""
	variable loadedOK
	Wave/Z tempWave=root:Packages:Convert2Dto1D:CCDImageToConvertTemp
	if(WaveExists(tempWave))
		KillWaves tempWave
	endif
	//For(i=0;i<imax;i+=1)
		//if (ListOf2DSampleDataNumbers[i])
			SelectedFileToLoad=image2conv		//this is the file selected to be processed
			loadedOK = NI1A_ImportThisOneFile(SelectedFileToLoad)
			if(!loadedOK)
				return 0
			endif
			NI1A_DezingerDataSetIfAskedFor(DataWaveName)
			Wave/Z tempWave=root:Packages:Convert2Dto1D:CCDImageToConvertTemp
			Wave CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert
			if(!WaveExists(tempWave))
				OldNote+=note(CCDImageToConvert)
				Duplicate/O CCDImageToConvert, root:Packages:Convert2Dto1D:CCDImageToConvertTemp
				numLoadedImages+=1
				TempNote=note(CCDImageToConvert)
				OldNote+="DataFileName"+num2str(numLoadedImages)+"="+StringByKey("DataFileName", TempNote , "=", ";")+";"
			else
				TempNote=note(CCDImageToConvert)
				MatrixOp/O/NTHR=0  tempWave=CCDImageToConvert+tempWave
				numLoadedImages+=1
				OldNote+="DataFileName"+num2str(numLoadedImages)+"="+StringByKey("DataFileName", TempNote , "=", ";")+";"
			endif
		//endif
	//endfor
	OldNote+="NumberOfAveragedFiles="+num2str(numLoadedImages)+";"
	Wave tempWave=root:Packages:Convert2Dto1D:CCDImageToConvertTemp
	redimension/D tempWave
	MatrixOp/O/NTHR=0   CCDImageToConvert=tempWave/numLoadedImages
	KillWaves/Z tempWave
	note/K CCDImageToConvert
	note CCDImageToConvert, OldNote
		NI1A_DisplayLoadedFile()
		NI1A_DisplayStatsLoadedFile("CCDImageToConvert")
		NI1A_TopCCDImageUpdateColors(1)
		NI1A_DoDrawingsInto2DGraph()
		NI1A_CallImageHookFunction()
		DoWIndow Sample_Information
		if(V_FLag)
			AutopositionWindow/M=0/R=CCDImageToConvertFig Sample_Information
		endif
	setDataFolder OldDf	
end


Function Nori_NI1A_ExportDisplayedImage()
	
	string OldDf=GetDataFolder(1)
	setDataFOlder root:Packages:Convert2Dto1D
	WAVE/Z ww=root:Packages:Convert2Dto1D:CCDImageToConvert_dis
	NVAR DisplayProcessed2DData=root:Packages:Convert2Dto1D:DisplayProcessed2DData
	if(WaveExists(ww)==0)
		Abort "Something is wrong here"
	endif
	SVAR FileNameToLoad=root:Packages:Convert2Dto1D:FileNameToLoad
	string  SaveFileName=FileNameToLoad[0,25]
	//Prompt SaveFileName, "Input file name for file to save"
	//DoPrompt "Correct file name to use for saving this file", SaveFileName
	//if(V_Flag)
	//	abort
	//endif
	//if (strlen(SaveFileName)==0)
	//	abort "No name specified"
	//endif
		//print SaveFileName[strlen(SaveFileName)-4,inf]
	
	variable name_len = strlen(SaveFileName)
	SaveFileName = SaveFileName[0, name_len - 4] + ".tif"
	//if(cmpstr(SaveFileName[strlen(SaveFileName)-4,inf],".tif")!=0)
		//SaveFileName+=".tif"
	//endif
	string ListOfFilesThere
	ListOfFilesThere=IndexedFile(Convert2Dto1DDataPath,-1,".tif")
	if(stringMatch(ListOfFilesThere,"*"+SaveFileName+"*"))
		DoAlert 1, "File with this name exists, overwrite?"
		if(V_Flag!=1)
			abort
		endif	
	endif
	Duplicate/O ww, wwtemp
	Redimension/S wwtemp
	//Redimension/W/U wwtemp		//this converts to unsigned 16 bit word... needed for export. It correctly rounds.... 
	if(!DisplayProcessed2DData)	//raw data, these are integers...	
		ImageSave/P=Convert2Dto1DDataPath/F/T="TIFF"/O wwtemp SaveFileName			//we save that as single precision float anyway...
	else			//processed, this is real data... 
		ImageSave/P=Convert2Dto1DDataPath/F/T="TIFF"/O wwtemp SaveFileName			// this is single precision float..  
	endif
	//ImageSave/D=16/T="TIFF"/O/P=Convert2Dto1DDataPath wwtemp SaveFileName
	KilLWaves wwtemp
	//NI1A_UpdateDataListBox()
	SetDataFolder OldDf
end


/////////////////////////////////////////
//load tiff file and show up in the list
/////////////////////////////////////////

function/S nori_load_tif()
	Variable refNum
	String message = "Select one or more files"
	String outputPaths
	String fileFilters = "All Files:.*;"
	SetDataFolder root:NORI_ALS_GIWAXS:tiffs
 
	Open /D /R /MULT=1 /F=fileFilters /M=message refNum
	outputPaths = S_fileName
 
	if (strlen(outputPaths) == 0)
		Print "Cancelled"
	else
		Variable numFilesSelected = ItemsInList(outputPaths, "\r")
		Variable i
		for(i=0; i<numFilesSelected; i+=1)
			String path = StringFromList(i, outputPaths, "\r")
//			Printf "%d: %s\r", i, path
			// Add commands here to load the actual waves.  An example command
			// is included below but you will need to modify it depending on how
			// the data you are loading is organized.
			//LoadWave/A/D/J/W/K=0/V={" "," $",0,0}/L={0,2,0,0,0} path
	//		string LegalFileName
	//		LegalFileName = CleanUpName(path,0)					// Fix the filename to a strict legal IGOR name
	//		LoadWave /O/G/W/A Path						// Load general text file, 1st block (matrix only)
			
			ImageLoad/T=tiff path
			// declare the loaded image as a wave; need to get the filename from the path string
			string imagename = parsefilepath(0,path,":",1,0)
//			print "name of image is", imagename
			
			// Get just the fileName but with the extension remove.
			String wName = ParseFilePath(3, path, ":", 0, 0)
			wName = CleanupName(wName, 0)	// Change 0 to 1 if you want to allow liberal names
//			print path
//			print wName
			Duplicate/O $imagename $wName
			killwaves $imagename
		endfor
	endif
 
	return outputPaths		// Will be empty if user canceled
End



Function nori_load_tif_BTN(ctrlName):ButtonControl
	string ctrlName
	string exe_load_tif = nori_load_tif()
	nori_update_wavelist()
	
end Function
	

Function nori_plotq_BTN(ctrlName) : ButtonControl
	string ctrlName
	SetDataFolder root:NORI_ALS_GIWAXS:qfiles
			
			string thiswavename
			string wavenamelist=wavelist("*",";","")
			//print wavenamelist
			variable i
			wave/T thewavelist = root:NORI_ALS_GIWAXS:thewavelist_q
			wave thewavelist_number = root:NORI_ALS_GIWAXS:thewavelist_q_number
			variable list_num = numpnts(thewavelist)
			
			for(i=0;i<list_num;i+=1)
				if(thewavelist_number[i]==1)
					thiswavename = thewavelist[i]
					string image_to_show = "root:NORI_ALS_GIWAXS:qfiles:" + thiswavename
					Preferences 0
					Display/K=1
					AppendImage $image_to_show
					ModifyImage $thiswavename ctab= {2, 5, Rainbow,1}
					
					ModifyGraph width=200
					ModifyGraph/Z height={Aspect,1}
					ModifyGraph/Z mirror=2
					ModifyGraph/Z fSize=16
					Label/Z left "\\Z18q\\Bz\\M\\Z18 (A\\S-1\\M\\Z18)"
					Label/Z bottom "\\Z18q\\Bxy\\M\\Z18 (A\\S-1\\M\\Z18)"					

			//		ModifyGraph height=0
					//print thiswavename
				endif
			endfor
	
	SetDataFolder root:NORI_ALS_GIWAXS
	return 0
End


#!/bin/bash
#########################################################################
# Author   	: Matteo Martelli
# Date 			: 12/01/2013
# License		: GNU v2 General Public License
# Email			: matteomartelli90@gmail.com
# License Info	: http://www.gnu.org/licenses/
#########################################################################


#First of all, check if mencoder is installed, if not ask for its installation.
if ! which mencoder >/dev/null; then
	#zenity ask
	if zenity --question --title "Mencoder not present" --text "The package mencoder is not installed.\nIt's needed for the ecoding procress.\nDo you want to install it?"
	then
		if ! gksudo 'xterm -e apt-get install -y mencoder' ; then 
			zenity --error --title "ERROR" --text "The package mencoder can't be installed. Aborting." 
			exit 1 
		elif which mencoder >/dev/null; then
			zenity --info --title "Installation complete" --text "The package mencoder has been successfully installed."
		else
			zenity --error --title "Installation error" --text " The package mencoder can't be installed.\nAsk your administrator to install it manually. Aborting."
			exit 1
		fi
	else
		zenity --error --title "ERROR" --text "The package mencoder is needed for this script. Aborting."
		exit 1
	fi
fi

#Fields init
inputsArray=()
subsArray=()
addSubs=false
newFolder=false
path="./"

#Ask at the user which options does it prefer for the encoding process.
response=`zenity --height=200 --width=400 --list --checklist --title='Selection' --column=Boxes --column=Selections --column=Text FALSE AS "Add subtitles to the video files" FALSE NF "Put converted files in a different folder" --separator=':' --hide-column=2 --text="Select your options"`

#Check what the user has selected
IFS=":" ; for word in $response ; do 
   case $word in
      AS) addSubs=true ;;
      NF) newFolder=true ;;
   esac
done

#Let the user select the video input files
inputs=`zenity --file-selection --title="Select Input Files" --multiple --filename=$PWD/ --separator=//`

#local str rest
rest=$inputs
while [ -n "$rest" ] ; do
   str=${rest%%\/\/*}  # Everything up to the first ';'
   # Trim up to the first ';' -- and handle final case, too.
   [ "$rest" = "${rest/\/\//}" ] && rest= || rest=${rest#*\/\/}
   inputsArray+=("$str");
done

#Abort if no file has been selected
if [[ ${#inputsArray[@]} == 0 ]]; then
	zenity --error --title "ERROR" --text "No input file selcted. Aborting"
	exit 1
fi

#If the user has choosen the option of subtitles, let him browse folders for subtitles
if [ $addSubs == true ]; then
	subs=`zenity --file-selection --title="Select subtitles files" --multiple --filename=$PWD/ --separator=//`
	
	if [ "$subs" == "" ]; then
		zenity --warning --title "No subtitle selcted" --text "No subtitle file selcted, thus no subtitle will be added"
		addSubs=false
	else
		#local str rest
		rest=$subs
		while [ -n "$rest" ] ; do
		   str=${rest%%\/\/*}  # Everything up to the first ';'
		   # Trim up to the first ';' -- and handle final case, too.
		   [ "$rest" = "${rest/\/\//}" ] && rest= || rest=${rest#*\/\/}
		   subsArray+=("$str");
		done

		if [[ ${#inputsArray[@]} != ${#subsArray[@]} ]]; then
			zenity --error --title "ERROR" --text "The number of input files should be the same of the number of sub files"
			exit 1
		fi
	fi
fi

#If the user want to put the output in a different folder, let the user choose it.
if [ $newFolder == true ] ; then
	path=`zenity --file-selection --directory --title="Select output destination" --filename=$PWD/`
	if [ "$path" == "" ]; then
		zenity --warning --title "No destination folder selcted" --text "No destination folder selcted, thus the converted files will be saved in the same folder of the source files"
		newFolder=false
	fi
fi
	
#For each input file selected, check again the options selected, and start the encoding process.
for (( i=0; i<${#inputsArray[@]}; i++ ))
do
		if [ $newFolder == true ] ; then
			destination="$path/"`echo "${inputsArray[$i]}" | awk -F/ '{print $NF}'`
		else
			destination="${inputsArray[$i]}"
		fi
		
		if [ $addSubs == true ] ; then
			xterm -e mencoder "${inputsArray[$i]}" -ovc xvid -xvidencopts pass=1:bitrate=3000 -oac mp3lame -sub "${subsArray[$i]}" -font "/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf" -subfont-autoscale 2 -vf scale -zoom -xy 640 -o "$destination.tv.avi"
		else
			xterm -e mencoder "${inputsArray[$i]}" -ovc xvid -xvidencopts pass=1:bitrate=3000 -oac mp3lame -vf scale -zoom -xy 640 -o "$destination.tv.avi"
		fi
done

#Remove the file log at the end of the encoding process.
fileLog="$PWD/divx2pass.log"
if [ -f "$fileLog" ] ; then
	rm "$fileLog"
fi

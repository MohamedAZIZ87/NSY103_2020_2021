#!/bin/bash

#Script Information
#Title : trifoto.sh
#Author : Mohamed AZIZ
#Date : 21/12/2020
#Description : Ce script est pour trier les Photos et Videos par le Pays et Ville ou sont pris.
#Requirements : 1 - programme "exiftool".
#				2 - programme "iconv".


IFS=$'\n'

# Il faut saisir le chemins de dossier ou se trouve les photos.#
if [ -n "$1" ];
	then
		folder=$1
		cd "$1"
		
		# Ici on va chercher tous les fichiers qui se trouve dans le dossier. #
		
		for image in ` find $folder -type f `; 

			do
				# Ici on va faire sortir le nom de ficier avec la commande "basename" puis l'extension de la fichier et la date de la craetion avec la commande "exiftool". #
				basename=$(basename "$image" | sed -e "s/ \+//g")
				type=$(exiftool "$image" | grep -w "MIME Type" | awk -F ": " '{print $2}' | awk -F '/' '{print $1}')
				date=$(exiftool "$image" | grep -w "Date*" | grep -v "GPS Date*" | awk -F ': ' '{print $2}' | cut -b1-10 | sort | head -n1| cut -b1-7 | sed -e "s/[:]/-/g")
				
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
							
							# Ici on va extraire le pays ou la photo est pris. #
							pays1=$( echo "$xmldata"|grep -o -P '(?<=country>).*(?=</country>)' | sed -e "s/[,'.]//g")
							
							# Si la photo contient "/" et plusieurs nom de pays comme le cas dans les photo qui sont pris en belgique dans ce cas la on va avoir 3 nom de pays. #
							if [[ "$pays1" =~ "/" ]]; 
								then 
									pays2=$(echo "$pays1" | awk -F ' / ' '{print $2}' | sed "s/ \+/_/g")
								else
									pays2=$(echo "$pays1" | sed "s/ \+/_/g")
								fi
							
							# Cete ligne est pour convertir les lettre accente vers des lettres normaux. #
							pays3=$(echo "$pays2" | iconv -f utf8 -t ascii//translit)

							# Si les donnees sortir apres la coversion contient "?" dans ce cas la on annule la conversion, je l'ai ajoute pour la langue arabe. #
							if [[ "$pays3" =~ "?" ]]; 
								then 
									pays="$pays2"
								else
									pays="$pays3"
							fi

							# Ici on va extraire le ville ou la photo est pris. #
							ville1=$( echo "$xmldata"| grep -o -P '(?<=municipality>).*(?=</municipality>)'\|'(?<=town>).*(?=</town>)'\|'(?<=city>).*(?=</city>)'\|'(?<=province>).*(?=</province>)' | head -n1 | sed -e "s/[,'.]//g")
							
							# Si la photo contient "/" et plusieurs nom de ville comme le cas dans les photo qui sont pris en brussels dans ce cas la on va avoir 3 nom de pays. #
							if [[ "$ville1" =~ "/" ]]; 
								then 
									ville2=$(echo "$ville1" | awk -F ' / ' '{print $2}' | sed "s/ \+/_/g")
								else
									ville2=$(echo "$ville1" | sed "s/-/_/g; s/ \+/_/g")
								fi
								
							# Cete ligne est pour convertir les lettre accente vers des lettres normaux. #
							ville3=$(echo "$ville2" | iconv -f utf8 -t ascii//translit)
					
							# Si les donnees sortir apres la coversion contient "?" dans ce cas la on annule la conversion, je l'ai ajoute pour la langue arabe. #
							if [[ "$ville3" =~ "?" ]]; 
								then 
									ville="$ville2"
								else
									ville="$ville3"
							fi
							
							# On va Checker si le dossier "$pays/$ville/$type/$date" existe sinon on va le creer. #
							if [ -d "$pays/$ville/$type/$date" ]; 
								then 
									: 
								else 
									mkdir -p "$pays/$ville/$type/$date"
							fi
							
							# Deplacer les images dans le dossier "$pays/$ville/$type/$date/" .#
							mv -v "$image" "$pays/$ville/$type/$date/$basename" 2>>trifoto.log
								
			
						else
						
							# Si on ne trouve pas les donnees gps on deplace les photo dans le dossier "No_GPS/$type/$date/$basename". #
							if [ -d "No_GPS/$type/$date" ]; 
									then 
										mv -v "$image" "No_GPS/$type/$date/$basename" 2>>trifoto.log
												
									else 
										mkdir -p "No_GPS/$type/$date"
										mv -v "$image" "No_GPS/$type/$date/$basename" 2>>trifoto.log

								fi
	
					fi

			done


	else
		 echo -e "Warning : Il faut ajouter le chemin de votre dossier qui contient les photos a renommer \nExample : ./Nom de Script.sh /home/user/photo"
fi

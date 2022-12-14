#!/bin/bash
## Usage: build.sh
##
## This scripts extracts flutter projects from zip files then builds their apks.
##
##  It expects zip files named in the format:
##      <netid>Project<number>.zip      Eg: ykurku2Project2.zip
##
##  For each zip file this script will extract the flutter project inside it into:
##      ./apks/<netid>Project<number>/<project_name>/       Eg: ./apks/ykurku2Project2/movie_list/
##
##      The pubspec.yaml file path would be: ./apks/ykurku2Project2/movie_list/pubspec.yaml
##
##  Once the project is built, it path would be:
##      ./apks/<netid>Project<number>/<netid>Project<number>.apk        Eg: ./apks/ykurku2Project2/ykurku2Project2.apk
##
##
## Options:
## <None>


# Project Name
project_name="Project2"

# Temp Directory to extract all files
TEMP_DIR="temp"

# Directory for final result (result directory)
EXTRACT_DIR="apks"

# Directory in which this script is located
SCRIPT_DIR=("$(pwd)")

# Number of projects that pass building the apk
NUM_BUILD_PASS=0

# Number of projects that fail building the apk
NUM_BUILD_FAIL=0

# List of project that failed building the apk
PROJECT_BUILD_FAIL=()

# Remove any old directories generated by this script
rm -rf $EXTRACT_DIR
rm -rf $TEMP_DIR

# Create new ones
mkdir $EXTRACT_DIR
mkdir $TEMP_DIR



echo "----BUILD APKS----"
while read project
do
		# Raw extracted project int temp directory
		PROJECT_DIR_TEMP="$TEMP_DIR/$project/"
		
		# Result after extracting the project root
		PROJECT_DIR="$EXTRACT_DIR/$project/"
		
		# Create the target dirs for extracting the project
		mkdir $PROJECT_DIR_TEMP
		mkdir $PROJECT_DIR
		
        # Unzip the project file into the temp directory
		echo "Unzip: ${project}.zip"
		unzip -q $project.zip -d $PROJECT_DIR_TEMP
		
		# Get the path to the project root by finding the pubspec.yaml file
		PROJECT_ROOT_PATH=("$(find $PROJECT_DIR_TEMP -name pubspec.yaml | sed -e "s/pubspec.yaml//g")")
		
        # Extract the project to the result directory
		mv $PROJECT_ROOT_PATH $PROJECT_DIR
		
        # Get the new project root path
		PROJECT_ROOT_PATH=("$(find $PROJECT_DIR -name pubspec.yaml | sed -e "s/pubspec.yaml//g")")
		
		# Change the name of the application to student's netid in the Android Manifest file
		netid="$(cut -d 'P' -f 1 <<< "$project")"
        echo "NetId: ${netid}"
		ANDROID_MANIFEST_FILE="${PROJECT_ROOT_PATH}android/app/src/main/AndroidManifest.xml"
		temp="$(sed '/android:label/{s/android:label=\".*\"/android:label=\"'"$netid"'\"/}' $ANDROID_MANIFEST_FILE)"
		echo "${temp}" > $ANDROID_MANIFEST_FILE

        # TODO: Change the android package name
		
        # clean, pub get and build the project using flutter
		cd $PROJECT_ROOT_PATH
		echo "Flutter in: ${PROJECT_ROOT_PATH}"
		echo "clean..."
		flutter clean >> /dev/null 2>&1 #Discard stdout and stderr
		echo "pub get..."
		flutter pub get >> /dev/null 2>&1 #Discard stdout and stderr
		echo "build apk..."
		flutter build apk --debug --no-sound-null-safety >> /dev/null 2>&1 #Discard stdout and stderr
		
		cd $SCRIPT_DIR
		
		# Move the built apk outside the root
		APK="${SCRIPT_DIR}/${PROJECT_ROOT_PATH}build/app/outputs/apk/debug/app-debug.apk"
		TARGET_APK="${SCRIPT_DIR}/${EXTRACT_DIR}/${project}/${project}.apk"
		mv $APK $TARGET_APK
		
		if test -f "$TARGET_APK"
		then
			echo "Flutter Build: Success"
			NUM_BUILD_PASS=$((NUM_BUILD_PASS+1))
		else
			echo "Flutter Build: Failed"
			NUM_BUILD_FAIL=$((NUM_BUILD_FAIL+1))
			PROJECT_BUILD_FAIL+=($PROJECT_ROOT_PATH)
		fi
		
		# Done building current project
		echo ""
		
done < <(ls *.zip|awk -F '.' '{print $1;}') # read from the list of all *.zip files

# Delete the temp directory
rm -r $TEMP_DIR

echo "Successfully built ${NUM_BUILD_PASS} projects."
echo "Failed to build ${NUM_BUILD_FAIL} projects."
for i in $PROJECT_BUILD_FAIL;
do
	echo "FAILED: ${i}"
done
echo "----FINISHED BUILDING APKS----"

# TODO: Introduce flag to enable installation
#echo "----INSTALL APKS----"
#find . -name *.apk |
#awk -F '/' '{if(NF==4) print $0}' |
#while read apk 
#do 
#	adb install $(echo "${apk}")
#done

#find . -name *.apk | awk -F '/' '{if(NF==4) print $0}' | while read apk; do adb install $(echo "${apk}"); done

#echo "----FINISHED INSTALLING APKS----"



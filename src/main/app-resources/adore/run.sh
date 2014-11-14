#!/bin/bash
 
# source the ciop functions (e.g. ciop-log)
source ${ciop_job_include}

# define the exit codes
SUCCESS=0
ERR_CURL=1
ERR_ADORE=2
ERR_PUBLISH=3

# add a trap to exit gracefully
function cleanExit ()
{
	local retval=$?
	local msg=""
	
	case "$retval" in
		$SUCCESS) msg="Processing successfully concluded";;
		$ERR_CURL) msg="Failed to retrieve the products";;
		$ERR_ADORE) msg="Failed during ADORE execution";;
		$ERR_PUBLISH) msg="Failed results publish";;
		*) msg="Unknown error";;
	esac

	[ "$retval" != "0" ] && ciop-log "ERROR" "Error $retval - $msg, processing aborted" || ciop-log "INFO" "$msg"
	exit $retval
}
trap cleanExit EXIT

# path and master/slave variable definition
UUID=`uuidgen`
#UUIDTMP="${TMPDIR}/`uuidgen`"
UUIDTMP="/tmp/fabio/${UUID}"
MASTER="`ciop-getparam adore_master`"
PROJECT="`ciop-getparam adore_project`"
SHORTPATH=/tmp/${UUID}

# creates the adore directory structure
ciop-log "INFO" "creating the directory structure"
mkdir -p ${UUIDTMP}
ln -s ${UUIDTMP} ${SHORTPATH}
mkdir ${UUIDTMP}/data
mkdir ${UUIDTMP}/data/master
mkdir ${UUIDTMP}/data/slave

ciop-log "INFO" "basedir is ${UUIDTMP} ${SHORTPATH}"

# copies the ODR files
ciop-log "INFO" "copying the ODR files"
cd ${UUIDTMP}/
tar xvfz /application/adore/files/ODR.tgz

# retrieves the files
ciop-log "INFO" "retrieving master [$MASTER]"
cd ${UUIDTMP}/data/

#test mode
if [ ! -e "/var/lib/hadoop-0.20/`basename ${MASTER}`" ]
then
	ciop-log "INFO" "downloading master [${MASTER}]"
	#ciop-copy -O ${UUIDTMP}/data/master ${MASTER}
	cd /var/lib/hadoop-0.20/
	curl -O ${MASTER} 2> /dev/null
	cd -
	#ciop-copy -O ${UUIDTMP}/data/master ${MASTER}
fi

cd ${UUIDTMP}/data/master/
unzip /var/lib/hadoop-0.20/`basename ${MASTER}`
cd -

res=$?

while read input
do
	ciop-log "INFO" "retrieving slave [$input]"
	#ciop-copy -O ${UUIDTMP}/data/slave ${input}
	if [ ! -e "/var/lib/hadoop-0.20/`basename ${input}`" ]
	then
		ciop-log "INFO" "downloading file"
		cd /var/lib/hadoop-0.20/
		curl -O $input
		cp `basename $input`  ${UUIDTMP}/data/slave/
		cd -
	fi

	cd ${UUIDTMP}/data/slave/
	unzip /var/lib/hadoop-0.20/`basename ${input}`
	cd -

	res=$(( $res + $? ))
done

if [ $res -ne 0 ]; then exit $ERR_CURL; fi

# setting the adore settings.set file
cat /application/adore/files/settings.set.template | sed "s|#BASEDIR#|${SHORTPATH}|g" | sed "s|#PROJECT#|${PROJECT}|g" > ${UUIDTMP}/settings.set

# ready to lauch adore
cd ${UUIDTMP}
export ADORESCR=/opt/adore/scr; export PATH=${PATH}:${ADORESCR}:/usr/local/bin
adore -u settings.set "m_readfiles; settings apply -r m_orbdir=${SHORTPATH}}/ODR; m_porbits; s_readfiles; s_porbits; m_crop; s_crop; coarseorb; dem make SRTM3 50 LAquila; s raster_format; settings apply -r raster_format=png; raster a m_crop -- -M1/5; raster a s_crop -- -M1/5; m_simamp; m_timing; coarsecorr; fine; reltiming; demassist; coregpm; resample; interfero; comprefpha; subtrrefpha; comprefdem; subtrrefdem; coherence; raster p subtrrefdem -- -M4/4; raster p subtrrefpha -- -M4/4; raster p interfero -- -M4/4; raster p coherence -- -M4/4 -cgray -b"

ciop-publish -m ${UUIDTMP}/*.png

#rm -rf ${UUIDTMP}

ciop-log "INFO" "That's all folks"

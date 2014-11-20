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
UUIDTMP="/tmp/${UUID}"

MASTER="`ciop-getparam adore_master`"
PROJECT="`ciop-getparam adore_project`"

# creates the adore directory structure
ciop-log "INFO" "creating the directory structure"

mkdir -p ${UUIDTMP}
# this is needed for the getorb (a too long path makes the binary segfail)
mkdir ${UUIDTMP}/data
mkdir ${UUIDTMP}/data/master
mkdir ${UUIDTMP}/data/slave

ciop-log "INFO" "basedir is ${UUIDTMP} ${SHORTPATH}"

# copies the ODR files
ciop-log "INFO" "copying the ODR files"
#cd ${UUIDTMP}/
tar -C ${UUIDTMP} -xvfz /application/adore/files/ODR.tgz

# retrieves the files
ciop-log "INFO" "retrieving master [$MASTER]"
cd ${UUIDTMP}/data/

# copies the master (with debug mode check for a local file)
if [ ! -e "/var/lib/hadoop-0.20/`basename ${MASTER}`" ]
then
	ciop-log "INFO" "downloading master [${MASTER}]"
	ciop-copy -O ${UUIDTMP}/data/master ${MASTER}
else
	ciop-log "INFO" "found debug file, copying from local then"
	cd ${UUIDTMP}/data/master
	unzip "/var/lib/hadoop-0.20/`basename ${MASTER}`"
	cd -
fi

res=$?

#retrieving the slave
slave="`cat`"

# check cardinality
[ "`echo "$slave" | wc -l`" != "1" ] && exit $ERR_CARDINALITY 

ciop-copy -O ${UUIDTMP}/data/slave ${slave}

# setting the adore settings.set file
cat > ${UUIDTMP}/settings.set << EOF
projectFolder="${UUIDTMP}"
runName="${PROJECT}"
slave="slave"
scenes_include=( master slave )
dataFile="ASA_*.N1"
m_in_method="ASAR"
m_in_vol="dummy"
m_in_lea="dummy"
m_in_null="dummy"
s_in_vol="dummy"
s_in_lea="dummy"
s_in_null="dummy"
EOF 

# ready to lauch adore
cd ${UUIDTMP}
export ADORESCR=/opt/adore/scr; export PATH=${PATH}:${ADORESCR}:/usr/local/bin
adore -u settings.set "m_readfiles; settings apply -r m_orbdir=${UUIDTMP}/ODR; m_porbits; s_readfiles; s_porbits; m_crop; s_crop; coarseorb; dem make SRTM3 50 LAquila; s raster_format; settings apply -r raster_format=png; raster a m_crop -- -M1/5; raster a s_crop -- -M1/5; m_simamp; m_timing; coarsecorr; fine; reltiming; demassist; coregpm; resample; interfero; comprefpha; subtrrefpha; comprefdem; subtrrefdem; coherence; raster p subtrrefdem -- -M4/4; raster p subtrrefpha -- -M4/4; raster p interfero -- -M4/4; raster p coherence -- -M4/4 -cgray -b"

ciop-publish -m ${UUIDTMP}/*.*

rm -rf ${UUIDTMP}

ciop-log "INFO" "That's all folks"

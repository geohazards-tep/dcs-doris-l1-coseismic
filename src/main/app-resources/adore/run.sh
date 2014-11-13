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
UUIDTMP="${TMPDIR}/`uuidgen`"
MASTER="`ciop-getparam adore_master`"
SLAVE="`ciop-getparam adore_slave`"

# creates the adore directory structure
ciop-log "INFO" "creating the directory structure"
mkdir ${UUIDTMP}/data/
mkdir ${UUIDTMP}/data/master
mkdir ${UUIDTMP}/data/slave

# copies the ODR files
ciop-log "INFO" "copying the ODR files"
cd ${UUIDTMP}/
tar xvfz /application/adore/files/ODR.tgz

# retrieves the files
ciop-log "INFO" "retrieving master and slave"
cd ${UUIDTMP}/data/
ciop-copy -O ${UUIDTMP}/master ${MASTER}
res=$?
ciop-copy -O ${UUIDTMP}/slave ${SLAVE}
res=$(( $res + $? ))

if [ $res -ne 0 ]; then exit $ERR_CURL; fi

# setting the adore settings.set file
cat /application/adore/files/settings.set.template | sed "s|#BASEDIR#|${UUIDTMP}|g" > ${UUIDTMP}/settings.set

# ready to lauch adore
cd ${UUIDTMP}
adore -u settings.set "m_readfiles; settings apply -r m_orbdir=${UUIDTMP}/ODR; m_porbits; s_readfiles; s_porbits; m_crop; s_crop; coarseorb; dem make SRTM3 50 LAquila; s raster_format; settings apply -r raster_format=png; raster a m_crop -- -M1/5; raster a s_crop -- -M1/5; m_simamp; m_timing; coarsecorr; fine; reltiming; demassist; coregpm; resample; interfero; comprefpha; subtrrefpha; comprefdem; subtrrefdem; coherence; raster p subtrrefdem -- -M4/4; raster p subtrrefpha -- -M4/4; raster p interfero -- -M4/4; raster p coherence -- -M4/4 -cgray -b"

ciop-publish -m ${UUIDTMP}/*

rm -rf ${UUIDTMP}

ciop-log "INFO" "That's all folks"

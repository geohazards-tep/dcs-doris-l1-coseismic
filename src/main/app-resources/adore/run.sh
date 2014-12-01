#!/bin/bash
 
# source the ciop functions (e.g. ciop-log)
source ${ciop_job_include}

# define the exit codes
SUCCESS=0
ERR_CURL=1
ERR_ADORE=2
ERR_PUBLISH=3
ERR_WRONGPROD=4

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
		$ERR_WRONGPROD) msg="Wrong product provided as input. Please use ASA_IMS_1P";;
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
mkdir ${UUIDTMP}/data
mkdir ${UUIDTMP}/data/master

ciop-log "INFO" "basedir is ${UUIDTMP}"

# copies the ODR files
[ ! -e /tmp/ODR ] && {
	ciop-log "INFO" "copying the ODR files"
	tar xvfz /application/adore/files/ODR.tgz -C /tmp &> /dev/null
}

# retrieves the files
ciop-log "INFO" "retrieving master [$MASTER]"
cd ${UUIDTMP}/data/

# copies the master
ciop-log "INFO" "downloading master [${MASTER}]"
MASTER=`ciop-copy -f -O ${UUIDTMP}/data/master ${MASTER}`
res=$?
[ $res -ne 0 ] && exit $ERR_CURL

# let's check if the correct product was provided
[ "`head -10 ${MASTER} | grep "^PRODUCT" | tr -d '"' | cut -d "=" -f 2 | cut -c 1-10`" != "ASA_IMS_1P" ] && exit $ERR_WRONGPROD

#retrieving the slave
SLAVE="`cat`"

# check cardinality
[ "`echo "${SLAVE}" | wc -l`" != "1" ] && exit $ERR_CARDINALITY 

ciop-log "INFO" "retrieving slave [${SLAVE}]"
SLAVE=`ciop-copy -f -O /tmp/ ${SLAVE}`
res=$?
[ $res -ne 0 ] && exit $ERR_CURL

# let's check if the correct product was provided
[ "`head -10 ${SLAVE} | grep "^PRODUCT" | tr -d '"' | cut -d "=" -f 2 | cut -c 1-10`" != "ASA_IMS_1P" ] && exit $ERR_WRONGPROD

SLAVE_ID=`head -10 ${SLAVE} | grep "^PRODUCT" | tr -d '"' | cut -d "=" -f 2 | cut -c 15-22`

#we can now create the slave dir and move the file to the right place
mkdir ${UUIDTMP}/data/${SLAVE_ID}

mv ${SLAVE} ${UUIDTMP}/data/${SLAVE_ID}/
SLAVE=${UUIDTMP}/data/${SLAVE_ID}/`basename ${SLAVE}`

# setting the adore settings.set file
cat > ${UUIDTMP}/settings.set <<EOF
projectFolder="${UUIDTMP}"
runName="${PROJECT}"
master="master"
slave="${SLAVE_ID}"
scenes_include=( master ${SLAVE_ID} )
dataFile="ASA_*.N1"
m_in_dat="${MASTER}"
s_in_dat="${SLAVE}"
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
adore -u settings.set "m_readfiles; s_readfiles; settings apply -r m_orbdir=/tmp/ODR; m_porbits; s_porbits; m_crop; s_crop; coarseorb; dem make SRTM3 50 LAquila; settings apply -r raster_format=png; raster a m_crop -- -M1/5; raster a s_crop -- -M1/5; m_simamp; m_timing; coarsecorr; fine; reltiming; demassist; coregpm; resample; interfero; comprefpha; subtrrefpha; comprefdem; subtrrefdem; coherence; unwrap; slant2h; geocode; raster p subtrrefdem -- -M4/4; raster p subtrrefpha -- -M4/4; raster p interfero -- -M4/4; raster p coherence -- -M4/4 -cgray -b; saveas gdal p subtrrefdem -of GTiff master_${SLAVE_ID}_srd.tiff; saveas gdal p subtrrefpha -of GTiff master_${SLAVE_ID}_srp.tiff; saveas gdal p interfero -of GTiff master_${SLAVE_ID}_cint.tiff; saveas gdal p coherence -of GTiff master_${SLAVE_ID}_coh.tiff" &> /dev/stdout

# removes unneeded files
cd ${UUIDTMP}
rm -rf *.res *.hgt *.drs *.temp *.ps *.DEM
ciop-publish -m ${UUIDTMP}/*.*

rm -rf ${UUIDTMP}

ciop-log "INFO" "That's all folks"

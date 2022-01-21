#!/bin/csh
#
# DART software - Copyright UCAR. This open source software is provided
# by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
# DART $Id$
#
# This script performs an assimilation by directly reading and writing to
# the CLM restart file. There is no post-processing step 'dart_to_clm',
# consequently, snow DA is not supported in this framework.

#=========================================================================
# This block is an attempt to localize all the machine-specific
# changes to this script such that the same script can be used
# on multiple platforms. This will help us maintain the script.
#=========================================================================

echo "`date` -- BEGIN CLM_ASSIMILATE"

# As of CESM2.0, the assimilate.csh is called by CESM - and has
# two arguments: the CASEROOT and the DATA_ASSIMILATION_CYCLE

setenv CASEROOT $1
setenv ASSIMILATION_CYCLE $2

# source ${CASEROOT}/DART_params.csh || exit 1

# Python uses C indexing on loops; cycle = [0,....,$DATA_ASSIMILATION_CYCLES - 1]
# "Fix" that here, so the rest of the script isn't confusing.
@ cycle = $ASSIMILATION_CYCLE + 1

# xmlquery must be executed in $CASEROOT.
cd ${CASEROOT}
setenv CASE           `./xmlquery CASE        --value`
setenv ENSEMBLE_SIZE  `./xmlquery NINST_LND   --value`
setenv EXEROOT        `./xmlquery EXEROOT     --value`
setenv RUNDIR         `./xmlquery RUNDIR      --value`
setenv ARCHIVE        `./xmlquery DOUT_S_ROOT --value`
setenv TOTALPES       `./xmlquery TOTALPES    --value`
setenv STOP_N         `./xmlquery STOP_N      --value`
setenv DATA_ASSIMILATION_CYCLES `./xmlquery DATA_ASSIMILATION_CYCLES --value`

# Raczka edit
setenv TASKS_PER_NODE `./xmlquery MAX_TASKS_PER_NODE --value`

# This may be determined from CASEROOT  ./preview_run  
# Raczka edit for kingspeak, taking out MPI_RUN_COMMAND ? 
# setenv MPI_RUN_COMMAND "mpiexec_mpt -np $TOTALPES omplace -tm open64"

setenv MPI_RUN_COMMAND "mpiexec -n $TOTALPES"


cd ${RUNDIR}

# Raczka -Setting baseobsdir
set BASEOBSDIR = /uufs/chpc.utah.edu/common/home/lin-group3/braczka/obstodart/products

# Raczka Added manually

switch ("`hostname`")
   case ys*:
      # NCAR "yellowstone"
      set   MOVE = 'mv -fv'
      set   COPY = 'cp -fv --preserve=timestamps'
      set   LINK = 'ln -fvs'
      set REMOVE = 'rm -fr'
      setenv MP_DEBUG_NOTIMEOUT yes

      set  LAUNCHCMD = mpirun.lsf
   breaksw

   case lone*:
      # UT lonestar
      set   MOVE = '/bin/mv -fv'
      set   COPY = '/bin/cp -fv --preserve=timestamps'
      set   LINK = '/bin/ln -fvs'
      set REMOVE = '/bin/rm -fr'

      set  LAUNCHCMD = mpirun.lsf
   breaksw

   case la*:
      # LBNL "lawrencium"
      set   MOVE = 'mv -fv'
      set   COPY = 'cp -fv --preserve=timestamps'
      set   LINK = 'ln -fvs'
      set REMOVE = 'rm -fr'

      set  LAUNCHCMD = "mpiexec -n $NTASKS"
   breaksw

   case r*:
      # NCAR "cheyenne"
      set   MOVE = 'mv -fv'
      set   COPY = 'cp -fv --preserve=timestamps'
      set   LINK = 'ln -fvs'
      set REMOVE = 'rm -fr'
      setenv MP_DEBUG_NOTIMEOUT yes
      set  LAUNCHCMD = mpiexec_mpt
   breaksw

   case example*:
      set   MOVE = 'mv -fv'
      set   COPY = 'cp -fv --preserve=timestamps'
      set   LINK = 'ln -fvs'
      set REMOVE = 'rm -fr'
      set LAUNCHCMD = "aprun -n $NTASKS"
   breaksw

#HFD kingspeak
   case kp*:
      set   MOVE = 'mv -fv'
      set   COPY = 'cp -fv --preserve=timestamps'
      set   LINK = 'ln -fvs'
      set REMOVE = 'rm -fr'
      set LAUNCHCMD = "mpiexec -n ${TOTALPES}"
   breaksw

   default:
      echo "FATAL ERROR: The system-specific environment must be specified."   
      echo "             Add system-specific info to a case statement in"   
      echo "             ${CASEROOT}/assimilate.csh"   
      exit 1
   breaksw
endsw


#=========================================================================
# Block 1: Determine time of model state ... from file name of first member
# of the form "./${CASE}.clm2_${ensemble_member}.r.2000-01-06-00000.nc"
#
# Piping stuff through 'bc' strips off any preceeding zeros.
#=========================================================================

set FILE = `head -n 1 rpointer.lnd_0001`
set FILE = $FILE:r
set LND_DATE_EXT = `echo $FILE:e`
set LND_DATE     = `echo $FILE:e | sed -e "s#-# #g"`
set LND_YEAR     = `echo $LND_DATE[1] | bc`
set LND_MONTH    = `echo $LND_DATE[2] | bc`
set LND_DAY      = `echo $LND_DATE[3] | bc`
set LND_SECONDS  = `echo $LND_DATE[4] | bc`
set LND_HOUR     = `echo $LND_DATE[4] / 3600 | bc`

echo "valid time of model is $LND_YEAR $LND_MONTH $LND_DAY $LND_SECONDS (seconds)"
echo "valid time of model is $LND_YEAR $LND_MONTH $LND_DAY $LND_HOUR (hours)"

#=========================================================================
# Block 2: Get observation sequence file ... or die right away.
#=========================================================================

# The observation file names have a time that matches the stopping time of CLM.
#
# The CLM observations are stored in two sets of directories.
# If you are stopping every 24 hours or more, the obs are in directories like YYYYMM.
# In all other situations the observations come from directories like YYYYMM_6H.
# The only ugly part here is if the first advance and subsequent advances are
# not the same length. The observations _may_ come from different directories.
#
# The contents of the file must match the history file contents if one is using
# the obs_def_tower_mod or could be the 'traditional' +/- 12Z ... or both.
# Since the history file contains the previous days' history ... so must the obs file.

if ($STOP_N >= 24) then
   set OBSDIR = `printf %04d%02d    ${LND_YEAR} ${LND_MONTH}`
else
   set OBSDIR = `printf %04d%02d_6H ${LND_YEAR} ${LND_MONTH}`
endif

# Raczka edits
set datehfd = `printf %04d_%02d_%02d_00_00_00 ${LND_YEAR} ${LND_MONTH} ${LND_DAY}` #Must match obs_seq
set OBS_FILE = ${BASEOBSDIR}/AGB_LAI_gridinterp_wusa2_${datehfd}.obsseq

${REMOVE} obs_seq.out

if (  -e   ${OBS_FILE} ) then
   ${LINK} ${OBS_FILE} obs_seq.out || exit 2
else
   echo "ERROR ... no observation file $OBS_FILE"
   echo "ERROR ... no observation file $OBS_FILE"
   exit 2
endif

#=========================================================================
# Block 3: Populate a run-time directory with the input needed to run DART.
#=========================================================================

echo "`date` -- BEGIN COPY BLOCK"

if (  -e   ${CASEROOT}/input.nml ) then
   ${COPY} ${CASEROOT}/input.nml .
else
   echo "ERROR ... DART required file ${CASEROOT}/input.nml not found ... ERROR"
   echo "ERROR ... DART required file ${CASEROOT}/input.nml not found ... ERROR"
   exit 3
endif

echo "`date` -- END COPY BLOCK"

# Raczka -- Round robin approach to deal out task now removed


#=========================================================================
# Block 4: DART INFLATION
# IF we are doing inflation, we must take the output inflation files from
# the previous cycle and rename them for input to the current cycle.
# The inflation values change through time and should be archived.
#
# If we need to run fill_inflation_restart,
# we need the links to the input files. So this has to come pretty early.
#==========================================================================



set     LND_RESTART_FILENAME = ${CASE}.clm2_0001.r.${LND_DATE_EXT}.nc
set     LND_HISTORY_FILENAME = ${CASE}.clm2_0001.h0.${LND_DATE_EXT}.nc
set LND_VEC_HISTORY_FILENAME = ${CASE}.clm2_0001.h2.${LND_DATE_EXT}.nc

# remove any potentially pre-existing linked files
${REMOVE} clm_restart.nc clm_history.nc clm_vector_history.nc 

${LINK} ${LND_RESTART_FILENAME} clm_restart.nc || exit 4
${LINK} ${LND_HISTORY_FILENAME} clm_history.nc || exit 4
if (  -s   ${LND_VEC_HISTORY_FILENAME} ) then
   ${LINK} ${LND_VEC_HISTORY_FILENAME} clm_vector_history.nc || exit 4
endif

# Raczka:  Taking out this section because fill_inflation_restart
# executable causes problems, and I don't think I need it other than
# for first assimilation step -- but I will turn off variable inflation
# for first time step anyway

# fill_inflation_restart creates files for all the domains in play,
# with names like input_priorinf_[mean,sd]_d0?.nc These should be renamed
# to be similar to what is created during the cycling. fill_inflation_restart
# only takes a second and only runs once.

# Raczka take out
#if ( -e clm_inflation_cookie ) then

#   ${EXEROOT}/fill_inflation_restart || exit  4

#   foreach FILE ( input_priorinf_*.nc )
#      set NEWBASE = `echo $FILE:r | sed -e "s#input#output#"`
#      ${MOVE} ${FILE} clm_${NEWBASE}.1601-01-01-00000.nc
#   end

#   # Make sure this only happens once. Eat the cookie. 
#   ${REMOVE} clm_inflation_cookie

#endif

# Raczka take out

# We have to potentially deal with files like:
# output_priorinf_mean_d01.${LND_DATE_EXT}.nc
# output_priorinf_mean_d02.${LND_DATE_EXT}.nc
# output_priorinf_mean_d03.${LND_DATE_EXT}.nc
# output_priorinf_sd_d01.${LND_DATE_EXT}.nc
# output_priorinf_sd_d02.${LND_DATE_EXT}.nc
# output_priorinf_sd_d03.${LND_DATE_EXT}.nc
# I am not going to worry about posterior inflation files.

# If the file exists, just link to the new expected name.
# the expected names have a _d0? inserted before the file extension
# if there are multiple domains.
# If the file does not exist, filter will die and issue a very explicit
# death message.

${REMOVE} input_priorinf_mean*.nc input_priorinf_sd*.nc

# As the run directory gets cluttered, the 'ls' command may take a significant
# amount of time. Should employ a pointer file strategy to always point to the
# inflation files from the last assimilation cycle. FIXME

foreach DOMAIN ( '' _d01 _d02 _d03 )

   # Checking for a prior inflation mean file from the previous assimilation.

   (ls -rt1 clm_output_priorinf_mean${DOMAIN}.* | tail -n 1 >! latestfile) > & /dev/null
   set nfiles = `cat latestfile | wc -l`

   if ( $nfiles > 0 ) then
      set latest = `cat latestfile`
      ${LINK} ${latest} input_priorinf_mean${DOMAIN}.nc
      # Create the expected output file (needed for NO_COPY_BACK variables)
      ${COPY} ${latest} output_priorinf_mean${DOMAIN}.nc
   endif

   # Checking for a prior inflation sd file from the previous assimilation.

   (ls -rt1 clm_output_priorinf_sd${DOMAIN}.* | tail -n 1 >! latestfile) > & /dev/null
   set nfiles = `cat latestfile | wc -l`

   if ( $nfiles > 0 ) then
      set latest = `cat latestfile`
      ${LINK} ${latest} input_priorinf_sd${DOMAIN}.nc
      # Create the expected output file (needed for NO_COPY_BACK variables)
      ${COPY} ${latest} output_priorinf_sd${DOMAIN}.nc
   endif

end

#=========================================================================
# Block 5: REQUIRED DART namelist settings
#
# "restart_files.txt" is mandatory. 
# "history_files.txt" and "history_vector_files.txt" are only needed if
# variables from these files are specified as part of the desired DART state.
# It is an error to specify them if they are not required.
#
# model_nml "clm_restart_filename" and "clm_history_filename" are mandatory
# and are used to determine the domain metadata and *shape* of the variables.
# "clm_vector_history_filename" is used to determine the shape of the 
# variables required to be read from the vector history file. If there are no
# vector-based history variables, 'clm_vector_history_filename' is not used.
#
# &filter_nml  
#     async                   = 0,
#     obs_sequence_in_name    = 'obs_seq.out'
#     obs_sequence_out_name   = 'obs_seq.final'
#     init_time_days          = -1,
#     init_time_seconds       = -1,
#     first_obs_days          = -1,
#     first_obs_seconds       = -1,
#     last_obs_days           = -1,
#     last_obs_seconds        = -1,
#     input_state_file_list   = "restart_files.txt",
#                               "history_files.txt",
#                               "history_vector_files.txt"
#     output_state_file_list  = "restart_files.txt",
#                               "history_files.txt",
#                               "history_vector_files.txt"
# &model_nml
#     clm_restart_filename        = 'clm_restart.nc'
#     clm_history_filename        = 'clm_history.nc'
#     clm_vector_history_filename = 'clm_vector_history.nc'
# &ensemble_manager_nml
#     single_restart_file_in  = .false.
#     single_restart_file_out = .false.
#=========================================================================
# clm always needs a clm_restart.nc, clm_history.nc for geometry information, etc.
# it may or may not need a vector-format history file - depends on user input

${REMOVE} restart_files.txt history_files.txt history_vector_files.txt

# Raczka dealing with monthly history files that have different naming convention
set LND_YEAR2 = `echo $LND_YEAR | bc`
set LND_MONTH2     = `echo $LND_MONTH - 1 | bc`
if ($LND_MONTH2 == 0) then
   set LND_YEAR2     = `echo $LND_YEAR - 1 | bc`
   set LND_MONTH2     = `echo 12 | bc`
endif

set LND_YEAR2 = `printf %04d ${LND_YEAR2}`
set LND_MONTH2 = `printf %02d ${LND_MONTH2}`

set ensmembernum = 1
while ($ensmembernum <= $ENSEMBLE_SIZE)
   set ensmembernum2 = `printf %04d ${ensmembernum}`
   ${LINK} ${CASE}.clm2_${ensmembernum2}.h0.${LND_YEAR2}-${LND_MONTH2}.nc ${CASE}.clm2_${ensmembernum2}.h0.${LND_DATE_EXT}.nc
   ${LINK} ${CASE}.clm2_${ensmembernum2}.h1.${LND_YEAR2}-${LND_MONTH2}.nc ${CASE}.clm2_${ensmembernum2}.h1.${LND_DATE_EXT}.nc
   ${LINK} ${CASE}.clm2_${ensmembernum2}.h2.${LND_YEAR2}-${LND_MONTH2}.nc ${CASE}.clm2_${ensmembernum2}.h2.${LND_DATE_EXT}.nc
   @ ensmembernum++
end
#------------------------------------------------------------------------------


ls -1 ${CASE}.clm2_*.r.${LND_DATE_EXT}.nc  >! restart_files.txt
ls -1 ${CASE}.clm2_*.h0.${LND_DATE_EXT}.nc >! history_files.txt
ls -1 ${CASE}.clm2_*.h2.${LND_DATE_EXT}.nc >! history_vector_files.txt

# This next block of 'ncatted' commands could be used to add appropriate
# variable attributes for early versions of CLM. The history files
# generally had the attributes, but the restart files did not.
# This is perhaps extra, and is certainly a serial step in a job
# that may take many hundreds (if not thousands) of processors.
# You should test with and without this logic to determine if the
# extra computational cost is warranted. If the restart variables
# already have these attributes, this code is certainly not needed.
# This logic should be applied to any variable you intend to include
# in the DART state.

#foreach FILE ( ${CASE}.clm2_*.r.${LND_DATE_EXT}.nc )
#
#   ncatted -O -a missing_value,H2OSOI_LIQ,o,d,1.0e36 $FILE
#   ncatted -O -a    _FillValue,H2OSOI_LIQ,o,d,1.0e36 $FILE
#
#   ncatted -O -a missing_value,H2OSOI_ICE,o,d,1.0e36 $FILE
#   ncatted -O -a    _FillValue,H2OSOI_ICE,o,d,1.0e36 $FILE
#
#   ncatted -O -a missing_value,H2OSNO,o,d,1.0e36 $FILE
#   ncatted -O -a    _FillValue,H2OSNO,o,d,1.0e36 $FILE
#
#end


## Raczka

## Older version has search and replace commands here.  But only because
## &filter_nml defined output_state_file list as restart_files_out.txt, history_files_out.txt

#if ( -e restart_files.txt ) then
#   sed -e "s#${LND_DATE_EXT}#${LND_DATE_EXT}.out#" restart_files.txt >! #restart_output_files.txt
#endif
#if ( -e history_files.txt ) then
#   sed -e "s#${LND_DATE_EXT}#${LND_DATE_EXT}.out#" history_files.txt >! #history_output_files.txt
#endif
#if ( -e history_vector_files.txt ) then
#   sed -e "s#${LND_DATE_EXT}#${LND_DATE_EXT}.out#" history_vector_files.txt >! #history_vector_output_files.txt
#endif


#=========================================================================
# Block 6: Actually run the assimilation.
#=========================================================================

echo "`date` -- BEGIN FILTER"
${MPI_RUN_COMMAND} ${EXEROOT}/filter || exit 6
echo "`date` -- END FILTER"

# FIXME: for multiple cycles this might rename the files over and over if
# FIXME: the short-term archiver is not on.

# Tag the output with the valid time of the model state.
# TODO could move each ensemble-member file to the respective member dir.

foreach FILE ( input*mean*nc      input*sd*nc     input_member*nc \
            forecast*mean*nc   forecast*sd*nc  forecast_member*nc \
            preassim*mean*nc   preassim*sd*nc  preassim_member*nc \
           postassim*mean*nc  postassim*sd*nc postassim_member*nc \
            analysis*mean*nc   analysis*sd*nc  analysis_member*nc \
              output*mean*nc     output*sd*nc )

   if (  -e $FILE ) then
      set FEXT  = $FILE:e
      set FBASE = $FILE:r
      ${MOVE} $FILE clm_${FBASE}.${LND_DATE_EXT}.${FEXT}
   else
      echo "$FILE does not exist, no need to take action."
   endif
end

# Tag the DART observation file with the valid time of the model state.

${MOVE} obs_seq.final    clm_obs_seq.${LND_DATE_EXT}.final
${MOVE} dart_log.out     clm_dart_log.${LND_DATE_EXT}.out


#   Raczka:   Block 7: does not exist for this updated version because included
#  in updated model_mod.f90

#=========================================================================
# Block 7: Update the CLM restart files - 
# required because of the special missing value flags and 
# possible snow recompaction, etc.
#>@todo make dart_to_clm run simultaneously ... mpi?
#=========================================================================

#@ instance = 0
#foreach MEMBER ( ${CASE}.clm2_*.r.${LND_DATE_EXT}.nc )

#   @ instance ++ 
#   set DARTFILE = `head -n $instance restart_output_files.txt | tail -n 1`

#   ${LINK} $MEMBER clm_restart_file.nc
#   ${LINK} $DARTFILE dart_posterior.nc

#   ../bld/dart_to_clm || exit 7

# end


#-------------------------------------------------------------------------
# Cleanup
#-------------------------------------------------------------------------

echo "`date` -- END CLM_ASSIMILATE"

exit 0

#!/bin/csh
#
# DART software - Copyright UCAR. This open source software is provided
# provided by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
# DART $Id: CLM5_setup_assimilation 12602 2018-05-25 17:23:52Z thoar@ucar.edu $

#-----------------------------------------------------------------------
# Purpose, describe things here, etc.
# BMR:  WESTERN domain with 'no-fire' implemented, AGB and LAI3g gridded and interped
# SourceMod changes for both CNPrecisionControlMod.f90 and CNBalanceCheckMod.F90.
# Initial Conditions based upon Polly met forcing and 3 loop CAM forcing

# 'Gridinterp' naming convention uses the systematic uncertainty observations (large uncertainty, using original simplistic method)

# Uses GIT dart code, Maxstate expands the clm variables to be updated within 'input.nml'
  

#-----------------------------------------------------------------------

# ==============================================================================
# Options defining the experiment:
#
# CASE          The value of "CASE" will be used many ways; directory and file
#               names both locally and (possibly) on the HPSS, and script names;
#               so consider its length and information content.
# compset       Defines the vertical resolution and physics packages to be used.
#               Must be a standard CESM compset; see the CESM documentation.
# resolution    Defines the horizontal resolution and dynamics; see CESM docs.
# cesmtag       The version of the CESM source code to use when building the code.
# num_instances The number of ensemble members.
#
# For list of the pre-defined component sets: ./query_config --compsets
# To create a variant compset, see the CESM documentation and carefully
# incorporate any needed changes into this script.
# ==============================================================================

setenv num_instances  80
setenv CASE           clm5_assim_WEST_AGBLAI_gridinterp_maxstate_p3
setenv resolution     CLM_USRDAT
setenv compset        I2000Clm50BgcCropGs
setenv cesmtag        9999
setenv processors  1

# processors is cpus assigned per instance, for 1 instance 80 cpus.

# ==============================================================================
# Directories:
# cesmdata     Location of some supporting CESM data files.
# cesmroot     Location of the CESM code base.  This version of the script
#              only supports version cesm1_5_beta06c.
# caseroot     Defines the CESM case directory - where the CESM+DART
#              configuration files will be stored.  This should probably not
#              be in scratch (on yellowstone, your 'work' partition is suggested).
#              This script will delete any existing caseroot, so this script,
#              and other useful things should be kept elsewhere.
# rundir       Defines the location of the CESM run directory.  Will need large
#              amounts of disk space, generally on a scratch partition.
# exeroot      Defines the location of the CESM executable directory , where the
#              CESM executables will be built.  Medium amount of space
#              needed, generally on a scratch partition.
# archdir      Defines the location of the CESM short-term archive directories.
#              Files remain here until the long-term archiver moves them to
#              permanent storage.  Requires large amounts of disk space. Should
#              not be on a scratch partition unless the long-term archiver is
#              invoked to move these files to permanent storage.
#
# dartroot     Location of the root of _your_ DART installation
# baseobsdir   Part of the directory name containing the observation sequence
#              files to be used in the assimilation. The observations are presumed
#              to be stored in sub-directories with names built from the year and
#              month. 'baseobsdir' will be inserted into the appropriate scripts.
# ==============================================================================

setenv project      9999
setenv machine      kingspeak
setenv cesmdata     /scratch/general/nfs1/u0983603/inputdata
setenv cesmroot     /uufs/chpc.utah.edu/common/home/u0983603/clm5.0
setenv caseroot     /uufs/chpc.utah.edu/common/home/u0983603/clm5.0/cime/scripts/cases/${CASE}
setenv rundir       /uufs/chpc.utah.edu/common/home/lin-group3/braczka/${CASE}/run
setenv exeroot      /uufs/chpc.utah.edu/common/home/lin-group3/braczka/${CASE}/bld
setenv archdir      /scratch/general/nfs1/u0983603/archive/${CASE}
setenv dartroot     /uufs/chpc.utah.edu/common/home/lin-group3/braczka/DART_git/DART_CLM
setenv baseobsdir   /uufs/chpc.utah.edu/common/home/lin-group3/braczka/obstodart/products

# ==============================================================================
# configure settings:
#
# refcase    Name of the existing reference case that this run will start from.
# refyear    The specific date/time-of-day in the reference case that this
# refmon     run will start from.  (Also see 'runtime settings' below for
# refday     start_year, start_mon, start_day and start_tod.)
# reftod
#
# stagedir   The directory location of the reference case files.
#            This will surely change based on the compset and machine.
#
# startdate  The date used as the starting date for the hybrid run.
# ==============================================================================

setenv refcase      clm5_assim_WEST_AGBLAI_gridinterp_maxstate_p2
setenv refyear      2011
setenv refmon       01
setenv refday       01
setenv reftod       00000
setenv refdate      $refyear-$refmon-$refday
setenv reftimestamp $refyear-$refmon-$refday-$reftod

setenv stagedir /uufs/chpc.utah.edu/common/home/lin-group10/braczka/DART/clm5_assim_WEST_AGBLAI_gridinterp_maxstate_p2/

setenv startdate    1998-01-01

# The forward operators for the flux tower obs REQUIRE that we predict the name of
# of the history file. The history file names of interest are time-tagged with the
# START of the forecast - not the restart time. The obs_def_tower_mod.f90 requires
# the stop_option to be 'nhours', and the stop_n to be accurate.

setenv stop_option  nmonths  # Using monthly assimilation frequency, good for biomass/LAI
setenv stop_n       1        # Assimilating obs once per month
setenv resubmit     0

@ clm_dtime = 1800
#@ h1nsteps = $stop_n * 3600 / $clm_dtime   #Comentado. Nao vou tentar salvar dados step by step no usr_nl_clm. Vou tentar criar apenas um dummy mensal como h1

#>@todo stream template files & multiple years. Do we need to specify
#> year 1 and year N (performance penalty?). Can we change years on-the-fly
#> during a run?

set stream_year_align = 1998
set stream_year_first = 1998
set stream_year_last  = 2010

# ==============================================================================
# job settings:
#
# queue      can be changed during a series by changing the case.run
# timewall   can be changed during a series by changing the case.run
#
# ==============================================================================

setenv queue        default
setenv timewall     30:00
setenv short_term_archiver on

# ==============================================================================
# standard commands:
#
# If you are running on a machine where the standard commands are not in the
# expected location, add a case for them below.
# ==============================================================================

set nonomatch       # suppress "rm" warnings if wildcard does not match anything

# The FORCE options are not optional.
# The VERBOSE options are useful for debugging though
# some systems don't like the -v option to any of the following
switch ("`hostname`")
   case ys*:
         # NCAR "yellowstone"
         set   MOVE = '/bin/mv -v'
         set   COPY = '/bin/cp -v --preserve=timestamps'
         set   LINK = '/bin/ln -vsf'
         set REMOVE = '/bin/rm -rf'
      breaksw
   default:
         # NERSC "hopper", TACC "stampede" ... many more
         set   MOVE = 'mv -v'
         set   COPY = 'cp -v --preserve=timestamps'
         set   LINK = 'ln -vsf'
         set REMOVE = 'rm -rf'
      breaksw
endsw

# ==============================================================================
# Create the case - this creates the CASEROOT directory.
#
# For list of the pre-defined component sets: ./create_newcase -list
# To create a variant compset, see the CESM documentation and carefully
# incorporate any needed changes into this script.
# ==============================================================================

# FATAL idea to make caseroot the same dir as where this setup script is
# since the build process removes all files in the caseroot dir before
# populating it.  try to prevent shooting yourself in the foot.

if ( ${caseroot} == `pwd` ) then
   echo "ERROR: the setup script should not be located in the caseroot"
   echo "directory, because all files in the caseroot dir will be removed"
   echo "before creating the new case.  move the script to a safer place."
   exit 1
endif

echo "removing old files from ${caseroot}"
echo "removing old files from ${exeroot}"
echo "removing old files from ${rundir}"

${REMOVE} ${caseroot}
${REMOVE} ${exeroot}
${REMOVE} ${rundir}
${cesmroot}/cime/scripts/create_newcase  --res  ${resolution} \
                                         --mach ${machine} \
                                         --compset ${compset} \
                                         --case ${caseroot} \
                                         --project ${project} \
                                         --run-unsupported \
                                         --ninst ${num_instances} \
                                         --pecount ${processors} \
                                         --multi-driver || exit 2

# ==============================================================================
# Preserve a copy of this script as it was run.
# Copy the DART setup script (CESM_DART_config) to CASEROOT.
# Since we know the DARTROOT and BASEOBSDIR now, record them into
# CASEROOT/CESM_DART_config now.
# ==============================================================================

set ThisFileName = $0:t
${COPY} $ThisFileName ${caseroot}/${ThisFileName}.original

set TEMPLATE = ${dartroot}/models/clm/shell_scripts/cesm2_0/CESM2_0_DART_config.template
if ( -e ${TEMPLATE} ) then
   sed -e "s#BOGUS_DART_ROOT_STRING#${dartroot}#" \
       -e "s#BOGUS_DART_OBS_STRING#${baseobsdir}#" \
       -e "s#BOGUS_CASEROOT_STRING#${caseroot}#" ${TEMPLATE} \
           >! ${caseroot}/CESM_DART_config  || exit 3
   chmod 755  ${caseroot}/CESM_DART_config
else
   echo "ERROR: the script to configure for data assimilation is not available."
   echo "       ${TEMPLATE} MUST exist."
   exit 4
endif

# ==============================================================================
cd ${caseroot}
# ==============================================================================

# Save a copy for debug purposes
foreach FILE ( *xml )
   if ( ! -e        ${FILE}.original ) then
      ${COPY} $FILE ${FILE}.original
   endif
end

# Get a bunch of environment variables.
# If any of these are changed by xmlchange calls in this program,
# then they must be explicty changed with setenv calls too.

setenv TEST_MPI              `./xmlquery MPI_RUN_COMMAND       --value`
setenv CLM_CONFIG_OPTS       `./xmlquery CLM_CONFIG_OPTS       --value`
setenv COMPSET               `./xmlquery COMPSET               --value`
setenv COMP_ATM              `./xmlquery COMP_ATM              --value`
setenv COMP_OCN              `./xmlquery COMP_OCN              --value`
setenv CIMEROOT              `./xmlquery CIMEROOT              --value`
setenv CASEROOT              `./xmlquery CASEROOT              --value`

# Make sure the case is configured with a stub ocean and a data atmosphere.

if ( (${COMP_OCN} != socn) || (${COMP_ATM} != datm) ) then
   echo " "
   echo "ERROR: This setup script is not appropriate for active ocean or atmospheric compsets."
   echo " "
   exit 5
endif

./xmlchange STOP_OPTION=$stop_option
./xmlchange STOP_N=$stop_n
./xmlchange RESUBMIT=$resubmit
./xmlchange REST_OPTION=$stop_option
./xmlchange REST_N=$stop_n

./xmlchange CALENDAR=GREGORIAN
./xmlchange EXEROOT=${exeroot}
./xmlchange RUNDIR=${rundir}
./xmlchange DOUT_S_ROOT=${archdir}  #HFD: this line was missing in original script

./xmlchange DATM_MODE=CPLHIST  #HFD CPLHISTForcing
./xmlchange DATM_CPLHIST_YR_ALIGN=$stream_year_align
./xmlchange DATM_CPLHIST_YR_START=$stream_year_first
./xmlchange DATM_CPLHIST_YR_END=$stream_year_last

# --- In a hybrid run the model is initialized as a startup, BUT uses
# initialization datasets FROM A PREVIOUS case.  This
# is somewhat analogous to a branch run with relaxed restart
# constraints.  A hybrid run allows users to bring together combinations
# of initial/restart files from a previous case (specified by
# RUN_REFCASE) at a given model output date (specified by
# RUN_REFDATE). Unlike a branch run, the starting date of a hybrid run
# (specified by RUN_STARTDATE) can be modified relative to the reference
# case. In a hybrid run, the model does not continue in a bit-for-bit
# fashion with respect to the reference case. The resulting climate,
# however, should be continuous provided that no model source code or
# namelists are changed in the hybrid run.  In a hybrid initialization,
# the ocean model does not start until the second ocean coupling
# (normally the second day), and the coupler does a cold start without
# a restart file.</desc>

./xmlchange RUN_TYPE=hybrid
./xmlchange RUN_REFCASE=${refcase}
./xmlchange RUN_REFDATE=${refdate}
./xmlchange RUN_STARTDATE=${startdate}

# pnetcdf is default
./xmlchange PIO_TYPENAME=netcdf


./xmlchange ATM_DOMAIN_PATH=/uufs/chpc.utah.edu/common/home/u0981255/clm5.0/cime/scripts/arquivosadaptados  #for some reason the atm domain is not being set correctly with these commands... will have to do this manually via namelist
./xmlchange LND_DOMAIN_PATH=/uufs/chpc.utah.edu/common/home/u0981255/clm5.0/cime/scripts/arquivosadaptados


# WESTERN domain file with Western states mask
#/uufs/chpc.utah.edu/common/home/u0981255/clm5.0/cime/scripts/arquivosadaptados/domain.lnd.fv0.9x1.25_gx1v7.151020_wusa2_{state-2-letter-abbreviation}.nc.
./xmlchange ATM_DOMAIN_FILE=domain.lnd.fv0.9x1.25_gx1v7.151020_wusa2_wstatesmask.nc
./xmlchange LND_DOMAIN_FILE=domain.lnd.fv0.9x1.25_gx1v7.151020_wusa2_wstatesmask.nc
./xmlchange -a CLM_CONFIG_OPTS='-nofire'



# Task layout:
# Set the nodes_per_instance below to match your case.
# By computing task counts like we do below, we guarantee each instance uses
# a whole number of nodes which is the recommended configuration.
# CIME interprets a negative task count as representing the number of nodes.
# On Cheyenne (at least) using multiple threads is not recommended.

@ nodes_per_instance = 4
@ nthreads = 1

@ atm_tasks = -1 * $nodes_per_instance
@ cpl_tasks = -1 * $nodes_per_instance
@ ocn_tasks = -1 * $nodes_per_instance
@ wav_tasks = -1 * $nodes_per_instance
@ glc_tasks = -1 * $nodes_per_instance
@ ice_tasks = -1 * $nodes_per_instance
@ rof_tasks = -1 * $nodes_per_instance
@ lnd_tasks = -1 * $nodes_per_instance
@ esp_tasks = -1 * $nodes_per_instance


./case.setup || exit 6

echo "case setup finished"

# ====================================

./xmlchange --subgroup case.run        --id JOB_QUEUE          --val ${queue}
./xmlchange --subgroup case.run        --id JOB_WALLCLOCK_TIME --val ${timewall}
./xmlchange --subgroup case.st_archive --id JOB_WALLCLOCK_TIME --val 25:00

# These are archiving options that may be used.
# You can turn the short/long term archivers on or off ({short,long}_term_archiver),
# but these settings should be made in either event.

if ($short_term_archiver == 'off') then
   ./xmlchange DOUT_S=FALSE
else
   ./xmlchange DOUT_S=TRUE
endif

# DEBUG = TRUE implies turning on run and compile time debugging.
# INFO_DBUG level of debug output, 0=minimum, 1=normal, 2=more, 3=too much.
./xmlchange DEBUG=FALSE
./xmlchange INFO_DBUG=0

# ==============================================================================
# Modify namelist templates for each instance.

@ inst = 1
while ( $inst <= $num_instances )

   set inst_string = `printf _%04d $inst`

   # ===========================================================================
   set fname = "user_nl_datm${inst_string}"
   # ===========================================================================
   # DATM namelist

   set FILE1 = datm.streams.txt.CPLHISTForcing.Solar${inst_string}
   set FILE2 = datm.streams.txt.CPLHISTForcing.nonSolarFlux${inst_string}
   set FILE3 = datm.streams.txt.CPLHISTForcing.State1hr${inst_string}
   set FILE4 = datm.streams.txt.CPLHISTForcing.State3hr${inst_string}

   echo "streams = '$FILE1 $stream_year_align $stream_year_first $stream_year_last'," >> ${fname}
   echo "          '$FILE2 $stream_year_align $stream_year_first $stream_year_last'," >> ${fname}
   echo "          '$FILE3 $stream_year_align $stream_year_first $stream_year_last'," >> ${fname}
   echo "          '$FILE4 $stream_year_align $stream_year_first $stream_year_last'," >> ${fname}
   echo "          'datm.streams.txt.presaero.clim_2000${inst_string} 1 1 1'"         >> ${fname}
   echo "vectors  = 'u:v' "     >> ${fname}
   echo "mapmask  = 'nomask', " >> ${fname}
   echo "           'nomask', " >> ${fname}
   echo "           'nomask', " >> ${fname}
   echo "           'nomask'  " >> ${fname}
   echo "tintalgo = 'coszen', " >> ${fname}
   echo "           'nearest'," >> ${fname}
   echo "           'linear', " >> ${fname}
   echo "           'linear'  " >> ${fname}
   echo "domainfile = '/uufs/chpc.utah.edu/common/home/u0981255/clm5.0/cime/scripts/arquivosadaptados/domain.lnd.fv0.9x1.25_gx1v7.151020_wusa2_wstatesmask.nc'" >> ${fname}

   # Create stream files for each ensemble member
   set SOURCEDIR = ${dartroot}/models/clm/shell_scripts/cesm2_0
   ${COPY} ${SOURCEDIR}/datm.streams.txt.CPLHISTForcing.Solar_complete        user_${FILE1}
   ${COPY} ${SOURCEDIR}/datm.streams.txt.CPLHISTForcing.nonSolarFlux_complete user_${FILE2}
   ${COPY} ${SOURCEDIR}/datm.streams.txt.CPLHISTForcing.State1hr_complete     user_${FILE3}
   ${COPY} ${SOURCEDIR}/datm.streams.txt.CPLHISTForcing.State3hr_complete     user_${FILE4}

   foreach FNAME ( user_datm.streams.txt*${inst_string} )
      echo "modifying $FNAME"
      sed s/_NINST/${inst_string}/g $FNAME >! temp
      sed s/\\/glade\\/p\\/image\\/thoar\\/CAM_DATM\\/4xdaily/\\/uufs\\/chpc\\.utah\\.edu\\/common\\/home\\/lin\\-group6\\/cam_ensemble/g temp >! temp2
      sed s/RUNYEAR/${stream_year_first}/g temp2 >! $FNAME
   end
   ${REMOVE} temp temp2

   # ===========================================================================
   set fname = "user_nl_clm${inst_string}"
   # ===========================================================================

   echo "hist_empty_htapes = .true."                                      >> ${fname}
   # IMPLEMENT same masking here as in the domain file ####  Also implement SourceMod changes here too.
   echo "fsurdat = '/uufs/chpc.utah.edu/common/home/u0981255/clm5.0/cime/scripts/arquivosadaptados/surfdata_0.9x1.25_78pfts_CMIP6_simyr2000_c170824_wusa2.nc'" >> ${fname}
   echo "hist_fincl1 = 'GPP','ER','NEP','TLAI','HTOP','EFLX_LH_TOT','H2OSOI','LEAFC','LIVESTEMC','DEADSTEMC','LIVECROOTC','DEADCROOTC','FROOTC','CPOOL','LITR1C_vr','LITR2C_vr','LITR3C_vr','SOIL1C_vr','SOIL2C_vr','SOIL3C_vr','LEAFN','LIVESTEMN','DEADSTEMN','LIVECROOTN','DEADCROOTN','FROOTN','NPOOL','LITR1N_vr','LITR2N_vr','LITR3N_vr','SOIL1N_vr','SOIL2N_vr','SOIL3N_vr','TSOI','TSOI_10CM','TV','TSA','RH2M','Q2M','SOILLIQ','SNOWLIQ','SNOWDP','H2OSOI','H2OSNO','HR','TG','FSH','FSIF','SNOW','RAIN','BTRAN2','BTRANMN','QINFL','TLAI','QRUNOFF','QDRAI','QVEGE','QVEGT','QSOIL'"               >> ${fname}
   echo "hist_fincl2 = 'GPP','ER','NEP','TLAI','HTOP','EFLX_LH_TOT','H2OSOI','LEAFC','LIVESTEMC','DEADSTEMC','LIVECROOTC','DEADCROOTC','FROOTC','CPOOL','LITR1C_vr','LITR2C_vr','LITR3C_vr','SOIL1C_vr','SOIL2C_vr','SOIL3C_vr','LEAFN','LIVESTEMN','DEADSTEMN','LIVECROOTN','DEADCROOTN','FROOTN','NPOOL','LITR1N_vr','LITR2N_vr','LITR3N_vr','SOIL1N_vr','SOIL2N_vr','SOIL3N_vr','TSOI','TSOI_10CM','TV','TSA','RH2M','Q2M','SOILLIQ','SNOWLIQ','SNOWDP','H2OSOI','H2OSNO','HR','TG','FSH','FSIF','SNOW','RAIN','BTRAN2','BTRANMN','QINFL','TLAI','QRUNOFF','QDRAI','QVEGE','QVEGT','QSOIL'"               >> ${fname}
   echo "hist_fincl3 = 'GPP','TLAI','HTOP'" >> ${fname}
   echo "hist_nhtfrq = 0,0,0"                               >> ${fname}
   echo "hist_mfilt  = 1,1,1"                                     >> ${fname}
   echo "hist_avgflag_pertape = 'A','A','A'"                              >> ${fname}
   echo "hist_dov2xy = .false.,.true.,.false."                             >> ${fname}
   echo "hist_type1d_pertape = ' ',' ',' '"                               >> ${fname}
   echo "dtime = $clm_dtime"                                              >> ${fname}
   echo "fire_method = 'nofire'"                                          >> ${fname}
   echo "use_init_interp = .true."                                         >> ${fname}
   @ inst ++
end

./preview_namelists || exit 3

# ==============================================================================
# Stage the restarts now that the run directory exists
# ==============================================================================

echo "staging restarts"

set init_time = ${reftimestamp}

cat << EndOfText >! stage_cesm_files
#!/bin/csh -f
# This script can be used to help restart an experiment from any previous step.
# The appropriate files are copied to the RUN directory.
#
# Before running this script:
#  1) be sure CONTINUE_RUN is set correctly in the env_run.xml file in
#     your CASEROOT directory.
#     CONTINUE_RUN=FALSE => you are starting over at the initial time.
#     CONTINUE_RUN=TRUE  => you are starting from a previous step but not
#                           the very first one.
#  2) be sure 'restart_time' is set to the day and time that you want to
#     restart from if not the initial time.

set restart_time = $init_time

# get the settings for this case from the CESM environment
cd ${caseroot}

setenv CONTINUE_RUN   `./xmlquery CONTINUE_RUN     --value`
setenv RUNDIR         `./xmlquery RUNDIR           --value`
setenv DOUT_S         `./xmlquery DOUT_S           --value`
setenv DOUT_S_ROOT    `./xmlquery DOUT_S_ROOT      --value`
setenv CASE           `./xmlquery CASE             --value`

cd \${RUNDIR}

echo 'Copying the required CESM files to the run directory to rerun'
echo 'a previous step.  CONTINUE_RUN from env_run.xml is' \${CONTINUE_RUN}
if ( \${CONTINUE_RUN} == TRUE ) then
  echo 'so files for some later step than the initial one will be restaged.'
  echo "Date to reset files to is: \${restart_time}"
else
  echo 'so files for the initial step of this experiment will be restaged.'
  echo "Date to reset files to is: ${init_time}"
endif
echo ''

if ( \${CONTINUE_RUN} == TRUE ) then

   #----------------------------------------------------------------------
   # This block copies over a set of restart files from any previous step of
   # the experiment that is NOT the initial step.
   # After running this script resubmit the job to rerun.
   #----------------------------------------------------------------------

   echo "Staging restart files for run date/time: " \${restart_time}

   #  The short term archiver is on, so the files we want should be in one
   #  of the short term archive 'rest' restart directories.  This assumes
   #  the long term archiver has NOT copied these files to the HPSS yet.

   if (  \${DOUT_S} == TRUE ) then

      # The restarts should be in the short term archive directory.  See
      # www.cesm.ucar.edu/models/cesm1.2/cesm/doc/usersguide1_2/x1565.html#running_ccsm_restarts
      # for more help and information.

      set RESTARTDIR = \${DOUT_S_ROOT}/rest/\${restart_time}

      if ( ! -d \${RESTARTDIR} ) then

         echo "restart file directory not found: "
         echo " \${RESTARTDIR}"
         echo "If the long-term archiver is on, you may have to restore this directory first."
         echo "You can also check for either a .sta or a .sta2 hidden subdirectory in"
         echo "\${DOUT_S_ROOT}"
         echo "which may contain the 'rest' directory you need,"
         echo "and then modify RESTARTDIR in this script."
         exit -1

      endif

      ${COPY} \${RESTARTDIR}/* . || exit -1

   else

      # The short term archiver is off, which leaves all the restart files
      # in the run directory.  The rpointer files must still be updated to
      # point to the files with the right day/time.

      @ inst=1
      while (\$inst <= $num_instances)

         set inst_string = \`printf _%04d \$inst\`

         echo "\${CASE}.cpl\${inst_string}.r.\${restart_time}.nc"    >! rpointer.drv\${inst_string}
         echo "\${CASE}.clm2\${inst_string}.r.\${restart_time}.nc"   >! rpointer.lnd\${inst_string}
         echo "\${CASE}.datm\${inst_string}.r.\${restart_time}.nc"   >! rpointer.atm\${inst_string}
         echo "\${CASE}.datm\${inst_string}.rs1.\${restart_time}.nc" >> rpointer.atm\${inst_string}
         echo "\${CASE}.mosart\${inst_string}.r.\${restart_time}.nc" >! rpointer.rof\${inst_string}

         @ inst ++
      end

      # If the multi-driver is not being used,
      # there is only a single coupler restart file.
      echo "\${case}.cpl.r.\${restart_time}.nc" >! rpointer.drv

   endif

   echo "All files reset to rerun experiment step for time " \$restart_time

else     # CONTINUE_RUN == FALSE

   #----------------------------------------------------------------------
   # This block links the right files to rerun the initial (very first)
   # step of an experiment.  The names and locations are set during the
   # building of the case; to change them rebuild the case.
   # After running this script resubmit the job to rerun.
   #----------------------------------------------------------------------

   @ inst=1
   while (\$inst <= $num_instances)

      set inst_string = \`printf _%04d \$inst\`

      echo "Staging initial files for instance \$inst of $num_instances"

      ${LINK} ${stagedir}/${refcase}.clm2\${inst_string}.r.${init_time}.nc .
      #HFD ${LINK} ${stagedir}/${refcase}.mosart\${inst_string}.r.${init_time}.nc .

      @ inst ++
   end

   echo "All files set to run the FIRST experiment step at time" $init_time

endif
exit 0

EndOfText
chmod 0755 stage_cesm_files

./stage_cesm_files || exit 2

#===============================================================================
# Copy modified CLM codes into SourceMods
# src.clm
# |-- clm4_0
# |   |-- biogeochem
# |   |   `-- CNBalanceCheckMod.F90
# |   `-- biogeophys
# |       |-- BalanceCheckMod.F90
# |       |-- SnowHydrologyMod.F90
# |       `-- UrbanMod.F90
# `-- clm5_0
#     |-- biogeochem
#     |   `-- CNBalanceCheckMod.F90
#     `-- biogeophys
#         `-- BalanceCheckMod.F90
# ==============================================================================

if (    -d     ~/${cesmtag}/SourceMods ) then

   ${COPY} -r ~/${cesmtag}/SourceMods/src.clm ${caseroot}/SourceMods/

   set clm_opts = `echo $CLM_CONFIG_OPTS | sed -e "s/-//"`

   @ iarg = 1
   while ($iarg <= $#clm_opts)

      @ iargp1 = $iarg + 1
      set option = $clm_opts[$iarg]
      set  value = $clm_opts[$iargp1]

      switch ( ${option} )
         case "phys":
            if ( -e    SourceMods/src.clm/${value} ) then
               cd      SourceMods/src.clm
               ${LINK} ${value}/*/*F90 .
               cd      ../..
            else
               echo "No SourceMods for CLM <${value}>."
               echo "Got the version from CLM_CONFIG_OPTS ...  <${CLM_CONFIG_OPTS}>"
            endif
         breaksw
      #  case "bgc":  no special action needed here at this time
      #  breaksw

         default:
         breaksw
      endsw

      @ iarg = $iarg + 2
   end

else

   echo "MESSAGE - No SourceMods for this case."
   echo "MESSAGE - No SourceMods for this case."

endif

cp -vi /uufs/chpc.utah.edu/common/home/u0981255/clm5.0/cime/scripts/arquivosadaptados/lnd_import_export.F90 SourceMods/src.clm/  #important source mod to bypass a few negative radiation values from DATM

## Loosen CN Balance and negative CN checks
cp -vi /uufs/chpc.utah.edu/common/home/u0983603/clm5.0/SourceMods/src.clm/clm5_0/biogeochem/*.F90 SourceMods/src.clm/  
# Do not take biogeophys BalanceCheckMod.f90
#cp -vi /uufs/chpc.utah.edu/common/home/u0983603/clm5.0/SourceMods/src.clm/clm5_0/biogeophys/*.F90 SourceMods/src.clm/  


## Adding SIF code for CLM5

cp -vi /uufs/chpc.utah.edu/common/home/u0983603/clm5.0/SourceMods/src.clm/clm5_0/biogeophys/PhotosynthesisMod.F90 SourceMods/src.clm/  
cp -vi /uufs/chpc.utah.edu/common/home/u0983603/clm5.0/SourceMods/src.clm/clm5_0/biogeophys/CanopyFluxesMod.F90 SourceMods/src.clm/  


./case.build || exit 7

# ==============================================================================
# What to do next
# ==============================================================================

cat << EndOfText >! CESM_instructions.txt

-------------------------------------------------------------------------
Time to check the case.

1) cd ${rundir}
   and check the compatibility between the namelists/pointer files
   and the files that were staged.

2) cd ${caseroot}

3) check things

4) run a single day, verify that it works without assimilation
   ./case.submit

5) IF NEEDED, compile all the DART executables by
   cd  ${dartroot}/models/clm/work
   ./quickbuild.csh -mpi

5) Modify the case to enable data assimilation and
   run DART by executing
   cd ${caseroot}
   ./CESM_DART_config

6) Make sure the DART-related parts are appropriate.
   Check the input.nml
   Check the assimilate.csh or perfect_model.csh - as appropriate
   ./case.submit

7) If that works
   ./xmlchange CONTINUE_RUN=TRUE
   that sort of thing
-------------------------------------------------------------------------

EndOfText

cat CESM_instructions.txt

exit 0

# <next few lines under version control, do not edit>
# $URL: https://svn-dares-dart.cgd.ucar.edu/DART/branches/cesm_clm/models/clm/shell_scripts/cesm2_0/CLM5_setup_assimilation $
# $Revision: 12602 $
# $Date: 2018-05-25 11:23:52 -0600 (Fri, 25 May 2018) $

#!/usr/bin/env bash

BaseCaseDir=/compyfs/yang954/xE3SM_scratch/C14/case_root/


AdspinupCase=xe3sm_hcru_hcru_c14_ad_spinup
FnspinupCase=xe3sm_hcru_hcru_c14_fn_spinup
TRrunPH1Case=xe3sm_hcru_hcru_c14_trans_phase1_fixalign
TransrunCase=xe3sm_hcru_hcru_c14_20TR_fixalign

Base_runDir=${BaseCaseDir}/${TransrunCase}/run
Base_bldDir=${BaseCaseDir}/${TransrunCase}/bld


CompSetName=I20TRCNPRDCTCBC

# ==case create
../cime/scripts/create_newcase --case $BaseCaseDir/$TransrunCase --mach compy --compset ${CompSetName} --res hcru_hcru --mpilib impi \
             --walltime 24:00:00 --handle-preexisting-dirs u --project e3sm --compiler intel

cd $BaseCaseDir/$TransrunCase





./xmlchange SAVE_TIMING=FALSE
./xmlchange MOSART_MODE=NULL


./xmlchange DATM_MODE=CLMGSWP3v1
./xmlchange DATM_CLMNCEP_YR_START=1901
./xmlchange DATM_CLMNCEP_YR_END=2010
./xmlchange DATM_CLMNCEP_YR_ALIGN=1901
./xmlchange ATM_NCPL=24


./xmlchange RUNDIR=$Base_runDir
./xmlchange EXEROOT=$Base_bldDir

./xmlchange JOB_WALLCLOCK_TIME="2:00:00"



comp=('ATM' 'LND' 'ICE' 'OCN' 'CPL' 'GLC' 'ROF' 'WAV')
for c in ${comp[@]}; do
    ./xmlchange NTASKS_$c=800
    ./xmlchange NTHRDS_$c=1
done

./xmlchange STOP_OPTION='nyears'
./xmlchange STOP_N=120
./xmlchange REST_N=10
./xmlchange RESUBMIT=100


./xmlchange CCSM_BGC=CO2A
./xmlchange CLM_CO2_TYPE=diagnostic

./xmlchange RUN_TYPE=branch
./xmlchange RUN_REFCASE=$TRrunPH1Case
./xmlchange RUN_REFDATE=1901-01-01
./xmlchange RUN_STARTDATE=1901-01-01



# ===case setup
./case.setup -r

# in order to reset the datm data start and end year, the rs1*.bin should be avaiable, them model will
# read the datm_in again
#/bin/cp -f $Base_runDir/$TransrunPH1Case/run/$TransrunPH1Case.datm.rs1.1901-01-01-00000.bin .
/bin/cp -f ${BaseCaseDir}/${TRrunPH1Case}/run/$TRrunPH1Case.cpl.r.1901-01-01-00000.nc ./run/
/bin/cp -f ${BaseCaseDir}/${TRrunPH1Case}/run/$TRrunPH1Case.clm2.r.1901-01-01-00000.nc ./run/
/bin/cp -f ${BaseCaseDir}/${TRrunPH1Case}/run/rpointer* ./run/

# -175200/24./365=-20
cat <<EOF >user_nl_clm
&clm_inparm
    hist_mfilt = 1
    hist_nhtfrq = 0
    hist_dov2xy = .true.
    stream_fldfilename_ndep = '/compyfs/inputdata/lnd/clm2/ndepdata/fndep_clm_rcp4.5_simyr1849-2106_1.9x2.5_c100428.nc'
    use_nitrif_denitrif = .true.
    nyears_ad_carbon_only = 25
    spinup_mortality_factor = 10

    !-flanduse_timeseries =
    !-check_finidat_fsurdat_consistency = .false.
    !-check_finidat_year_consistency = .false.

    atm_c14_filename = '/compyfs/inputdata/atm/datm7/CO2/atm_delta_C14_data_1850-2007_monthly_25082011.nc'
    use_c14 = .true.
    use_c14_bombspike = .true.


EOF


#update the mete forcing from GSWP3v1 to GSWP3v2
#-meteforcing=(Precip Solar TPQW)
#-/bin/rm -f datm.streams.txt.CLMGSWP3*.txt
#-for mete in ${meteforcing[@]}; do
#-    /bin/cp -f Buildconf/datmconf/datm.streams.txt.CLMGSWP3v1.$mete user_datm.streams.txt.CLMGSWP3v1.$mete
#-    sed -i -e 's/v1.c170516/v2.c180716/g' user_datm.streams.txt.CLMGSWP3v1.$mete
#-done
#-
#-#change the name in datm_in, cannot change the names
#-#sed -i -e 's/CLMGSWP3v1/CLMGSWP3v2/g' Buildconf/datmconf/datm_in
#-#/bin/cp -f Buildconf/datmconf/datm_in user_nl_datm
#-
#-sed -i -e 's/v2.c180716\/TPHWL/v2.c180716\/TPHWL3Hrly/' user_datm.streams.txt.CLMGSWP3v1.TPQW
#-sed -i -e 's/v2.c180716\/Precip/v2.c180716\/Precip3Hrly/' user_datm.streams.txt.CLMGSWP3v1.Precip
#-sed -i -e 's/v2.c180716\/Solar/v2.c180716\/Solar3Hrly/' user_datm.streams.txt.CLMGSWP3v1.Solar

# ===case build
./case.build


# ===




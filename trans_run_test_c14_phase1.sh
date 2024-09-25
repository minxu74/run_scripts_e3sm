#!/usr/bin/env bash

BaseCaseDir=/compyfs/yang954/xE3SM_scratch/C14/case_root/



AdspinupCase=xe3sm_hcru_hcru_c14_ad_spinup
FnspinupCase=xe3sm_hcru_hcru_c14_fn_spinup
TRrunPH1Case=xe3sm_hcru_hcru_c14_trans_phase1

Base_runDir=${BaseCaseDir}/${TRrunPH1Case}/run
Base_bldDir=${BaseCaseDir}/${TRrunPH1Case}/bld

CompSetName=I20TRCNPRDCTCBC

# ==case create
../cime/scripts/create_newcase --case $BaseCaseDir/$TRrunPH1Case --mach compy --compset $CompSetName --res hcru_hcru --mpilib impi \
             --walltime 24:00:00 --handle-preexisting-dirs u --project e3sm --compiler intel


cd $BaseCaseDir/$TRrunPH1Case




./xmlchange SAVE_TIMING=FALSE
./xmlchange MOSART_MODE=NULL


./xmlchange RUN_TYPE=hybrid
./xmlchange RUN_REFCASE=$FnspinupCase
./xmlchange RUN_REFDATE=0601-01-01
./xmlchange RUN_STARTDATE=1850-01-01


./xmlchange DATM_MODE=CLMGSWP3v1
./xmlchange DATM_CLMNCEP_YR_START=1901
./xmlchange DATM_CLMNCEP_YR_END=1920
./xmlchange DATM_CLMNCEP_YR_ALIGN=1841
./xmlchange ATM_NCPL=24

./xmlchange RUNDIR=$Base_runDir
./xmlchange EXEROOT=$Base_bldDir

./xmlchange JOB_WALLCLOCK_TIME="2:00:00"


# CO2 configure
./xmlchange CCSM_BGC=CO2A
./xmlchange CLM_CO2_TYPE=diagnostic

# pe layout
comp=('ATM' 'LND' 'ICE' 'OCN' 'CPL' 'GLC' 'ROF' 'WAV')
for c in ${comp[@]}; do
    ./xmlchange NTASKS_$c=800
    ./xmlchange NTHRDS_$c=1
done



./xmlchange STOP_OPTION='nyears'
./xmlchange STOP_N=40
./xmlchange REST_N=10
./xmlchange RESUBMIT=100

#-./xmlchange PIO_VERSION=2


# ===case setup
./case.setup -r

# copy data to FinspinupCase to NormspinupCase
/bin/cp -f $BaseCaseDir/${FnspinupCase}/run/rpointer* ./run/
/bin/cp -f $BaseCaseDir/${FnspinupCase}/run/$FnspinupCase.datm.rs1.0301-01-01-00000.bin ./run/
/bin/cp -f $BaseCaseDir/${FnspinupCase}/run/$FnspinupCase.cpl.r.0301-01-01-00000.nc ./run/
/bin/cp -f $BaseCaseDir/${FnspinupCase}/run/$FnspinupCase.clm2.r.0301-01-01-00000.nc ./run/

# -175200/24./365=-20
cat <<EOF >user_nl_clm
&clm_inparm
    hist_dov2xy = .true.
    hist_mfilt = 1
    hist_nhtfrq = 0
    stream_fldfilename_ndep = '/compyfs/inputdata/lnd/clm2/ndepdata/fndep_clm_rcp4.5_simyr1849-2106_1.9x2.5_c100428.nc'
    use_nitrif_denitrif = .true.
    nyears_ad_carbon_only = 25
    spinup_mortality_factor = 10
    !-flanduse_timeseries =
    !-check_finidat_fsurdat_consistency = .false.
    !-check_finidat_year_consistency = .false.
    paramfile = '/compyfs/inputdata/lnd/clm2/paramdata/clm_params_c180524.nc'

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


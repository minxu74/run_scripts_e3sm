#!/usr/bin/env bash

E3SMCimeDir=/global/homes/m/minxu/MyGit/e3sm_v3/cime/scripts/

BaseCaseDir=/global/cfs/projectdirs/m2467/prj_minxu/E3SM_cases/
BaseSimuDir=/pscratch/sd/m/minxu/E3SM_simulations/

GridRes=hcru_hcru   # 0.5 degree 0-360

Machine='pm-cpu'
Compiler='intel'

Compset=I20TRCNPRDCTCBC

CurDate=`date '+%Y-%m-%d'`
RunName=trans_EXPAI_RUBISCO

AdspinupYear='0201'
FnspinupYear='0991'

AdspinupCase=2024-09-26.ad_spinup_EXPAI_RUBISCO.${Compset}.${GridRes}.${Machine}.${Compiler}
FnspinupCase=2024-09-29.fn_spinup_EXPAI_RUBISCO.${Compset}.${GridRes}.${Machine}.${Compiler}
TrspinupCase=${CurDate}.${RunName}.${Compset}.${GridRes}.${Machine}.${Compiler}


Base_runDir=$BaseSimuDir/${TrspinupCase}/run
Base_bldDir=$BaseSimuDir/${TrspinupCase}/bld

Base_fnrDir=$BaseSimuDir/${FnspinupCase}/run
Base_adrDir=$BaseSimuDir/${AdspinupCase}/run

# ==case create
$E3SMCimeDir/create_newcase --case $BaseCaseDir/$TrspinupCase --mach ${Machine} --compset ${Compset} --res ${GridRes} --mpilib mpich\
             --walltime 24:00:00 --handle-preexisting-dirs u --project m2467 --compiler ${Compiler}


cd $BaseCaseDir/$TrspinupCase

./xmlchange SAVE_TIMING=FALSE
./xmlchange MOSART_MODE=NULL


./xmlchange DATM_MODE=CLMGSWP3v1
./xmlchange DATM_CLMNCEP_YR_START=1901
./xmlchange DATM_CLMNCEP_YR_END=2014
./xmlchange DATM_CLMNCEP_YR_ALIGN=1901
./xmlchange ATM_NCPL=24


./xmlchange RUNDIR=$Base_runDir
./xmlchange EXEROOT=$Base_bldDir

./xmlchange JOB_WALLCLOCK_TIME="48:00:00"


comp=('ATM' 'LND' 'ICE' 'OCN' 'CPL' 'GLC' 'ROF' 'WAV')

for c in ${comp[@]}; do
    ./xmlchange NTASKS_$c=1536
    ./xmlchange NTHRDS_$c=1
done

./xmlchange STOP_OPTION='nyears'
./xmlchange STOP_N=25
./xmlchange REST_N=1
./xmlchange RESUBMIT=10

#-./xmlchange PIO_VERSION=2

# multi-instance 144/4. = 36
# need to change 2 to 36

./xmlchange NINST_ATM=2
./xmlchange NINST_LND=2


# ===case setup
./case.setup -r


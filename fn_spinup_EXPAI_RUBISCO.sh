#!/usr/bin/env bash

E3SMCimeDir=/global/homes/m/minxu/MyGit/e3sm_v3/cime/scripts/

BaseCaseDir=/global/cfs/projectdirs/m2467/prj_minxu/E3SM_cases/
BaseSimuDir=/pscratch/sd/m/minxu/E3SM_simulations/

GridRes=hcru_hcru   # 0.5 degree 0-360

Machine='pm-cpu'
Compiler='intel'

Compset=I1850CNRDCTCBC

CurDate=`date '+%Y-%m-%d'`
RunName=fn_spinup_EXPAI_RUBISCO

AdspinupYear='0201'
AdspinupCase=2024-09-26.ad_spinup_EXPAI_RUBISCO.${Compset}.${GridRes}.${Machine}.${Compiler}
FnspinupCase=${CurDate}.${RunName}.${Compset}.${GridRes}.${Machine}.${Compiler}

CompSetName=I1850CNRDCTCBC

Base_runDir=$BaseSimuDir/${FnspinupCase}/run
Base_bldDir=$BaseSimuDir/${FnspinupCase}/bld
Base_adrDir=$BaseSimuDir/${AdspinupCase}/run

# ==case create
$E3SMCimeDir/create_newcase --case $BaseCaseDir/$FnspinupCase --mach ${Machine} --compset ${Compset} --res ${GridRes} --mpilib mpich\
             --walltime 24:00:00 --handle-preexisting-dirs u --project m2467 --compiler ${Compiler}


cd $BaseCaseDir/$FnspinupCase

./xmlchange SAVE_TIMING=FALSE
./xmlchange MOSART_MODE=NULL


./xmlchange DATM_MODE=CLMGSWP3v1
./xmlchange DATM_CLMNCEP_YR_START=1901
./xmlchange DATM_CLMNCEP_YR_END=1920
./xmlchange DATM_CLMNCEP_YR_ALIGN=1
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
./xmlchange STOP_N=180
./xmlchange REST_N=30
./xmlchange RESUBMIT=10

#-./xmlchange PIO_VERSION=2


# ===case setup
./case.setup -r


# -175200/24./365=-20
# 262800 = 30
cat <<EOF >user_nl_elm
&elm_inparm
    hist_mfilt = 1
    hist_nhtfrq = -262800
    hist_empty_htapes = .true.
    hist_fincl1 = 'PPOOL','EFLX_LH_TOT','RETRANSN','PCO2','PBOT','NDEP_TO_SMINN','OCDEP','BCDEP','COL_FIRE_CLOSS','HDM','LNFM','NEE','GPP','FPSN','AR','HR','MR','GR','ER','NPP','TLAI','SOIL3C','TOTSOMC','TOTSOMC_1m','LEAFC','DEADSTEMC','DEADCROOTC','FROOTC','LIVESTEMC','LIVECROOTC','TOTVEGC','N_ALLOMETRY','P_ALLOMETRY','TOTCOLC','TOTLITC','BTRAN','SCALARAVG_vr','CWDC','QVEGE','QVEGT','QSOIL','QDRAI','QRUNOFF','FPI','FPI_vr','FPG','FPI_P','FPI_P_vr','FPG_P','CPOOL','NPOOL','PPOOL','SMINN','HR_vr','SOIL4C'
    hist_dov2xy = .true.


    finidat = "$Base_adrDir/${AdspinupCase}.elm.r.${AdspinupYear}-01-01-00000.nc"
    stream_fldfilename_ndep = '/global/cfs/projectdirs/e3sm/inputdata/lnd/clm2/ndepdata/fndep_clm_rcp4.5_simyr1849-2106_1.9x2.5_c100428.nc'
    nyears_ad_carbon_only = 25
    spinup_mortality_factor = 10

    paramfile = '/global/cfs/projectdirs/e3sm/inputdata/lnd/clm2/paramdata/clm_params_c180524.nc'

EOF


#update the mete forcing from GSWP3v1 to GSWP3v2
#-meteforcing=(Precip Solar TPQW)
#-/bin/rm -f datm.streams.txt.CLMGSWP3*.txt
#-for mete in ${meteforcing[@]}; do
#-    /bin/cp -f Buildconf/datmconf/datm.streams.txt.CLMGSWP3v1.$mete user_datm.streams.txt.CLMGSWP3v1.$mete
#-    sed -i -e 's/v1.c170516/v2.c180716/g' user_datm.streams.txt.CLMGSWP3v1.$mete
#-done

#change the name in datm_in, cannot change the names
#sed -i -e 's/CLMGSWP3v1/CLMGSWP3v2/g' Buildconf/datmconf/datm_in
#/bin/cp -f Buildconf/datmconf/datm_in user_nl_datm

#-sed -i -e 's/v2.c180716\/TPHWL/v2.c180716\/TPHWL3Hrly/' user_datm.streams.txt.CLMGSWP3v1.TPQW
#-sed -i -e 's/v2.c180716\/Precip/v2.c180716\/Precip3Hrly/' user_datm.streams.txt.CLMGSWP3v1.Precip
#-sed -i -e 's/v2.c180716\/Solar/v2.c180716\/Solar3Hrly/' user_datm.streams.txt.CLMGSWP3v1.Solar


# ===case build
./case.build


# ===case submit
./case.submit

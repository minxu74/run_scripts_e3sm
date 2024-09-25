#!/usr/bin/env bash


E3SM_ROOT=/ccsopen/home/mfx/MyGit/E3SM

BaseCaseDir=/ccsopen/home/mfx/scratch/E3SM_simulations/TRENDY2024/case_root/



AdspinupCase=xe3sm_f09_f09_trendy2024_ad_spinup
Base_runDir=${BaseCaseDir}/${AdspinupCase}/run
Base_bldDir=${BaseCaseDir}/${AdspinupCase}/bld


# ==case create
${E3SM_ROOT}/cime/scripts/create_newcase --case $BaseCaseDir/$AdspinupCase --mach cades-baseline --compset I1850CNRDCTCBC --res f09_f09 --mpilib openmpi\
             --walltime 24:00:00 --handle-preexisting-dirs u --project cli185 --compiler gnu

cd $BaseCaseDir/$AdspinupCase

./xmlchange SAVE_TIMING=FALSE
./xmlchange MOSART_MODE=NULL
#./xmlchange --append CLM_BLDNML_OPTS='-bgc_spinup on'
./xmlchange --append ELM_BLDNML_OPTS='-bgc_spinup on'

./xmlchange DATM_MODE=CLMGSWP3v1
./xmlchange DATM_CLMNCEP_YR_START=1901
./xmlchange DATM_CLMNCEP_YR_END=1920
./xmlchange DATM_CLMNCEP_YR_ALIGN=1
./xmlchange ATM_NCPL=24


./xmlchange RUNDIR=$Base_runDir
./xmlchange EXEROOT=$Base_bldDir

./xmlchange JOB_WALLCLOCK_TIME="72:00:00"


# pe setting
comp=('ATM' 'LND' 'ICE' 'OCN' 'CPL' 'GLC' 'ROF' 'WAV')
for c in ${comp[@]}; do
    ./xmlchange NTASKS_$c=1920
    ./xmlchange NTHRDS_$c=1
done


# running time and restart
./xmlchange STOP_OPTION='nyears'
./xmlchange STOP_N=600
./xmlchange REST_N=25
./xmlchange RESUBMIT=100


# ===case setup
./case.setup -r


# -175200/24./365=-20
cat <<EOF >user_nl_elm
&elm_inparm
    hist_mfilt = 1, 1
    hist_nhtfrq = -175200, -175200
    hist_empty_htapes = .true.


    hist_fincl1 = 'PPOOL','EFLX_LH_TOT','RETRANSN','PCO2','PBOT','NDEP_TO_SMINN','OCDEP','BCDEP','COL_FIRE_CLOSS','HDM','LNFM','NEE','GPP','FPSN','AR','HR','MR','GR','ER','NPP','TLAI','SOIL3C','TOTSOMC','TOTSOMC_1m','LEAFC','DEADSTEMC','DEADCROOTC','FROOTC','LIVESTEMC','LIVECROOTC','TOTVEGC','N_ALLOMETRY','P_ALLOMETRY','TOTCOLC','TOTLITC','BTRAN','SCALARAVG_vr','CWDC','QVEGE','QVEGT','QSOIL','QDRAI','QRUNOFF','FPI','FPI_vr','FPG','FPI_P','FPI_P_vr','FPG_P','CPOOL','NPOOL','PPOOL','SMINN','HR_vr','SOIL4C'
    hist_dov2xy = .true., .false.
    hist_fincl2 = 'CWDC_vr','CWDN_vr','CWDP_vr','SOIL2C_vr','SOIL2N_vr','SOIL2P_vr','SOIL3C_vr','SOIL3N_vr','SOIL3P_vr','DEADSTEMC','DEADSTEMN','DEADSTEMP','DEADCROOTC','DEADCROOTN','DEADCROOTP','LITR3C_vr','LITR3N_vr','LITR3P_vr','LEAFC','TOTVEGC','TLAI','SOIL4C_vr','SOIL4N_vr','SOIL4P_vr'

    finidat = ''
    stream_fldfilename_ndep = '/gpfs/wolf2/cades/cli185/world-shared/e3sm/inputdata/lnd/clm2/ndepdata/fndep_clm_rcp4.5_simyr1849-2106_1.9x2.5_c100428.nc'
    nyears_ad_carbon_only = 25
    spinup_mortality_factor = 10
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


# ===



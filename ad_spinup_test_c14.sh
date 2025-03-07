#!/usr/bin/env bash



BaseCaseDir=/compyfs/yang954/xE3SM_scratch/C14/case_root/



AdspinupCase=xe3sm_hcru_hcru_c14_ad_spinup
Base_runDir=/compyfs/yang954/xE3SM_scratch/C14/case_root/${AdspinupCase}/run
Base_bldDir=/compyfs/yang954/xE3SM_scratch/C14/case_root/${AdspinupCase}/bld


# ==case create
../cime/scripts/create_newcase --case $BaseCaseDir/$AdspinupCase --mach compy --compset I1850CNRDCTCBC --res hcru_hcru --mpilib impi\
             --walltime 24:00:00 --handle-preexisting-dirs u --project e3sm --compiler intel

cd $BaseCaseDir/$AdspinupCase

./xmlchange SAVE_TIMING=FALSE
./xmlchange MOSART_MODE=NULL
./xmlchange --append CLM_BLDNML_OPTS='-bgc_spinup on'

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
    ./xmlchange NTASKS_$c=2400
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
cat <<EOF >user_nl_clm
&clm_inparm
    hist_mfilt = 1, 1
    hist_nhtfrq = -175200, -175200
    hist_empty_htapes = .true.


    hist_fincl1 = 'PPOOL','EFLX_LH_TOT','RETRANSN','PCO2','PBOT','NDEP_TO_SMINN','OCDEP','BCDEP','COL_FIRE_CLOSS','HDM','LNFM','NEE','GPP','FPSN','AR','HR','MR','GR','ER','NPP','TLAI','SOIL3C','TOTSOMC','TOTSOMC_1m','LEAFC','DEADSTEMC','DEADCROOTC','FROOTC','LIVESTEMC','LIVECROOTC','TOTVEGC','N_ALLOMETRY','P_ALLOMETRY','TOTCOLC','TOTLITC','BTRAN','SCALARAVG_vr','CWDC','QVEGE','QVEGT','QSOIL','QDRAI','QRUNOFF','FPI','FPI_vr','FPG','FPI_P','FPI_P_vr','FPG_P','CPOOL','NPOOL','PPOOL','SMINN','HR_vr','SOIL4C'
    hist_dov2xy = .true., .false.
    hist_fincl2 = 'CWDC_vr','CWDN_vr','CWDP_vr','SOIL2C_vr','SOIL2N_vr','SOIL2P_vr','SOIL3C_vr','SOIL3N_vr','SOIL3P_vr','DEADSTEMC','DEADSTEMN','DEADSTEMP','DEADCROOTC','DEADCROOTN','DEADCROOTP','LITR3C_vr','LITR3N_vr','LITR3P_vr','LEAFC','TOTVEGC','TLAI','SOIL4C_vr','SOIL4N_vr','SOIL4P_vr'

    finidat = ''
    stream_fldfilename_ndep = '/compyfs/inputdata/lnd/clm2/ndepdata/fndep_clm_rcp4.5_simyr1849-2106_1.9x2.5_c100428.nc'
    use_nitrif_denitrif = .true.
    nyears_ad_carbon_only = 25
    spinup_mortality_factor = 10

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

#change the name in datm_in, cannot change the names
#sed -i -e 's/CLMGSWP3v1/CLMGSWP3v2/g' Buildconf/datmconf/datm_in
#/bin/cp -f Buildconf/datmconf/datm_in user_nl_datm

#-sed -i -e 's/v2.c180716\/TPHWL/v2.c180716\/TPHWL3Hrly/' user_datm.streams.txt.CLMGSWP3v1.TPQW
#-sed -i -e 's/v2.c180716\/Precip/v2.c180716\/Precip3Hrly/' user_datm.streams.txt.CLMGSWP3v1.Precip
#-sed -i -e 's/v2.c180716\/Solar/v2.c180716\/Solar3Hrly/' user_datm.streams.txt.CLMGSWP3v1.Solar


# ===case build
./case.build


# ===



#!/usr/bin/env bash

E3SMCimeDir=/global/homes/m/minxu/MyGit/e3sm_v3/cime/scripts/

BaseCaseDir=/global/cfs/projectdirs/m2467/prj_minxu/E3SM_cases/
BaseSimuDir=/pscratch/sd/m/minxu/E3SM_simulations/

GridRes=hcru_hcru   # 0.5 degree 0-360

Machine='pm-cpu'
Compiler='intel'

Compset=I20TRCNPRDCTCBC

CurDate=`date '+%Y-%m-%d'`
RunName=trans_EXPAI_RUBISCO_CMIP6_phase1

AdspinupYear='0201'
#FnspinupYear='0730'
#Ens='000'

#FnspinupYear='0850'
#Ens='001'

FnspinupYear='0970'
Ens='002'

CompSetName=I1850CNPRDCTCBC

AdspinupCase=2024-10-07.ad_spinup_EXPAI_RUBISCO_CMIP6.${CompSetName}.${GridRes}.${Machine}.${Compiler}
FnspinupCase=2024-10-09.fn_spinup_EXPAI_RUBISCO_CMIP6.${CompSetName}.${GridRes}.${Machine}.${Compiler}

Transph1Case=${CurDate}.${RunName}.${Compset}.${GridRes}.${Machine}.${Compiler}_${Ens}


Base_runDir=$BaseSimuDir/${Transph1Case}/run
Base_bldDir=$BaseSimuDir/${Transph1Case}/bld

Base_fnrDir=$BaseSimuDir/${FnspinupCase}/run
Base_adrDir=$BaseSimuDir/${AdspinupCase}/run

# ==case create
$E3SMCimeDir/create_newcase --case $BaseCaseDir/$Transph1Case --mach ${Machine} --compset ${Compset} --res ${GridRes} --mpilib mpich\
             --walltime 24:00:00 --handle-preexisting-dirs u --project m2467 --compiler ${Compiler}


cd $BaseCaseDir/$Transph1Case

./xmlchange SAVE_TIMING=FALSE
./xmlchange MOSART_MODE=NULL


./xmlchange DATM_MODE=CLMGSWP3v1
./xmlchange DATM_CLMNCEP_YR_START=1901
./xmlchange DATM_CLMNCEP_YR_END=1920
./xmlchange DATM_CLMNCEP_YR_ALIGN=1841
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
./xmlchange STOP_N=50
./xmlchange REST_N=10
./xmlchange RESUBMIT=0

./case.setup

#-./xmlchange PIO_VERSION=2

# copy files
/bin/cp -f ${Base_fnrDir}/$FnspinupCase.datm.rs1.${FnspinupYear}-01-01-00000.bin ${Base_runDir}/
/bin/cp -f ${Base_fnrDir}/$FnspinupCase.cpl.r.${FnspinupYear}-01-01-00000.nc ${Base_runDir}/
/bin/cp -f ${Base_fnrDir}/$FnspinupCase.elm.r.${FnspinupYear}-01-01-00000.nc ${Base_runDir}/


./xmlchange RUN_TYPE=hybrid
./xmlchange RUN_REFDIR=$Base_fnrDir
./xmlchange RUN_REFCASE=$FnspinupCase
./xmlchange RUN_REFDATE=${FnspinupYear}-01-01
./xmlchange RUN_STARTDATE=1850-01-01


# till 2014
/bin/cp -f /global/homes/m/minxu/MyGit/MySrc/run_scripts_e3sm/datm_expai/user_datm.streams.txt.co2tseries.20tr .
/bin/cp -f /global/homes/m/minxu/MyGit/MySrc/run_scripts_e3sm/datm_expai/user_datm.streams.txt.presaero.trans_1850-2000 .

# ===case setup
./case.setup -r


cat <<EOF >user_nl_elm
&elm_inparm
    hist_nhtfrq = 0,-24,0,0                                                                         
    hist_mfilt = 1,365,1,1  
    hist_dov2xy = .true., .true., .false., .false.
    hist_fincl1 = 'TOTPRODC','LEAFC_STORAGE','LEAFC_XFER','FROOTC_STORAGE','FROOTC_XFER','LIVESTEMC_STORAGE','LIVESTEMC_XFER',
                  'DEADSTEMC_STORAGE','DEADSTEMC_XFER','LIVECROOTC_STORAGE','LIVECROOTC_XFER','DEADCROOTC_STORAGE','DEADCROOTC_XFER',
                  'GRESP_STORAGE','GRESP_XFER','TOTPRODN','DWT_PROD100C_GAIN','DWT_PROD10C_GAIN','COL_FIRE_CLOSS','DWT_CLOSS',
                  'DWT_NLOSS','PROD100C','PROD10C','PRODUCT_CLOSS','PROD1N','PROD10N','PROD100N','PRODUCT_NLOSS','PROD1N_LOSS','PROD10N_LOSS',
                  'PROD100N_LOSS','COL_FIRE_NLOSS','NET_NMIN','LEAFN_TO_LITTER','FROOTN_TO_LITTER','M_NPOOL_TO_LITTER','M_RETRANSN_TO_LITTER',
                  'M_LEAFN_TO_LITTER','M_LEAFN_STORAGE_TO_LITTER','M_LEAFN_XFER_TO_LITTER','M_FROOTN_TO_LITTER','M_FROOTN_STORAGE_TO_LITTER',
                  'M_FROOTN_XFER_TO_LITTER','M_LIVESTEMN_TO_LITTER','M_LIVESTEMN_STORAGE_TO_LITTER','M_LIVESTEMN_XFER_TO_LITTER','M_DEADSTEMN_TO_LITTER',
                  'M_DEADSTEMN_STORAGE_TO_LITTER', 'M_DEADSTEMN_XFER_TO_LITTER','M_LIVECROOTN_TO_LITTER','M_LIVECROOTN_STORAGE_TO_LITTER',
                  'M_LIVECROOTN_XFER_TO_LITTER','M_DEADCROOTN_TO_LITTER','M_DEADCROOTN_STORAGE_TO_LITTER','M_DEADCROOTN_XFER_TO_LITTER',
                  'M_DEADSTEMN_TO_LITTER_FIRE','M_DEADCROOTN_TO_LITTER_FIRE','LEAFN_STORAGE','LEAFN_XFER','LIVESTEMN_STORAGE','LIVESTEMN_XFER',
                  'DEADSTEMN_STORAGE','DEADSTEMN_XFER','LIVECROOTN_STORAGE','LIVECROOTN_XFER','DEADCROOTN_STORAGE','DEADCROOTN_XFER','FROOTN_STORAGE',
                  'FROOTN_XFER','LEAFC_XFER_TO_LEAFC','CPOOL_TO_LEAFC','LIVESTEMC_XFER_TO_LIVESTEMC','CPOOL_TO_LIVESTEMC','DEADSTEMC_XFER_TO_DEADSTEMC',
                  'CPOOL_TO_DEADSTEMC','CPOOL_TO_LIVECROOTC','CPOOL_TO_DEADCROOTC','LIVECROOTC_XFER_TO_LIVECROOTC','DEADCROOTC_XFER_TO_DEADCROOTC',
                  'CPOOL_TO_FROOTC','FROOTC_XFER_TO_FROOTC','FROOT_MR','LIVESTEM_MR','LIVECROOT_MR','CPOOL_LEAF_GR','CPOOL_LEAF_STORAGE_GR',
                  'TRANSFER_LEAF_GR','LITFIRE','SOMFIRE','VEGFIRE','FROOTC_TO_LITTER','M_LEAFC_TO_LITTER','M_LEAFC_STORAGE_TO_LITTER',
                  'M_LEAFC_XFER_TO_LITTER','M_FROOTC_TO_LITTER','M_FROOTC_STORAGE_TO_LITTER','M_FROOTC_XFER_TO_LITTER','M_LIVESTEMC_TO_LITTER',
                  'M_LIVESTEMC_STORAGE_TO_LITTER','M_LIVESTEMC_XFER_TO_LITTER','M_DEADSTEMC_TO_LITTER','M_DEADSTEMC_STORAGE_TO_LITTER',
                  'M_DEADSTEMC_XFER_TO_LITTER','M_LIVECROOTC_TO_LITTER','M_LIVECROOTC_STORAGE_TO_LITTER','M_LIVECROOTC_XFER_TO_LITTER',
                  'M_DEADCROOTC_TO_LITTER','M_DEADCROOTC_STORAGE_TO_LITTER','M_DEADCROOTC_XFER_TO_LITTER','M_LEAFC_TO_LITTER_FIRE',
                  'M_LEAFC_STORAGE_TO_LITTER_FIRE','M_LEAFC_XFER_TO_LITTER_FIRE','M_FROOTC_TO_LITTER_FIRE','M_FROOTC_STORAGE_TO_LITTER_FIRE',
                  'M_FROOTC_XFER_TO_LITTER_FIRE','M_LIVESTEMC_TO_LITTER_FIRE','M_LIVESTEMC_STORAGE_TO_LITTER_FIRE','M_LIVESTEMC_XFER_TO_LITTER_FIRE',
                  'M_DEADSTEMC_TO_LITTER_FIRE','M_DEADSTEMC_STORAGE_TO_LITTER_FIRE','M_DEADSTEMC_XFER_TO_LITTER_FIRE','M_LIVECROOTC_STORAGE_TO_LITTER_FIRE',
                  'M_DEADCROOTC_STORAGE_TO_LITTER_FIRE','M_GRESP_STORAGE_TO_LITTER_FIRE','M_GRESP_XFER_TO_LITTER_FIRE','M_CPOOL_TO_LITTER_FIRE',
                  'M_LIVEROOTC_TO_LITTER_FIRE','M_LIVEROOTC_TO_LITTER_FIRE','M_LIVEROOTC_XFER_TO_LITTER_FIRE','M_DEADROOTC_TO_LITTER_FIRE',
                  'M_DEADROOTC_XFER_TO_LITTER_FIRE','GAP_NLOSS_LITTER','FIRE_NLOSS_LITTER','HRV_NLOSS_LITTER','SEN_NLOSS_LITTER','GAP_PLOSS_LITTER',
                  'FIRE_PLOSS_LITTER','HRV_PLOSS_LITTER','SEN_PLOSS_LITTER','FSRND','FSRNI','FSRVD','FSRVI',
                  'CPOOL_FROOT_GR','CPOOL_FROOT_STORAGE_GR','TRANSFER_FROOT_GR','CPOOL_LIVESTEM_GR','CPOOL_LIVESTEM_STORAGE_GR','TRANSFER_LIVESTEM_GR',
                  'CPOOL_DEADSTEM_GR','CPOOL_DEADSTEM_STORAGE_GR','TRANSFER_DEADSTEM_GR','CPOOL_LIVECROOT_GR','CPOOL_LIVECROOT_STORAGE_GR','TRANSFER_LIVECROOT_GR',
                  'CPOOL_DEADCROOT_GR','CPOOL_DEADCROOT_STORAGE_GR','TRANSFER_DEADCROOT_GR','M_GRESP_STORAGE_TO_LITTER','M_GRESP_XFER_TO_LITTER','M_CPOOL_TO_FIRE',
                  'NPOOL','NPOOL_TO_LEAFN','NPOOL_TO_FROOTN','NPOOL_TO_LIVESTEMN','NPOOL_TO_DEADSTEMN','NPOOL_TO_LIVECROOTN','NPOOL_TO_DEADCROOTN',
                  'LEAFN_XFER_TO_LEAFN','FROOTN_XFER_TO_FROOTN','LIVESTEMN_XFER_TO_LIVESTEMN','DEADSTEMN_XFER_TO_DEADSTEMN','LIVECROOTN_XFER_TO_LIVECROOTN',
                  'DEADCROOTN_XFER_TO_DEADCROOTN','TOTPRODP','LEAFP_STORAGE','LEAFP_XFER','FROOTP_STORAGE','FROOTP_XFER','LIVESTEMP_STORAGE','LIVESTEMP_XFER',
                  'DEADSTEMP_STORAGE','DEADSTEMP_XFER','LIVECROOTP_STORAGE','LIVECROOTP_XFER','DEADCROOTP_STORAGE','DEADCROOTP_XFER','PPOOL','PPOOL_TO_LEAFP',
                  'PPOOL_TO_FROOTP','PPOOL_TO_LIVESTEMP','PPOOL_TO_DEADSTEMP','PPOOL_TO_LIVECROOTP','PPOOL_TO_DEADCROOTP','LEAFP_XFER_TO_LEAFP',
                  'FROOTP_XFER_TO_FROOTP','LIVESTEMP_XFER_TO_LIVESTEMP','DEADSTEMP_XFER_TO_DEADSTEMP','LIVECROOTP_XFER_TO_LIVECROOTP',
                  'DEADCROOTP_XFER_TO_DEADCROOTP', 'VEGC_TO_CWDC','VEGN_TO_CWDN','VEGP_TO_CWDP','M_CPOOL_TO_LITTER','M_NPOOL_TO_LITTER','M_PPOOL_TO_LITTER',
                  'M_CPOOL_TO_LITTER_FIRE','M_NPOOL_TO_LITTER_FIRE','M_PPOOL_TO_LITTER_FIRE',
                  'DWT_PROD100N_GAIN','DWT_PROD10N_GAIN','DWT_PROD100P_GAIN','DWT_PROD10P_GAIN','WOOD_HARVESTP','DWT_PLOSS','DWT_NLOSS', 'LAND_USE_FLUX', 
                  'FSDSNI', 'FSDSVI'

    hist_fincl2 = 'QRUNOFF_R','TWS','SOILWATER_10CM','QSOIL', 'QVEGE', 'QVEGT','GPP','QRUNOFF', 'AR', 'HR'
    hist_fincl3 = 'GPP','NEE','NEP','NPP','TLAI','TOTVEGC','TOTVEGN','TOTVEGP','FROOTC','FROOTN','FROOTP','LIVECROOTC','LIVECROOTN','LIVECROOTP',
                  'DEADCROOTC','DEADCROOTN','DEADCROOTP', 'LIVESTEMC','LIVESTEMN','LIVESTEMP','DEADSTEMC','DEADSTEMN','DEADSTEMP','TOTPFTC','TOTPFTN','TOTPFTP',
                  'PFT_FIRE_CLOSS','PFT_FIRE_NLOSS','PFT_FIRE_PLOSS','AR','HR','PCT_LANDUNIT','PCT_NAT_PFT'
    hist_fincl4 = 'TOTLITC','TOTLITN','TOTLITP','CWDC','CWDN','CWDP','DWT_CLOSS','DWT_NLOSS','DWT_PLOSS','HR','TOTCOLC','TOTCOLN','TOTCOLP','TOTECOSYSC',
                  'TOTECOSYSN','TOTECOSYSP','TOTSOMC','TOTSOMN','TOTSOMP'


    stream_fldfilename_ndep = '/global/cfs/projectdirs/e3sm/inputdata/lnd/clm2/ndepdata/fndep_elm_cbgc_exp_simyr1849-2101_1.9x2.5_ssp245_c240903.nc'
    fsurdat = '/global/homes/m/minxu/projbgc/rubisco_cmip6_ssp/surfdata_map/surfdata_360x720cru_simyr1850_c241007.nc'
    flanduse_timeseries = '/global/homes/m/minxu/projbgc/rubisco_cmip6_ssp/surfdata_map/landuse.timeseries_360x720cru_HIST_simyr1850-2015_c241007.nc'

    check_dynpft_consistency = .false.
    check_finidat_fsurdat_consistency = .false.
    check_finidat_year_consistency = .false.


    create_crop_landunit = .false.
    suplphos = 'NONE'



    !-stream_fldfilename_ndep = '/compyfs/inputdata/lnd/clm2/ndepdata/fndep_clm_rcp4.5_simyr1849-2106_1.9x2.5_c100428.nc'
    !-flanduse_timeseries =
    !-check_finidat_fsurdat_consistency = .false.
    !-check_finidat_year_consistency = .false.
    !-paramfile = '/compyfs/inputdata/lnd/clm2/paramdata/clm_params_c180524.nc'
EOF


./case.build

#!/usr/bin/env bash



datmvars=(Precip Solar TPQW)
datmhead='users_datm.streams.txt.CLMGSWP3v1.' 

set -x

for var in ${datmvars[@]}; do

    file=${datmhead}${var}

    ofil='user_datm.streams.txt.CLMGSWP3v1.'${var}

    # remove monthly file names and only keep YYYY-10.nc
    sed '/-[01][1-9].nc/d' $file > tmp

    # change names 
    if [[ $var == 'Precip' ]]; then
       sed 's/clmforc.GSWP3.c2011.0.5x0.5.Prec/elmforc.TRENDY.c2024_0.5x0.5.PREC/' tmp > tmp2
    fi

    if [[ $var == 'Solar' ]]; then
       sed 's/clmforc.GSWP3.c2011.0.5x0.5.Solr/elmforc.TRENDY.c2024_0.5x0.5.Solr/' tmp > tmp2
    fi

    if [[ $var == 'TPQW' ]]; then
       sed 's/clmforc.GSWP3.c2011.0.5x0.5.TPQWL/elmforc.TRENDY.c2024_0.5x0.5.TPQWL/' tmp > tmp2
    fi

    # remove the YYYY-10 to YYYY
    sed 's/-10.nc/.nc/' tmp2 > out/$ofil

    # 
    sed -i 's|/gpfs/wolf2/cades/cli185/world-shared/e3sm/inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516/.*|\
         /ccsopen/home/mfx/scratch/TRENDY2024|' out/$ofil
    sed -i 's|/gpfs/wolf2/cades/cli185/world-shared/e3sm/inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516|\
         /ccsopen/home/mfx/scratch/TRENDY2024|' out/$ofil

    sed -i 's/domain.lnd.360x720_gswp3.0v1.c170606.nc/domain.lnd.r05_EC15to60E2r4.201104.nc/' out/$ofil

    /bin/rm -f tmp tmp2 

done

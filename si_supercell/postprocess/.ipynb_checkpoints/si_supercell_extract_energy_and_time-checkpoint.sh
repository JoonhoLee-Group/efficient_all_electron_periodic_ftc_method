#!/bin/bash

# Root directories
base_in="/n/home02/hieudinh/rsdf_test_full_J/input/si_supercell"
base_out="/n/home02/hieudinh/rsdf_test_full_J/output/si_supercell"
data_path="/n/home02/hieudinh/rsdf_test_full_J/post_process/si_supercell"

# Basis sets, omega values, grid sizes
basis_list=("ccpvdz")
omega_list=("0.3" "0.6" "0.9")
grid_list=("111")   
supercell_list=("111" "222" "333")


# Loop over basis sets
for basis in "${basis_list[@]}"; do
    output_csv="${data_path}/data_${basis}.csv"
    
    # Write CSV header (no "Basis")
    echo "Omega,Grid,Supercell,Energy,RIJ-BIGMEM(s),DFT-XC(s),2e3c-CC(s),2e3c-CD(s),2e2c(s),niter" > "$output_csv"

    for supercell in "${supercell_list[@]}"; do
        for omega in "${omega_list[@]}"; do
            for grid in "${grid_list[@]}"; do
                outfile="$base_out/si_${supercell}/si_${supercell}_${basis}_omega_${omega}_${grid}.out"

                if [ -f "$outfile" ]; then
                    # Extract data
                    energy=$(grep "Final energy is" "$outfile" | awk '{print $4}')
                    rij_time=$(grep "Total wall time for computing RIJ-BIGMEM" "$outfile" | awk '{print $7}')
                    xc_time=$(grep "Total wall time for computing DFT XC" "$outfile" | awk '{print $8}')
                    sr2e3c_cc_time=$(grep "Time for computing 2e3c SR integral (CC)" "$outfile" | awk '{print $9}')
                    sr2e3c_cd_time=$(grep "Time for computing 2e3c SR integral (CD)" "$outfile" | awk '{print $9}')
                    sr2e2c_time=$(grep "2e2c SR integral" "$outfile" | awk '{print $8}' | tr -d '\n')  # prevent going to the next line
                    niters=$(grep -o "Energy components after cycle" "$outfile" | wc -l)

                    # If not found, set 2e3c time to 0
                    sr2e3c_cc_time=${sr2e3c_cc_time:-0}
                    sr2e3c_cd_time=${sr2e3c_cd_time:-0}

                    # Only write if all values are present
                    if [[ -n "$energy" && -n "$rij_time" && -n "$xc_time" ]]; then
                        echo "$omega,$grid,$supercell,$energy,$rij_time,$xc_time,$sr2e3c_cc_time,$sr2e3c_cd_time,$sr2e2c_time,$niters" >> "$output_csv"
                    else
                        echo "Warning: Missing data in $outfile" >&2
                    fi
                else
                    echo "Missing file: $outfile" >&2
                fi
            done
        done
    done
done

echo "Done. Output files written: data_ccpvdz.csv"

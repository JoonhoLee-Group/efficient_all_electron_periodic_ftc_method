#!/bin/bash

# Root directories
base_in="/n/home02/hieudinh/rsdf_test_full_J/input/si_supercell"
base_out="/n/home02/hieudinh/rsdf_test_full_J/output/si_supercell"
data_path="/n/home02/hieudinh/rsdf_test_full_J/post_process/si_supercell"

# Lists
basis_list=("ccpvdz") # ("ccpvtz" "ccpvqz")
omega_list=("0.3" "0.6" "0.9")
cell_list=("111" "222" "333" "444") # supercell list
grid_list=("111")              # grid list

# ---- Helpers ----
sum_mem_gb () {
  # Sum all "Static memory requirement for 2e3c SR integrals: <num> GB" in a file
  # Prints the numeric sum (GB). Returns 0 even if nothing found (sum=0).
  local f="$1"
  LC_ALL=C awk -F': ' '
    $0 ~ /^Static memory requirement for 2e3c SR integrals:/ {
      val = $2
      sub(/[[:space:]]*GB.*/,"", val)   # strip trailing "GB" and anything after
      gsub(/[[:space:]]/,"", val)       # trim spaces
      if (val ~ /^[0-9]+(\.[0-9]+)?$/) sum += val
    }
    END { printf("%.6f\n", (sum==""?0:sum)) }
  ' "$f" 2>/dev/null || echo "0"
}

# ---- Main loop ----
for basis in "${basis_list[@]}"; do
    # CSV file for the memory
    output_csv="${data_path}/memory_${basis}_2.csv"
    echo "Omega,Cell,StaticMem(GB)" > "$output_csv"
    for grid in "${grid_list[@]}"; do
        for omega in "${omega_list[@]}"; do
            for cell in "${cell_list[@]}"; do

            # output qcpbc file
            outfile="${base_out}/si_${cell}/si_${cell}_${basis}_omega_${omega}_${grid}_2.out"
            echo "Processing file: ${outfile}"
            # Parse and sum memory from the outfile
            total_gb="$(sum_mem_gb "${outfile}")"

            # Append to CSV
            echo "${omega},${cell},${total_gb}" >> "${output_csv}"

            echo " -> Total static memory (GB): ${total_gb}"
            done
        done
    done
done

# echo "Done. Output files written: memory_ccpvdz.csv"

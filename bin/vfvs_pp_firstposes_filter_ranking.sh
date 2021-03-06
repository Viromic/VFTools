d#!/usr/bin/env bash
usage="vfvs_pp_firstposes_filter_ranking.sh <ranking file> <energie file> <max obabel energy> <collection regex> <output filename>

The ranking file needs to have in
    column 1: the collection name
    column 2: the ligand name
    column 3: the score
    
The energy file needs to have in
    column 3: the energy
"

# Standard error response 
error_response_std() {
    echo "Error was trapped" 1>&2
    echo "Error in bash script $(basename ${BASH_SOURCE[0]})" 1>&2
    echo "Error on line $1" 1>&2
    echo "Exiting."
    exit 1
}
trap 'error_response_std $LINENO' ERR

clean_up() {
    # rm .winner.temp 1>/dev/null 2>&1 || true
    echo
}
trap 'clean_up' EXIT

# Checking the input paras
if [ "${1}" == "-h" ]; then
    echo -e "\n${usage}\n\n"
    exit 0
fi
if [ "$#" -ne "5" ]; then
    echo -e "\nWrong number of arguments. Exiting.\n"
    echo -e "${usage}\n\n"
    exit 1
fi

# Printing some information
echo
echo
echo "*********************************************************************"
echo "                       Ranking the first poses                       "
echo "*********************************************************************"
echo

# Variables
ranking_filename=${1}
energy_filename=${2}
max_energy=${3}
grep_regex="${4}"
output_filename=${5}

# Main
if [ -f ${output_filename} ]; then
    echo " * The outputfile ${output_filename} does already exist. Overwriting..."
    >${output_filename}
fi

# Applying the collection regular expression
echo " * Filtering the poses using the provided collection regular epression."
grep -E "${grep_regex}" ${ranking_filename}  > ${output_filename}.tmp || true

echo " * Filtering the poses bases on the provided energies."
for ligand in $(awk '{print $2}' ${output_filename}.tmp); do
    echo -e "\n * Processing ligand ${ligand}"
    energy=$(grep $ligand ${energy_filename} | awk '{print $3}')
    if (( $(echo "${energy} <= ${max_energy}" | bc -l) )); then
        echo " * Energy (${energy}) below maximum value (${max_energy}). Accepting the ligand ${ligand}."
        collection=$(grep $ligand ${ranking_filename} | awk '{print $1}')
        score=$(grep $ligand ${ranking_filename} | awk '{print $3}')
        printf "%-12s %s %6s %20s\n" $collection $ligand $score $energy >> ${output_filename}
    else
        echo " * Energy (${energy}) above maximum value (${max_energy}). Filtering out ligand ${ligand}"  
    fi
done

rm ${output_filename}.tmp

echo -e "\n * The filtering of the poses has been completed.\n\n"

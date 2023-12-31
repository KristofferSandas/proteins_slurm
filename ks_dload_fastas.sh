#!/bin/bash

# As I understand this, I have requested 10 nodes for a job array with ten slots in the array. 
# So one node per array slot.
# Each node performs one task at a time and each task uses one cpu.
# The instances from the while loop that calls the function on each ID in the file
# are automatically assigned to an array slot by slurm.
# As soon as one job is finished, meaning one ID is requested from UniProt, the following 
# ID is added to that array slot.
# The function checks if the file corresponding to an ID already exists, in which case it skips to the next.

# The function and while loop works locally with the test file of 10 lines. Also works on the server,
# but I have no idea if it actually interacts with slurm or where/when it is run.

# Does this work?
# When i run my full file with 5000 lines of protein IDs, should I specify as large an array as possible?
# Im not getting an output file but the echo "Download complete." is printed to stdout. 
# Does this mean im not using slurm at all?

#SBATCH -A naiss2023-5-303
#SBATCH --job-name=ks_dload_fastas_TEST
#SBATCH --output=/proj/tbio/users/x_krsan/slurm_outs_and_errs/ks_dload_fastas_TEST_%A_%a.out
#SBATCH --error=/proj/tbio/users/x_krsan/slurm_outs_and_errs/ks_dload_fastas_TEST_%A_%a.err
#SBATCH --nodes=10
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=10:00
#SBATCH --array=1-10

DOWNLOAD_FOLDER="/proj/tbio/users/x_krsan/benchmrk_fastas"

# Function to download a single fasta
download_fasta() {
    UNIPROT_ID=$1
    OUTPUT_FILE="${DOWNLOAD_FOLDER}/${UNIPROT_ID}.fasta"

    # Check if the file already exists. Skip if it does.
    if [ -e "$OUTPUT_FILE" ]; then
        echo "Skipping ${UNIPROT_ID}.fasta. File already exists."
        return
    fi

    # curl the fasta from uniprot
    echo "Downloading ${UNIPROT_ID}..."
    curl -L "https://www.uniprot.org/uniprot/${UNIPROT_ID}.fasta" -o "$OUTPUT_FILE"

    # Check if the downloaded file is empty or not a valid FASTA file
    if [ ! -s "$OUTPUT_FILE" ]; then
        echo "WARNING: ${UNIPROT_ID}.fasta is empty."
    elif ! grep -q "^>" "$OUTPUT_FILE"; then
        echo "WARNING: ${UNIPROT_ID}.fasta does not start with a FASTA header."
    fi
}

export -f download_fasta

# Read protein IDs from txt file and download FASTA sequences (in parallel?)
while read -r UNIPROT_ID; do
    download_fasta "$UNIPROT_ID" &
done < prot_ids_newline_sep_TEST.txt

# wait for all processes to finish
wait

echo "Download complete."

## Concatenate all phenotype tables produced by Pantry into one, along with a
## groups file that specifies all phenotypes per gene as one group. This allows
## for special downstream analyses such as QTL mapping that reports
## conditionally independent QTLs per gene even across modalities.
##
## Usage: bash scripts/combine_modalities.sh alt_polyA alt_TSS expression isoforms splicing stability
##
## Outputs: output/all.bed.gz, output/all.bed.gz.tbi, output/all.phenotype_groups.txt
##
## The phenotype names are modified by prepending '{modality}:' so they are
## unique and so their modalities can be recovered. After running, add 'all' as
## a modality in the Pheast config and generate QTLs for it.

if [ "$#" -lt 1 ]; then
    echo "Usage: bash scripts/combine_modalities.sh alt_polyA alt_TSS expression isoforms splicing stability"
    exit 1
fi

## Combine all bed files:
# First confirm that all bed files have the same header:
for modality in "$@"; do
    diff <(zcat output/$1.bed.gz | head -n 1) <(zcat output/$modality.bed.gz | head -n 1)
done
for modality in "$@"; do
    echo $modality
    # Prepend modality name to phenotype names:
    zcat output/$modality.bed.gz | tail -n+2 | awk -v OFS='\t' '{$4 = "'$modality':"$4; print}' >> output/all_tmp.bed
done
zcat output/$1.bed.gz | head -n1 > output/all.bed
sort -k1,1 -k2,2n output/all_tmp.bed >> output/all.bed
rm output/all_tmp.bed
bgzip output/all.bed
tabix -p bed output/all.bed.gz

## Make phenotype_groups file:
zcat output/all.bed.gz | tail -n+2 | cut -f4 | awk -F'[:.]' '{print $0"\t"$2}' > output/all.phenotype_groups.txt

def groups_arg(wildcards, input):
    """Pass the phenotype groups file as a Python arg if applicable"""
    if phenotypes[wildcards.pheno]['grouped']:
        return f'--groups {input.groups}'
    else:
        return ''

def groups_input(wildcards):
    """Include the phenotype groups file as an input if applicable"""
    if phenotypes[wildcards.pheno]['grouped']:
        return pheno_dir / f'{wildcards.pheno}.phenotype_groups.txt'
    else:
        return []

rule tensorqtl_perm:
    """Map cis-QTLs, determining significance using permutations.
    Outputs the top association per phenotype.
    """
    input:
        geno = multiext(geno_prefix, '.bed', '.bim', '.fam'),
        bed = pheno_dir / '{pheno}.bed.gz',
        bedi = pheno_dir / '{pheno}.bed.gz.tbi',
        covar = interm_dir / 'covar' / '{pheno}.covar.tsv',
        groups = groups_input,
    output:
        output_dir / 'qtl' / '{pheno}.cis_qtl.txt.gz',
    params:
        geno_prefix = geno_prefix,
        qtl_dir = output_dir / 'qtl',
        groups_arg = groups_arg,
    resources:
        walltime = 12,
        partition = '--partition=gpu',
    shell:
        ## Cluster environments may require cuda to be loaded, e.g.:
        # module load cuda
        """
        mkdir -p {params.qtl_dir}
        python3 scripts/run_tensorqtl.py \
            {params.geno_prefix} \
            {input.bed} \
            {output} \
            --covariates {input.covar} \
            {params.groups_arg} \
            --mode cis
        """

rule tensorqtl_independent:
    """Use stepwise regression to identify multiple conditionally independent cis-QTLs per phenotype."""
    input:
        geno = multiext(geno_prefix, '.bed', '.bim', '.fam'),
        bed = pheno_dir / '{pheno}.bed.gz',
        bedi = pheno_dir / '{pheno}.bed.gz.tbi',
        covar = interm_dir / 'covar' / '{pheno}.covar.tsv',
        groups = groups_input,
        cis = output_dir / 'qtl' / '{pheno}.cis_qtl.txt.gz',
    output:
        output_dir / 'qtl' / '{pheno}.cis_independent_qtl.txt.gz',
    params:
        geno_prefix = geno_prefix,
        groups_arg = groups_arg,
    resources:
        walltime = 20,
        partition = '--partition=gpu',
    shell:
        ## Cluster environments may require cuda to be loaded, e.g.:
        # module load cuda
        """
        python3 scripts/run_tensorqtl.py \
            {params.geno_prefix} \
            {input.bed} \
            {output} \
            --covariates {input.covar} \
            --cis_output {input.cis} \
            {params.groups_arg} \
            --mode cis_independent
        """

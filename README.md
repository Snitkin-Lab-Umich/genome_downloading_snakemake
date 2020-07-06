# Snakemake pipeline to download genomes from NCBI using Biosample Accession Numbers and fasterq-dump

Written by Sophie Hoffman & Zena Lapp

## Useful links:
- [NCBI website](https://www.ncbi.nlm.nih.gov/)
- [SRA number information](https://www.ncbi.nlm.nih.gov/sra/docs/)
- [Biosample Accession Number information](https://www.ncbi.nlm.nih.gov/biosample/docs/submission/faq/)

## Fasterq-dump and NCBI
### Preparation
NCBI API Key:
- An API key is necessary if you are downloading a large number of genomes.
- To get an API key, register for an NCBI account [here](https://www.ncbi.nlm.nih.gov/account/?back_url=https%3A%2F%2Fwww.ncbi.nlm.nih.gov%2Fmyncbi%2F). Go to the "Settings" page in your account, then click "Create an API Key" under "API Key Management".
- To use the API key, create an environment variable called `ENTREZ_KEY` in your `~/.bashrc`, ex. `ENTREZ_KEY={your key}`.

Caching: 
- NCBI caches data in your home directory by default, so if you are downloading a large amount of data you'll want to change the cache location to scratch instead.
- Information on how to do that is [here](https://github.com/ncbi/sra-tools/wiki/03.-Quick-Toolkit-Configuration) or you go into your `~/.ncbi/user-settings.mkfg` file and edit the `/repository/user/default-path = "/home/uniquename/ncbi"` line by replacing `"/home/uniquename/ncbi"` with a path to your desired scratch location.  

### Downloading genomes with fasterq-dump
- Fasterq-dump uses an SRA number to find a genome in the NCBI database to download. The following command shows how to download a single genome from a single SRA number (-O specifies the output file location).
```
/nfs/esnitkin/bin_group/sratoolkit.2.9.1-1-centos_linux64/bin/fasterq-dump {SRA number} -O output_files
```  
  
- I recommend making an alias in your `~./bashrc` for fasterq-dump so that you don't need to use the file path every time.
- If you don't have an SRA number but only have a Biosample Accession Number then you can use the following command to find the SRA number associated with that Biosample number.
```
esearch -db sra -query {Biosample number} </dev/null | efetch -format docsum | xtract -pattern Runs -element Run@acc
```  
- You could combine these two commands to download a genome directly from its Biosample Accession Number, but not all SRA numbers have one unique Biosample Accession Number. Therefore we have to separate our workflow into three parts:
  1. Get the SRA number(s) for each Biosample number
  2. Create a reference file of SRA to Biosample Accession Numbers and a list of the SRA numbers 
  3. Download the genomes associated with each SRA number 
- We have lots of genomes to download, which could be done in a loop, but snakemake can run the jobs in parallel which is especially helpful for steps 1 and 3.

## Benefits of snakemake

- Your analysis is reproducible.
- You don't have to re-perform computationally intensive tasks early in the pipeline to change downstream analyses or figures.
- You can easily combine shell, R, python, etc. scritps into one pipeline.
- You can easily share your pipeline with others.
- You can submit a single slurm job and snakemake handles submitting the rest of your jobs for you.

## Download this repo

First, go to the directory where you want to dowload the repo to. We recommend a directory in scratch because these files take up a lot of space. 
Next, run the following command:
```
git clone https://github.com/Snitkin-Lab-Umich/genome_downloading_snakemake.git #verify this??
```

## Conda

To [download miniconda](https://docs.conda.io/en/latest/miniconda.html) for linux if you don't already have it:
```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-MacOSX-x86_64.sh
```

To create and activate the conda environment:
```
conda env create -f download_genomes.yaml # you only have to do this once
conda activate download_genomes # you have to do this every time 
```

## Running the genome downloading snakemake pipeline on the cluster

To run the ARIBA snakemake pipeline on the cluster, you have to:
- Modify your email address in `download_genomes.sbat` and `config/slurm/cluster.yaml`.
- Substitute your list of Biosample Accession Numbers for the PATRIC_Biosample_accession_nums in the snakemake_f1 file.

Then run:
```
conda activate download_genomes # if you're not already in the download_genomes conda environment
sbatch download_genomes.sbat
```

You can check your job using:
```
squeue -u UNIQNAME
```

The pipeline outputs:
- A folder called refs which should contain files whose names match the Biosample Accession Numbers specified and whose contents are the associated SRA numbers. 
- R output matching the format of the example_R_output ?? folder
- A folder called downloaded_genomes (change this to match) which contains the forward and backward reads for each SRA number. 


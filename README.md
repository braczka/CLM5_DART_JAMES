# CLM5_DART_JAMES
Includes CLM5_DART setup scripts used to perform the simulation within Raczka et al., (2021) https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2020MS002421

Here I have provided the DART scripts (`CLM5_setup_assimilation`, `assimilate.csh` `input.nml`) that were used to create the Western US assimilation runs within the Raczka et al., (2021) JAMES manuscript.  These scripts are compatible with the git branch `cesm_clm` with the repository https://github.com/NCAR/DART_CLM run with cesm version 2.0 (cesm2.0).

After the mansucript publication there has been an effort to merge CLM DART code development within the https://github.com/NCAR/DART_CLM repository to the core DART repository https://github.com/NCAR/DART.  This merge and code development included changes for the latest cesm release (cesm2.2).  

At present (1/21/22) the tag `clm-swe_pre-release` within https://github.com/NCAR/DART is the most recent validated release for CLM5-DART assimilation work.  The   
DART scripts (`CLM5_setup_assimilation`, `assimilate.csh`, `input.nml`) to reproduce the assimilations in Raczka et al., (2021), have been updated, and tested with this latest tag. 

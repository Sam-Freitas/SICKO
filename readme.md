# SICKO - _**S**ystematic **I**maging of **C**. elegans **K**illing **O**rganisms_

## [paper published here](https://elifesciences.org/reviewed-preprints/102518v1)

![default_img](https://github.com/Sam-Freitas/SICKO/blob/main/header_img.png)

###### Developed by [Samuel Freitas](https://github.com/Sam-Freitas), [Luis Espejo](https://github.com/lespejo1990), and [George Sutphin (PI)](https://mcb.arizona.edu/profile/george-sutphin) at the [University of Arizona](https://mcb.arizona.edu/)

This repository is a complete data computation and analysis package for the SICKO -- Patent pending -- system.

SICKO was initially developed to quantitatively analyze infection progression of fluorescently tagged E. coli and P. aeruginosa in a C. elegans system, consequently SICKO can analyze any fluorescent-type signal in a longitudinal analysis of C. elegans

For the post processing scripts please see [the Full statistical analysis and Figure production](https://github.com/lespejo1990/SICKO_Analysis) -- [https://github.com/lespejo1990/SICKO_Analysis](https://github.com/lespejo1990/SICKO_Analysis)

## Preprint/Paper

[Read our paper here -- https://elifesciences.org/reviewed-preprints/102518v1](https://elifesciences.org/reviewed-preprints/102518v1)

[Read our preprint here -- https://www.biorxiv.org/content/10.1101/2023.02.17.529009v2](https://www.biorxiv.org/content/10.1101/2023.02.17.529009v2)

## Features

- Invidiualized longitudinal analysis of infected C. elegans
- Automatic comparison and analysis
- Automatic Heatmap creation

## Usage

The basic steps of using SICKO are:

1) SICKO ------- SICKO_2022.m
    - Explanation: A Full GUI for selecting and censoring the fluorescent data
    - Usage: Full usage breakdown in the SICKO "Protocol.pdf" in the scripts folder
        - Output(s): many csv(s) in each individual folder each representing a single days worth of data for each of the experiment subsections (plates) or groups of images

2) combine ----- combine_csv.m
    - Explanation: Combines the many csv(s) from all(any of) the replicates into a single csv file for further processing; furthermore, associates all metadata (area,intensity,dead,fled) with the specific animal
    - Usage: When ran, select the experiments folder that contains the experiemntal replicate(s)
        - Output(s): a single csv in the 'outputs' folder titled 'experiment_name_N.csv'

3) compile ----- compile_data.m
    - Explanation: Compiles the data from the 'experiment_name_N.csv' into a single longitudinal based array for each specific animal
    - Usage: When ran, select the 'experiment_name_N.csv'
        - Output(s): a single csv in the 'outputs' folder titled 'experiment_name_N_compiled.csv'

4) analyze ----- analyze_data_heatmap.m
    - Explanation: Data analysis for the compiled data, and implementation of the 'SICKO coefficient' for deatn incorporation in logitudinal studies
    - Usage: When ran, select the 'experiment_name_N_compiled.csv'
    - if SICKO coefficient is to be used, select 'yes' on the next window and enter the associated numbers with the experiment
        - Output(s): a single csv in the 'outputs' folder titled 'experiment_name_N_compiled_analyzed.csv'
        - the cumulative sum and heatmap data graphs (with and without SICKO coefficient if 'yes' selected, otherwise just standard outputs)

### File setup

![Example_file_setup.png](https://github.com/Sam-Freitas/SICKO/blob/main/example_data_setup.png)


## Required Packages

- MATLAB 2020+
- Image processing toolbox

## Installation (github desktop)

- copy this URL

 ```
 https://github.com/Sam-Freitas/SICKO
 ```

- Go to File>Clone repository (Ctrl+Shift+O)
- On the top bar click on the URL tab
- Paste the previously copied URL and click 'Clone'

## Installation (git)

```sh
cd Documents
git clone https://github.com/Sam-Freitas/SICKO
```

## Common errors that crop up

- "erase" or any error during combine_csv.m
  - Make sure that there are the correct amount of csvs (6) for the associated conditions*days
  - Delete the extra csvs or make sure that you ran the SICKO script on all the data
  - Extra csvs can crop up when incorrect folders are present
- Heatmap only showing one (or just a few) of the data points
  - One (or a few) of the data points might have not been censored when necessary
  - You can manually find the **non-matching** data using the compiled csv
  - Once identified find the corresponding censor.csv and rerun the combine/compile/analyze scripts

## Example data (publication coming soon)

![default_img2](https://github.com/Sam-Freitas/SICKO/blob/main/example_data_graph.png)

![default_img3](https://github.com/Sam-Freitas/SICKO/blob/main/example_data_heatmap.png)

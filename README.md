# winsorization
- paper_being_winsorized directory contains all the replicated paper that using winsorization
  - Seasonal Liquidity, Rural Labor Markets, and Agricultural Production is from 2020
    - the reproduce.R in the folder contains the reporduced code

  - Market Power and Innovation in the Intangible Economy is from 2024
    - the reproduce.R in the folder contains the reproduced code

  - The Economic Impact of Depression Treatment in India- Evidence from Community-Based Provision of Pharmacotherapy
    is from 2024
    - The reproduce.R in the folder contains the reproduced code
    - the plot folder contains the plots that showing the percentile of winsorization is choosen to maximize the significance level

- way of checking for winsorization:
  - check the following tuple of words or regex in a sentence: [("winsorization", "%"), ("winsorized", "%"), ("winsorizing", "%"), ("winsor", "%"),
       ("trimmed", "%"), ("trimming", "%"), ("winsorization", "percent"), ("winsorized", "percent"),
       ("winsorizing", "percent"), ("winsor", "percent"), ("trimmed", "percent"), ("trimming", "percent"),
       ("winsorized", r"\b\d+\b", second_regex), ("winsorizing", r"\b\d+\b", second_regex),
       (r"\btrimmed\b", r"\b\d+\b", first_regex, second_regex), (r"\btrimming\b", r"\b\d+\b", first_regex, second_regex),
      ("winsorize", r"\b\d+\b", second_regex), (r"\btrim\b", r"\b\d+\b", first_regex, second_regex),
                     ("winsorizing", "extreme"), ("trimming", "extreme"), ("winsorized", "extreme"),
                     ("trimmed", "extreme"), ("winsorizing", "outlier"), ("winsorized", "outlier"),
                     ("trimmed", "outlier"), ("trimming", "outlier")
       ] 

- way of checking for empirical:
  -  check the following tuple of words or regex in a sentence: [("data", "descriptive"), ("data", "administrative"), ("data", "survey"), ("data", "summary statistics"),
         ("data", "table"), ("data", "figure")]
  
- In the code folder:
    - analysis_after_2022.py:
        - How to use:
            - Run check_winsorization_and_empirical(input_file, output_file)
            - input_file = file_produced from the download_articles_after_2022.py
        - output_file = file you want to created
        - full text is extracted from the pdf using PdfReader

    - analysis_helper.py:
        - 3 different ways of searching words
        - the constant contains the words and regex to check for using_winsorization and is_empirical respectively

    - analysis_Jstor.py:
        - Change the output file directory and run the file 
        - analyze the paper before 2023 and back to 1900s
        - output All_AER_articles.xlsx

    - create_request_list_from_Jstor.py:
        - create a list of ids that send to the Jstor: ids_to_Jstor.txt
        - create a set contains all information: AER_all_articles.txt
        - How to Use:
            - change the name of the output file and run the file
        - uses the json file from https://www.jstor.org/ta-support and create an item list that 
        sent back to Jstor, then we would have full text data

    - download_articles_after_2022.py is to download all the paper from AER after 2022 
        - Need to download the metadata from AER website: https://www.aeaweb.org/journals/articles/sgml?journal=1
        - Automated the downloading through opening each of the url and manually click download.

    - clt_failed.py:
        - example of the failure of Central limit theorem based t test when it has heavy tail distribution.

    - function_in_muller_remark_1.py:
        - reproduced the function in https://www.princeton.edu/~umueller/sumrates.pdf.

    - theory_test_population_mean_at_population_quantile_using_density_estimation.py:
        - Using density estimation and bootstrapped methods for estimating the adjusted standard error for CLT T test.
        - For Pareto and T distribution.

    - theory_test_population_mean_at_sample_quantile.py:
        - T test for the population at the sampled winsorized level.

    - theory_test_population_mean_at_sample_quantile_power.py:
        - T test for the population at the sampled winsorized level, measured by power.

    - time_series_plot.R:
        - produce a plot for proportion of using winsorization over the years
    
    - non_parametric folder:
        - contains the plot generated from theory_test_population_mean_at_population_quantile_using_density_estimation.py
    
    - population_mean_sample_quantile:
        - contains the plot for theory_test_population_mean_at_sample_quantile.py
    
    - power:
        - contains the plot for theory_test_population_mean_at_sample_quantile_power.py

- time_series_plot_for_presenting folder:
    - csv file for each years being winsorized
    - scatter plot for presentation
    - code for producing the plot
    

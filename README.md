# winsorization
The code folder contains 5 work
- create_request_list_from_Jstor.py is to get all the paper from AER before 2022
  - create_request_list_from_Jstor.py uses the json file from https://www.jstor.org/ta-support and create an item list that 
    sent back to Jstor, then we would have full text data
- download_articles_after_2022.py is to download all the paper from AER after 2022 
  - Required to download the metadata from AER website
  - Automated the downloading through opening each of the url and manually click download
 
- time_series_plot.R is to produce a propotion of winsorization over the years, data are not reliable though
- analysis_Jstor.py is to analysis the paper before 2023 and back to 1900s 
  - full text is extracted from the pdf using PdfReader
  - use key word checking to check whether paper is being winsorized and is empirical
- analysis_after_2022.py
  - full text is returned by Jstor
  - using key word checking to check whether paper is being winsorized and is empirical

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
  
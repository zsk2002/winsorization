import gzip
import json
from pathlib import Path
import pandas as pd
import ast
from analysis_helper import *

# it is the file from the Jstor contains the paper before 2022
path = Path("winsorization_data/raw data/2b51d731-4b8e-44eb-b7ba-3ca54f2e406c.jsonl.gz") # fixed

rows = []
with gzip.open(path, "rt", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        rows.append(json.loads(line))

all_jstor_articles_before_2022 = pd.DataFrame(rows)
all_jstor_articles_before_2022 = all_jstor_articles_before_2022.rename(
    columns={"iid": "item_id"}
)


Jstor_id = "winsorization_data/AER_2022_articles_and_before/AER_all_articles.txt" # fixed, IDS TO SENT TO JSTOR

records = []
with open(Jstor_id, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        records.append(ast.literal_eval(line))   # converts string dict -> Python dict

all_jstor_articles_before_2022_id = pd.DataFrame(records)


merged = pd.merge(
    all_jstor_articles_before_2022,
    all_jstor_articles_before_2022_id,
    on="item_id",
    how="inner",
    suffixes=("_gz", "_txt")
)

# original way of checking winsorization
# using_winsorization = ["winsorization", "winsorized", "winsorizing", "winsor", "trimmed", "trimming",]  # example, replace with your own
# merged["using_winsorization_1"] = merged["full_text"].apply(
#     lambda text: find_key_words(using_winsorization, text)
# )

# most recent way of winsorization
merged['using_winsorization'] = merged["full_text"].apply(
    lambda text: find_key_words_in_one_sentence(
        CHECK_WINSORIZATION, text)
)

# original way of checking is empirical
# merged["is_empirical_1"] = merged["full_text"].apply(
#     lambda text: find_key_words_conditioned(['data'],
#                                             ["descriptive", "relationship", "regression", "coefficient", "design", "administrative",
#      "survey", "summary statistics"],
#                                             text)
# )

merged["is_empirical"] = merged["full_text"].apply(
    lambda text: find_key_words_in_one_sentence(
        CHECK_WINSORIZATION,text))

# filter out the articles that is not research articles
merged = merged[merged["content_subtype"] == "research-article"]
merged = merged.sort_values(by="published_date")
merged.to_excel("winsorization_data/AER_2022_articles_and_before/All_AER_articles.xlsx") # to change, output file



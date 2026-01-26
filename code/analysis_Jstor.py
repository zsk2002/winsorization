import gzip
import json
from pathlib import Path
import pandas as pd
import ast
from analysis_helper import *
import re
second_regex = 1
first_regex = 1

path = Path("/Users/zhushangkai/Desktop/winsorization_data/raw data/2b51d731-4b8e-44eb-b7ba-3ca54f2e406c.jsonl.gz")

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


old_path = "/Users/zhushangkai/Desktop/winsorization_data/AER_2022_articles_and_before/AER_all_articles.txt"

records = []
with open(old_path, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        records.append(ast.literal_eval(line))   # converts string dict -> Python dict

all_jstor_articles_before_2022_info = pd.DataFrame(records)


merged = pd.merge(
    all_jstor_articles_before_2022,
    all_jstor_articles_before_2022_info,
    on="item_id",
    how="inner",
    suffixes=("_gz", "_txt")
)
# text = merged.loc[
#     merged["item_id"] == "f0c025b6-7213-3de8-a711-41ba6e49e8c8",
#     "full_text"
# ].iloc[0]
#
# a = find_key_words_in_one_sentence(CHECK_WINSORIZATION,
#                                            text)
# print(a)


using_winsorization = ["winsorization", "winsorized", "winsorizing", "winsor", "trimmed", "trimming",]  # example, replace with your own

merged["using_winsorization_1"] = merged["full_text"].apply(
    lambda text: find_key_words(using_winsorization, text)
)
second_regex = 1
merged['using_winsorization_2'] = merged["full_text"].apply(
    lambda text: find_key_words_in_one_sentence(
        CHECK_WINSORIZATION,
                                           text)
)


merged["is_empirical_1"] = merged["full_text"].apply(
    lambda text: find_key_words_conditioned(['data'],
                                            ["descriptive", "relationship", "regression", "coefficient", "design", "administrative",
     "survey", "summary statistics"],
                                            text)
)

merged["is_empirical_2"] = merged["full_text"].apply(
    lambda text: find_key_words_in_one_sentence(
       [
           ("data", "descriptive"), ("data", "administrative"), ("data", "survey"), ("data", "summary statistics"),
           ("data", "table"), ("data", "figure"),("statistics", "table")
       ],
                                           text)
)

merged = merged[
    merged["content_subtype"] == "research-article"
]
merged = merged.sort_values(by="published_date")
merged.to_excel("/Users/zhushangkai/Desktop/winsorization_data/AER_2022_articles_and_before/All_AER_articles_2.xlsx")

# aer_1918 = merged[merged["published_date"].astype(str).str.contains("1918")]
#
# aer_1918.to_excel("/Users/zhushangkai/Desktop/winsorization_data/AER_1918.xlsx")

# cols_to_keep = ["item_id", "using_winsorization", "is_empirical","published_date", "ithaka_doi"]
#
# winsorized = (
#     merged
#     .loc[merged["using_winsorization_1"] == 1, cols_to_keep]
#     .sort_values("published_date")  # ascending by default
# )
#
# winsorized.to_excel(
#     "/Users/zhushangkai/Desktop/winsorization_data/AER_2022_articles_and_before/All_AER_articles_winsorized.xlsx",
#     index=False,
# )

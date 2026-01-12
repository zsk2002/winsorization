import gzip
import json
from pathlib import Path
import pandas as pd
import ast

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

def find_key_words(key_words, text) -> int:
    # Handle lists: join elements into one big string
    if isinstance(text, list):
        text = " ".join(str(part) for part in text)
    # Handle None/NaN and other non-strings
    elif not isinstance(text, str):
        if text is None:
            text = ""
        else:
            text = str(text)

    t = text.lower()
    return int(any(kw.lower() in t for kw in key_words))

def find_key_words_conditioned(condition_words: list, key_words: list, text: str) -> int:
    if isinstance(text, list):
        text = " ".join(str(part) for part in text)
    elif not isinstance(text, str):
        if text is None:
            text = ""
        else:
            text = str(text)
    if not isinstance(text, str):
        return 0

    t = text.lower()

    for cw in condition_words:
        if cw.lower() in t and any(kw.lower() in t for kw in key_words):
            return 1
    return 0

using_winsorization = ["winsorization", "winsorized", "winsorizing", "winsor", "trimmed", "trimming",]  # example, replace with your own

merged["using_winsorization"] = merged["full_text"].apply(
    lambda txt: find_key_words(using_winsorization , txt)
)





merged["is_empirical"] = merged["full_text"].apply(
    lambda txt: find_key_words_conditioned(['data'],
                                           ["descriptive", "relationship", "regression", "coefficient", "design", "administrative",
     "survey", "summary statistics"] ,
                                           txt)
)
merged.to_excel("/Users/zhushangkai/Desktop/winsorization_data/AER_2022_articles_and_before/All_AER_articles.xlsx")

cols_to_keep = ["item_id", "using_winsorization", "is_empirical","published_date", "ithaka_doi"]

winsorized = (
    merged
    .loc[merged["using_winsorization"] == 1, cols_to_keep]
    .sort_values("published_date")  # ascending by default
)

winsorized.to_excel(
    "/Users/zhushangkai/Desktop/winsorization_data/AER_2022_articles_and_before/All_AER_articles_winsorized.xlsx",
    index=False,
)

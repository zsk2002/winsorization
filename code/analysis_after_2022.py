from pathlib import Path
from pypdf import PdfReader
import re
import pandas as pd
from difflib import get_close_matches
from analysis_helper import *

def extract_text_from_pdf(pdf_path):
    pdf_path = Path(pdf_path)
    text = ""
    reader = PdfReader(str(pdf_path))
    for page in reader.pages:
       text = text + page.extract_text() + "\n" 
    return text


def remove_references(text: str) -> str:
    pat = re.compile(r"^(?:\s*)references\s*[:\-]?\s*$", re.IGNORECASE | re.MULTILINE)
    matches = list(pat.finditer(text))
    if not matches:
        return text
    cut = matches[-1].start()
    return text[:cut].rstrip()


def check_winsorization_and_empirical(input_excel, output_excel):
    df = pd.read_excel(input_excel)

    for idx, pdf_link in df['local_path'].items():
        if pd.isna(pdf_link) or not pdf_link:
            continue

        text = extract_text_from_pdf(pdf_link)
        text = remove_references(text)

        use_winsorization = find_key_words(
            ["winsorization", "winsorized", "winsorizing", "winsor", "winsorisation", "trimmed", "trimming"],
            text,
        )
        using_winsorization_2 = find_key_words_in_one_sentence(
        [("winsorization", "%"), ("winsorized", "%"), ("winsorizing", "%"), ("winsor", "%"),
         ("trimmed", "%"), ("trimming", "%"), ("winsorization", "percent"), ("winsorized", "percent"),
         ("winsorizing", "percent"), ("winsor", "percent"), ("trimmed", "percent"), ("trimming", "percent")
         ],
        text)


        is_empirical = find_key_words_conditioned(
            ["data"],
            ["descriptive", "relationship", "regression", "coefficient","design", "administrative",
                        "survey", "summary statistics"],
            text
        )
        is_empirical_2 = find_key_words_in_one_sentence(
            CHECK_EMPIRICAL,text)

        df.at[idx, "full_text"] = text
        df.at[idx, "using_winsorization_1"] = use_winsorization
        df.at[idx, "using_winsorization_2"] = using_winsorization_2
        df.at[idx, "is_empirical_1"] = is_empirical
        df.at[idx, "is_empirical_2"] = is_empirical_2


    df.to_excel(output_excel, index=False)

if __name__ == "__main__":

    # check_winsorization_and_empirical(
    # "/Users/zhushangkai/Desktop/winsorization_data/AER_2023_whole_lists.xlsx",
    # "/Users/zhushangkai/Desktop/winsorization_data/aer_2023_all_papers.xlsx",
    # )

    # check_winsorization_and_empirical(
    # "/Users/zhushangkai/Desktop/winsorization_data/AER_2024_whole_lists.xlsx",
    # "/Users/zhushangkai/Desktop/winsorization_data/aer_2024_all_papers.xlsx",
    # )

    # check_winsorization_and_empirical(
    # "/Users/zhushangkai/Desktop/winsorization_data/AER_2023_whole_lists.xlsx",
    # "/Users/zhushangkai/Desktop/winsorization_data/aer_2023_all_papers_2.xlsx",
    # )
    #
    # check_winsorization_and_empirical(
    # "/Users/zhushangkai/Desktop/winsorization_data/AER_2024_whole_lists.xlsx",
    # "/Users/zhushangkai/Desktop/winsorization_data/aer_2024_all_papers_2.xlsx",
    # )
    check_winsorization_and_empirical(
    "/Users/zhushangkai/Desktop/winsorization_data/AER_2025_whole_lists.xlsx",
    "/Users/zhushangkai/Desktop/winsorization_data/aer_2025_all_papers_5.xlsx",
    )

    # check_winsorization_and_empirical(
    #     "/Users/zhushangkai/Desktop/winsorization_data/AER_2024_whole_lists.xlsx",
    #     "/Users/zhushangkai/Desktop/winsorization_data/aer_2024_all_papers_3.xlsx",
    # )


# df = pd.read_excel("/Users/zhushangkai/Desktop/seasonal_liquidity/AER_2024/aer_2024_all_papers.xlsx")
#
#
# df_trim = df[df["using_winsorization_trimming"] == 1].copy()
#
# # quick sanity check
# print(df_trim.shape)
# print(df_trim[["title", "using_winsorization_trimming"]].head())
# out_path = "/Users/zhushangkai/Desktop/seasonal_liquidity/AER_2024/aer_2024_winsor_trim_only.xlsx"
# df_trim.to_excel(out_path, index=False)



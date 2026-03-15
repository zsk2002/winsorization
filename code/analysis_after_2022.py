from pathlib import Path
import pandas as pd
from PyPDF2 import PdfReader
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

        using_winsorization = find_key_words_in_one_sentence(CHECK_WINSORIZATION, text)
        is_empirical = find_key_words_in_one_sentence(CHECK_EMPIRICAL,text)

        df.at[idx, "full_text"] = text
        df.at[idx, "using_winsorization"] = using_winsorization
        df.at[idx, "is_empirical_1"] = is_empirical

    df.to_excel(output_excel, index=False)

if __name__ == "__main__":
    # input file is the output file from download_articles_after_2022.py
    check_winsorization_and_empirical(
    "/Users/zhushangkai/Desktop/winsorization_data/AER_2023_whole_lists.xlsx", # to change
    "/Users/zhushangkai/Desktop/winsorization_data/aer_2023_all_papers.xlsx", # to change
    )

    check_winsorization_and_empirical(
    "/Users/zhushangkai/Desktop/winsorization_data/AER_2024_whole_lists.xlsx", # to change
    "/Users/zhushangkai/Desktop/winsorization_data/aer_2024_all_papers.xlsx", # to change
    )
    check_winsorization_and_empirical(
    "/Users/zhushangkai/Desktop/winsorization_data/AER_2025_whole_lists.xlsx", # to change
    "/Users/zhushangkai/Desktop/winsorization_data/aer_2025_all_papers.xlsx", # to change
    )




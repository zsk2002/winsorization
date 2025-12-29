from pathlib import Path
from pypdf import PdfReader
import re
import pandas as pd
from difflib import get_close_matches

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


def find_key_words(key_words, text: str) -> int:
    t = text.lower()
    return int(any(kw.lower() in t for kw in key_words))

def tail_after_year(stem: str) -> str:
    # find the LAST "-YYYY-" occurrence (handles 2023/2024 etc.)
    hits = list(re.finditer(r"-(?:19|20)\d{2}-", stem))
    if not hits:
        return stem  # no year found; return full stem as fallback
    j = hits[-1].end()  # position after "-YYYY-"
    return stem[j:]

def normalize_title(s: str) -> str:
    # lower, remove non-alphanum, collapse whitespace
    s = s.lower()
    s = re.sub(r"[^a-z0-9\s]", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def batch_extract_pdf_dir(in_dir: str | Path, input_excel_path,
                          output_file_path: str | Path) -> None:
    in_dir = Path(in_dir).expanduser()
    pdfs = sorted(in_dir.glob("*.pdf"))

    df = pd.read_excel(input_excel_path)

    # prepare/clean title column once
    if "title cleaned" not in df.columns:
        df["title cleaned"] = (
            df["title"]
            .astype(str)
            .str.lower()
            .str.replace(r"[^a-z0-9\s]", " ", regex=True)
            .str.replace(r"\s+", " ", regex=True)
            .str.strip()
        )

    # make sure output columns exist
    for col in ["pdf_path", "using_winsorization", "using_regression"]:
        if col not in df.columns:
            df[col] = pd.NA

    print(f"Found {len(pdfs)} PDFs in {in_dir}")

    for k, pdf in enumerate(pdfs, start=1):
        print(k)
        stem = Path(pdf).stem  # filename without .pdf
        # try to cut leading year tokens like "...-2024-<title>"
        tail = tail_after_year(stem)
        norm_title = normalize_title(tail)

        # find exact match row(s)
        mask = df["title cleaned"] == norm_title
        idx = df.index[mask]

        # if no exact match, try a fuzzy fallback on close strings
        if len(idx) == 0:
            candidates = df["title cleaned"].tolist()
            nearest = get_close_matches(norm_title, candidates, n=1, cutoff=0.85)
            if nearest:
                idx = df.index[df["title cleaned"] == nearest[0]]


        if len(idx) == 0:
            print(f"[WARN] No match in Excel for PDF: {pdf.name}  -> cleaned='{norm_title}'")
            continue  # skip to next PDF

        # extract and analyze text
        text = extract_text_from_pdf(pdf)
        text = remove_references(text)

        use_winsorization = find_key_words(
            ["winsorization", "winsorized", "winsorizing", "winsor", "trimmed", "trimming", "drop"], text

        )
        use_regression = find_key_words(
            ["regression", "correlation"], text
        )

        # assign into the matched rows (usually 1)
        df.loc[idx, "pdf_path"] = str(pdf)
        df.loc[idx, "using_winsorization_trimming"] = use_winsorization
        df.loc[idx, "using_regression"] = use_regression

    df = df.loc[df["title cleaned"] != "front matter"].copy()

    # write out the updated sheet
    output_file_path = Path(output_file_path)
    # output_file_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_excel(output_file_path, index=False)

# batch_extract_pdf_dir("/Users/zhushangkai/Desktop/seasonal_liquidity/AER_2024_articles",
#                       "/Users/zhushangkai/Desktop/seasonal_liquidity/AER_2024/whole_list.xlsx",
#                       "/Users/zhushangkai/Desktop/seasonal_liquidity/AER_2024/whole_list_automatic_labled_use_trimmed_winsored_drop.xlsx")

def analysis_pdf(input_excel, output_excel):
    df = pd.read_excel(input_excel)
    for col in ["using_winsorization", "using_regression", "is_empirical"]:
        if col not in df.columns:
            df[col] = pd.NA

    for idx, pdf_link in df['local_path'].items():
        if pd.isna(pdf_link) or not pdf_link:
            continue

        text = extract_text_from_pdf(pdf_link)
        text = remove_references(text)


        use_winsorization = find_key_words(
            ["winsorization", "winsorized", "winsorizing", "winsor", "winsorisation", "trim"],
            text,
        )
        use_regression = find_key_words(
            ["regression", "correlation"],
            text,
        )

        is_empirical = find_key_words(
            ["data"],
            text
        )


        df.at[idx, "using_winsorization"] = use_winsorization
        df.at[idx, "using_regression"] = use_regression
        df.at[idx, "is_empirical"] = is_empirical

    # columns_to_keep = ['doi', 'pdf_url','local_path', 'using_winsorization', 'using_regression']
    df.to_excel(output_excel, index=False)

if __name__ == "__main__":

    analysis_pdf(
    "/Users/zhushangkai/Desktop/winsorization_data/AER_2023_whole_lists.xlsx",
    "/Users/zhushangkai/Desktop/winsorization_data/aer_2023_all_papers.xlsx",
    )

    analysis_pdf(
    "/Users/zhushangkai/Desktop/winsorization_data/AER_2024_whole_lists.xlsx",
    "/Users/zhushangkai/Desktop/winsorization_data/aer_2024_all_papers.xlsx",
    )

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



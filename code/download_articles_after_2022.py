import pandas as pd
from bs4 import BeautifulSoup
import os
import re
from playwright.sync_api import sync_playwright
import time

def read_sgml_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
        soup = BeautifulSoup(content, 'html.parser')
        return soup

def get_pdf_urls(df):
    df['pdf_url'] = "https://pubs.aeaweb.org/doi/pdfplus/" + df['doi'].astype(str)
    return df

def remove_front_matter(df):
    # remove the paper without an abstract
    # df = df[df['abstract'].notna() & (df['abstract'].str.strip() != '')]
    df = df[df['document_type'] == "Articles"]
    return df


def extract_from_sgml(sgml_directory):
    df = read_all_sgml_file(sgml_directory)
    df = get_pdf_urls(df)
    df = remove_front_matter(df)
    return df


def parse_articles(soup):
    articles_data = []
    
    for head in soup.find_all('head'):
        artinfo = head.find('artinfo')
        if artinfo:
            authors = []
            for au in artinfo.find_all('au'):
                gnm = au.find('gnm')
                snm = au.find('snm')
                aff = au.find('aff')
                full_name = f"{gnm.text} {snm.text}" if gnm and snm else None
                affiliation = aff.text if aff else None
                authors.append({'name': full_name, 'affiliation': affiliation})

            articles_data.append({
                'title': artinfo.find('ti').text if artinfo.find('ti') else None,
                'document_type': head.find('docty').text if head.find('docty') else None,
                'authors': authors,
                'start_page': artinfo.find('ppf').text if artinfo.find('ppf') else None,
                'end_page': artinfo.find('ppl').text if artinfo.find('ppl') else None,
                'abstract': artinfo.find('ab').text if artinfo.find('ab') else None,
                'doi': artinfo.find('doi').text if artinfo.find('doi') else None,
                'article_url': artinfo.find('art_url').text if artinfo.find('art_url') else None,
                'dataset_url': artinfo.find('dataset').text if artinfo.find('dataset') else None,
            })

    return pd.DataFrame(articles_data)


def read_all_sgml_file(dir_path):
    all_dfs = []

    for name in sorted(os.listdir(dir_path)):
        if not name.lower().endswith(".sgml"):
            continue
        full_path = os.path.join(dir_path, name)
        docs = read_sgml_file(full_path)
        df = parse_articles(docs)
        all_dfs.append(df)
    return pd.concat(all_dfs, ignore_index=True)


def clean_title(t):
    t = t.lower()
    t = re.sub(r'[^a-z0-9]+', '-', t)
    return t.strip('-')

def get_pdf(df, save_dir):
    urls = df['pdf_url'].tolist()
    titles = df['title'].tolist()
    if "local_path" not in df.columns:
        df["local_path"] = None

    file_paths = []
    os.makedirs(save_dir, exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        ctx = browser.new_context(accept_downloads=True)
        page = ctx.new_page()

        idx = 0
        for pdf_url, pdf_title in zip(urls, titles):

            new_title = clean_title(pdf_title)
            file_path = f"{save_dir}/{new_title}.pdf"

            if os.path.exists(file_path):
                df.at[idx, "local_path"] = file_path
                print("Already exists:", file_path)
                idx = idx + 1
                continue
            else:
                with page.expect_download() as d:
                    # If pdf_url goes straight to the PDF:
                    page.goto(pdf_url, wait_until="networkidle")

                download = d.value
                download.save_as(file_path)

                df.at[idx, "local_path"] = file_path
                idx = idx + 1
                print("Saved:", file_path)
        browser.close()
    print(df)
    return df

def chunk_df(df, chunk_size):
    return [
        df.iloc[i:i + chunk_size].reset_index(drop=True)
        for i in range(0, len(df), chunk_size)
    ]

def full_process(sgml_directory, pdf_directory, output_file_path,
                 chunk_size=80,
                 cooldown_between_chunks=1):

    df = extract_from_sgml(sgml_directory)
    print(f"Total papers found: {len(df)}")

    if len(df) == 0:
        print("No papers found.")
        return

    df_chunks = chunk_df(df, chunk_size)
    all_results = []

    for k, df_chunk in enumerate(df_chunks, start=1):
        print(f"\n=== Processing chunk {k}/{len(df_chunks)} "
              f"({len(df_chunk)} papers) ===")

        # Download PDFs for this chunk
        chunk_result = get_pdf(df_chunk, pdf_directory)

        # get_pdf may return paths or modify df — adapt as needed
        if isinstance(chunk_result, list):
            df_chunk = df_chunk.assign(pdf_path=chunk_result)

        all_results.append(df_chunk)

        # cooldown between chunks (VERY important for AER)
        if k < len(df_chunks):
            print(f"Cooling down {cooldown_between_chunks} seconds...")
            time.sleep(cooldown_between_chunks)

    # recombine
    final_df = pd.concat(all_results, ignore_index=True)
    final_df.to_excel(output_file_path, index=False)
    print(f"Final output written to {output_file_path}")


if __name__ == "__main__":
    # Automatically extract pdf
    full_process("/Users/zhushangkai/Desktop/winsorization_data/AER_2023_sgml",
             "/Users/zhushangkai/Desktop/winsorization_data/AER_2023_articles",
             "/Users/zhushangkai/Desktop/winsorization_data/AER_2023_whole_lists.xlsx")
    #
    # full_process("/Users/zhushangkai/Desktop/winsorization_data/AER_2024_sgml",
    #          "/Users/zhushangkai/Desktop/winsorization_data/AER_2024_articles",
    #          "/Users/zhushangkai/Desktop/winsorization_data/AER_2024_whole_lists.xlsx")

    # full_process("/Users/zhushangkai/Desktop/winsorization_data/AER_2025_sgml",
    #          "/Users/zhushangkai/Desktop/winsorization_data/AER_2025_articles",
    #          "/Users/zhushangkai/Desktop/winsorization_data/AER_2025_whole_lists.xlsx")


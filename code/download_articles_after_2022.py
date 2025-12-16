import pandas as pd
from bs4 import BeautifulSoup
import os
import re
from playwright.sync_api import sync_playwright

def read_sgml_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
        soup = BeautifulSoup(content, 'html.parser')
        return soup

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

def get_pdf_urls(df):
    df['pdf_url'] = "https://pubs.aeaweb.org/doi/pdfplus/" + df['doi'].astype(str)
    return df

def remove_front_matter(df):
    # remove the paper without an abstract
    df = df[df['abstract'].notna() & (df['abstract'].str.strip() != '')]
    df = df[df['document_type'] == "Articles"]
    return df

# df = read_all_sgml_file('/Users/zhushangkai/Desktop/seasonal_liquidity/AER_2024')
# df = get_pdf_urls(df)
# df.to_excel("/Users/zhushangkai/Desktop/seasonal_liquidity/AER_2024/whole_list.xlsx", index=False)
# print(df)

def extract_from_sgml(sgml_directory):
    df = read_all_sgml_file(sgml_directory)
    df = get_pdf_urls(df)
    df = remove_front_matter(df)
    return df

def clean_title(t):
    t = t.lower()
    t = re.sub(r'[^a-z0-9]+', '-', t)
    return t.strip('-')
def get_pdf(df, save_dir):
    urls = df['pdf_url'].tolist()
    titles = df['title'].tolist()
    file_paths = []
    os.makedirs(save_dir, exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        ctx = browser.new_context(accept_downloads=True)
        page = ctx.new_page()

        for pdf_url, pdf_title in zip(urls, titles):
            new_title = clean_title(pdf_title)
            file_path = f"{save_dir}/{new_title}.pdf"

            with page.expect_download() as d:
                # If pdf_url goes straight to the PDF:
                page.goto(pdf_url, wait_until="networkidle")

            download = d.value
            download.save_as(file_path)
            file_paths.append(file_path)
            print("Saved:", file_path)

        browser.close()
    df['local_path'] = file_paths
    return df


def full_process(sgml_directory, pdf_directory, output_file_path):
    df =extract_from_sgml(sgml_directory,)
    df = get_pdf(df, pdf_directory)
    print(df)
    df.to_excel(output_file_path, index = False)

full_process("/Users/zhushangkai/Desktop/seasonal_liquidity/AER_2023",
             "/Users/zhushangkai/Desktop/seasonal_liquidity/AER_2023_articles",
             "/Users/zhushangkai/Desktop/seasonal_liquidity/AER_2023/whole_lists.xlsx")




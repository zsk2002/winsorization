import gzip
import json

item_ids = []
full = []
journal_title = "The American Economic Review"
# Using gzip.open it is possible to read the file line by line without loading it all into memory
with (
    gzip.open(
        "/Users/zhushangkai/Desktop/seasonal_liquidity/jstor_metadata_2025-11-28.jsonl.gz",
        # Replace with the name of the most recent metadata file you downloaded from https://www.jstor.org/ta-support/metadata
        "rt",
        encoding="utf-8"
    ) as f
):
    for line_number, line in enumerate(f, start=1):
        # Print progress every 1000 lines to avoid overwhelming Jupyter

        if line_number % 10000 == 0:
            print(f"\rProcessing line: {line_number}", end="", flush=True)

        data = json.loads(line)
        if data.get("is_part_of") == journal_title:
            item_ids.append(data["item_id"])
            full.append(data)


    print()  # Move to the next line after processing

# Write the item IDs to a file
output_file = "/Users/zhushangkai/Desktop/seasonal_liquidity/american_economic_review.txt"
with open(output_file, "w") as f:
    for item_id in item_ids:
        f.write(f"{item_id}\n")
print("Output file:" + output_file)

# Write all information of selected articles to a file
output_file_2 = "/Users/zhushangkai/Desktop/seasonal_liquidity/AER_all_articles.txt"
with open(output_file_2, "w") as f:
    for everything in full:
        f.write(f"{everything}\n")
print("Output file:" + output_file_2)

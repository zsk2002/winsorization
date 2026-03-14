import re
second_regex = 1
first_regex = 1
CHECK_WINSORIZATION = [("winsorization", "%"), ("winsorized", "%"), ("winsorizing", "%"), ("winsor", "%"),
         ("trimmed", "%"), ("trimming", "%"), ("winsorization", "percent"), ("winsorized", "percent"),
         ("winsorizing", "percent"), ("winsor", "percent"), ("trimmed", "percent"), ("trimming", "percent"),
         ("winsorized", r"\b\d+\b", second_regex), ("winsorizing", r"\b\d+\b", second_regex),
         (r"\btrimmed\b", r"\b\d+\b", first_regex, second_regex), (r"\btrimming\b", r"\b\d+\b", first_regex, second_regex),
        ("winsorize", r"\b\d+\b", second_regex), (r"\btrim\b", r"\b\d+\b", first_regex, second_regex),
                       ("winsorizing", "extreme"), ("trimming", "extreme"), ("winsorized", "extreme"),
                       ("trimmed", "extreme"), ("winsorizing", "outlier"), ("winsorized", "outlier"),
                       ("trimmed", "outlier"), ("trimming", "outlier")
         ]
CHECK_EMPIRICAL =  [("data", "descriptive"), ("data", "administrative"), ("data", "survey"), ("data", "summary statistics"),
           ("data", "table"), ("data", "figure")]

def find_key_words(key_words, text) -> int:
    if isinstance(text, list):
        text = " ".join(str(part) for part in text)
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

def find_key_words_in_one_sentence(words_pair:list, text:str):
    if isinstance(text, list):
        text = " ".join(str(part) for part in text)
    elif not isinstance(text, str):
        if text is None:
            text = ""
        else:
            text = str(text)
    if not isinstance(text, str):
        return 0

    t = re.split(r"\.\s+(?=[A-Z1-9])", text)
    for sentence in t:
        sentence_l = sentence.lower()
        for pair in words_pair:
            first = pair[0]
            second = pair[1]
            if len(pair) == 2:
                if first.lower() in sentence_l and second.lower() in sentence_l:
                    return 1
            elif len(pair) == 3:
                if first.lower() in sentence_l:
                    if re.search(str(second), sentence_l):
                        return 1
            elif len(pair) == 4:
                if re.search(str(first), sentence_l) and re.search(str(second), sentence_l):
                    return 1


    return 0

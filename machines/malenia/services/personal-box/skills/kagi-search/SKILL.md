---
name: kagi-search
description: "Your web search: search the internet through Kagi. Use it whenever a task needs facts you cannot verify yourself, or anything current: news, prices, products, places, opening hours, how-tos, sources to cite."
---

# Kagi search

Run `kagi-search QUERY`. It prints up to 10 results, each as title, URL,
date, and snippet. `-n N` changes the count.

Each search costs Break about 1.2 cents. Search with purpose, and do not
run the same query twice.

To read a result, run `w3m -dump URL`: the page as plain text. For a PDF,
run `curl -sL URL -o /tmp/doc.pdf && pdftotext -layout /tmp/doc.pdf -`.

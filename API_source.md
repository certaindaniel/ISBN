以下是 **可以用 ISBN 查詢書本資料的公開資料庫與 API**（適合開發、查詢、整合書籍資訊用途）：

---

## 🌍 國際通用的公開資料庫 / API

### ✅ **Open Library (Internet Archive)**

* **特點**：完全免費、開放使用，支援 ISBN 查詢書籍基本元資料（書名、作者、出版社、封面等）。可直接透過 REST API 取得 JSON。([開放公共API][1])
* **API 範例**：
  `https://openlibrary.org/api/books?bibkeys=ISBN:9780140328721&format=json`
* **用途**：個人或商用、圖書管理系統、書目工具。([Public APIs][2])

### 📚 **Google Books API**

* **特點**：Google 提供的書籍數據 API，可依 ISBN 搜尋，回傳書名、作者、摘要、出版資訊、封面等。需用 Google API 金鑰。([Google for Developers][3])
* **優點**：涵蓋大量國際出版書籍；穩定性高。([Google for Developers][4])
* **限制**：需註冊與 API key；每日請求有配額。([Google for Developers][3])

---

## 📘 商業或需要註冊的書籍資訊服務

### 🧾 **ISBNdb**

* **特點**：付費/免費試用混合服務，資料更全面（多種元資料欄位可取得）。([維基百科][5])
* **用途**：適合書店、電商、商業應用整合書籍資訊。([HubSpot 博客][6])

### 🔎 **Barcode Lookup API**

* **特點**：UPC/EAN/ISBN 通用 API，可查詢產品（含書籍）詳細資料。需申請 API key。([條碼查詢][7])
* **用途**：條碼掃描應用、庫存管理系統。([條碼查詢][7])

### 🪪 **EAN-DB**

* **特點**：全球條碼資料庫，含 ISBN 查詢（需註冊並可能付費）。([EAN-DB][8])

---

## 📚 圖書館與圖書目錄資源

### 📖 **WorldCat / xISBN (OCLC)**

* **WorldCat**：全球最大圖書館聯盟書目查詢，可用 ISBN 查詢圖書館典藏資訊。
* **xISBN API**：OCLC 提供的 API，可依一個 ISBN 查詢同一本書的其他版本/譯本。([維基百科][9])
* **用途**：適合圖書館系統與書目分析。([維基百科][9])

### 📚 **‡biblios.net**

* **特點**：免費的書目編目服務，可查看與編輯書目記錄（需註冊）。([維基百科][10])
* **用途**：圖書館目錄管理和書籍查詢。([維基百科][10])

### 📘 **OpenAlex（學術著作，也含書籍）**

* **特點**：開放性學術作品資料庫，資料龐大且可透過 API 查詢；適合研究用途。([arXiv][11])

---

## 🇹🇼 國內 / 中文語境可參考（非完整 API）

### 🇹🇼 **全國新書資訊網（國家圖書館 ISBN 系統）**

* 台灣 ISBN 官方查詢服務，可查詢中文書籍的書目資訊。（主要是網站查詢，API 需另洽）([ISBN 中心][12])

### 📌 **中文 ISBN 查詢第三方 API**

* 有一些非官方 API（如 `api.jike.xyz/situ/book/isbn/...`）提供 ISBN 查詢中文書本資訊（需申請 API key）。([免費API大全][13])
* **注意**：這類服務可能不保證穩定性或完整性。

---

## 🛠 開發者工具 / 程式庫（輔助查詢）

### 🐍 **isbnlib**（Python 套件）

* 可以**驗證、清理 ISBN** 並透過多種來源抓取元資料。不是資料庫，但能方便整合多種 API。([PyPI][14])

---

## 📌 建議使用方式（簡單比較）

| 來源               | 是否免費 | API Key | 覆蓋範圍        | 適合用途      |
| ---------------- | ---- | ------- | ----------- | --------- |
| Open Library     | ✅    | ❌       | 國際書籍        | 個人 & 開發   |
| Google Books     | ✅    | ✅       | 大範圍國際       | 應用 / App  |
| ISBNdb           | ⚠️   | ✅       | 全面書籍        | 商業 / 電商   |
| Barcode Lookup   | ⚠️   | ✅       | ISBN + 其他條碼 | 商品 & 庫存   |
| WorldCat / xISBN | ⚠️   | 需申請     | 圖書館書目       | 圖書館系統     |
| 中文第三方 API        | ⚠️   | 依服務     | 中文書籍        | 中文開發 & UI |

---

## 📌 小貼士

* **開發者常見用法**：透過 Open Library + Google Books 組合補足資料缺漏。([blog.csdn.net][15])
* 若要在系統裡大量查詢 ISBN，記得注意 **API 請求配額與限制**（有些免費 API 有每日次數上限）。([Google for Developers][3])

---

如果你想，我也可以提供 **各個 API 的查詢範例程式碼（例如 Python/JavaScript）**，幫你直接整合到你的書本管理系統裡 📚💡。

[1]: https://openpublicapis.com/api/open-library?utm_source=chatgpt.com "Open Library API - Free Public APIs"
[2]: https://publicapis.io/open-library-api-api?utm_source=chatgpt.com "Open Library API API — Free Public API | Public APIs Directory"
[3]: https://developers.google.com/books/docs/v1/using?hl=zh-tw&utm_source=chatgpt.com "使用API | Google Books APIs"
[4]: https://developers.google.com/books?utm_source=chatgpt.com "Google Books APIs"
[5]: https://en.wikipedia.org/wiki/ISBNdb.com?utm_source=chatgpt.com "ISBNdb.com"
[6]: https://blog.hubspot.com/website/api-books?utm_source=chatgpt.com "12 Essential Book APIs"
[7]: https://www.barcodelookup.com/api?utm_source=chatgpt.com "Barcode Lookup API | Search our UPC, EAN and ISBN Database"
[8]: https://ean-db.com/?utm_source=chatgpt.com "EAN-DB — API for product lookups by EAN / UPC / ISBN"
[9]: https://de.wikipedia.org/wiki/XISBN?utm_source=chatgpt.com "XISBN"
[10]: https://en.wikipedia.org/wiki/%E2%80%A1biblios.net?utm_source=chatgpt.com "‡biblios.net"
[11]: https://arxiv.org/abs/2205.01833?utm_source=chatgpt.com "OpenAlex: A fully-open index of scholarly works, authors, venues, institutions, and concepts"
[12]: https://isbn.ncl.edu.tw/NEW_ISBNNet/C00_index.php?KeepThis=true&PHPSESSID=f3306tl73s990rqevht4o18fq3&Pfile=3320&TB_iframe=true&height=650&width=900&utm_source=chatgpt.com "圖書館的行動服務：以「i 找書」App 為例"
[13]: https://free-api.com/doc/543?utm_source=chatgpt.com "中文ISBN查询-免费API,收集所有免费的API"
[14]: https://pypi.org/project/isbnlib/?utm_source=chatgpt.com "isbnlib"
[15]: https://blog.csdn.net/m0_52537869/article/details/148002314?utm_source=chatgpt.com "探索ISBN查询接口：为图书管理系统赋能原创"

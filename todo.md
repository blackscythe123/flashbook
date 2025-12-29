# Todo List

- [x] Update backend `requirements.txt` with `pypdf` and `python-multipart`.
- [x] Create backend endpoint `/extractText` in `src/api/extract_text.py`.
- [x] Register new endpoint in `backend/main.py`.
- [x] Update frontend `BackendApiClient` to call `/extractText`.
- [x] Update frontend `BookProvider` to handle PDF upload via backend.
- [x] Update frontend `BookSourceScreen` to route PDF files to backend upload.

## Next Steps for User
1.  Navigate to `backend/` directory.
2.  Run `pip install -r requirements.txt` to install new dependencies.
3.  Restart the backend server (`python main.py`).
4.  Restart the Flutter app.
5.  Try uploading a PDF file.

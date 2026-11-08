# Common mistakes

- Do not sign Android release builds with the debug key. Use ignored `android/key.properties` and verify the certificate against the intended distribution channel.
- Do not claim a successful release from a passing Flutter build alone. Validate the exact commit, version/build code, native install, and store/backend compatibility.
- Do not reintroduce `flutter_pdfview`; `pdfrx` is the only PDF engine. The former fork conflicted with PDFium and was removed.
- Do not replace a failed account or balance refresh with a zero balance. Preserve the last known state and show an error when the value is required.
- Do not treat Settings > Delete account as server deletion until a real backend contract and test exist. The current implementation only clears the local session; see the release review notes.
- Preserve uncommitted work in the primary worktree. Use a separate worktree for broad review changes.

# M1 — Recovery probe

`recovery_probe.py` extracts text span positions from PDF and compares token presence with printable strings from INDD byte streams. It generates HTML/JSON evidence reports.

Treat all generated output as potentially sensitive when applied to customer documents. Do not commit real recovery maps, rendered page previews, or extracted text from private files.

# Validation gates

Before calling any output an IDML conversion, record:

1. ZIP integrity and expected package components.
2. XML well-formedness and valid component references.
3. Successful open in an identified IDML-capable application.
4. Text editability in a single frame containing multiple paragraphs.
5. Text reflow after changing frame width.
6. Visual comparison with a reference render.
7. Known losses and warnings.

ZIP/XML checks alone are not application-level validation.

# Publish this seed to the existing GitHub repository

Target: https://github.com/nalakara/indd_2_idml

The GitHub connector could read the repository, but its write calls were rejected with HTTP 403 (`Resource not accessible by integration`). This seed is staged locally so it can be pushed with your own authenticated Git client.

1. Download and unzip `indd_2_idml_repo_seed.zip`.
2. In Terminal, choose a working directory and run:

```bash
git clone https://github.com/nalakara/indd_2_idml.git
cd indd_2_idml
# Copy the contents of the extracted seed directory into this directory.
# For example, if both directories are in ~/Downloads:
cp -R ~/Downloads/indd_2_idml_repo_seed/. .
git status
git add README.md .gitignore docs experiments tests src PUBLISH_TO_GITHUB.md
git commit -m "chore: seed INDD to IDML research prototype"
git push -u origin main
```

If your clone cannot check out a branch because the GitHub repository is still empty, clone may create an empty working directory; copy the seed into it, then `git add`, `git commit`, and `git push -u origin main`.

Review `git status` before committing. Do not add benchmark `.indd`/`.pdf` files or local recovery JSON/HTML outputs.

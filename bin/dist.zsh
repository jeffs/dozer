#!/usr/bin/env -S zsh -euo pipefail
#
# This script builds the accompanying site for distribution via GitHub Pages.

readonly source_branch="$(git rev-parse --abbrev-ref HEAD)"
readonly source_rev="$(git rev-parse --short HEAD)"
readonly package_path="$(git rev-parse --show-toplevel)"
readonly package_name="$(basename $package_path)"

# Check out the dist branch with a working copy of the source branch.
git branch dist-parent dist
git branch -f dist
git checkout dist
git reset dist-parent

# Build the code and put it where GitHub wants it.
cd "$package_path"
rm -rf docs
trunk build --release --dist=docs --public-url="$package_name/"

# Work around minor Trunk/Safari incompatibility.  See also:
# <https://github.com/trunk-rs/trunk/issues/229#issuecomment-1575487406>
sed 's/ crossorigin=""//' docs/index.html > docs/index.html.new
mv docs/index.html.new docs/index.html
for f in docs/*.js; do
    sed 's/input = fetch(input)/input = fetch(input, { mode: "no-cors" })/' $f > $f.new
    mv $f.new $f
done

# Deploy the built artifacts.
git add .
git commit -m "Build $source_branch ($source_rev)"
git push -fu origin dist

# Clean up.
git branch -d dist-parent
git checkout "$source_branch"

<<EOF
For progress and deployment, see:
https://github.com/jeffs/$package_name/deployments
https://jeffs.github.io/$package_name/
EOF

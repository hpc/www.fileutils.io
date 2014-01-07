#!/bin/bash

echo ==================
echo Minify css
echo ==================
juicer merge --force bootstrap/css/bootstrap.css \
    css/docs.css \
    css/fileutils.css \
    css/flat-ui.css -o css/min.css

echo ==================
echo Building site
echo ==================
rm -rf ./_site
mkdir ./_site
cp -R robots.txt js css images bootstrap fonts index.html ./_site

echo =========================
echo GZIP All Html, css and js
echo =========================

find _site/ -iname '*.html' -exec gzip -N {} +
find _site/ -iname '*.js' -exec gzip -N {} +
find _site/ -iname '*.css' -exec gzip -N {} +
find _site/ -iname '*.gz' -exec rename 's/\.gz$//i' {} +
echo done.

echo ==================
echo Syncing to S3
echo ==================

pushd _site

# sync gzipped html files
s3cmd sync --delete-removed --progress -M --acl-public --add-header 'Cache-control: public' --add-header 'Content-Encoding:gzip' . s3://fileutils.io/ --exclude '*.*' --include '*.html'

# sync gzipped css and js to static bucket
s3cmd sync --progress -M --acl-public --add-header 'Content-Encoding:gzip' --add-header 'Cache-Control: max-age=31449600' . s3://fileutils.io/ --exclude '*.*' --include '*.js' --include '*.css'

# sync all non gzipped css, js and image files to the static bucket (e.g. images)
s3cmd sync --progress -M --acl-public --add-header 'Cache-Control: public' --add-header 'Vary: Accept-Encoding' --add-header 'Cache-Control: max-age=31449600' . s3://fileutils.io/ --exclude '*.css' --exclude '*.js'

popd

exit 0

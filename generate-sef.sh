#!/bin/bash

# Generate SEF (Saxon Export Format) file from XSLT
# This compiles the XSLT stylesheet for use with SaxonJS

echo "Generating SEF file from src/graph-client.xsl..."

npx xslt3-he -t -xsl:./src/graph-client.xsl -export:./dist/graph-client.xsl.sef.json -nogo -ns:##html5 -relocate:on

if [ $? -eq 0 ]; then
    echo "✓ SEF file generated successfully: dist/graph-client.xsl.sef.json"
else
    echo "✗ Error generating SEF file"
    exit 1
fi

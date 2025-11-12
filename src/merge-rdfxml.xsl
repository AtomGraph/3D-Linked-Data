<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#"
    exclude-result-prefixes="#all"
    version="3.0">

    <!-- Key for looking up resources by @rdf:about -->
    <xsl:key name="resources" match="rdf:Description[@rdf:about]" use="@rdf:about"/>

    <!-- Identity template for ldh:MergeRDF mode -->
    <xsl:template match="@* | node()" mode="ldh:MergeRDF">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- Merge new RDF descriptions into existing rdf:RDF element -->
    <xsl:template match="rdf:RDF" mode="ldh:MergeRDF">
        <xsl:param name="new-rdf" as="document-node()" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <xsl:variable name="existing-rdf" select="root(.)" as="document-node()"/>
            <!-- Add new descriptions that don't exist in the existing document -->
            <xsl:for-each select="$new-rdf/rdf:RDF/*[@rdf:about]">
                <xsl:if test="not(key('resources', @rdf:about, $existing-rdf))">
                    <xsl:apply-templates select="." mode="#current"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>

    <!-- Merge new properties into existing rdf:Description -->
    <xsl:template match="rdf:Description" mode="ldh:MergeRDF">
        <xsl:param name="new-rdf" as="document-node()" tunnel="yes"/>

        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>

            <!-- Add new properties from $new-rdf for the same resource -->
            <xsl:variable name="resource-uri" select="@rdf:about" as="xs:anyURI"/>
            <xsl:apply-templates select="key('resources', $resource-uri, $new-rdf)/*" mode="#current"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>

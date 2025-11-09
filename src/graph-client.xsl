<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#"
    xmlns:local="http://example.org/local#"
    exclude-result-prefixes="#all"
    extension-element-prefixes="ixsl"
    version="3.0">

    <xsl:import href="normalize-rdfxml.xsl"/>
    <xsl:import href="3d-force-graph.xsl"/>

    <!-- Main template - runs on page load -->
    <xsl:template name="main">
        <xsl:param name="graph-id" select="'3d-graph'" as="xs:string"/>
        <xsl:param name="document-uri" select="xs:anyURI('examples/example.rdf')" as="xs:anyURI"/>
        <xsl:param name="graph-width" select="800" as="xs:double"/>
        <xsl:param name="graph-height" select="600" as="xs:double"/>
        <xsl:param name="node-rel-size" select="6" as="xs:double"/>
        <xsl:param name="link-width" select="2" as="xs:double"/>
        <xsl:param name="node-label-color" select="'white'" as="xs:string"/>
        <xsl:param name="node-label-text-height" select="5" as="xs:double"/>
        <xsl:param name="node-label-position-y" select="10" as="xs:double"/>
        <xsl:param name="link-label-color" select="'lightgrey'" as="xs:string"/>
        <xsl:param name="link-label-text-height" select="3" as="xs:double"/>
        <xsl:param name="link-force-distance" select="100" as="xs:double"/>
        <xsl:param name="charge-force-strength" select="-200" as="xs:double"/>

        <!-- Initialize LinkedDataHub namespace -->
        <xsl:if test="not(ixsl:contains(ixsl:window(), 'LinkedDataHub'))">
            <xsl:variable name="LinkedDataHub-obj" select="ixsl:eval('({})')"/>
            <ixsl:set-property name="LinkedDataHub" select="$LinkedDataHub-obj" object="ixsl:window()"/>
        </xsl:if>

        <!-- Initialize LinkedDataHub.graphs object if it doesn't exist -->
        <xsl:variable name="LinkedDataHub" select="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <xsl:if test="not(ixsl:contains($LinkedDataHub, 'graphs'))">
            <xsl:variable name="graphs-obj" select="ixsl:eval('({})')"/>
            <ixsl:set-property name="graphs" select="$graphs-obj" object="$LinkedDataHub"/>
        </xsl:if>

        <!-- Get container element and create ForceGraph3D builder -->
        <xsl:variable name="container" select="id($graph-id, ixsl:page())" as="element()"/>
        <xsl:variable name="ForceGraph3D" select="ixsl:get(ixsl:window(), 'ForceGraph3D')"/>
        <xsl:variable name="builder" select="ixsl:apply($ForceGraph3D, [])"/>

        <!-- Initialize 3D Force Graph and get graph state -->
        <xsl:variable name="graph-state" as="item()">
            <xsl:call-template name="ldh:ForceGraph3D-init">
                <xsl:with-param name="graph-id" select="$graph-id"/>
                <xsl:with-param name="container" select="$container"/>
                <xsl:with-param name="builder" select="$builder"/>
                <xsl:with-param name="graph-width" select="$graph-width"/>
                <xsl:with-param name="graph-height" select="$graph-height"/>
                <xsl:with-param name="node-rel-size" select="$node-rel-size"/>
                <xsl:with-param name="link-width" select="$link-width"/>
                <xsl:with-param name="node-label-color" select="$node-label-color"/>
                <xsl:with-param name="node-label-text-height" select="$node-label-text-height"/>
                <xsl:with-param name="node-label-position-y" select="$node-label-position-y"/>
                <xsl:with-param name="link-label-color" select="$link-label-color"/>
                <xsl:with-param name="link-label-text-height" select="$link-label-text-height"/>
                <xsl:with-param name="link-force-distance" select="$link-force-distance"/>
                <xsl:with-param name="charge-force-strength" select="$charge-force-strength"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- Store graph state in LinkedDataHub.graphs -->
        <xsl:variable name="graphs" select="ixsl:get($LinkedDataHub, 'graphs')"/>
        <ixsl:set-property name="{$graph-id}" select="$graph-state" object="$graphs"/>
        <xsl:message>XSLT initialized - ready to handle graph events</xsl:message>

        <!-- Create tooltip and info panel UI elements -->
        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:append-content">
                <div id="tooltip-{$graph-id}"></div>
                <div id="info-panel">
                    <div id="info-content-{$graph-id}">Click a node or link to see details</div>
                </div>
            </xsl:result-document>
        </xsl:for-each>

        <!-- Load RDF data automatically on startup -->
        <xsl:call-template name="load-and-update-graph">
            <xsl:with-param name="graph-id" select="$graph-id"/>
            <xsl:with-param name="document-uri" select="$document-uri"/>
            <xsl:with-param name="graph-state" select="$graph-state"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Load RDF document and update graph -->
    <xsl:template name="load-and-update-graph">
        <xsl:param name="graph-id" as="xs:string"/>
        <xsl:param name="document-uri" as="xs:anyURI"/>
        <xsl:param name="graph-state" as="item()"/>

        <xsl:message>Loading RDF data from <xsl:value-of select="$document-uri"/>...</xsl:message>

        <!-- Create HTTP request with Accept header for RDF/XML -->
        <xsl:variable name="request" select="map{
            'method': 'GET',
            'href': $document-uri,
            'headers': map{ 'Accept': 'application/rdf+xml' }
        }" as="map(*)"/>

        <!-- Create context map to pass data through promise chain -->
        <xsl:variable name="context" select="map{
            'graph-id': $graph-id,
            'graph-state': $graph-state,
            'document-uri': $document-uri
        }" as="map(*)"/>

        <!-- Execute async HTTP request with promise chain -->
        <ixsl:promise select="
            ixsl:http-request($request)
                => ixsl:then(local:handle-rdf-response($context, ?))
        " on-failure="local:handle-load-error#1"/>
    </xsl:template>

    <!-- Handle RDF response and update graph -->
    <xsl:function name="local:handle-rdf-response" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="response" as="map(*)"/>

        <xsl:variable name="graph-id" select="$context('graph-id')" as="xs:string"/>
        <xsl:variable name="graph-state" select="$context('graph-state')" as="item()"/>
        <xsl:variable name="document-uri" select="$context('document-uri')" as="xs:anyURI"/>

        <xsl:message>RDF document loaded from <xsl:value-of select="$document-uri"/></xsl:message>

        <!-- Access the parsed RDF/XML document from response body -->
        <xsl:for-each select="$response?body">
            <xsl:variable name="rdf-doc" select="." as="document-node()"/>
            <xsl:message>Document root element: <xsl:value-of select="name($rdf-doc/*)"/></xsl:message>
            <xsl:message>Number of top-level children: <xsl:value-of select="count($rdf-doc/*/*)"/></xsl:message>

            <!-- Normalize RDF/XML (3 passes: normalize syntax, flatten structure, resolve URIs) -->
            <xsl:variable name="normalized-rdf" as="document-node()">
                <xsl:apply-templates select="$rdf-doc">
                    <xsl:with-param name="base-uri" select="$document-uri"/>
                </xsl:apply-templates>
            </xsl:variable>

            <!-- Convert normalized RDF to graph data -->
            <xsl:variable name="graph-data" as="item()">
                <xsl:apply-templates select="$normalized-rdf" mode="ldh:ForceGraph3D-convert-data"/>
            </xsl:variable>

            <!-- Update graph state -->
            <xsl:message>Updating graph visualization...</xsl:message>

            <!-- Reset info panel to default state -->
            <xsl:variable name="info-content-id" select="concat('info-content-', $graph-id)" as="xs:string"/>
            <xsl:for-each select="id($info-content-id, ixsl:page())">
                <xsl:result-document href="?." method="ixsl:replace-content">
                    Click a node or link to see details
                </xsl:result-document>
            </xsl:for-each>

            <!-- Update the stored data reference -->
            <ixsl:set-property name="data" select="$graph-data" object="$graph-state"/>

            <!-- Update the graph instance -->
            <xsl:variable name="graph-instance" select="ixsl:get($graph-state, 'instance')"/>
            <xsl:sequence select="ixsl:call($graph-instance, 'graphData', [ $graph-data ], map{ 'convert-args': false() })[current-date() lt xs:date('2000-01-01')]"/>

            <xsl:message>Graph updated successfully from RDF</xsl:message>
        </xsl:for-each>
    </xsl:function>

    <!-- Handle load errors -->
    <xsl:function name="local:handle-load-error" ixsl:updating="yes">
        <xsl:param name="error" as="map(*)"/>

        <xsl:message>Error loading RDF: <xsl:value-of select="serialize($error, map{'method': 'json'})"/></xsl:message>
        <xsl:variable name="error-msg" select="if ($error?description) then $error?description else if ($error?message) then $error?message else serialize($error, map{'method': 'json'})" as="xs:string"/>
        <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Error loading RDF: ' || $error-msg ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:function>

    <!-- Input field event handlers -->
    <xsl:template match="input[@id = 'uri-input']" mode="ixsl:onkeypress">
        <xsl:variable name="key" select="ixsl:get(ixsl:event(), 'key')" as="xs:string"/>

        <!-- Trigger on Enter key -->
        <xsl:if test="$key = 'Enter'">
            <xsl:variable name="go-button" select="id('go-button', ixsl:page())" as="element()"/>
            <xsl:sequence select="ixsl:call($go-button, 'click', [])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <!-- Button event handlers using IXSL mode templates -->
    <xsl:template match="button[@id = 'go-button']" mode="ixsl:onclick">
        <xsl:message>Go button clicked</xsl:message>

        <xsl:variable name="uri-input" select="id('uri-input', ixsl:page())" as="element()"/>
        <xsl:variable name="uri-string" select="ixsl:get($uri-input, 'value')" as="xs:string"/>

        <!-- Validate and load RDF from URI -->
        <xsl:choose>
            <xsl:when test="$uri-string castable as xs:anyURI and (starts-with($uri-string, 'http://') or starts-with($uri-string, 'https://'))">
                <xsl:variable name="uri" select="xs:anyURI($uri-string)" as="xs:anyURI"/>
                <xsl:variable name="graph-id" select="'3d-graph'" as="xs:string"/>
                <xsl:variable name="graphs" select="ixsl:get(ixsl:window(), 'LinkedDataHub.graphs')"/>
                <xsl:variable name="graph-state" select="ixsl:get($graphs, $graph-id)"/>

                <xsl:message>Loading RDF from: <xsl:value-of select="$uri"/></xsl:message>

                <xsl:call-template name="load-and-update-graph">
                    <xsl:with-param name="graph-id" select="$graph-id"/>
                    <xsl:with-param name="document-uri" select="$uri"/>
                    <xsl:with-param name="graph-state" select="$graph-state"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Invalid URI: <xsl:value-of select="$uri-string"/></xsl:message>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Please enter a valid HTTP(S) URI' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="button[@id = 'reset-camera']" mode="ixsl:onclick">
        <xsl:param name="camera-position-x" select="0" as="xs:double"/>
        <xsl:param name="camera-position-y" select="0" as="xs:double"/>
        <xsl:param name="camera-position-z" select="300" as="xs:double"/>
        <xsl:param name="camera-lookat-x" select="0" as="xs:double"/>
        <xsl:param name="camera-lookat-y" select="0" as="xs:double"/>
        <xsl:param name="camera-lookat-z" select="0" as="xs:double"/>
        <xsl:param name="camera-transition-duration" select="1000" as="xs:integer"/>

        <xsl:message>Reset camera button clicked</xsl:message>

        <xsl:variable name="graph-id" select="'3d-graph'" as="xs:string"/>
        <xsl:variable name="graphs" select="ixsl:get(ixsl:window(), 'LinkedDataHub.graphs')"/>
        <xsl:variable name="graph-state" select="ixsl:get($graphs, $graph-id)"/>

        <xsl:if test="exists($graph-state)">
            <xsl:variable name="graph-instance" select="ixsl:get($graph-state, 'instance')"/>

            <!-- Create JavaScript objects for position and lookAt -->
            <xsl:variable name="new-position" select="ixsl:eval('({})')"/>
            <xsl:for-each select="$new-position">
                <ixsl:set-property name="x" select="$camera-position-x" object="."/>
                <ixsl:set-property name="y" select="$camera-position-y" object="."/>
                <ixsl:set-property name="z" select="$camera-position-z" object="."/>
            </xsl:for-each>

            <xsl:variable name="look-at" select="ixsl:eval('({})')"/>
            <xsl:for-each select="$look-at">
                <ixsl:set-property name="x" select="$camera-lookat-x" object="."/>
                <ixsl:set-property name="y" select="$camera-lookat-y" object="."/>
                <ixsl:set-property name="z" select="$camera-lookat-z" object="."/>
            </xsl:for-each>

            <!-- Call cameraPosition with position, lookAt, and duration -->
            <xsl:sequence select="ixsl:call($graph-instance, 'cameraPosition', [ $new-position, $look-at, $camera-transition-duration ])[current-date() lt xs:date('2000-01-01')]"/>

            <xsl:message>Camera reset to default position</xsl:message>
        </xsl:if>
    </xsl:template>

    <!-- Graph event handlers -->
    <xsl:template match="." mode="ixsl:onForceGraph3DNodeClick">
        <xsl:variable name="event-detail" select="ixsl:get(ixsl:event(), 'detail')"/>
        <xsl:variable name="canvas-id" select="ixsl:get($event-detail, 'canvasId')" as="xs:string"/>
        <xsl:variable name="node-id" select="ixsl:get($event-detail, 'nodeId')" as="xs:string"/>
        <xsl:variable name="node-label" select="ixsl:get($event-detail, 'nodeLabel')" as="xs:string"/>
        <xsl:variable name="node-type" select="ixsl:get($event-detail, 'nodeType')" as="xs:string"/>

        <xsl:message>Node clicked: <xsl:value-of select="$node-id"/> (<xsl:value-of select="$node-label"/>)</xsl:message>

        <xsl:variable name="info-content-id" select="concat('info-content-', $canvas-id)" as="xs:string"/>
        <xsl:for-each select="id($info-content-id, ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <h4><xsl:value-of select="$node-label"/></h4>
                <dl>
                    <dt>ID</dt>
                    <dd>
                        <xsl:choose>
                            <xsl:when test="starts-with($node-id, 'http://') or starts-with($node-id, 'https://')">
                                <a href="{$node-id}" target="_blank"><xsl:value-of select="$node-id"/></a>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$node-id"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </dd>
                    <dt>Types</dt>
                    <dd><xsl:value-of select="$node-type"/></dd>
                </dl>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="." mode="ixsl:onForceGraph3DNodeRightClick">
        <xsl:variable name="event-detail" select="ixsl:get(ixsl:event(), 'detail')"/>
        <xsl:variable name="node-id" select="ixsl:get($event-detail, 'nodeId')" as="xs:string"/>
        <xsl:variable name="node-label" select="ixsl:get($event-detail, 'nodeLabel')" as="xs:string"/>

        <xsl:message>Node right-clicked: <xsl:value-of select="$node-id"/> (<xsl:value-of select="$node-label"/>)</xsl:message>
    </xsl:template>

    <xsl:template match="." mode="ixsl:onForceGraph3DNodeHoverOn">
        <xsl:variable name="event-detail" select="ixsl:get(ixsl:event(), 'detail')"/>
        <xsl:variable name="canvas-id" select="ixsl:get($event-detail, 'canvasId')" as="xs:string"/>
        <xsl:variable name="node-id" select="ixsl:get($event-detail, 'nodeId')" as="xs:string"/>
        <xsl:variable name="node-label" select="ixsl:get($event-detail, 'nodeLabel')" as="xs:string"/>
        <xsl:variable name="node-type" select="ixsl:get($event-detail, 'nodeType')" as="xs:string"/>
        <xsl:variable name="screen-x" select="ixsl:get($event-detail, 'screenX')" as="xs:double"/>
        <xsl:variable name="screen-y" select="ixsl:get($event-detail, 'screenY')" as="xs:double"/>
        <xsl:variable name="tooltip-id" select="concat('tooltip-', $canvas-id)" as="xs:string"/>

        <xsl:for-each select="id($tooltip-id, ixsl:page())">
            <!-- Show tooltip centered over node -->
            <ixsl:set-style name="display" select="'block'"/>
            <ixsl:set-style name="left" select="concat($screen-x, 'px')"/>
            <ixsl:set-style name="top" select="concat($screen-y, 'px')"/>
            <xsl:result-document href="?." method="ixsl:replace-content">
                <strong><xsl:value-of select="$node-label"/></strong><br/>
                <xsl:value-of select="$node-type"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="." mode="ixsl:onForceGraph3DNodeHoverOff">
        <xsl:variable name="event-detail" select="ixsl:get(ixsl:event(), 'detail')"/>
        <xsl:variable name="canvas-id" select="ixsl:get($event-detail, 'canvasId')" as="xs:string"/>
        <xsl:variable name="tooltip-id" select="concat('tooltip-', $canvas-id)" as="xs:string"/>

        <xsl:for-each select="id($tooltip-id, ixsl:page())">
            <ixsl:set-style name="display" select="'none'"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="." mode="ixsl:onForceGraph3DLinkClick">
        <xsl:variable name="event-detail" select="ixsl:get(ixsl:event(), 'detail')"/>
        <xsl:variable name="source-id" select="ixsl:get($event-detail, 'sourceId')" as="xs:string"/>
        <xsl:variable name="target-id" select="ixsl:get($event-detail, 'targetId')" as="xs:string"/>
        <xsl:variable name="link-label" select="ixsl:get($event-detail, 'linkLabel')" as="xs:string"/>

        <xsl:message>Link clicked: <xsl:value-of select="$source-id"/> --[<xsl:value-of select="$link-label"/>]--&gt; <xsl:value-of select="$target-id"/></xsl:message>
    </xsl:template>

    <xsl:template match="." mode="ixsl:onForceGraph3DBackgroundClick">
        <xsl:message>Background clicked</xsl:message>
    </xsl:template>

</xsl:stylesheet>

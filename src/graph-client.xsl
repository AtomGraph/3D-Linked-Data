<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#"
    xmlns:local="http://example.org/local#"
    exclude-result-prefixes="#all"
    extension-element-prefixes="ixsl"
    version="3.0">

    <xsl:import href="normalize-rdfxml.xsl"/>
    <xsl:import href="merge-rdfxml.xsl"/>
    <xsl:import href="3d-force-graph.xsl"/>

    <!-- Global parameters -->
    <xsl:param name="graph-id" select="'3d-graph'" as="xs:string"/> <!-- string: graph container element ID -->
    <xsl:param name="cors-proxy" select="'https://corsproxy.io/'" as="xs:string"/> <!-- string: CORS proxy URL prefix -->
    <xsl:param name="info-panel-content" as="element()">
        <div>Click a node or link to see details<br/>Double-click a node to expand its properties</div>
    </xsl:param>

    <!-- Helper function to get the graphs object from window -->
    <xsl:function name="local:get-graphs" as="item()">
        <xsl:sequence select="ixsl:get(ixsl:window(), 'LinkedDataHub.graphs')"/>
    </xsl:function>

    <!-- Helper function to get graph state by ID -->
    <xsl:function name="local:get-graph-state" as="item()">
        <xsl:param name="graph-id" as="xs:string"/>
        <xsl:sequence select="ixsl:get(local:get-graphs(), $graph-id)"/>
    </xsl:function>

    <!-- Main template - runs on page load -->
    <xsl:template name="main">
        <xsl:param name="document-uri" select="xs:anyURI('https://linkeddatahub.com/demo/skos/concepts/concept17128/')" as="xs:anyURI"/>
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

        <!-- Update the URI input field to show what's being loaded -->
        <xsl:variable name="uri-input" select="id('uri-input', ixsl:page())" as="element()"/>
        <ixsl:set-property name="value" select="string($document-uri)" object="$uri-input"/>

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
                <xsl:with-param name="cooldown-time" select="3000"/>
                <xsl:with-param name="node-click-event-name" select="'ForceGraph3DNodeClick'"/>
                <xsl:with-param name="node-dblclick-event-name" select="'ForceGraph3DNodeDblClick'"/>
                <xsl:with-param name="node-rightclick-event-name" select="'ForceGraph3DNodeRightClick'"/>
                <xsl:with-param name="node-hover-on-event-name" select="'ForceGraph3DNodeHoverOn'"/>
                <xsl:with-param name="node-hover-off-event-name" select="'ForceGraph3DNodeHoverOff'"/>
                <xsl:with-param name="link-click-event-name" select="'ForceGraph3DLinkClick'"/>
                <xsl:with-param name="background-click-event-name" select="'ForceGraph3DBackgroundClick'"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- Store graph state in LinkedDataHub.graphs -->
        <xsl:variable name="graphs" select="ixsl:get($LinkedDataHub, 'graphs')"/>
        <ixsl:set-property name="{$graph-id}" select="$graph-state" object="$graphs"/>

        <!-- Initialize global RDF document (empty, will be populated on first load) -->
        <xsl:variable name="empty-rdf-doc" as="document-node()">
            <xsl:document>
                <rdf:RDF/>
            </xsl:document>
        </xsl:variable>
        <ixsl:set-property name="document" select="$empty-rdf-doc" object="$LinkedDataHub"/>

        <!-- Initialize loaded URIs as JavaScript array (tracks URIs loaded via HTTP, not stubs) -->
        <ixsl:set-property name="loaded-uris" select="ixsl:new('Array', [])" object="$LinkedDataHub" convert-value="no"/>

        <xsl:message>XSLT initialized - ready to handle graph events</xsl:message>

        <!-- Create tooltip and info panel UI elements -->
        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:append-content">
                <div id="tooltip-{$graph-id}"></div>
                <div id="info-panel">
                    <div id="info-content-{$graph-id}">
                        <xsl:copy-of select="$info-panel-content"/>
                    </div>
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

    <!-- Zoom camera to fit all nodes in view -->
    <xsl:template name="zoom-to-fit">
        <xsl:param name="graph-state" as="item()" required="yes"/>
        <xsl:param name="zoom-transition-duration" select="1000" as="xs:integer"/>
        <xsl:param name="zoom-padding" select="20" as="xs:integer"/>

        <xsl:variable name="graph-instance" select="ixsl:get($graph-state, 'instance')"/>
        <xsl:sequence select="ixsl:call($graph-instance, 'zoomToFit', [ $zoom-transition-duration, $zoom-padding ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:message>Camera zoomed to fit all nodes</xsl:message>
    </xsl:template>

    <!-- Update graph with new RDF descriptions -->
    <xsl:template name="update-graph">
        <xsl:param name="new-descriptions" as="document-node()" required="yes"/>
        <xsl:param name="current-doc" as="document-node()" required="yes"/>
        <xsl:param name="graph-instance" as="item()" required="yes"/>

        <!-- Merge new descriptions into current document using ldh:MergeRDF mode -->
        <xsl:variable name="merged-doc" as="document-node()">
            <xsl:document>
                <xsl:apply-templates select="$current-doc" mode="ldh:MergeRDF">
                    <xsl:with-param name="new-rdf" select="$new-descriptions" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:document>
        </xsl:variable>

        <!-- Debug: serialize merged document -->
        <!-- <xsl:message>Merged document: <xsl:value-of select="serialize($merged-doc)"/></xsl:message> -->

        <!-- Update global document -->
        <xsl:variable name="LinkedDataHub" select="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <ixsl:set-property name="document" select="$merged-doc" object="$LinkedDataHub"/>

        <!-- Convert entire merged document to graph data -->
        <xsl:variable name="graph-data" as="item()">
            <xsl:apply-templates select="$merged-doc" mode="ldh:ForceGraph3D-convert-data"/>
        </xsl:variable>

        <!-- Update graph visualization -->
        <xsl:sequence select="ixsl:call($graph-instance, 'graphData', [ $graph-data ], map{ 'convert-args': false() })[current-date() lt xs:date('2000-01-01')]"/>

        <xsl:message>Graph updated with <xsl:value-of select="count($merged-doc/rdf:RDF/*)"/> total descriptions</xsl:message>
    </xsl:template>

    <!-- Load RDF document and update graph -->
    <xsl:template name="load-and-update-graph">
        <xsl:param name="graph-id" as="xs:string"/>
        <xsl:param name="document-uri" as="xs:anyURI"/>
        <xsl:param name="graph-state" as="item()"/>

        <xsl:message>Loading RDF data from <xsl:value-of select="$document-uri"/>...</xsl:message>

        <!-- Wrap document URI with CORS proxy -->
        <xsl:variable name="proxied-uri" select="xs:anyURI($cors-proxy || '?url=' || encode-for-uri($document-uri))" as="xs:anyURI"/>

        <!-- Create HTTP request with Accept header for RDF/XML and pool storage -->
        <xsl:variable name="request" select="map{
            'method': 'GET',
            'href': $proxied-uri,
            'headers': map{ 'Accept': 'application/rdf+xml' },
            'pool': 'xml'
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
            <xsl:call-template name="process-rdf-document">
                <xsl:with-param name="rdf-doc" select="."/>
                <xsl:with-param name="document-uri" select="$document-uri"/>
                <xsl:with-param name="graph-id" select="$graph-id"/>
                <xsl:with-param name="graph-state" select="$graph-state"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:function>

    <!-- Process RDF document: normalize, merge, and update graph -->
    <xsl:template name="process-rdf-document" ixsl:updating="yes">
        <xsl:param name="rdf-doc" as="document-node()" required="yes"/>
        <xsl:param name="document-uri" as="xs:anyURI" required="yes"/>
        <xsl:param name="graph-id" as="xs:string" required="yes"/>
        <xsl:param name="graph-state" as="item()" required="yes"/>

        <xsl:message>Document root element: <xsl:value-of select="name($rdf-doc/*)"/></xsl:message>
        <xsl:message>Number of top-level children: <xsl:value-of select="count($rdf-doc/*/*)"/></xsl:message>

        <!-- Normalize RDF/XML (3 passes: normalize syntax, flatten structure, resolve URIs) -->
        <!-- Strip fragment from base URI if present -->
        <xsl:variable name="base-uri" select="if (contains($document-uri, '#')) then xs:anyURI(substring-before($document-uri, '#')) else $document-uri" as="xs:anyURI"/>
        <xsl:variable name="normalized-rdf" as="document-node()">
            <xsl:apply-templates select="$rdf-doc">
                <xsl:with-param name="base-uri" select="$base-uri"/>
            </xsl:apply-templates>
        </xsl:variable>

        <!-- Get current global document and loaded URIs -->
        <xsl:variable name="LinkedDataHub" select="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
        <xsl:variable name="current-doc" select="ixsl:get($LinkedDataHub, 'document')" as="document-node()"/>
        <xsl:variable name="loaded-uris" select="ixsl:get($LinkedDataHub, 'loaded-uris', map{ 'convert-result': false() })"/>

        <!-- Add document URI to loaded URIs array -->
        <xsl:sequence select="ixsl:call($loaded-uris, 'push', [ string($document-uri) ])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:message>Added document URI to loaded-uris: <xsl:value-of select="$document-uri"/> (now <xsl:value-of select="ixsl:get($loaded-uris, 'length')"/> total)</xsl:message>

        <!-- Update graph with new descriptions -->
        <xsl:variable name="graph-instance" select="ixsl:get($graph-state, 'instance')"/>
        <xsl:call-template name="update-graph">
            <xsl:with-param name="new-descriptions" select="$normalized-rdf"/>
            <xsl:with-param name="current-doc" select="$current-doc"/>
            <xsl:with-param name="graph-instance" select="$graph-instance"/>
        </xsl:call-template>

        <!-- Reset info panel to default state -->
        <xsl:variable name="info-content-id" select="concat('info-content-', $graph-id)" as="xs:string"/>
        <xsl:for-each select="id($info-content-id, ixsl:page())">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$info-panel-content"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- Handle load errors -->
    <xsl:function name="local:handle-load-error" ixsl:updating="yes">
        <xsl:param name="error" as="map(*)"/>

        <xsl:variable name="error-msg" select="if ($error?description) then string($error?description) else if ($error?message) then string($error?message) else 'Unknown error'" as="xs:string"/>
        <xsl:message>Error loading RDF: <xsl:value-of select="$error-msg"/></xsl:message>
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

                <xsl:message>Loading RDF from: <xsl:value-of select="$uri"/></xsl:message>

                <!-- Reset global state (document and loaded URIs) -->
                <xsl:variable name="LinkedDataHub" select="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
                <xsl:variable name="empty-rdf-doc" as="document-node()">
                    <xsl:document>
                        <rdf:RDF/>
                    </xsl:document>
                </xsl:variable>
                <ixsl:set-property name="document" select="$empty-rdf-doc" object="$LinkedDataHub"/>
                <ixsl:set-property name="loaded-uris" select="ixsl:new('Array', [])" object="$LinkedDataHub" convert-value="no"/>
                <xsl:message>Reset global document and loaded-uris</xsl:message>

                <xsl:call-template name="load-and-update-graph">
                    <xsl:with-param name="graph-id" select="$graph-id"/>
                    <xsl:with-param name="document-uri" select="$uri"/>
                    <xsl:with-param name="graph-state" select="local:get-graph-state($graph-id)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Invalid URI: <xsl:value-of select="$uri-string"/></xsl:message>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Please enter a valid HTTP(S) URI' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="button[@id = 'zoom-to-fit']" mode="ixsl:onclick">
        <xsl:param name="zoom-transition-duration" select="1000" as="xs:integer"/>
        <xsl:param name="zoom-padding" select="20" as="xs:integer"/>

        <xsl:message>Zoom to fit button clicked</xsl:message>

        <!-- Use global $graph-id parameter -->
        <xsl:variable name="graph-state" select="local:get-graph-state($graph-id)"/>

        <xsl:call-template name="zoom-to-fit">
            <xsl:with-param name="graph-state" select="$graph-state"/>
            <xsl:with-param name="zoom-transition-duration" select="$zoom-transition-duration"/>
            <xsl:with-param name="zoom-padding" select="$zoom-padding"/>
        </xsl:call-template>
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

    <xsl:template match="." mode="ixsl:onForceGraph3DNodeDblClick">
        <xsl:variable name="event-detail" select="ixsl:get(ixsl:event(), 'detail')"/>
        <xsl:variable name="node-id" select="ixsl:get($event-detail, 'nodeId')" as="xs:string"/>
        <xsl:variable name="node-label" select="ixsl:get($event-detail, 'nodeLabel')" as="xs:string"/>

        <xsl:message>Node double-clicked: <xsl:value-of select="$node-id"/> (<xsl:value-of select="$node-label"/>)</xsl:message>

        <!-- Only load if node-id is a valid HTTP(S) URI -->
        <xsl:if test="starts-with($node-id, 'http://') or starts-with($node-id, 'https://')">
            <xsl:variable name="graph-state" select="local:get-graph-state($graph-id)"/>
            <xsl:variable name="LinkedDataHub" select="ixsl:get(ixsl:window(), 'LinkedDataHub')"/>
            <xsl:variable name="current-doc" select="ixsl:get($LinkedDataHub, 'document')" as="document-node()"/>
            <xsl:variable name="loaded-uris" select="ixsl:get($LinkedDataHub, 'loaded-uris', map{ 'convert-result': false() })"/>

            <!-- Strip fragment from node URI for checking against loaded URIs -->
            <xsl:variable name="node-uri-without-fragment" select="if (contains($node-id, '#')) then substring-before($node-id, '#') else $node-id" as="xs:string"/>

            <!-- <xsl:message>Current doc: <xsl:value-of select="serialize($current-doc)"/></xsl:message> -->

            <xsl:choose>
                <!-- Case 1: Node URI was loaded via HTTP - expand its objects -->
                <xsl:when test="ixsl:call($loaded-uris, 'includes', [ $node-uri-without-fragment ])">
                    <xsl:message>Node <xsl:value-of select="$node-id"/> already loaded</xsl:message>

                    <xsl:variable name="description" select="key('resources', $node-id, $current-doc)"/>

                    <!-- Get all object resource URIs from the description that don't already have descriptions -->
                    <xsl:variable name="object-uris" select="distinct-values($description/*/@rdf:resource)[not(key('resources', ., $current-doc))]" as="xs:anyURI*"/>

                    <xsl:if test="exists($object-uris)">
                        <xsl:message>Expanding <xsl:value-of select="count($object-uris)"/> object resources</xsl:message>

                        <!-- Create new descriptions for object resources -->
                        <xsl:variable name="new-descriptions" as="document-node()">
                            <xsl:document>
                                <rdf:RDF>
                                    <xsl:for-each select="$object-uris">
                                        <rdf:Description rdf:about="{.}">
                                            <rdfs:label><xsl:value-of select="tokenize(., '[/#]')[last()]"/></rdfs:label>
                                        </rdf:Description>
                                    </xsl:for-each>
                                </rdf:RDF>
                            </xsl:document>
                        </xsl:variable>

                        <!-- Debug: serialize new descriptions -->
                        <!-- <xsl:message>New descriptions to merge: <xsl:value-of select="serialize($new-descriptions)"/></xsl:message> -->

                        <!-- Update graph with new descriptions -->
                        <xsl:variable name="graph-instance" select="ixsl:get($graph-state, 'instance')"/>
                        <xsl:call-template name="update-graph">
                            <xsl:with-param name="new-descriptions" select="$new-descriptions"/>
                            <xsl:with-param name="current-doc" select="$current-doc"/>
                            <xsl:with-param name="graph-instance" select="$graph-instance"/>
                        </xsl:call-template>
                    </xsl:if>
                </xsl:when>

                <!-- Case 2: Node URI not loaded - load from HTTP -->
                <xsl:otherwise>
                    <xsl:message>Node <xsl:value-of select="$node-id"/> not loaded - fetching via HTTP: <xsl:value-of select="$node-uri-without-fragment"/></xsl:message>

                    <xsl:call-template name="load-and-update-graph">
                        <xsl:with-param name="graph-id" select="$graph-id"/>
                        <xsl:with-param name="document-uri" select="xs:anyURI($node-uri-without-fragment)"/>
                        <xsl:with-param name="graph-state" select="$graph-state"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
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

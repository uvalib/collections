<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"    
    exclude-result-prefixes="xs" 
    xpath-default-namespace="urn:isbn:1-931666-22-9"
    version="2.0">

<!--  stylesheet to strip out dsc of Reed guide, and strip out most of the 
       other tags and text except for identifying elements,  to make a more
       concise structural outline. Adds subcomponent counts to c0n elements.   -->

<xsl:output indent="yes"  method="xml" />
    
    <xsl:template match="/">
        <xsl:variable name="subcount" select="count(/ead/archdesc/dsc/c01)" />
        <dsc>
        <xsl:attribute name="subcomponentcount" select="$subcount" />    
        <xsl:apply-templates select="/ead/archdesc/dsc/c01"  />
        </dsc>
    </xsl:template>

    <xsl:template match="*|@*">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates  select="@level|@label|@audience|*|text()" />
        </xsl:copy>
    </xsl:template>

    <xsl:template match="c01|c02|c03|c04|c05|c06|c07|c08|c09">
        <xsl:variable name="subcount" select="count( c02|c03|c04|c05|c06|c07|c08|c09 )"/>
        <xsl:copy copy-namespaces="no">
           <xsl:apply-templates select="@level|@label" />
           <xsl:attribute name="subcomponentcount" select="$subcount" />
           <xsl:apply-templates select="did" />
            <xsl:apply-templates select="c01|c02|c03|c04|c05|c06|c07|c08|c09" />
        </xsl:copy>
    </xsl:template>

    <xsl:template match="scopecontent|controlaccess|langmaterial|origination|physdesc" />
    
    <xsl:template match="text()">
        <xsl:value-of select="normalize-space(.)" />
    </xsl:template>

    <xsl:template match="title">
        <xsl:copy copy-namespaces="no"><xsl:apply-templates select="text()"/></xsl:copy>
    </xsl:template>

</xsl:stylesheet>
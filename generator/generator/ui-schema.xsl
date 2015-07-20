<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns    ="http://www.w3.org/2002/xforms"
                xmlns:ev ="http://www.w3.org/2001/xml-events"
                xmlns:h  ="http://www.w3.org/1999/xhtml"
                xmlns:jr ="http://openrosa.org/javarosa"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                version="1.0">
  <xsl:output method="xml" indent="yes"/>

  <xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'" />
  <xsl:variable name="doWarn"    select="not(/module/@suppressWarnings = 'true')" />

  <xsl:template match="/">
    <h:html>
      <h:head>
        <h:title>Fill This In</h:title>
        <model>
          <instance>
            <faims id="Fill_This_In">
              <style>
                <orientation>
                  <orientation/>
                </orientation>
                <even>
                  <layout_weight/>
                </even>
                <large>
                  <layout_weight/>
                </large>
              </style>
              <xsl:call-template name="model"/>
            </faims>
          </instance>
          <xsl:call-template name="bindings"/>
        </model>
      </h:head>
      <h:body>
        <group ref="style">
          <label/>
          <group ref="orientation">
            <label/>
            <input ref="orientation">
              <label>horizontal</label>
            </input>
          </group>
          <group ref="even">
            <label/>
            <input ref="layout_weight">
              <label>1</label>
            </input>
          </group>
          <group ref="large">
            <label/>
            <input ref="layout_weight">
              <label>3</label>
            </input>
          </group>
        </group>
        <xsl:call-template name="body"/>
      </h:body>
    </h:html>
  </xsl:template>

  <xsl:template name="model">
    <xsl:for-each select="/module/*">                                  <!-- Iterate over tab group nodes -->
      <xsl:element name="{name(.)}">
        <xsl:for-each select="*">                                      <!-- Iterate over tab nodes -->
          <xsl:if test="not(translate(name(.), $smallcase, '') = '')"> <!-- Skip nodes with "reserved" names (i.e. all lower case letters -->
            <xsl:element name="{name(.)}">
              <xsl:for-each select="*">                         <!-- Iterate over GUI elements -->
                <xsl:call-template name="model-expand-cols-or-view"/>
              </xsl:for-each>
            </xsl:element>
          </xsl:if>
        </xsl:for-each>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="bindings">
    <xsl:for-each select="/module/*">                                <!-- Iterate over tab group nodes -->
      <xsl:for-each select="*">                                      <!-- Iterate over tab nodes -->
        <xsl:if test="not(translate(name(.), $smallcase, '') = '')"> <!-- Skip nodes with "reserved" names (i.e. all lower case letters -->
          <xsl:for-each select="*">                                  <!-- Iterate over GUI elements -->
            <xsl:call-template name="bind-expand-cols-or-view"/>
          </xsl:for-each>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="body">
    <xsl:for-each select="/module/*">                                <!-- Iterate over tab group nodes -->
      <xsl:element name="group">
        <xsl:attribute name="ref"><xsl:value-of select="name()"/></xsl:attribute>
        <xsl:if test="not(ancestor-or-self::*[contains(@f, 'onlyui')])">
          <xsl:attribute name="faims_archent_type"><xsl:value-of select="name()"/></xsl:attribute>
        </xsl:if>
        <xsl:call-template name="label" />
        <xsl:for-each select="*">                                      <!-- Iterate over tab nodes -->
          <xsl:if test="not(translate(name(.), $smallcase, '') = '')"> <!-- Skip nodes with "reserved" names (i.e. all lower case letters -->
            <xsl:element name="group">
              <xsl:attribute name="ref"><xsl:value-of select="name()"/></xsl:attribute>
              <xsl:if test=".//*[normalize-space(@t) = 'map']">
                <xsl:attribute name="faims_scrollable">false</xsl:attribute>
              </xsl:if>
              <xsl:call-template name="parse-flags">
                <xsl:with-param name="flags" select="@f" />
              </xsl:call-template>
              <xsl:call-template name="label" />
              <xsl:for-each select="*[not(contains(@f, 'onlydata'))]"> <!-- Iterate over GUI elements -->
                <xsl:call-template name="body-expand-cols-or-view"/>
              </xsl:for-each>
            </xsl:element>
          </xsl:if>
        </xsl:for-each>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="model-expand-cols-or-view">
    <xsl:choose>
      <xsl:when test="name(.) = 'cols'">
        <xsl:call-template name="model-expand-cols" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="model-expand-view" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="model-expand-view">
    <xsl:element name="{name(.)}"/>
    <xsl:if test="normalize-space(@t) = 'audio'
      or normalize-space(@t) = 'camera'
      or normalize-space(@t) = 'file'
      or normalize-space(@t) = 'video'">
      <xsl:element name="Button_{name(.)}"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="model-expand-cols">
    <xsl:element name="Colgroup_{count(./preceding-sibling::cols)}">
      <xsl:for-each select="*">
        <xsl:element name="Col_{count(./preceding-sibling::*)}">
          <xsl:choose>
            <xsl:when test="name() = 'col'">
                <xsl:for-each select="*">
                  <xsl:element name="{name(.)}"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{name(.)}"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>

  <xsl:template name="bind-expand-cols-or-view">
    <xsl:choose>
      <xsl:when test="name(.) = 'cols'">
        <xsl:call-template name="bind-expand-cols" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="@b">
          <xsl:element name="bind">
            <xsl:attribute name="type">
              <xsl:value-of select="normalize-space(@b)"/>
            </xsl:attribute>
            <xsl:attribute name="nodeset">/faims/<xsl:value-of select="name(ancestor::*[last()-1])"/>/<xsl:value-of select="name(ancestor::*[last()-2])"/>/<xsl:value-of select="name()"/></xsl:attribute>
          </xsl:element>
          <xsl:if test="$doWarn and normalize-space(@b) != 'decimal'">
            <xsl:comment>WARNING: Unexpected binding "<xsl:value-of select="@b"/>"</xsl:comment>
          </xsl:if>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="bind-expand-cols">
    <xsl:for-each select=".//*[@b]">
      <!--<xsl:comment><xsl:value-of select="name()"/></xsl:comment>-->
      <xsl:element name="bind">
        <xsl:attribute name="type">
          <xsl:value-of select="normalize-space(@b)"/>
        </xsl:attribute>
        <xsl:choose>
          <xsl:when test="./ancestor::col">
            <xsl:attribute name="nodeset">/faims/<xsl:value-of select="name(ancestor::*[last()-1])"/>/<xsl:value-of select="name(ancestor::*[last()-2])"/>/Colgroup_<xsl:value-of select="count(./ancestor::cols[1]/preceding-sibling::cols)"/>/Col_<xsl:value-of select="count(./ancestor::col[1]/preceding-sibling::*)"/>/<xsl:value-of select="name()"/></xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="nodeset">/faims/<xsl:value-of select="name(ancestor::*[last()-1])"/>/<xsl:value-of select="name(ancestor::*[last()-2])"/>/Colgroup_<xsl:value-of select="count(./ancestor::cols[1]/preceding-sibling::cols)"/>/Col_<xsl:value-of select="count(./preceding-sibling::*)"/>/<xsl:value-of select="name()"/></xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:element>
      <xsl:if test="$doWarn and normalize-space(@b) != 'decimal'">
        <xsl:comment>WARNING: Unexpected binding "<xsl:value-of select="@b"/>"</xsl:comment>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="body-expand-cols-or-view">
    <xsl:choose>
      <xsl:when test="name(.) = 'cols'">
        <xsl:call-template name="body-expand-cols" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="body-expand-view" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="body-expand-cols">
    <xsl:element name="group">
      <xsl:attribute name="ref">Colgroup_<xsl:value-of select="count(./preceding-sibling::cols)"/></xsl:attribute>
      <xsl:attribute name="faims_style">orientation</xsl:attribute>
      <label/>
      <xsl:for-each select="*">
        <xsl:element name="group">
          <xsl:attribute name="ref">Col_<xsl:value-of select="count(./preceding-sibling::*)"/></xsl:attribute>
          <xsl:attribute name="faims_style">even</xsl:attribute>
          <label/>
          <xsl:choose>
            <xsl:when test="name() = 'col'">
                <xsl:for-each select="*">
                  <xsl:call-template name="body-expand-view" />
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="body-expand-view" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>

  <xsl:template name="body-expand-view">
    <xsl:choose>
      <xsl:when test="normalize-space(@t)='audio'">
        <xsl:element name="select">
          <xsl:attribute name="type">file</xsl:attribute>
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'onlyui')])">
            <xsl:attribute name="faims_attribute_type">measure</xsl:attribute>
          </xsl:if>
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'nosync')])">
            <xsl:attribute name="faims_sync">true</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="body-expand-view-standard-nodes" />
          <item>
            <label>Options not loaded</label>
            <value>0</value>
          </item>
        </xsl:element>
        <trigger ref="Button_{name()}">
          <xsl:variable name="nodeName">Button_<xsl:value-of select="name()"/></xsl:variable>
          <xsl:if test="$doWarn and ../*[name() = $nodeName]">
            <xsl:comment>WARNING: View name is duplicated such that this UI schema is invalid.</xsl:comment>
          </xsl:if>
          <label>{Button_<xsl:value-of select="name()"/>}</label>
        </trigger>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='button'">
        <xsl:element name="trigger">
          <xsl:call-template name="body-expand-view-standard-nodes" />
        </xsl:element>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='camera'">
        <xsl:element name="select">
          <xsl:attribute name="type">camera</xsl:attribute>
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'onlyui')])">
            <xsl:attribute name="faims_attribute_type">measure</xsl:attribute>
          </xsl:if>
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'nosync')])">
            <xsl:attribute name="faims_sync">true</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="body-expand-view-standard-nodes" />
          <item>
            <label>Options not loaded</label>
            <value>0</value>
          </item>
        </xsl:element>
        <trigger ref="Button_{name()}">
          <xsl:variable name="nodeName">Button_<xsl:value-of select="name()"/></xsl:variable>
          <xsl:if test="$doWarn and ../*[name() = $nodeName]">
            <xsl:comment>WARNING: View name is duplicated such that this UI schema is invalid.</xsl:comment>
          </xsl:if>
          <label>{Button_<xsl:value-of select="name()"/>}</label>
        </trigger>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='checkbox'">
        <xsl:element name="select">
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'onlyui')])">
            <xsl:attribute name="faims_attribute_type">vocab</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="body-expand-view-standard-nodes" />
          <item>
            <label>Options not loaded</label>
            <value>0</value>
          </item>
        </xsl:element>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='dropdown'">
        <xsl:element name="select1">
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'onlyui')])">
            <xsl:attribute name="faims_attribute_type">vocab</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="body-expand-view-standard-nodes" />
          <item>
            <label>Options not loaded</label>
            <value>0</value>
          </item>
        </xsl:element>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='file'">
        <xsl:element name="select">
          <xsl:attribute name="type">file</xsl:attribute>
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'onlyui')])">
            <xsl:attribute name="faims_attribute_type">measure</xsl:attribute>
          </xsl:if>
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'nosync')])">
            <xsl:attribute name="faims_sync">true</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="body-expand-view-standard-nodes" />
          <item>
            <label>Options not loaded</label>
            <value>0</value>
          </item>
        </xsl:element>
        <trigger ref="Button_{name()}">
          <xsl:variable name="nodeName">Button_<xsl:value-of select="name()"/></xsl:variable>
          <xsl:if test="$doWarn and ../*[name() = $nodeName]">
            <xsl:comment>WARNING: View name is duplicated such that this UI schema is invalid.</xsl:comment>
          </xsl:if>
          <label>{Button_<xsl:value-of select="name()"/>}</label>
        </trigger>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='group'">
        <xsl:element name="{normalize-space(@t)}">
          <xsl:call-template name="body-expand-view-standard-nodes" />
        </xsl:element>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='input'">
        <xsl:element name="{normalize-space(@t)}">
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'onlyui')])">
            <xsl:attribute name="faims_attribute_type">measure</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="body-expand-view-standard-nodes" />
        </xsl:element>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='list'">
        <xsl:element name="select1">
          <xsl:attribute name="appearance">compact</xsl:attribute>
          <xsl:call-template name="body-expand-view-standard-nodes" />
          <item>
            <label>Options not loaded</label>
            <value>0</value>
          </item>
        </xsl:element>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='map'">
        <xsl:element name="input">
          <xsl:attribute name="faims_map">true</xsl:attribute>
          <xsl:call-template name="body-expand-view-standard-nodes" />
        </xsl:element>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='picture'">
        <xsl:element name="select1">
          <xsl:attribute name="type">image</xsl:attribute>
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'onlyui')])">
            <xsl:attribute name="faims_attribute_type">vocab</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="body-expand-view-standard-nodes" />
          <item>
            <label>Options not loaded</label>
            <value>0</value>
          </item>
        </xsl:element>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='radio'">
        <xsl:element name="select1">
          <xsl:attribute name="appearance">full</xsl:attribute>
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'onlyui')])">
            <xsl:attribute name="faims_attribute_type">vocab</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="body-expand-view-standard-nodes" />
          <item>
            <label>Options not loaded</label>
            <value>0</value>
          </item>
        </xsl:element>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='video'">
        <xsl:element name="select">
          <xsl:attribute name="type">video</xsl:attribute>
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'onlyui')])">
            <xsl:attribute name="faims_attribute_type">measure</xsl:attribute>
          </xsl:if>
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'nosync')])">
            <xsl:attribute name="faims_sync">true</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="body-expand-view-standard-nodes" />
          <item>
            <label>Options not loaded</label>
            <value>0</value>
          </item>
        </xsl:element>
        <trigger ref="Button_{name()}">
          <xsl:variable name="nodeName">Button_<xsl:value-of select="name()"/></xsl:variable>
          <xsl:if test="../*[name() = $nodeName]">
            <xsl:comment>ERROR: View name is duplicated such that this UI schema is invalid.</xsl:comment>
          </xsl:if>
          <label>{Button_<xsl:value-of select="name()"/>}</label>
        </trigger>
      </xsl:when>
      <xsl:when test="normalize-space(@t)='webview'">
        <xsl:element name="input">
          <xsl:attribute name="faims_web">true</xsl:attribute>
          <xsl:call-template name="body-expand-view-standard-nodes" />
        </xsl:element>
      </xsl:when>
      <xsl:when test="normalize-space(@t) = ''">
        <xsl:element name="input">
          <xsl:if test="not(ancestor-or-self::*[contains(@f, 'onlyui')])">
            <xsl:attribute name="faims_attribute_type">measure</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="body-expand-view-standard-nodes" />
          <xsl:if test="$doWarn">
            <xsl:comment>WARNING: No type t was given for this view; assuming it is an input.</xsl:comment>
          </xsl:if>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="{normalize-space(@t)}">
          <xsl:call-template name="body-expand-view-standard-nodes" />
          <xsl:if test="$doWarn">
            <xsl:comment>WARNING: This view was created from an element whose t attribute's value is unexpected.</xsl:comment>
          </xsl:if>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="body-expand-view-standard-nodes">
    <xsl:attribute name="ref"><xsl:value-of select="name()"/></xsl:attribute>
    <xsl:if test="@c">
      <xsl:attribute name="faims_style_class"><xsl:value-of select="@c"/></xsl:attribute>
    </xsl:if>
    <xsl:if test="normalize-space(@t) != 'group' and
      normalize-space(@t) != 'button' and
      normalize-space(@t) != 'map' and
      normalize-space(@t) != 'webview' and
      not(ancestor-or-self::*[contains(@f, 'onlyui')])">
      <xsl:attribute name="faims_attribute_name">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="name()" />
          <xsl:with-param name="replace" select="'_'" />
          <xsl:with-param name="by" select="' '" />
        </xsl:call-template>
      </xsl:attribute>
    </xsl:if>
    <xsl:call-template name="parse-flags">
      <xsl:with-param name="flags" select="@f" />
    </xsl:call-template>
    <xsl:call-template name="label" />
  </xsl:template>

  <xsl:template name="label">
    <xsl:element name="label">
      <xsl:if test="not(contains(@f, 'nolabel')) and not(contains(@f, 'onlydata'))">
        <xsl:choose>
          <xsl:when test="normalize-space(text())">
            <xsl:text>{</xsl:text>
            <xsl:call-template name="string-to-arch16n-line">
              <xsl:with-param name="string" select="normalize-space(text())" />
            </xsl:call-template>
            <xsl:text>}</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>{</xsl:text>
            <xsl:call-template name="string-to-arch16n-line">
              <xsl:with-param name="string" select="name()" />
            </xsl:call-template>
            <xsl:text>}</xsl:text>
            <xsl:if test="$doWarn">
              <xsl:comment>WARNING: Label not given; automatically generated from element name.</xsl:comment>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </xsl:element>
  </xsl:template>

<!--
  Function string-replace-all taken from:
    http://geekswithblogs.net/Erik/archive/2008/04/01/120915.aspx
  Invoked as:

    <xsl:variable name="newtext">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text" select="$text" />
        <xsl:with-param name="replace" select="a" />
        <xsl:with-param name="by" select="b" />
      </xsl:call-template>
    </xsl:variable>
-->
  <xsl:template name="string-replace-all">
    <xsl:param name="text" />
    <xsl:param name="replace" />
    <xsl:param name="by" />
    <xsl:choose>
      <xsl:when test="contains($text, $replace)">
        <xsl:value-of select="substring-before($text,$replace)" />
        <xsl:value-of select="$by" />
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text"
          select="substring-after($text,$replace)" />
          <xsl:with-param name="replace" select="$replace" />
          <xsl:with-param name="by" select="$by" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="parse-flags">
    <xsl:param name="flags" />
    <xsl:variable name="v1">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text"    select="$flags" />
        <xsl:with-param name="replace" select="'notscrollable'" />
        <xsl:with-param name="by"      select="''" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="string-length($v1) &lt; string-length($flags)">
      <xsl:attribute name="faims_scrollable">false</xsl:attribute>
    </xsl:if>
    <xsl:variable name="v2">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text"    select="$v1" />
        <xsl:with-param name="replace" select="'readonly'" />
        <xsl:with-param name="by"      select="''" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="string-length($v2) &lt; string-length($v1)">
      <xsl:attribute name="faims_read_only">true</xsl:attribute>
    </xsl:if>
    <xsl:variable name="v3">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text"    select="$v2" />
        <xsl:with-param name="replace" select="'nocertainty'" />
        <xsl:with-param name="by"      select="''" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="string-length($v3) &lt; string-length($v2)">
      <xsl:attribute name="faims_certainty">false</xsl:attribute>
    </xsl:if>
    <xsl:variable name="v4">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text"    select="$v3" />
        <xsl:with-param name="replace" select="'noannotation'" />
        <xsl:with-param name="by"      select="''" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="string-length($v4) &lt; string-length($v3)">
      <xsl:attribute name="faims_annotation">false</xsl:attribute>
    </xsl:if>
    <xsl:variable name="v5">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text"    select="$v4" />
        <xsl:with-param name="replace" select="'hidden'" />
        <xsl:with-param name="by"      select="''" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="string-length($v5) &lt; string-length($v4)">
      <xsl:attribute name="faims_hidden">true</xsl:attribute>
    </xsl:if>
    <xsl:variable name="v6">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text"    select="$v5" />
        <xsl:with-param name="replace" select="'id'" />
        <xsl:with-param name="by"      select="''" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="v7">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text"    select="$v6" />
        <xsl:with-param name="replace" select="'onlyui'" />
        <xsl:with-param name="by"      select="''" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="v8">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text"    select="$v7" />
        <xsl:with-param name="replace" select="'onlydata'" />
        <xsl:with-param name="by"      select="''" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="v9">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text"    select="$v8" />
        <xsl:with-param name="replace" select="'nosync'" />
        <xsl:with-param name="by"      select="''" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="v10">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text"    select="$v9" />
        <xsl:with-param name="replace" select="'nothumbnail'" />
        <xsl:with-param name="by"      select="''" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="v11">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text"    select="$v10" />
        <xsl:with-param name="replace" select="'nothumb'" />
        <xsl:with-param name="by"      select="''" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="v12">
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text"    select="$v11" />
        <xsl:with-param name="replace" select="'user'" />
        <xsl:with-param name="by"      select="''" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="v13">
      <xsl:value-of select="normalize-space($v12)" />
    </xsl:variable>
    <xsl:if test="$doWarn and $v13 != ''">
      <xsl:comment>WARNING: Unexpected flag(s) "<xsl:value-of select="$v13" />"</xsl:comment>
    </xsl:if>
  </xsl:template>

  <!-- WARNING:  This template assumes $string contains at most 80
       non-alphanumeric characters
  -->
  <xsl:template name="string-to-arch16n-line">
    <xsl:param name="string" />
    <xsl:value-of select="
      translate(
        $string,
        translate(
          $string,
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
          ''
        ),
        '________________________________________________________________________________'
      )
    " />
  </xsl:template>

</xsl:stylesheet>

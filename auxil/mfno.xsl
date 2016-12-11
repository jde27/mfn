<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE stylesheet [
     <!ENTITY rss SYSTEM "rss.svg">
     <!ENTITY ccbysa SYSTEM "cc-by-sa.svg">
]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/">
  <html>
    <head>
	<link rel="stylesheet" href="../auxil/mfno.css"/>
	<title>Mathematical Field Notes</title>
	<!-- The following scripts allow for
	     (a) toggling proofs
	     (b) Using MathJax
	     (c) Ensuring that LaTeX delimiters $...$ work
	-->	
	<script type="text/javascript">
	  function toggle(element) {
	  if (element.style.display == 'none') {
	  element.style.display = 'block';
	  } else {
	  element.style.display = 'none';
	  }
	  }
	</script>
	
	<script type="text/javascript"
		src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML">
	</script>
	
	<script type="text/x-mathjax-config">
	  MathJax.Hub.Config({
	  tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]},
	  });
	</script>
    </head>

    <body>
	\(
	\def\RR{\mathbf{R}}
	\def\CC{\mathbf{C}}
	\def\ZZ{\mathbf{Z}}
	\def\Z#1{{\bf Z}_{#1}}
	\def\cp#1{\mathbf{CP}^{#1}}
	\def\OP#1{\mathrm{#1}}
	\)
	<div class="card">
	  <div class="cardname"><xsl:value-of select="/card/@title"/></div><div class="mfn"><a href="index.xml" style="color:white;">Mathematical Field Notes</a></div><div class="clear-box"/>
	</div>
	<div class="contentbox">
	  <div class="sidebar">
	    <a href="mfno.rss">&rss;</a>
	    <xsl:if test="/card/@type">
	      <xsl:if test="((/card/@type!='tag') and (/card/@type!='index'))">
		<p><a href="index.xml">Index</a></p>
	      </xsl:if>
	    </xsl:if>
	    <p><a href="about.xml">About</a></p>
	    <xsl:if test="/card/@type">
	      <xsl:if test="((/card/@type!='tag') and (/card/@type!='index'))">
		<span class="bf">Links:</span><br/>
		<xsl:apply-templates select="/card/metadata/links"/>
	      <br/>
	      <span class="bf">Tags:</span><br/>
	      <xsl:apply-templates select="/card/metadata/tags"/>
	      <br/>
	      </xsl:if>
	    </xsl:if>
	  </div>
	  <div class="content">
	    <div class="authors">
	      <xsl:apply-templates select="/card/metadata/authors"/>
	    </div>
	    <div class="bod-div">
	      <xsl:apply-templates select="/card/bod"/>
	    </div>
	  </div>
	  <div class="clear-box"/>
	</div>
	<div class="foot">&ccbysa;</div>
    </body>
  </html>
</xsl:template>

<!-- divs for authors/links -->

<xsl:template match="authors">
  <xsl:apply-templates select="author"/>
  Last modified:&#32;<xsl:value-of select="/card/@date"/> Created:&#32;<xsl:value-of select="/card/@created"/>
</xsl:template>

<xsl:template match="author">
  Author:&#32;<xsl:value-of select="@name"/>&#32;&#183;&#32;
  <xsl:if test="@email"><a><xsl:attribute name="href">mailto:<xsl:value-of select="@email"/></xsl:attribute>&#32;&#9993;</a></xsl:if><br/>
</xsl:template>

<xsl:template match="links">
    <xsl:apply-templates select="link"/>
</xsl:template>

<xsl:template match="link">
  <xsl:param name="href" select="./@href"/>
  - <a>
  <xsl:attribute name="href"><xsl:value-of select="$href"/></xsl:attribute>
  <xsl:choose>
    <xsl:when test="document($href)/card/@title">
      <xsl:value-of select="document($href)/card/@title"/>
    </xsl:when>
    <xsl:otherwise>
      Link coming soon
    </xsl:otherwise>
    </xsl:choose>
  </a><br/>
</xsl:template>

<!-- divs for sections -->

<xsl:template match="bod">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="section">
  <div class="section-div">
    <p class="section"><xsl:number format="1. "/><xsl:value-of select="@name"/></p>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="tags">
  <xsl:apply-templates select="tag"/>
</xsl:template>

<xsl:template match="tag">
  #<a><xsl:attribute name="href"><xsl:value-of select="@name"/>.xml</xsl:attribute><xsl:value-of select="@name"/></a> 
</xsl:template>

<xsl:template match="recent">
  <xsl:param name="href" select="./@href"/>
  <xsl:param name="date" select="./@date"/>
  - <xsl:value-of select="$date"/>, <a>
  <xsl:attribute name="href"><xsl:value-of select="$href"/></xsl:attribute>
  <xsl:choose>
    <xsl:when test="document($href)/card/@title">
      <xsl:value-of select="document($href)/card/@title"/>
    </xsl:when>
    <xsl:otherwise>
      Link coming soon
    </xsl:otherwise>
    </xsl:choose>
  </a><br/>
</xsl:template>


<!-- divs for index cards -->

<xsl:template match="index">
  <div class="section-div">
    <p>The following field notes are tagged #<xsl:value-of select="/card/@title"/>.</p>
    <!-- Need to order items alphabetically using XSLT -->
    <ul>
      <xsl:apply-templates select="item"/>
    </ul>
  </div>
</xsl:template>

<xsl:template match="item">
  <li><a><xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute><xsl:value-of select="."/></a></li>
</xsl:template>


<!-- These templates are for mimicking HTML -->

<xsl:template match="table">
  <table>
    <xsl:copy-of select="./*"/>
  </table>
</xsl:template>

<xsl:template match="a">
  <xsl:param name="lid" select="./@lid"/>
  <xsl:param name="link" select="./@link"/>

  <a>
    <xsl:attribute name="href"><xsl:if test="./@link"><xsl:value-of select="$link"/></xsl:if><xsl:if test="./@lid">#<xsl:value-of select="$lid"/></xsl:if></xsl:attribute>
    <xsl:choose>
      <!-- if the link test is empty we will have to generate it
	   This will only occur if the link is to another MFN page
      -->
      <xsl:when test=".=''">
	<xsl:choose>
	  <!-- if the link is to an item -->
	  <xsl:when test="./@lid">
	    <xsl:choose>
	      <!-- if the link is not in-page -->
	      <xsl:when test="./@link">
		<!-- look for env with id=lid in the document $link,
		     get its type, its sectionnum and itemnum
		     and write... -->
		<xsl:value-of select="document($link)//env[@id=$lid]/@type"/>&#32;(<xsl:value-of select="document($link)//env[@id=$lid]/@sectionnum"/>-<xsl:value-of select="document($link)//env[@id=$lid]/@itemnum"/>)
	      </xsl:when>
	      <xsl:otherwise>
		<!-- look for env with id=lid,
		     get its type, its sectionnum and itemnum
		     and write... -->
		<xsl:value-of select="//env[@id=$lid]/@type"/>&#32;(<xsl:value-of select="//env[@id=$lid]/@sectionnum"/>-<xsl:value-of select="//env[@id=$lid]/@itemnum"/>)
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:when>
	  <!-- if the link is not to an item it must be to an external page -->
	  <xsl:otherwise>
	    <xsl:value-of select="document($link)/card/@title"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </a>
</xsl:template>

<xsl:template match="i">
  <span class="em"><xsl:value-of select="."/></span>
</xsl:template>

<xsl:template match="b">
  <span class="bf"><xsl:value-of select="."/></span>
</xsl:template>

<xsl:template match="ul">
  <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="br">
  <br/>
</xsl:template>

<xsl:template match="p">
  <p><xsl:apply-templates/></p>
</xsl:template>

<!-- This is a catch-all environment for Lemmas/Theorems/ etc -->

<xsl:template match="env">
  <div class="env-div">
    <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
    <span class="env"><xsl:value-of select="@sectionnum"/>-<xsl:value-of select="@itemnum"/>.&#32; <xsl:value-of select="@type"/>.&#32;</span>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<!-- This environment is for hidden proofs. -->

<xsl:template match="proof">
  <div class="prf-div">
    <xsl:choose>
      <xsl:when test="@vis='off'">
	<a>
	  <xsl:attribute name="id"><xsl:value-of select="./@id"/>show</xsl:attribute>
	  <xsl:attribute name="href">#<xsl:value-of select="./@id"/>show</xsl:attribute>
	  <xsl:attribute name="onclick">toggle(<xsl:value-of select="@id"/>);</xsl:attribute>
	  [Show/hide proof:]
	</a>
	<span style="display:none;">
	  <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
	  <span class="prf">Proof:</span> <xsl:apply-templates/>&#160;&#160;&#x2588;
	</span>
      </xsl:when>
      <xsl:otherwise>
	<span class="prf">Proof:</span> <xsl:apply-templates/>&#160;&#160;&#x2588;
      </xsl:otherwise>
    </xsl:choose>
  </div>
</xsl:template>

<!-- This environment is for hidden answers. -->

     <xsl:template match="ans">
  <div class="ans-div">
    <xsl:choose>
      <xsl:when test="@vis='off'">
	<a>
	  <xsl:attribute name="href">#<xsl:value-of select="../@id"/></xsl:attribute>
	  <xsl:attribute name="onclick">toggle(<xsl:value-of select="@id"/>);</xsl:attribute>
	  [Show/hide answer:]
	</a>
	<span style="display:none;">
	  <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
	  <xsl:apply-templates/>
	</span>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </div>
</xsl:template>

</xsl:stylesheet>

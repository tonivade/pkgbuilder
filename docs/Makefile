XSLT_PARAMS = --stringparam chunk.first.sections 1 --stringparam chunk.section.dep 8 --stringparam section.autolabel 1
STYLESHEET = /usr/share/xml/docbook/xsl-stylesheets-1.76.1/xhtml/chunk.xsl

all: 
	xsltproc $(XSLT_PARAMS) --output html/ $(STYLESHEET) manual.xml

clean:
	rm -rf html

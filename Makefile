FONTSITE = http://greekfontsociety.gr
# FONTSITE = http://ancientgreekocr.org/archived # backup copies
WORDLISTS = \
            grc.word.txt \
            grc.freq.txt \
            grc.punc.txt \
            grc.number.txt
DAWGS = $(WORDLISTS:.txt=-dawg)
ifeq ($(shell uname),Darwin)
	MEDIUM = Medium
endif
FONT_NAMES = \
             "$(strip GFS Artemisia ${MEDIUM})" \
             "GFS Artemisia Bold" \
             "GFS Artemisia Bold Italic" \
             "$(strip GFS Artemisia ${MEDIUM} Italic)" \
             "$(strip GFS Bodoni ${MEDIUM})" \
             "GFS Bodoni Bold" \
             "GFS Bodoni Bold Italic" \
             "$(strip GFS Bodoni ${MEDIUM} Italic)" \
             "$(strip GFS Didot ${MEDIUM})" \
             "GFS Didot Bold" \
             "GFS Didot Bold Italic" \
             "$(strip GFS Didot ${MEDIUM} Italic)" \
             "$(strip GFS DidotClassic ${MEDIUM})" \
             "$(strip GFS Neohellenic ${MEDIUM})" \
             "GFS Neohellenic Bold" \
             "GFS Neohellenic Bold Italic" \
             "$(strip GFS Neohellenic ${MEDIUM} Italic)" \
             "$(strip GFS Philostratos ${MEDIUM})" \
             "$(strip GFS Porson ${MEDIUM})" \
             "$(strip GFS Pyrsos ${MEDIUM})" \
             "$(strip GFS Solomos ${MEDIUM})"
FONT_URLNAMES = \
                GFS_ARTEMISIA_OT \
                GFS_BODONI_OT \
                GFS_DIDOTCLASS_OT \
                GFS_DIDOT_OT \
                GFS_NEOHELLENIC_OT \
                GFS_PHILOSTRATOS \
                GFS_PORSON_OT \
                GFS_PYRSOS \
                GFS_SOLOMOS_OT
CHARSPACING = 1.0

.SUFFIXES: .txt -dawg

all: grc.traineddata

grc.traineddata: grc.config features grc.unicharset grc.pffmtable grc.inttemp grc.shapetable grc.normproto grc.unicharambigs $(DAWGS)
	combine_tessdata grc.

fonts:
	for i in $(FONT_URLNAMES); do \
		wget -q -O $$i.zip $(FONTSITE)/$$i.zip ; \
		unzip -q -j $$i.zip ; \
		rm -f OFL-FAQ.txt OFL.txt *Specimen.pdf *Specimenn.pdf ; \
		rm -f readme.rtf .DS_Store ._* $$i.zip; \
	done
	chmod 644 *otf
	touch $@

images: fonts training_text.txt
	for i in $(FONT_NAMES); do \
		n=`echo $$i | sed 's/ //g'` ; \
		for e in -3 -2 -1 0 1 2 3; do \
			text2image --exposure $$e --char_spacing $(CHARSPACING) \
			           --fonts_dir . --text training_text.txt \
			           --outputbase grc.$$n.exp$$e --font "$$i" ; \
		done ; \
	done
	touch $@

# .tr files
features: images
	for i in *tif; do b=`basename $$i .tif`; tesseract $$i $$b box.train; done
	touch $@

# unicharset to pass to mftraining
grc.earlyunicharset: images
	unicharset_extractor *box
	set_unicharset_properties -U unicharset -O $@ --script_dir .
	rm unicharset

# cntraining
grc.normproto: features
	cntraining grc*tr
	mv normproto $@

# mftraining
%.unicharset %.inttemp %.pffmtable %.shapetable: grc.earlyunicharset features font_properties
	mftraining -F font_properties -U grc.earlyunicharset -O grc.unicharset grc*tr
	for i in inttemp pffmtable shapetable; do mv $$i $*.$$i; done

.txt-dawg: mftraining # for the newest .unicharset
	wordlist2dawg $< $@ grc.unicharset

install: grc.traineddata
	cp grc.traineddata ../../../tessdata

clean:
	rm -f images features mftraining *tif *box *tr *dawg grc.GFS*txt
	rm -f grc.inttemp grc.normproto grc.pffmtable grc.shapetable grc.unicharset grc.earlyunicharset

cleanfonts:
	rm -f fonts *otf

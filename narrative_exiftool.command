echo
exiftool '-alldates<${directory}$filename' ~/Pictures/Narrative\ Clip/2014/05/02/210506c.jpg 
exiftool -alldates-=4 ~/Pictures/Narrative\ Clip/2014/05/02/210506c.jpg 
exiftool -n -orientation=8 ~/Pictures/Narrative\ Clip/2014/05/02/210506c.jpg
exiftool -model='Narrative Clip' ~/Pictures/Narrative\ Clip/2014/05/02/210506c.jpg

exiftool -config Narrative_XMP_config "-xmp-NarrClip:tags=mag_data:[[-71, 405, 1085]]"  ~/Pictures/Narrative\ Clip/2014/05/02/210506c.jpg

# another change 2

# orientation cheat sheet:
# 1 = Horizontal (normal) 
# 3 = Rotate 180 
# 6 = Rotate 90 CW 
# 8 = Rotate 270 CW﻿


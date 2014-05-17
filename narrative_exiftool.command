echo
exiftool '-alldates<${directory}$filename' ~/Pictures/Narrative\ Clip/2014/05/02/210506c.jpg 
exiftool -alldates-=4 ~/Pictures/Narrative\ Clip/2014/05/02/210506c.jpg 
exiftool -n -orientation=8 ~/Pictures/Narrative\ Clip/2014/05/02/210506c.jpg
exiftool -model='Narrative Clip' ~/Pictures/Narrative\ Clip/2014/05/02/210506c.jpg


# 1 = Horizontal (normal) 
# 3 = Rotate 180 
# 6 = Rotate 90 CW 
# 8 = Rotate 270 CW﻿


# exiftool "-datetimeoriginal<${directory}:01 00:00:00" -r c:\images


# script to prepare Narrative photos with EXIF metadata 
# for upload via Google+ Auto Backup

use File::Find::Rule;	# find all the subdirectories of a given directory

my $home = "/Users/chuckkahn/";
# my $home = "/Users/charleskahn/";

my $path = $home . "Pictures/Narrative\ Clip/2014/04/05";

if ($path =~ /(\d.*\d)/ )
{
	$date = $1;
	$date =~ s/\//-/g;
	print $date;
}

$htmlpath = $home . "Pictures/Narrative\ Clip\ EXIF/HTML/";

my @folders = File::Find::Rule->file->in( $path );

$html = $htmlpath . "narrative_pics_" . $date . ".html";
open (HTML, ">$html");		# open file for output

$html_num = $htmlpath . "narrative_numbers_" . $date . ".html";
open (HTMLNUM, ">$html_num");		# open file for output

print HTML <<"zarp";
<html>
<head>
<style>

body {color:white;}
a:link {color:#FF0000;}    /* unvisited link */
a:visited {color:#00FF00;} /* visited link */
a:hover {color:#FF00FF;}   /* mouse over link */
a:active {color:#0000FF;}  /* selected link */

table,td,th
{
border:1px solid white;
}

div#rotate0
{
-webkit-transform:rotate(0deg); /* Chrome, Safari, Opera */
transform:rotate(0deg); /* Standard syntax */
}

div#rotate90
{
-webkit-transform:rotate(90deg); /* Chrome, Safari, Opera */
transform:rotate(90deg); /* Standard syntax */
}

div#rotate180
{
-webkit-transform:rotate(180deg); /* Chrome, Safari, Opera */
transform:rotate(180deg); /* Standard syntax */
}

div#rotate270
{
-webkit-transform:rotate(270deg); /* Chrome, Safari, Opera */
transform:rotate(270deg); /* Standard syntax */
}

img.normal {height:auto;}
img.big {height:40%; width:40%}
img.small {height:10%; width:10%}

</style>
</head>

<body bgcolor=#222222>
zarp

print HTML "$path<HR>\n\n";
print HTML "<table>\n";
print HTMLNUM "<table border=1>\n";

			print HTMLNUM <<"zarp";
<tr>
<TD > file </A></td>
<td > acc_x</td>
<td > acc_y</td>
<td > acc_z</td>
<td > angle </td>
<td > exif # </td>
</tr>
zarp

$imgheight = "15%";

use JSON qw( );		# using JSON 

foreach my $filepath (@folders)			# going through the directory
{
	if ($filepath =~ /(.*)\/(\d*)(.jpg)/ )		# looking for .jpeg files
	{
		$path = $1;
		$file = $2;
		$ext  = $3;

		# print $filepath . "\n";

		$jpegpath{$filepath}  = $filepath;

		# .json files are in the meta folder
		
		$jsonpath{$filepath}  = $path . "/" . "meta/" . $file . ".json";

		print $jpegpath{$filepath}  . " [jpegpath] \n";
		print $jsonpath{$filepath}  . " [jsonpath] \n";
		print "\n";

		$json_status = 1;

		my $json_text = do {
		   open(my $json_fh, "<:encoding(UTF-8)", $jsonpath{$filepath})
			  or $json_status = 0;
		   local $/;
		   <$json_fh>
		};

		if ( $json_status == 1 )
		{
			print $json_text . "\n";

			my $json = JSON->new;

			#		print $json . "\n";

			# the format from the camera should be something like: 
			# "acc_data": { "samples":[[-684, 36, 846]] }, 
			# where x-axis=-684, y-axis=36 and z-axis=846.

			# The x-axis of the accelerometer is positive toward the empty side of the clip, e.g. the bottom if you wear it on a shirt, 
			# the y-axis is positive toward the usb-port 
			# and the z-axis is positive toward the front of the clip.

			# In order to just decide the rotation in 2 dimensions you should be able to use simple trig-methods with two of the vectors, 
			# e.g. x and y if you just want to rotate the photos correctly

			my $decoded = $json->decode($json_text);
			$meta_json{$filepath} = $decoded;

			$acc_x{$filepath} = $decoded->{'acc_data'}{'samples'}[0][0];	# grabbing acc_data numbers...
			$acc_y{$filepath} = $decoded->{'acc_data'}{'samples'}[0][1];
			$acc_z{$filepath} = $decoded->{'acc_data'}{'samples'}[0][2];

			my $pi = 3.14159265358979;

			sub deg_to_rad { ($_[0]/180) * $pi }
			sub rad_to_deg { ($_[0]/$pi) * 180 }
			sub asin { atan2($_[0], sqrt(1 - $_[0] * $_[0])) }
			sub acos { atan2( sqrt(1 - $_[0] * $_[0]), $_[0] ) }
			sub tan  { sin($_[0]) / cos($_[0])  }
			sub atan { atan2($_[0],1) };

			# =degrees(pi()-atan2(C2,D2))  -- formula for (y,x)

			$rotate{$filepath} = rad_to_deg( $pi - atan2 ( $acc_y{$filepath}, $acc_x{$filepath} ) ) ;    # using ceil to round

			use POSIX;
			$rotate{$filepath} = ceil ($rotate{$filepath} );

			if ( $rotate{$filepath} >= 316 )
			{
				$rotate{$filepath} = $rotate{$filepath} - 360;
			}

			# exiftool -n -orientation=8 210506c.jpg

			# 1 = Horizontal (normal) 0
			# 3 = Rotate 180 
			# 6 = Rotate 90 CW 
			# 8 = Rotate 270 CW
		
			# setting rotation values
		
			# 0, 90, 180, 270
		
			if ( $rotate{$filepath} ~~ [46..135] ) 			# > 800	
			{										# ------------- Rotate 90 CW
				$ETrot{$filepath} = 6;  
				$rounded{$filepath} = 90;
			}
			elsif ( $rotate{$filepath} ~~ [136..225] ) 			# > 250  < 800
			{										# ------------- Rotate 180 CW
				$ETrot{$filepath} = 3; 
				$rounded{$filepath} = 180;
			}
			elsif ( $rotate{$filepath} ~~ [-45..45] ) 		# > -611 < 249
			{										# ------------- Rotate 0   CW
				$ETrot{$filepath} = 1;
				$rounded{$filepath} = 0;
			}
			elsif ( $rotate{$filepath} ~~ [226..315] ) 		# < -611
			{										# ------------- Rotate 270 CW
				$ETrot{$filepath} = 8;
				$rounded{$filepath} = 270;
			}
			else
			{
				print "$rotate{$filepath} doesn't fit!!!\n\n";
				exit;
			}
		
			++$c; 							# increment counter 

			# print table row
			print HTML <<"zarp";
<tr height=400px>
<td> $c </td>
<td> <div id="div"><img height="$imgheight" src="$jpegpath{$filepath}" ></div> </TD>
<TD width=20px> <A HREF="$jpegpath{$filepath}">$file</A></td>
<td width=20px> acc_x $acc_x{$filepath}</td>
<td width=20px> acc_y $acc_y{$filepath}</td>
<td width=20px> acc_z $acc_z{$filepath}</td>
<td width=20px> $rotate{$filepath} CW [$rounded{$filepath}]</td>
<td width=20px> $ETrot{$filepath} </td>

<td  >  <div id="rotate$rounded{$filepath}"><img height="$imgheight" src="$jpegpath{$filepath}"  ></div></td>
</tr>
zarp

			print "\n";

			# print numeric table row
			
			print HTMLNUM <<"zarp";
<tr>
<TD > <A HREF="$jpegpath{$filepath}">$jpegpath{$filepath}</A></td>
<td > $acc_x{$filepath}</td>
<td > $acc_y{$filepath}</td>
<td > $acc_z{$filepath}</td>
<td > $rotate{$filepath} CW [$rounded{$filepath}]</td>
<td > $ETrot{$filepath} </td>
</tr>
zarp

			print "\n";

		}	
	}
}


print HTML <<"zarp";
</table>
</body>
</html>
zarp

print HTMLNUM <<"zarp";
</table>
</body>
</html>
zarp

close (HTML);
close (HTMLNUM);

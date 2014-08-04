# script to create table of Narrative photos and meta folder data

use File::Find::Rule;	# find all the subdirectories of a given directory

my $home = "/Users/chuckkahn/";
# my $home = "/Users/charleskahn/";

my $path = $home . "Pictures/Narrative\ Clip/2014/";

$htmlpath = $home . "Pictures/Narrative\ Clip\ EXIF/HTML/";

my @jpegs = File::Find::Rule->file()
							->name( '*.jpg' )
							->in( $path );

$imgheight = "15%";

use JSON qw( );		# using JSON 

foreach $jpegpath (@jpegs)					# all jpegs in the directory
{
	print $jpegpath . "\n";

	use File::Basename;

	# get full path in $path
	$jpegname = basename($jpegpath);

	print $jpegname . "\n";

	# /Users/chuckkahn/Pictures/Narrative Clip/2014/04/04/195818.jpg   # eg. path

	# .json files are in the meta folder

	$jsonname = $jpegname;
	$jsonname =~ s/.jpg/.json/;	
	
	$jsonpath{$jpegpath}  = $jpegpath;
	$jsonpath{$jpegpath}  =~ s/$jpegname//;
	$jsonpath{$jpegpath}  = $jsonpath{$jpegpath} . "meta/" . $jsonname;
	
	print $jsonpath{$jpegpath}  . "\n";
	
	if ( $jpegpath =~ /(\d\d\d\d)\/(\d\d)\/(\d\d)/ )
	{
		$prevday = $day;
		$year  = $1;
		$month = $2;
		$day   = $3;
		$date = $year . $month . $day;
		print "------------- $date --------------- \n";
	}
	
	$json_status = 1;

	$json_text = do {
	   open(my $json_fh, "<:encoding(UTF-8)", $jsonpath{$jpegpath})
		  or $json_status = 0;
	   local $/;
	   <$json_fh>
	};

	if ( $json_status == 1 )
	{
		if ( $day != $prevday )
		{
			&footer;	# print footer and close file

			# open new files for new day
		
			$html = $htmlpath . $date . "_narrative_pics.html";
			open (HTML, ">$html");		# open file for output

			$html_num = $htmlpath . $date . "_narrative_numbers.html";
			open (HTMLNUM, ">$html_num");		# open file for output

			print $jpegpath  . " [jpegpath] \n";
			print $jsonpath{$jpegpath}  . " [jsonpath] \n";
			print "\n";

			&header;	# print new header
		}

		print $json_text . "\n";

		my $json = JSON->new;

		#		print $json . "\n";

		my $decoded = $json->decode($json_text);
		$meta_json{$jpegpath} = $decoded;

		$acc_x{$jpegpath} = $decoded->{'acc_data'}{'samples'}[0][0];	# grabbing acc_data numbers...
		$acc_y{$jpegpath} = $decoded->{'acc_data'}{'samples'}[0][1];
		$acc_z{$jpegpath} = $decoded->{'acc_data'}{'samples'}[0][2];

		$pi = 3.14159265358979;

#		sub deg_to_rad { ($_[0]/180) * $pi }
		sub rad_to_deg { ($_[0]/$pi) * 180 }
#		sub asin { atan2($_[0], sqrt(1 - $_[0] * $_[0])) }
#		sub acos { atan2( sqrt(1 - $_[0] * $_[0]), $_[0] ) }
#		sub tan  { sin($_[0]) / cos($_[0])  }
#		sub atan { atan2($_[0],1) };

		# =degrees(pi()-atan2(C2,D2))  -- formula for (y,x)

		$rotate{$jpegpath} = rad_to_deg( $pi - atan2 ( $acc_y{$jpegpath}, $acc_x{$jpegpath} ) ) ;    # using ceil to round

		use POSIX;
		$rotate{$jpegpath} = ceil ($rotate{$jpegpath} );

		if ( $rotate{$jpegpath} >= 316 )
		{
			$rotate{$jpegpath} = $rotate{$jpegpath} - 360;
		}

		# exiftool -n -orientation=8 210506c.jpg

		# 1 = Horizontal (normal) 0
		# 3 = Rotate 180 
		# 6 = Rotate 90 CW 
		# 8 = Rotate 270 CW
	
		# setting rotation values
	
		# 0, 90, 180, 270
	
		if ( $rotate{$jpegpath} ~~ [46..135] ) 			# > 800	
		{										# ------------- Rotate 90 CW
			$ETrot{$jpegpath} = 6;  
			$rounded{$jpegpath} = 90;
		}
		elsif ( $rotate{$jpegpath} ~~ [136..225] ) 			# > 250  < 800
		{										# ------------- Rotate 180 CW
			$ETrot{$jpegpath} = 3; 
			$rounded{$jpegpath} = 180;
		}
		elsif ( $rotate{$jpegpath} ~~ [-45..45] ) 		# > -611 < 249
		{										# ------------- Rotate 0   CW
			$ETrot{$jpegpath} = 1;
			$rounded{$jpegpath} = 0;
		}
		elsif ( $rotate{$jpegpath} ~~ [226..315] ) 		# < -611
		{										# ------------- Rotate 270 CW
			$ETrot{$jpegpath} = 8;
			$rounded{$jpegpath} = 270;
		}
		else
		{
			print "$rotate{$jpegpath} doesn't fit!!!\n\n";
			exit;
		}
	
		++$c; 							# increment counter 

		&rows; 			# print table row
	}	
}

sub header
{
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

print HTML <<"zarp";
<table>
<tr>
<TD > # </td>
<td > jpeg </td>
<td > file </td>
<td > acc_x </td>
<td > acc_y </td>
<td > acc_z </td>
<td > roate </td>
<td > EXIF </td>
</tr>
zarp

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
} 1;


sub rows
{
print "$jpegpath jpegpath ---------------- \n";

			print HTML <<"zarp";
<tr height=400px>
<td> $c </td>
<td> <div id="div"><img height="$imgheight" src="$jpegpath" ></div> </TD>
<TD width=20px> <A HREF="$jpegpath">$jpegname</A></td>
<td width=20px> acc_x $acc_x{$jpegpath}</td>
<td width=20px> acc_y $acc_y{$jpegpath}</td>
<td width=20px> acc_z $acc_z{$jpegpath}</td>
<td width=20px> $rotate{$jpegpath} CW [$rounded{$jpegpath}]</td>
<td width=20px> $ETrot{$jpegpath} </td>

<td  >  <div id="rotate$rounded{$jpegpath}"><img height="$imgheight" src="$jpegpath"  ></div></td>
</tr>
zarp

			print "\n";

			# print numeric table row
			
			print HTMLNUM <<"zarp";
<tr>
<TD > <A HREF="$jpegpath">$jpegpath</A></td>
<td > $acc_x{$jpegpath}</td>
<td > $acc_y{$jpegpath}</td>
<td > $acc_z{$jpegpath}</td>
<td > $rotate{$jpegpath} CW [$rounded{$jpegpath}]</td>
<td > $ETrot{$jpegpath} </td>
</tr>
zarp
print "\n";
} 1;

sub footer
{
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
} 1;


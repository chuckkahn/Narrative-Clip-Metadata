# script to prepare Narrative photos with EXIF metadata 
# for upload via Google+ Auto Backup

use File::Find::Rule;	# find all the subdirectories of a given directory

my $home = "/Users/chuckkahn/";			# home directory
# my $home = "/Users/charleskahn/";

# my $path= $home . "Pictures/Narrative\ Clip/2014/05/02c";    # path to narrative jpegs
my $path= $home . "Pictures/Narrative\ Clip/2014/06/20";    # path to narrative jpegs

my @folders = File::Find::Rule->file->in( $path );

$html = "narrative_pics.html";
open (HTML, ">$html");		# open file for output

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

push ( @INC,"/usr/bin/exiftool");

use lib qw(..);

use JSON qw( );		# using JSON 

foreach my $i (@folders)			# going through the directory
{
	if ($i =~ /(.*)\/(\d*)(.json)/ )		# looking for .json files
	{
		$path = $1;
		$file = $2;
		$ext  = $3;

		$jsonpath{$file}  = $path . "/" . $file . ".json";

		my $filename = $jsonpath{$file};

		print $filename . "\n\n";

		my $json_text = do {
		   open(my $json_fh, "<:encoding(UTF-8)", $filename)
			  or die("Can't open \$filename\": $!\n");
		   local $/;
		   <$json_fh>
		};

#		print $json_text . "\n";

		my $json = JSON->new;

#		print $json . "\n";

		my $decoded = $json->decode($json_text);
		$meta_json{$file} = $decoded;

		$n1{$file} = $decoded->{'acc_data'}{'samples'}[0][0];	# grabbing acc_data numbers...
		$n2{$file} = $decoded->{'acc_data'}{'samples'}[0][1];
		$n3{$file} = $decoded->{'acc_data'}{'samples'}[0][2];
		
		$imagepath{$file} = $path . $file . ".jpg";
		$imagepath{$file} =~  s/meta//;

		if ( $n2{$file} > 800 ) 				# setting rotation values
		{
			$rotate{$file} = 90;
			$ETrot{$file} = 6;
		}
		elsif ( $n2{$file} > 140 ) 
		{
			$rotate{$file} = 180;
			$ETrot{$file} = 3;
		}
		elsif ( $n2{$file} < -198 ) 
		{
			$rotate{$file} = 270;
			$ETrot{$file} = 8;
		}
		elsif ( $n2{$file} < 60 ) 
		{
			$rotate{$file} = 0;
			$ETrot{$file} = 1;
		}
	}
}

@files = sort { $a <=> $b } keys %n1;		# sort by file order

# @files = sort { $n2{$b} <=> $n1{$a} } keys %n1;	# sort by 2nd acc_data number

# exiftool -n -orientation=8 210506c.jpg

# 1 = Horizontal (normal) 
# 3 = Rotate 180 
# 6 = Rotate 90 CW 
# 8 = Rotate 270 CW

$height = "15%";

foreach $file (@files)
{
		++$c;
		# print table row
		print HTML <<"zarp";
<tr>
<td> $c </td>
<td> <div id="div"><img  height="$height" src="$imagepath{$file}" ></div> </TD>
<TD width=20px> <A HREF="$imagepath{$file}">$file</A></td>
<td width=20px> n1 $n1{$file}</td>
<td width=20px> n2 $n2{$file}</td>
<td width=20px> n3 $n3{$file}</td>
<td width=20px> $rotate{$file} </td>
<td height=200% >  <div id="rotate$rotate{$file}"><img height="$height" src="$imagepath{$file}"  ></div></td>
</tr>
zarp


$sfile = $imagepath{$file};
$sfile =~ s/ /\\ /g;

print "\n";

system "exiftool '-alldates<\${directory}\$filename' -overwrite_original $sfile" || die "exif1 fail" ;		# set EXIF date by file and directory name
system "exiftool -alldates-=4 -overwrite_original $sfile";													# adjust for timezone (EST)
system "exiftool -n -orientation=$ETrot{$file} -overwrite_original $sfile";									# set orientation
system "exiftool -model='Narrative Clip' -overwrite_original $sfile";										# set EXIF Camera model to "Narrative Clip"
}

print HTML <<"zarp";
</table>
</body>
</html>
zarp

close (HTML);

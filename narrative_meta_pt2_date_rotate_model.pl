# script to add EXIF metadata to Narrative Clip jpegs 

use File::Find::Rule;	# find all the subdirectories of a given directory

my $home = "/Users/chuckkahn/";			# user's home directory
# my $home = "/Users/charleskahn/";

my $path= $home . "Pictures/Narrative\ Clip/2014r/07/20/";    # path to narrative jpegs

push ( @INC,"/usr/bin/exiftool");

use lib qw(..);

use JSON qw( );		# using JSON 

my @folders = File::Find::Rule->file->in( $path );

print "PATH is " . $path . "\n\n";

foreach my $filepath (@folders)				# going through the directory
{
	if ($filepath =~ /(.*)\/(\d*)(.jpg)/ )		# looking for .jpeg files
	{
		$path = $1;
		$file = $2;
		$ext  = $3;

		print $filepath . "\n";
	
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

			my $decoded = $json->decode($json_text);
			$meta_json{$filepath} = $decoded;

			$n1{$filepath} = $decoded->{'acc_data'}{'samples'}[0][0];	# grabbing acc_data numbers...
			$n2{$filepath} = $decoded->{'acc_data'}{'samples'}[0][1];
			$n3{$filepath} = $decoded->{'acc_data'}{'samples'}[0][2];

			# exiftool -n -orientation=8 210506c.jpg

			# 1 = Horizontal (normal) 
			# 3 = Rotate 180 
			# 6 = Rotate 90 CW 
			# 8 = Rotate 270 CW
		
			if ( $n2{$filepath} > 800 ) 				# setting rotation values
			{
				$rotate{$filepath} = 90;
				$ETrot{$filepath} = 6;
			}
			elsif ( $n2{$filepath} > 140 ) 
			{
				$rotate{$filepath} = 180;
				$ETrot{$filepath} = 3;
			}
			elsif ( $n2{$filepath} < -198 ) 
			{
				$rotate{$filepath} = 270;
				$ETrot{$filepath} = 8;
			}
			elsif ( $n2{$filepath} < 60 ) 
			{
				$rotate{$filepath} = 0;
				$ETrot{$filepath} = 1;
			}
		
			++$c; 							# increment counter 

			$sfile = $jpegpath{$filepath};
			$sfile =~ s/ /\\ /g;				# changing spaces in jpeg path to "\ " for command line usage

			print "$sfile [space-d file]\n";

			# sending system exiftool command-line
			# (seem inefficient and slow?)

			$ifcondition = "-if 'not \$model'";		# set condition to not change if camera model is set
		#	$ifcondition = "";

			print "set date and shift by 4 hours (EST timezone), set rotation and camera model\n";
			system "exiftool '-alldates<\${directory}\$filename' -execute -alldates-=4 -n -orientation=$ETrot{$filepath} -model='Narrative Clip' -common_args -overwrite_original $ifcondition $sfile" || die "exif1 fail" ;		

			# display date, camera model and orientation
			# system "exiftool -DateTimeOriginal -model -orientation $sfile";													

			print "----------------------------\n\n";
		
			if ($c > 4)
			{
				exit;
			}
		}
	}
}


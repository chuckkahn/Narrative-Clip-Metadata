# script to add EXIF orientation metadata to Narrative Clip jpegs 

use File::Find::Rule;	# find all the subdirectories of a given directory

my $home = "/Users/chuckkahn/";			# user's home directory
# my $home = "/Users/charleskahn/";

my $path= $home . "Pictures/Narrative\ Clip/2014/";    # path to narrative jpegs

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

#		print $filepath . "\n";
	
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

			$rotate{$filepath} = rad_to_deg( $pi - atan2 ( $acc_y{$filepath}, $acc_x{$filepath} ) ) ;
			
			print "rotation is $rotate{$filepath}\n";

			use POSIX;
			$rotate{$filepath} = ceil ($rotate{$filepath} );     # using ceil to round

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

			$sfile = $jpegpath{$filepath};
			$sfile =~ s/ /\\ /g;				# changing spaces in jpeg path to "\ " for command line usage

			# print "$sfile [space-d file]\n";

			# sending system exiftool command-line
			# (seem inefficient and slow?)

		#	 $ifcondition = "-if 'not \$orientation'";		# set condition if orientation is not set
			$ifcondition = "";

			print "set orientation $ETrot{$filepath}\n";

#			system "exiftool -orientation= -progress -overwrite_original -n $ifcondition $sfile" || die "exif1 fail" ;				# wipe orientation
			system "exiftool -orientation=$ETrot{$filepath} -overwrite_original -n $ifcondition $sfile" || die "exif1 fail" ;		# set orientation

			# display date, camera model and orientation
			system "exiftool -DateTimeOriginal -model -orientation $sfile";													

			print "----------------------------\n\n";
		
			if ($c > 33333)
			{
				exit;
			}
		}
	}
}


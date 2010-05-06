module OpenTox

	class Compound #< OpenTox

		attr_reader :inchi, :uri

		# Initialize with <tt>:uri => uri</tt>, <tt>:smiles => smiles</tt> or <tt>:name => name</tt> (name can be also an InChI/InChiKey, CAS number, etc)
		def initialize(params)
			@@cactus_uri="http://cactus.nci.nih.gov/chemical/structure/"
			if params[:smiles]
				@inchi = smiles2inchi(params[:smiles])
				@uri = File.join(@@config[:services]["opentox-compound"],URI.escape(@inchi))
			elsif params[:inchi]
				@inchi = params[:inchi]
				@uri = File.join(@@config[:services]["opentox-compound"],URI.escape(@inchi))
			elsif params[:sdf]
				@inchi = sdf2inchi(params[:sdf])
				@uri = File.join(@@config[:services]["opentox-compound"],URI.escape(@inchi))
			elsif params[:name]
				# paranoid URI encoding to keep SMILES charges and brackets
				@inchi = RestClientWrapper.get("#{@@cactus_uri}#{URI.encode(params[:name], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}/stdinchi").chomp
				@uri = File.join(@@config[:services]["opentox-compound"],URI.escape(@inchi))
			elsif params[:uri]
				@uri = params[:uri]
				case params[:uri]
				when /ambit/ # Ambit does not deliver InChIs reliably
					smiles = RestClientWrapper.get @uri, :accept => 'chemical/x-daylight-smiles'
					@inchi = obconversion(smiles,'smi','inchi')
				when /InChI/ # shortcut for IST services
					@inchi = params[:uri].sub(/^.*InChI/, 'InChI')
				else
					@inchi = RestClientWrapper.get @uri, :accept => 'chemical/x-inchi'
				end
			end
		end

		# Get the (canonical) smiles
		def smiles
			obconversion(@inchi,'inchi','can')
		end

		def sdf
			obconversion(@inchi,'inchi','sdf')
		end

		def image
			RestClientWrapper.get("#{@@cactus_uri}#{@inchi}/image")
		end

		def image_uri
			"#{@@cactus_uri}#{@inchi}/image"
		end

		# Matchs a smarts string
		def match?(smarts)
			obconversion = OpenBabel::OBConversion.new
			obmol = OpenBabel::OBMol.new
			obconversion.set_in_format('inchi')
			obconversion.read_string(obmol,@inchi) 
			smarts_pattern = OpenBabel::OBSmartsPattern.new
			smarts_pattern.init(smarts)
			smarts_pattern.match(obmol)
		end

		# Match an array of smarts features, returns matching features
		def match(smarts_array)
			smarts_array.collect{|s| s if match?(s)}.compact
		end

		def sdf2inchi(sdf)
			obconversion(sdf,'sdf','inchi')
		end

		def smiles2inchi(smiles)
			obconversion(smiles,'smi','inchi')
		end

		def smiles2cansmi(smiles)
			obconversion(smiles,'smi','can')
		end

		def obconversion(identifier,input_format,output_format)
			obconversion = OpenBabel::OBConversion.new
			obmol = OpenBabel::OBMol.new
			obconversion.set_in_and_out_formats input_format, output_format
			obconversion.read_string obmol, identifier
			case output_format
			when /smi|can|inchi/
				obconversion.write_string(obmol).gsub(/\s/,'').chomp
			else
				obconversion.write_string(obmol)
			end
		end
	end
end

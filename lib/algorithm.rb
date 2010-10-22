module OpenTox

  module Algorithm 

    include OtObject

    class Generic 
      include Algorithm
      #include OtObject
      protected
#      def initialize(owl)
#        @title = owl.get("title")
#        @date = owl.get("date")
#        @uri = owl.uri 
#      end
      
    end

    class Fminer < Generic

      def self.create_feature_dataset(params)
				LOGGER.debug File.basename(__FILE__) + ": creating feature dataset"
        resource = RestClient::Resource.new(params[:feature_generation_uri])
        resource.post :dataset_uri => params[:dataset_uri], :feature_uri => params[:feature_uri]
      end

			def self.uri
				File.join(CONFIG[:services]["opentox-algorithm"], "fminer")
			end
    end

    class Lazar 
			
			def self.create_model(params)
				LOGGER.debug params
				LOGGER.debug File.basename(__FILE__) + ": creating model"
				LOGGER.debug File.join(CONFIG[:services]["opentox-algorithm"], "lazar")
        resource = RestClient::Resource.new(File.join(CONFIG[:services]["opentox-algorithm"], "lazar"), :content_type => "application/x-yaml")
        @uri = resource.post(:dataset_uri => params[:dataset_uri], :prediction_feature => params[:prediction_feature], :feature_generation_uri => File.join(CONFIG[:services]["opentox-algorithm"], "fminer")).body.chomp
			end

			def self.uri
				File.join(CONFIG[:services]["opentox-algorithm"], "lazar")
			end

    end

    class Similarity
      def self.weighted_tanimoto(fp_a,fp_b,p)
        common_features = fp_a & fp_b
        all_features = (fp_a + fp_b).uniq
        common_p_sum = 0.0
        if common_features.size > 0
          common_features.each{|f| common_p_sum += OpenTox::Utils.gauss(p[f])}
          all_p_sum = 0.0
          all_features.each{|f| all_p_sum += OpenTox::Utils.gauss(p[f])}
          common_p_sum/all_p_sum
        else
          0.0
        end
      end
      def self.euclidean(prop_a,prop_b)
        common_properties = prop_a.keys & prop_b.keys
        if common_properties.size > 1
          dist_sum = 0
          common_properties.each do |p|
            dist_sum += (prop_a[p] - prop_b[p])**2
          end
          1/(1+Math.sqrt(dist_sum))
        else
          nil
        end
      end
    end

  end
end

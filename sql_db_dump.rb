require 'aws-sdk'
=begin
s3 = Aws::S3::Client.new(
	region: 'ap-southeast-1')
=end
s3 = Aws::S3::Client.new(region: 'ap-southeast-1')
s3.list_objects({:bucket => "sz-db-dumps",:prefix => "2016/09/25/mysql-2016-09-25-13-30-01/inasra"}).contents.each do |content|
	begin
		key = content.key
		file = File.join("/Users/Surya",key)
		FileUtils.mkdir_p(File.dirname(file))
		if not File.exists?file
			s3.get_object({:bucket => "sz-db-dumps",:key => key,:response_target =>file})
			puts "saved"
		end
	rescue Exception => e 
		puts e.message

	end
end

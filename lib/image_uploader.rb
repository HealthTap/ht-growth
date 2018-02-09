# Basic interface for writing to the guest s3 bucket.
# Right now only used for medication pages.
# Use ImageUploader.write_image(key, local_filename), where key includes
# a folder and identifier (ex. 'medications/1')
class ImageUploader
  @s3_client = nil

  def self.client
    if @s3_client.nil?
      consul_settings = App.settings.consul
      access_key_id = consul_settings[:aws][:access_key_id]
      secret_access_key = consul_settings[:aws][:secret_access_key]
      @s3_client = ::Aws::S3::Client.new(region: 'us-west-1',
                                         access_key_id: access_key_id,
                                         secret_access_key: secret_access_key)
    end
    @s3_client
  end

  # Opens a file and writes it to the guest s3 bucket
  def self.write_image(key, filename)
    File.open(filename, 'rb') do |file|
      client.put_object(bucket: App.settings.s3[:bucket],
                        key: key, body: file, acl: 'public-read')
    end
  end
end

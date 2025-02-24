namespace :disposable_email do
  desc "Downloads the latest list of disposable emails"
  task download: :environment do
    require 'net/http'
    require 'uri'

    begin
      uri = URI("https://disposable.github.io/disposable-email-domains/domains.txt")
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        path = Rails.root.join("data/disposable_email_domains.txt")
        File.write(path, response.body)
        puts "Successfully downloaded disposable email domains list"
      else
        puts "Failed to download: HTTP #{response.code}"
      end
    rescue => e
      puts "Error downloading disposable email domains: #{e.message}"
      raise
    end
  end
end

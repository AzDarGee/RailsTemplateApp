module DisposableEmailService
    module_function

    def disposable?(email_address)
        email = Mail::Address.new(email_address.downcase) rescue nil

        binding.remote_pry

        if email
            disposable_email_domains.include?(email.domain)
        else
            false
        end
    end

    def disposable_email_domains
        @_disposable_email_domains ||= Set.new(File.readlines(Rails.root.join("data", "disposable_email_domains.txt")).map(&:strip))
    end
end
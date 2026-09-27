require "net/sftp"

module BankUpload
  def self.push(contents)
    Net::SFTP.start(ENV.fetch("BANK_SFTP_HOST"), ENV.fetch("BANK_SFTP_USER"), password: ENV.fetch("BANK_SFTP_PASSWORD")) do |sftp|
      sftp.file.open("/inbound/ach-#{Time.now.to_i}.txt", "w") { |f| f.write(contents) }
    end
  end
end

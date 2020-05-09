module PopulateDemoData
  def self.run
    populate_users
    populate_certificate_instructors
  end

  def self.load_user_ids
    User.where.not(email: 'demo@example.com').pluck(:id)
  end

  def self.populate_users
    (1..100).each do |n|
      name = Faker::Name.unique.name
      email = Faker::Internet.unique.safe_email(name: name)
      password = SecureRandom.hex
      User.create!(name: name, email: email, password: password)
    end
  end

  def self.populate_certification_instructors
    CertificateInstructor.destroy_all

    user_ids = load_user_ids
    user_ids.shuffle!
    Certification.all.each do |cert|
      pass_on = []
      rand(3..7).times do |n|
        id = user_ids.pop
        cert.certification_instructors.create!(user_id: id) unless cert.certification_instructors.where(user_id: id).exists?
        pass_on.push(id) if rand(1..3) == 1
      end
      user_ids.push(*pass_on)
    end
  end

  def self.populate_certification_issuances
    puts "STARTING THING"
    CertificationIssuance.destroy_all

    user_ids = load_user_ids
    user_ids.shuffle!
    Certification.all.each do |cert|
      instructors = cert.instructors.pluck(:id)
      rand(15..30).times do |n|
        id = user_ids.sample
        user = User.find(id)
        cert.certification_issuances.create!(
          user_id: id,
          issued_at: Date.today - rand(1..365),
          notes: "#{user.name} is so cool. They passed with flying colors",
          certifier_id: instructors.sample
        ) unless cert.certification_issuances.where(user_id: id).exists?
      end
      puts "DONE THING #{cert}"
    end

    puts "NOW REVOKING"

    cert_iss = CertificationIssuance.all.to_a
    cert_iss.shuffle!
    cert_count = Certification.all.count
    rand((cert_count * 3)..(cert_count * 5)).times do |n|
      cert_iss[n].revoke!(cert_iss[n].certification.instructors.to_a.sample, "Whoops, not gonna let #{cert_iss[n].user.name} use this space anymore")
    end
  end
end

class ImportBeaches
  def all
    cleanup
    import_beaches
    Rails.logger.info "#{Store.where(store_type: :beach).count} total stores"
  end

  def cleanup
    Store.where(store_type: :beach).delete_all
  end

  def import_beaches
    import 'Importing beaches', 'praias.csv' do |file|
      CSV.new(file, headers: true, skip_blanks: true).each do |csv|
        store = Store.new(
          name: csv[1]&.strip,
          country: 'Portugal',
          store_type: :beach,
          city: csv[4]&.strip,
          street: csv[5]&.strip,
          district: "#{csv[3]}, #{csv[2]}",
          latitude: csv[6],
          longitude: csv[7],
          source: 'DECO Proteste'
        )
        season_dates = csv[25].split(' a ')
        season_dates = nil unless season_dates.size == 2
        store.beach_configuration = BeachConfiguration.new(
          category: csv[8].strip == 'Fluvial' ? :river : :ocean,
          beach_type: csv[9]&.strip,
          ground: csv[10]&.strip,
          restrictions: csv[11]&.strip,
          risk_areas: csv[12]&.strip,
          average_users: csv[13]&.strip,
          guarded: csv[14],
          first_aid_station: csv[15],
          wc: csv[16],
          showers: csv[17],
          accessibility: csv[18],
          garbage_collection: csv[19],
          cleaning: csv[20],
          info_panel: csv[21],
          restaurant: csv[22],
          parking: csv[23],
          parking_spots: csv[24],
          season_start: season_dates ? Date.parse(season_dates.first) : nil,
          season_end: season_dates ? Date.parse(season_dates.last) : nil,
          water_quality: csv[31],
          water_quality_url: csv[32]&.strip,
          quality_flag: csv[33],
          water_quality_entity: csv[35]&.strip,
          water_quality_contact: csv[36]&.strip,
          water_contact_email: csv[37]&.strip,
          security_entity: csv[38]&.strip,
          security_entity_contact: csv[39]&.strip,
          security_entity_email: csv[40]&.strip,
          health_authority: csv[41]&.strip,
          health_authority_contact: csv[42]&.strip,
          health_authority_email: csv[43]&.strip,
          municipality: csv[44]&.strip,
          municipality_contact: csv[45]&.strip,
          municipality_email: csv[46]&.strip
        )

        store.save
      end
    end
  end

  private

  def import(store_name, filename)
    Rails.logger.info "Starting #{store_name}, we have #{Store.count} total stores"

    file = Rails.root.join('db/files', filename).open

    yield file

    file.close

    Rails.logger.info "#{Store.count} total stores"
  end
end

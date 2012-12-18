class CensusImporter
  def self.run(ten_year, one_year)
    time = Benchmark.realtime do
      process_ten_year(ten_year)
      process_one_year(one_year)
    end
    LOG('import', :cyan, "Completed in #{time}s")
    LOG('import', :cyan, "Success!", :green)
    return true
  end

  private

  def self.process_ten_year(file_name)
    LOG('import', :cyan, "Processing 2000-2010 data...")
    File.open(File.join(DATA_DIRECTORY, '20002010census.csv'), "r:ISO-8859-1") do |f|
      Estimate.transaction do
        f.read.encode('UTF-8').split("\r\n").each do |line|
          cells = line.split(',')
          if(cells[0] == "SUMLEV" || cells[0] == "40" || cells.count != 20)
            #LOG('import', :cyan, "skipped " + line)
            next
          end
          (0..9).each do |idx|
            Estimate.create(:state => get_state(cells[5], cells[3]), :county_name => cells[6], :county_id => cells[4], :fips_id => cells[3].rjust(2, "0") + cells[4].rjust(3, "0"), :population => cells[idx+8], :year => (2000 + idx).to_s)
          end
          Estimate.create(:state => get_state(cells[5], cells[3]), :county_name => cells[6], :county_id => cells[4], :fips_id => cells[3].rjust(2, "0") + cells[4].rjust(3, "0"), :population => cells[19], :year => "2010")
        end
      end
    end
  end

  def self.process_one_year(file_name)
    LOG('import', :cyan, "Processing 2010-2011 data...")
    File.open(File.join(DATA_DIRECTORY, '20102011census.csv'), "r:ISO-8859-1") do |f|
      Estimate.transaction do
        f.read.encode('UTF-8').split("\r\n").each do |line|
          cells = line.split(',')
          #LOG('import', :cyan, "scanning " + cells[0] + " " + cells.count.to_s, :light_black)
          if(cells[0] == "SUMLEV" || cells[0].to_i.to_s == "40" || cells.count != 36)
            #LOG('import', :cyan, "Missing cells: " + line, :red) if cells.count != 36
            #LOG('import', :cyan, "Summary row: " + line, :red) if cells[0] == "SUMLEV"
            #LOG('import', :cyan, "Sumlev 40: " + line, :red) if cells[0] == "40"
            #LOG('import', :cyan, "skipped " + line)
            next
          end
          #LOG('import', :cyan, "inserting " + line)
          Estimate.create(:state => get_state(cells[5], cells[3]), :county_name => cells[6], :county_id => cells[4], :fips_id => cells[3].rjust(2, "0") + cells[4].rjust(3, "0"), :population => cells[10], :year => "2011")
        end
      end
    end
  end

  def self.get_state(name, id)
    s = State.first(:name => name, :number => id)
    unless(s)
      s = State.create(:name => name, :number => id)
    end
    return s
  end
end

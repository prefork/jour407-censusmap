require './environment'

task :default => [:export]

desc "Copy data to app folder"
task :sync => [:data_directory] do
  names = {}
  LOG('sync', :magenta, "Cleaning up old files...")
  #`rm -f #{File.join(OUTPUT_DIRECTORY, '*')}`
  ['map.json', 'population_summary.json', 'trie.json', 'index.json'].each do |file_name|
    unless(File.exists?(File.join(DATA_DIRECTORY, file_name)))
      LOG('error', :red, "Missing file '#{file_name}'.")
      LOG('error', :red, "Run 'rake export' to fix this.")
      exit
    end
    LOG('sync', :magenta, "Copying file '#{file_name}'...")
    hsh = Digest::SHA1.hexdigest(File.read(File.join(DATA_DIRECTORY, file_name)))[0,7]
    names[file_name.split('.').first] = file_name.split('.').first + ".#{hsh}.json"
    `cp #{File.join(DATA_DIRECTORY, file_name)} #{File.join(OUTPUT_DIRECTORY, names[file_name.split('.').first])}`
  end
  LOG('sync', :magenta, "Writing key...")
  File.open(File.join(OUTPUT_DIRECTORY, 'key.js'), 'w') {|f|
    f.write("var CensusMap = CensusMap || {};\n")
    f.write("CensusMap.dataFiles = {map: '#{names['map']}', summary: '#{names['population_summary']}', trie: '#{names['trie']}', index: '#{names['index']}'};")
  }
  LOG('sync', :magenta, "Success!", :green)
end

desc "Export processed data to JSON"
task :export => [:import] do
#task :export do
  CensusExporter.run(DATA_DIRECTORY)
end

desc "Import Census datafiles to SQLite"
task :import => [:download] do
  CensusImporter.run(File.join(DATA_DIRECTORY, '20002010census.csv'), File.join(DATA_DIRECTORY, '20102011census.csv'))
end

desc "Download Census datafiles"
task :download => [:data_directory] do
  time = Benchmark.realtime do
    LOG('rake', :yellow, "Downloading map of US counties...")
    `wget --quiet http://files.nben.es/get/UqCtZs9oL23KRfHZTHxbug/us.json -O #{File.join(DATA_DIRECTORY, 'map.json')}`

    LOG('rake', :yellow, "Downloading census data (2000-2010)...")
    `wget --quiet http://www.census.gov/popest/data/intercensal/county/files/CO-EST00INT-TOT.csv -O #{File.join(DATA_DIRECTORY, '20002010census.csv')}`

    LOG('rake', :yellow, "Downloading census data (2010-2011)...")
    `wget --quiet http://www.census.gov/popest/data/counties/totals/2011/files/CO-EST2011-Alldata.csv -O #{File.join(DATA_DIRECTORY, '20102011census.csv')}`
  end
  LOG('rake', :yellow, "Completed in #{time}s")
  LOG('rake', :yellow, 'Success!', :green)
end

desc "Make sure the data directory exists."
task :data_directory do
  unless(Dir.exists?(DATA_DIRECTORY))
    Dir.mkdir(DATA_DIRECTORY)
  end
end
